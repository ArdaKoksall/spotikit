package com.ardakoksal.spotikit

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class AuthManager(private val context: Context) : EventChannel.StreamHandler {

    companion object {
        private const val TAG = "AuthManager"
        private const val PREFS_NAME = "SpotifyTokenPrefs"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_TOKEN_EXPIRES_AT = "token_expires_at"
    }

    private var sharedPreferences: SharedPreferences
    private var eventSink: EventChannel.EventSink? = null

    // Networking
    private val httpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    // State
    private var _accessToken: String? = null
    @Volatile private var refreshToken: String? = null
    @Volatile private var tokenExpiresAt: Long = 0

    // Custom setter to update stream automatically
    var accessToken: String?
        get() = _accessToken
        private set(value) {
            _accessToken = value
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(value)
            }
        }

    // Coroutine Scope
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    init {
        // Initialize EncryptedSharedPreferences
        sharedPreferences = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context, PREFS_NAME, masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            Log.e(TAG, "EncryptedPrefs failed, using standard", e)
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
        loadTokensFromPrefs()
    }

    fun cleanup() {
        coroutineScope.cancel()
        eventSink = null
    }

    // --- Stream Handler Impl ---
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        Handler(Looper.getMainLooper()).post { events?.success(accessToken) }
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    // --- Token Logic ---

    fun getValidAccessToken(
        clientId: String,
        clientSecret: String,
        onSuccess: (String) -> Unit,
        onError: (String, String?) -> Unit
    ) {
        val bufferTimeMs = 5 * 60 * 1000
        if (accessToken != null && System.currentTimeMillis() < (tokenExpiresAt - bufferTimeMs)) {
            onSuccess(accessToken!!)
        } else if (refreshToken != null) {
            refreshToken(clientId, clientSecret, onSuccess, onError)
        } else {
            onError("NO_TOKEN", "No valid token available")
        }
    }

    fun exchangeCode(code: String, redirectUri: String, clientId: String, clientSecret: String, onSuccess: () -> Unit, onError: (String, String?) -> Unit) {
        coroutineScope.launch {
            try {
                val body = FormBody.Builder()
                    .add("grant_type", "authorization_code")
                    .add("code", code)
                    .add("redirect_uri", redirectUri)
                    .build()

                val response = makeTokenRequest(body, clientId, clientSecret)
                if (response != null) {
                    processTokenResponse(response)
                    withContext(Dispatchers.Main) { onSuccess() }
                } else {
                    throw Exception("Null response")
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { onError("token_exchange_failed", e.message) }
            }
        }
    }

    fun refreshToken(clientId: String, clientSecret: String, onSuccess: (String) -> Unit, onError: (String, String?) -> Unit) {
        val currentRefresh = refreshToken ?: return onError("NO_REFRESH_TOKEN", null)

        coroutineScope.launch {
            try {
                val body = FormBody.Builder()
                    .add("grant_type", "refresh_token")
                    .add("refresh_token", currentRefresh)
                    .build()

                val response = makeTokenRequest(body, clientId, clientSecret)
                if (response != null) {
                    processTokenResponse(response)
                    withContext(Dispatchers.Main) {
                        accessToken?.let { onSuccess(it) } ?: onError("REFRESH_FAILED", "Token null after refresh")
                    }
                } else {
                    throw Exception("Null response")
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { onError("REFRESH_ERROR", e.message) }
            }
        }
    }

    fun logout() {
        accessToken = null
        refreshToken = null
        tokenExpiresAt = 0
        sharedPreferences.edit().clear().apply()
    }

    private fun makeTokenRequest(formBody: FormBody, clientId: String, clientSecret: String): String? {
        val credentials = Base64.encodeToString("$clientId:$clientSecret".toByteArray(), Base64.NO_WRAP)
        val request = Request.Builder()
            .url("https://accounts.spotify.com/api/token")
            .addHeader("Authorization", "Basic $credentials")
            .post(formBody)
            .build()

        httpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return null
            return response.body?.string()
        }
    }

    private fun processTokenResponse(jsonBody: String) {
        val json = JSONObject(jsonBody)
        val newAccess = json.getString("access_token")
        val newRefresh = json.optString("refresh_token", "")
        if (newRefresh.isNotEmpty()) refreshToken = newRefresh

        tokenExpiresAt = System.currentTimeMillis() + (json.getInt("expires_in") * 1000L)

        // This setter triggers the stream update
        accessToken = newAccess
        saveTokensToPrefs()
    }

    private fun saveTokensToPrefs() {
        sharedPreferences.edit()
            .putString(KEY_ACCESS_TOKEN, accessToken)
            .putString(KEY_REFRESH_TOKEN, refreshToken)
            .putLong(KEY_TOKEN_EXPIRES_AT, tokenExpiresAt)
            .apply()
    }

    private fun loadTokensFromPrefs() {
        _accessToken = sharedPreferences.getString(KEY_ACCESS_TOKEN, null)
        refreshToken = sharedPreferences.getString(KEY_REFRESH_TOKEN, null)
        tokenExpiresAt = sharedPreferences.getLong(KEY_TOKEN_EXPIRES_AT, 0)
    }
}