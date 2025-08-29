# Spotikit

Flutter plugin for integrating Spotify on Android using both the Spotify App Remote SDK (realtime playback control/state) and the Spotify Web API (rich metadata, search, etc.).

> Status: Experimental (v0.0.24). Android only for now. iOS support planned.

---
## Highlights (TL;DR)
- Auth (Authorization Code + refresh)
- Play / pause / resume / next / previous / seek / skip +/- seconds
- Realtime playback state stream (track, artist, progress, paused, image)
- One‑shot search & play first result
- Full track metadata via Web API
- Centralized logging & auto token refresh

---
## Platform Support
| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅     | Uses App Remote SDK + Web API |
| iOS      | ⏳     | Planned |
| Web/Desktop | ❌ | Not targeted |

---
## Prerequisites
1. Spotify Developer account: https://developer.spotify.com/dashboard
2. Create an app → copy Client ID (and Client Secret if using backend‑less flow here).
3. Add redirect URI (e.g. `your.app://callback`).
4. Use the SAME redirect URI in your AndroidManifest intent filter if you customize it.

Scopes requested by default (override if you want fewer):
```
user-read-playback-state user-modify-playback-state user-read-currently-playing app-remote-control streaming playlist-read-private playlist-read-collaborative playlist-modify-public playlist-modify-private user-library-modify user-library-read user-top-read user-read-playback-position user-read-recently-played user-follow-read user-follow-modify user-read-email user-read-private
```
Trim to the minimum you actually need.

---
## Installation & REQUIRED Android Init
Quick steps:
1. Add to `pubspec.yaml`:
   ```yaml
dependencies:
  spotikit: ^0.0.24
   ```
2. Fetch packages:
   ```
flutter pub get
   ```
3. IMPORTANT (one‑time per clone / after cleaning android dir): run the init script so the Spotify AARs are downloaded & Gradle includes are inserted at the top of `android/settings.gradle`:
   ```
dart run spotikit:android_init
   ```
   If you skip this, Gradle will fail because the required `spotify-app-remote` and `spotify-auth` modules won’t exist.
4. (Optional) If Gradle metadata gets messy or you want to re‑download AARs, clean with:
   ```
dart run spotikit:android_clean && dart run spotikit:android_init
   ```
5. Ensure `minSdkVersion >= 21`.

Intent filter (only if you changed the default scheme/host):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="your.app" android:host="callback" />
</intent-filter>
```

---
## Quick Start
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Spotikit.enableLogging();

  await Spotikit.initialize(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
    redirectUri: 'your.app://callback',
  );

  await Spotikit.authenticateSpotify();
  await Spotikit.connectToSpotify();
  await Spotikit.playUri(spotifyUri: 'spotify:track:11dFghVXANMlKmJXsNCbNl');

  Spotikit.onPlaybackStateChanged.listen((state) {
    print('Now playing: ${state.name} by ${state.artist} ${(state.progress * 100).toStringAsFixed(1)}%');
  });
}
```

---
## Auth State Stream
```dart
Spotikit.onAuthStateChanged.listen((auth) {
  switch (auth) {
    case AuthSuccess(:final accessToken):
      print('Authenticated. Token: $accessToken');
      break;
    case AuthFailure(:final error, :final message):
      print('Auth failed: $error $message');
      break;
    case AuthCancelled():
      print('User cancelled Spotify login');
      break;
  }
});
```

---
## Playback State Stream
```dart
final sub = Spotikit.onPlaybackStateChanged.listen((s) {
  print('Track: ${s.name} | Paused: ${s.isPaused} | Position: ${s.positionMs}/${s.durationMs}');
});
```
Fields: `uri`, `name`, `artist`, `isPaused`, `positionMs`, `durationMs`, `imageUri`, helpers: `progress`, `id`.

---
## Core Control APIs
| Action | Method |
|--------|--------|
| Play by URI | `Spotikit.playUri(spotifyUri: ...)` |
| Pause / Resume | `pause()` / `resume()` |
| Next / Previous | `skipTrack()` / `previousTrack()` |
| Seek absolute | `seekTo(positionMs: ...)` |
| Skip fwd/back seconds | `skipForward(seconds: ...)` / `skipBackward(seconds: ...)` |
| Playing (basic) | `getPlayingTrackInfo()` |
| Full metadata | `getPlayingTrackFull()` |
| Search & play first | `playSong(query: ...)` |
| Is playing? | `isPlaying()` |
| Disconnect | `disconnect()` |
| Logout (clear tokens) | `logout()` |

---
## Example App
Located in `example/` (shows auth → connect → playback + search + progress slider). Run:
```
cd example
flutter run
```
Add real credentials in `example/lib/main.dart`.

---
## Token Handling
- Authorization Code flow
- Access + refresh cached (SharedPreferences)
- Automatic refresh when expired on demand
- Future: proactive refresh events

Security:
- Never commit secrets
- Prefer `--dart-define` for CI/builds
- Consider backend proxy for token exchange in production

---
## Error Handling
Native issues surface as `PlatformException`. Future: richer `SpotikitException` wrapper.

---
## Roadmap
- iOS
- Shuffle / repeat
- Queue ops
- Volume, context metadata
- EventChannel optimization
- More Web API (playlists, library, user)
- Proactive token refresh
- Filtered track change stream + caching

---
## Contributing
1. Fork / branch
2. Implement + update example/docs
3. `flutter format .` & fix analyzer warnings
4. PR with description + test notes

---
## Dev Scripts (repeat: init is REQUIRED) ✅
```
dart run spotikit:android_init   # REQUIRED after adding plugin / fresh clone / cleaning android
dart run spotikit:android_clean  # Optional helper (then rerun android_init)
```

---
## License
MIT © 2025 spotikit contributors

---
## Attribution
Uses Spotify App Remote SDK & Web API. Not affiliated with or endorsed by Spotify.

---
## Support
Issues / ideas: https://github.com/ArdaKoksall/spotikit/issues

Enjoy building with Spotikit! 🎧
