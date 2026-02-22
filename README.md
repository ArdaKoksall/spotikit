# Spotikit

[![pub package](https://img.shields.io/pub/v/spotikit.svg)](https://pub.dev/packages/spotikit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for controlling Spotify playback on Android via the **Spotify App Remote SDK**.

> **Version 2.0.0** — App Remote only. No Web API, no client secret required.

---

## Highlights

- Connect to the Spotify App Remote with just a `clientId` and `redirectUri`
- Play / pause / resume / next / previous / seek / skip ±N seconds
- Realtime playback state stream (track, artist, progress, paused status, image URL)
- No client secret, no OAuth server-side flow, no token management

---

## Platform Support

| Platform    | Status | Notes                     |
|-------------|--------|---------------------------|
| Android     | ✅     | Spotify App Remote SDK    |
| iOS         | ⏳     | Planned                   |
| Web/Desktop | ❌     | Not targeted              |

---

## Prerequisites

1. A [Spotify Developer](https://developer.spotify.com/dashboard) account.
2. Create an app → copy the **Client ID**.
3. Add a redirect URI (e.g. `your.app://callback`) in the dashboard.
4. The Spotify app **must be installed** on the device.

> No client secret is needed — Spotikit uses the App Remote SDK only.

---

## Installation & Required Android Init

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     spotikit: ^2.0.0
   ```

2. Fetch packages:
   ```
   flutter pub get
   ```

3. **Required** (once per clone / after cleaning android dir): run the init script to download the Spotify App Remote AAR and insert the Gradle include:
   ```
   dart run spotikit:android_init
   ```
   To use a custom redirect URI:
   ```
   dart run spotikit:android_init --fallback-url=your.app://callback
   ```

4. (Optional) To clean and re-initialise:
   ```
   dart run spotikit:android_clean && dart run spotikit:android_init
   ```

5. Ensure `minSdkVersion >= 21`.

### Intent Filter (only if using a custom scheme/host)
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final spotikit = Spotikit.instance;
  spotikit.configureLogging(loggingEnabled: true);

  await spotikit.initialize(
    clientId: 'YOUR_CLIENT_ID',
    redirectUri: 'your.app://callback',
  );

  await spotikit.connectToSpotify();

  await spotikit.playUri(spotifyUri: 'spotify:track:4cOdK2wGLETKBW3PvgPWqT');

  spotikit.onPlaybackStateChanged.listen((state) {
    print('Now playing: ${state.name} by ${state.artist} — ${(state.progress * 100).toStringAsFixed(1)}%');
  });
}
```

---

## Initialization

```dart
await Spotikit.instance.initialize(
  clientId: 'YOUR_CLIENT_ID',
  redirectUri: 'your.app://callback',
  connectToRemote: true, // optionally connect immediately
);
```

| Parameter       | Required | Description                                      |
|-----------------|----------|--------------------------------------------------|
| `clientId`      | ✅       | Spotify app Client ID from the developer dashboard |
| `redirectUri`   | ✅       | Redirect URI registered in the developer dashboard |
| `connectToRemote` | ❌     | Connect to App Remote immediately (default: false) |

---

## Playback State Stream

```dart
spotikit.onPlaybackStateChanged.listen((state) {
  print('Track : ${state.name}');
  print('Artist: ${state.artist}');
  print('Paused: ${state.isPaused}');
  print('Progress: ${state.positionMs}/${state.durationMs} ms');
  print('Image URL: ${state.imageUrl}');
});
```

**`SpotifyPlaybackState` fields:**

| Field         | Type      | Description                          |
|---------------|-----------|--------------------------------------|
| `uri`         | `String`  | Full Spotify URI of the track        |
| `name`        | `String`  | Track name                           |
| `artist`      | `String`  | Primary artist name                  |
| `isPaused`    | `bool`    | Whether playback is paused           |
| `positionMs`  | `int`     | Current playback position (ms)       |
| `durationMs`  | `int`     | Total track duration (ms)            |
| `imageUrl`    | `String?` | Album art URL (HTTPS)                |
| `progress`    | `double`  | `positionMs / durationMs` (0.0–1.0)  |
| `id`          | `String`  | Track ID extracted from `uri`        |

---

## Control API

| Action                  | Method                                          |
|-------------------------|-------------------------------------------------|
| Connect to App Remote   | `spotikit.connectToSpotify()`                   |
| Play by URI             | `spotikit.playUri(spotifyUri: ...)`             |
| Pause                   | `spotikit.pause()`                              |
| Resume                  | `spotikit.resume()`                             |
| Next track              | `spotikit.skipTrack()`                          |
| Previous track          | `spotikit.previousTrack()`                      |
| Seek to position        | `spotikit.seekTo(positionMs: ...)`              |
| Skip forward N seconds  | `spotikit.skipForward(seconds: 10)`             |
| Skip backward N seconds | `spotikit.skipBackward(seconds: 10)`            |
| Get current track info  | `spotikit.getPlayingTrackInfo()`                |
| Is playing?             | `spotikit.isPlaying()`                          |
| Disconnect              | `spotikit.disconnect()`                         |
| Logout & disconnect     | `spotikit.logout()`                             |

---

## Track Info

`getPlayingTrackInfo()` returns a `SpotifyTrackInfo?` with fields:

| Field      | Type     | Description               |
|------------|----------|---------------------------|
| `name`     | `String` | Track name                |
| `artist`   | `String` | Primary artist name       |
| `uri`      | `String` | Full Spotify URI          |
| `isPaused` | `bool`   | Whether playback is paused |

---

## Logging

```dart
spotikit.configureLogging(
  loggingEnabled: true,       // verbose info logs (default: false)
  errorLoggingEnabled: true,  // error logs (default: true)
);
```

---

## Error Handling

Native issues surface as `PlatformException`. Spotikit wraps initialization failures in a `SpotikitException`.

Common error codes from native:

| Code                   | Cause                                          |
|------------------------|------------------------------------------------|
| `SPOTIFY_NOT_INSTALLED`| Spotify app is not installed on the device     |
| `CONNECTION_ERROR`     | App Remote failed to connect                   |
| `NOT_CONNECTED`        | A control method was called before connecting  |
| `NOT_INIT`             | `connectToSpotify` called before `initialize`  |
| `INIT_FAILED`          | Missing `clientId` or `redirectUri`            |
| `NO_TRACK`             | `getTrackInfo` called while nothing is playing |

---

## Dev Scripts

```
dart run spotikit:android_init   # REQUIRED after adding plugin / fresh clone / cleaning android
dart run spotikit:android_clean  # Optional helper (then rerun android_init)
```

---

## Roadmap

- iOS support
- Shuffle / repeat control
- Queue management
- Volume control
- Context metadata

---

## Contributing

1. Fork / branch
2. Implement + update example / docs
3. `flutter format .` & fix analyser warnings
4. Open a PR with a description and test notes

---

## License

MIT © 2026 spotikit contributors

---

## Attribution

Uses the Spotify App Remote SDK. Not affiliated with or endorsed by Spotify AB.

---

## Support

Issues / ideas: https://github.com/ArdaKoksall/spotikit/issues

Enjoy building with Spotikit! 🎧
