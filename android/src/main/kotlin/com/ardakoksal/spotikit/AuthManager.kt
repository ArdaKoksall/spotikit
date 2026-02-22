package com.ardakoksal.spotikit

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.spotify.sdk.android.auth.AuthorizationClient
import com.spotify.sdk.android.auth.AuthorizationRequest
import com.spotify.sdk.android.auth.AuthorizationResponse
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class AuthManager : PluginRegistry.ActivityResultListener {

    companion object {
        private const val TAG = "AuthManager"
        private const val AUTH_REQUEST_CODE = 1337
    }

    private var pendingResult: MethodChannel.Result? = null
    private var onTokenReceived: ((String) -> Unit)? = null

    /**
     * Launches the Spotify authorization flow.
     * [onSuccess] is called with the access token when auth succeeds.
     * [result] is called with an error if auth fails.
     */
    fun authorize(
        activity: Activity,
        clientId: String,
        redirectUri: String,
        result: MethodChannel.Result,
        onSuccess: (String) -> Unit
    ) {
        if (pendingResult != null) {
            result.error("AUTH_IN_PROGRESS", "An authorization is already in progress", null)
            return
        }

        pendingResult = result
        onTokenReceived = onSuccess

        val request = AuthorizationRequest.Builder(
            clientId,
            AuthorizationResponse.Type.TOKEN,
            redirectUri
        )
            .setScopes(
                arrayOf(
                    "streaming",
                    "user-read-playback-state",
                    "user-modify-playback-state",
                    "user-read-currently-playing"
                )
            )
            .build()

        AuthorizationClient.openLoginActivity(activity, AUTH_REQUEST_CODE, request)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != AUTH_REQUEST_CODE) return false

        val response = AuthorizationClient.getResponse(resultCode, data)
        val pending = pendingResult
        val callback = onTokenReceived

        pendingResult = null
        onTokenReceived = null

        when (response.type) {
            AuthorizationResponse.Type.TOKEN -> {
                Log.d(TAG, "Auth succeeded, token received")
                if (callback != null && pending != null) {
                    callback(response.accessToken)
                } else {
                    pending?.error("AUTH_ERROR", "Internal error: no callback", null)
                }
            }
            AuthorizationResponse.Type.ERROR -> {
                Log.e(TAG, "Auth error: ${response.error}")
                pending?.error("AUTH_ERROR", response.error, null)
            }
            else -> {
                Log.w(TAG, "Auth cancelled or unknown response: ${response.type}")
                pending?.error("AUTH_CANCELLED", "Authorization was cancelled", null)
            }
        }

        return true
    }
}

