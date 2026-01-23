package com.ardakoksal.spotikit

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import com.spotify.sdk.android.auth.AuthorizationClient
import com.spotify.sdk.android.auth.AuthorizationRequest
import com.spotify.sdk.android.auth.AuthorizationResponse
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class SpotikitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val CHANNEL_NAME = "spotikit"
        private const val EVENT_CHANNEL_NAME = "spotikit/token_stream"
        private const val AUTH_REQUEST_CODE = 1337
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context

    // Managers
    private lateinit var authManager: AuthManager
    private lateinit var remoteManager: RemoteManager

    // Activity State
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Config
    private var clientId: String? = null
    private var redirectUri: String? = null
    private var clientSecret: String? = null
    private var scope: String? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        // 1. Setup Channels
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)

        // 2. Init Managers
        authManager = AuthManager(context)
        eventChannel.setStreamHandler(authManager) // AuthManager handles the stream

        remoteManager = RemoteManager(context, channel)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        authManager.cleanup()
        remoteManager.disconnect()
    }

    // --- Method Call Handler ---
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                clientId = call.argument("clientId")
                redirectUri = call.argument("redirectUri")
                clientSecret = call.argument("clientSecret")
                scope = call.argument("scope")

                if (clientId != null && redirectUri != null && clientSecret != null && scope != null) {
                    result.success(true)
                } else {
                    result.error("INIT_FAILED", "Missing config", null)
                }
            }
            "authenticateSpotify" -> {
                if (activity == null || clientId == null || redirectUri == null || scope == null) {
                    result.error("ERROR", "Not initialized or no activity", null)
                    return
                }
                val req = AuthorizationRequest.Builder(clientId, AuthorizationResponse.Type.CODE, redirectUri)
                    .setScopes(scope!!.split(" ").toTypedArray())
                    .build()
                AuthorizationClient.openLoginActivity(activity, AUTH_REQUEST_CODE, req)
                result.success("Auth started")
            }
            "connectToSpotify" -> {
                if (clientId != null && redirectUri != null) {
                    remoteManager.connect(clientId!!, redirectUri!!, result)
                } else {
                    result.error("NOT_INIT", "Call initialize first", null)
                }
            }
            "getAccessToken" -> {
                if (clientId != null && clientSecret != null) {
                    authManager.getValidAccessToken(clientId!!, clientSecret!!,
                        onSuccess = { token -> result.success(token) },
                        onError = { code, msg -> result.error(code, msg, null) }
                    )
                } else {
                    result.error("NOT_INIT", "Call initialize first", null)
                }
            }
            "refreshToken" -> {
                if (clientId != null && clientSecret != null) {
                    authManager.refreshToken(clientId!!, clientSecret!!,
                        onSuccess = { token -> result.success(token) },
                        onError = { code, msg -> result.error(code, msg, null) }
                    )
                }
            }
            "logout" -> {
                authManager.logout()
                remoteManager.disconnect(result) // Disconnects and sends success
            }
            // Delegate Player Commands to RemoteManager
            "play" -> call.argument<String>("spotifyUri")?.let { remoteManager.play(it, result) }
            "pause" -> remoteManager.pause(result)
            "resume" -> remoteManager.resume(result)
            "skipTrack" -> remoteManager.skipNext(result)
            "previousTrack" -> remoteManager.skipPrevious(result)
            "seekTo" -> call.argument<Number>("positionMs")?.let { remoteManager.seekTo(it.toLong(), result) }
            "skipForward" -> remoteManager.skipForward(call.argument<Number>("seconds")?.toLong() ?: 0L, result)
            "skipBackward" -> remoteManager.skipBackward(call.argument<Number>("seconds")?.toLong() ?: 0L, result)
            "isPlaying" -> remoteManager.isPlaying(result)
            "getTrackInfo" -> remoteManager.getTrackInfo(result)
            "disconnect" -> remoteManager.disconnect(result)
            else -> result.notImplemented()
        }
    }

    // --- Activity Lifecycle ---
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
        remoteManager.disconnect()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode == AUTH_REQUEST_CODE) {
            val response = AuthorizationClient.getResponse(resultCode, intent)
            when (response.type) {
                AuthorizationResponse.Type.CODE -> {
                    if (redirectUri != null && clientId != null && clientSecret != null) {
                        authManager.exchangeCode(
                            response.code,
                            redirectUri!!,
                            clientId!!,
                            clientSecret!!,
                            onSuccess = { channel.invokeMethod("spotifyAuthSuccess", mapOf("accessToken" to authManager.accessToken)) },
                            onError = { code, msg -> channel.invokeMethod("spotifyAuthFailed", mapOf("error" to code, "message" to msg)) }
                        )
                    }
                }
                AuthorizationResponse.Type.ERROR -> channel.invokeMethod("spotifyAuthFailed", mapOf("error" to response.error))
                else -> channel.invokeMethod("spotifyAuthFailed", mapOf("error" to "cancelled"))
            }
            return true
        }
        return false
    }
}