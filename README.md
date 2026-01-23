# Spotikit

[![pub package](https://img.shields.io/pub/v/spotikit.svg)](https://pub.dev/packages/spotikit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Flutter plugin for integrating Spotify on Android using both the Spotify App Remote SDK (realtime playback control/state) and the Spotify Web API (rich metadata, search, etc.).

> **Version 1.0.0** - First stable release! Android only for now. iOS support planned.

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
     spotikit: ^1.0.0
   ```
2. Fetch packages:
   ```
   flutter pub get
   ```
3. **IMPORTANT** (one-time per clone / after cleaning android dir): run the init script so the Spotify AARs are downloaded & Gradle includes are inserted at the top of `android/settings.gradle`:
   ```
   dart run spotikit:android_init
   ```
   By default, this uses `spotify-sdk://auth` as the redirect URI. To use a custom redirect URI:
   ```
   dart run spotikit:android_init --fallback-url=your.app://callback
   ```
   If you skip this, Gradle will fail because the required `spotify-app-remote` and `spotify-auth` modules won't exist.
4. (Optional) If Gradle metadata gets messy or you want to re-download AARs, clean with:
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
import 'package:spotikit/spotikit.dart';
import 'package:spotikit/models/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final spotikit = Spotikit.instance;
  spotikit.configureLogging(loggingEnabled: true);

  await spotikit.initialize(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
    redirectUri: 'your.app://callback',
  );

  spotikit.onAuthStateChanged.listen((state) async {
    if (state is AuthSuccess) {
      await spotikit.connectToSpotify();
      await spotikit.playUri(spotifyUri: 'spotify:track:4cOdK2wGLETKBW3PvgPWqT');
    }
  });

  await spotikit.authenticateSpotify();

  spotikit.onPlaybackStateChanged.listen((state) {
    print('Now playing: ${state.name} by ${state.artist} ${(state.progress * 100).toStringAsFixed(1)}%');
  });
}
```

---
## Auth State Stream
```dart
final spotikit = Spotikit.instance;

spotikit.onAuthStateChanged.listen((state) {
  switch (state) {
    case AuthSuccess(:final accessToken):
      print('Authenticated. Token: $accessToken');
    case AuthFailure(:final error, :final message):
      print('Auth failed: $error ${message ?? ''}');
    case AuthCancelled():
      print('User cancelled Spotify login');
  }
});
```

---
## Playback State Stream
```dart
final spotikit = Spotikit.instance;

final sub = spotikit.onPlaybackStateChanged.listen((state) {
  print('Track: ${state.name} | Paused: ${state.isPaused} | Position: ${state.positionMs}/${state.durationMs}');
});
```
Fields: `uri`, `name`, `artist`, `isPaused`, `positionMs`, `durationMs`, `imageUrl`, helpers: `progress`, `id`.

---
## Core Control APIs
| Action | Method |
|--------|--------|
| Play by URI | `spotikit.playUri(spotifyUri: ...)` |
| Pause / Resume | `spotikit.pause()` / `spotikit.resume()` |
| Next / Previous | `spotikit.skipTrack()` / `spotikit.previousTrack()` |
| Seek absolute | `spotikit.seekTo(positionMs: ...)` |
| Skip fwd/back seconds | `spotikit.skipForward(seconds: ...)` / `spotikit.skipBackward(seconds: ...)` |
| Playing (basic) | `spotikit.getPlayingTrackInfo()` |
| Full metadata | `spotikit.getPlayingTrackFull()` |
| Search & play first | `spotikit.playSong(query: ...)` |
| Is playing? | `spotikit.isPlaying()` |
| Disconnect | `spotikit.disconnect()` |
| Logout (clear tokens) | `spotikit.logout()` |

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
MIT © 2026 spotikit contributors

---
## Attribution
Uses Spotify App Remote SDK & Web API. Not affiliated with or endorsed by Spotify.

---
## Support
Issues / ideas: https://github.com/ArdaKoksall/spotikit/issues

Enjoy building with Spotikit! 🎧
