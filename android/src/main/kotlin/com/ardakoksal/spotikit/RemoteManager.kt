package com.ardakoksal.spotikit

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.spotify.android.appremote.api.ConnectionParams
import com.spotify.android.appremote.api.Connector
import com.spotify.android.appremote.api.SpotifyAppRemote
import com.spotify.protocol.client.Subscription
import com.spotify.protocol.types.PlayerState
import io.flutter.plugin.common.MethodChannel

class RemoteManager(private val context: Context, private val methodChannel: MethodChannel) {

    companion object {
        private const val TAG = "RemoteManager"
    }

    private var spotifyAppRemote: SpotifyAppRemote? = null
    private var playerStateSubscription: Subscription<PlayerState>? = null

    fun connect(clientId: String, redirectUri: String, result: MethodChannel.Result) {
        if (!isSpotifyInstalled()) {
            result.error("SPOTIFY_NOT_INSTALLED", "Spotify is not installed", null)
            return
        }

        if (spotifyAppRemote?.isConnected == true) {
            result.success("Already connected")
            return
        }

        val params = ConnectionParams.Builder(clientId)
            .setRedirectUri(redirectUri)
            .showAuthView(true)
            .build()

        SpotifyAppRemote.connect(context, params, object : Connector.ConnectionListener {
            override fun onConnected(appRemote: SpotifyAppRemote) {
                spotifyAppRemote = appRemote
                Log.d(TAG, "Connected to Spotify App Remote")
                subscribeToPlayerState()
                result.success("Connected")
            }

            override fun onFailure(t: Throwable) {
                Log.e(TAG, "Connection failed", t)
                result.error("CONNECTION_ERROR", t.message, null)
            }
        })
    }

    fun disconnect(result: MethodChannel.Result? = null) {
        playerStateSubscription?.cancel()
        playerStateSubscription = null
        spotifyAppRemote?.let {
            if (it.isConnected) SpotifyAppRemote.disconnect(it)
        }
        spotifyAppRemote = null
        result?.success("Disconnected")
    }

    private fun subscribeToPlayerState() {
        playerStateSubscription?.cancel()
        playerStateSubscription = spotifyAppRemote?.playerApi?.subscribeToPlayerState()
            ?.setEventCallback { playerState ->
                val track = playerState.track
                if (track != null) {
                    try {
                        val imageRaw = track.imageUri?.raw
                        val imageUrl = if (imageRaw?.startsWith("spotify:image:") == true) {
                            "https://i.scdn.co/image/" + imageRaw.substring(14)
                        } else null

                        val map = hashMapOf(
                            "uri" to track.uri,
                            "name" to track.name,
                            "artist" to track.artist.name,
                            "isPaused" to playerState.isPaused,
                            "positionMs" to playerState.playbackPosition.toInt(),
                            "durationMs" to track.duration.toInt(),
                            "imageUri" to imageUrl
                        )
                        methodChannel.invokeMethod("playbackState", map)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error mapping state", e)
                    }
                }
            }

        playerStateSubscription?.setErrorCallback { t ->
            Log.e(TAG, "Player subscription error", t)
        }
    }

    // --- Controls ---

    // The logic below is explicit for every method.
    // It is slightly more verbose but 100% safe from type inference errors.

    fun play(uri: String, result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.play(uri)
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("PLAY_ERROR", t.message, null) }
        }
    }

    fun pause(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.pause()
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("PAUSE_ERROR", t.message, null) }
        }
    }

    fun resume(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.resume()
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("RESUME_ERROR", t.message, null) }
        }
    }

    fun skipNext(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.skipNext()
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("SKIP_ERROR", t.message, null) }
        }
    }

    fun skipPrevious(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.skipPrevious()
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("PREV_ERROR", t.message, null) }
        }
    }

    fun seekTo(positionMs: Long, result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.seekTo(positionMs)
                .setResultCallback { result.success(true) }
                .setErrorCallback { t -> result.error("SEEK_ERROR", t.message, null) }
        }
    }

    fun skipForward(seconds: Long, result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.playerState
                .setResultCallback { state ->
                    val newPos = state.playbackPosition + (seconds * 1000)
                    remote.playerApi.seekTo(newPos)
                        .setResultCallback { result.success(true) }
                        .setErrorCallback { t -> result.error("SEEK_ERROR", t.message, null) }
                }
                .setErrorCallback { t -> result.error("STATE_ERROR", t.message, null) }
        }
    }

    fun skipBackward(seconds: Long, result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.playerState
                .setResultCallback { state ->
                    val newPos = (state.playbackPosition - (seconds * 1000)).coerceAtLeast(0)
                    remote.playerApi.seekTo(newPos)
                        .setResultCallback { result.success(true) }
                        .setErrorCallback { t -> result.error("SEEK_ERROR", t.message, null) }
                }
                .setErrorCallback { t -> result.error("STATE_ERROR", t.message, null) }
        }
    }

    fun isPlaying(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.playerState
                .setResultCallback { state -> result.success(!state.isPaused) }
                .setErrorCallback { t -> result.error("STATE_ERROR", t.message, null) }
        }
    }

    fun getTrackInfo(result: MethodChannel.Result) {
        useRemote(result) { remote ->
            remote.playerApi.playerState
                .setResultCallback { state ->
                    val track = state.track
                    if (track != null) {
                        result.success(mapOf(
                            "artist" to track.artist.name,
                            "name" to track.name,
                            "uri" to track.uri,
                            "isPaused" to state.isPaused
                        ))
                    } else {
                        result.error("NO_TRACK", "No track playing", null)
                    }
                }
                .setErrorCallback { t -> result.error("STATE_ERROR", t.message, null) }
        }
    }

    // --- Helper ---
    // This simply checks the connection and passes the valid remote object to the block.
    // It does NOT handle the result callbacks; the block must do that.
    private fun useRemote(result: MethodChannel.Result, block: (SpotifyAppRemote) -> Unit) {
        val remote = spotifyAppRemote
        if (remote != null && remote.isConnected) {
            block(remote)
        } else {
            result.error("NOT_CONNECTED", "Spotify App Remote is not connected", null)
        }
    }

    private fun isSpotifyInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo("com.spotify.music", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}