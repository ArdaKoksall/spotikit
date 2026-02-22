package com.ardakoksal.spotikit

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SpotikitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val CHANNEL_NAME = "spotikit"
        private const val TAG = "SpotikitPlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    // Managers
    private lateinit var remoteManager: RemoteManager
    private val authManager = AuthManager()

    // Activity State
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Config
    private var clientId: String? = null
    private var redirectUri: String? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        remoteManager = RemoteManager(context, channel)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        remoteManager.disconnect()
    }

    // --- Method Call Handler ---
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                clientId = call.argument("clientId")
                redirectUri = call.argument("redirectUri")

                if (clientId != null && redirectUri != null) {
                    result.success(true)
                } else {
                    result.error("INIT_FAILED", "Missing clientId or redirectUri", null)
                }
            }
            "connectToSpotify" -> {
                val id = clientId
                val uri = redirectUri
                val act = activity

                if (id == null || uri == null) {
                    result.error("NOT_INIT", "Call initialize first", null)
                    return
                }

                // If already connected, skip auth
                if (remoteManager.isConnected()) {
                    result.success("Already connected")
                    return
                }

                if (act == null) {
                    result.error("NO_ACTIVITY", "No activity available", null)
                    return
                }

                // Step 1: OAuth auth flow → Step 2: App Remote connect
                authManager.authorize(act, id, uri, result) { _token ->
                    Log.d(TAG, "Auth succeeded, connecting App Remote")
                    remoteManager.connect(id, uri, result)
                }
            }
            "logout" -> {
                remoteManager.disconnect(result)
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
        remoteManager.activity = binding.activity
        binding.addActivityResultListener(authManager)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(authManager)
        activity = null
        activityBinding = null
        remoteManager.activity = null
        remoteManager.disconnect()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}