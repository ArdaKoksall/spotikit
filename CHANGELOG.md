## 2.0.1
### 🛠 Example App Update — February 22, 2026

- Updated example app to remove `flutter_dotenv` and all auth/Web API references
- Credentials are now set as plain constants at the top of `example/lib/main.dart`
- Quick Play chips now use hardcoded Spotify URIs instead of Web API search
- Removed `.env` asset and `flutter_dotenv` dependency from example `pubspec.yaml`

---

## 2.0.0
### 🚀 App Remote Only — February 22, 2026

This is a **breaking change** release. Spotikit now wraps **only** the Spotify App Remote SDK.
All Spotify Web API functionality and OAuth authentication have been removed.

#### ⚠️ Breaking Changes

- **`initialize()`** no longer accepts `clientSecret`, `scope`, or `authenticate` parameters.
  Only `clientId`, `redirectUri`, and the optional `connectToRemote` flag remain.
- **Removed methods:** `authenticateSpotify()`, `getAccessToken()`, `getPlayingTrackFull()`, `playSong()`
- **Removed streams:** `accessTokenStream`, `onAuthStateChanged`
- **Removed models:** `SpotifyTrack`, `AlbumImage`, `AuthState` (and subclasses `AuthSuccess`, `AuthFailure`, `AuthCancelled`)
- **Removed Dart package:** `api/spotify_api.dart` (SpotifyApi class)
- **Removed pub dependencies:** `dio`, `path`, `yaml`

#### Changes

- `initialize()` now only requires `clientId` and `redirectUri`
- `SpotikitPlugin.kt` stripped of all auth code — no more `AuthManager`, `EventChannel`, or `PluginRegistry.ActivityResultListener`
- `AuthManager.kt` deleted
- `android/build.gradle` now only depends on `spotify-app-remote` (removed `spotify-auth`, `okhttp3`, `kotlinx-coroutines`, `gson`, `security-crypto`)

#### Migration Guide

Before (v1.x):
```dart
await spotikit.initialize(
  clientId: 'id',
  clientSecret: 'secret',
  redirectUri: 'myapp://callback',
  scope: 'user-read-playback-state ...',
);
spotikit.onAuthStateChanged.listen((state) { ... });
await spotikit.authenticateSpotify();
```

After (v2.x):
```dart
await spotikit.initialize(
  clientId: 'id',
  redirectUri: 'myapp://callback',
);
await spotikit.connectToSpotify();
```

---

## 1.0.0
### 🎉 First Stable Release — January 23, 2026

This marks the first stable release of Spotikit.

#### Features
- **Authentication**: Full Authorization Code flow with automatic token refresh
- **Playback Control**: Play, pause, resume, skip, previous, seek, and relative skip (forward/backward)
- **Realtime Playback State**: Stream-based playback state updates with track info, progress, and pause status
- **Search & Play**: One-shot search functionality to find and play tracks
- **Full Track Metadata**: Rich metadata via Spotify Web API (album, images, popularity, etc.)
- **Centralized Logging**: Built-in logging for debugging and diagnostics

#### Platform Support
- ✅ Android (App Remote SDK + Web API)
- ⏳ iOS (planned for future release)

---

## 0.0.24
### Demo Release
- First good release I hope.
