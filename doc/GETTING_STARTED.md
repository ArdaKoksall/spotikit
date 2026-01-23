# Getting Started with Spotikit

> **Version 1.0.0** - First stable release

This guide walks you through minimal setup to authenticate and control Spotify playback on Android.

## 1. Prerequisites
- Spotify Developer Account
- Registered application with: Client ID, Client Secret
- Redirect URI (e.g. `your.app://callback`) added in Spotify dashboard

## 2. Install
```yaml
dependencies:
  spotikit: ^1.0.0
```

```
flutter pub get
```

## 3. Android Setup (REQUIRED)
Run the init script to download Spotify AARs and configure Gradle:
```
dart run spotikit:android_init
```

By default, the script uses `spotify-sdk://auth` as the redirect URI for manifest placeholders. To use a custom redirect URI, pass the `--fallback-url` argument:
```
dart run spotikit:android_init --fallback-url=your.app://callback
```

> **Note:** This step is required after adding the plugin, fresh cloning, or cleaning the android directory. If skipped, Gradle will fail because the required `spotify-app-remote` and `spotify-auth` modules won't exist.

To clean and re-run setup:
```
dart run spotikit:android_clean && dart run spotikit:android_init
```

## 4. Android Manifest (Optional Custom Scheme)
Add if you use a custom redirect URI (replace values accordingly):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="your.app" android:host="callback" />
</intent-filter>
```

## 5. Initialize & Authenticate
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Spotikit.enableLogging();

  await Spotikit.initialize(
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_CLIENT_SECRET',
    redirectUri: 'your.app://callback',
  );

  Spotikit.onAuthStateChanged.listen((state) async {
    if (state is AuthSuccess) {
      await Spotikit.connectToSpotify();
      await Spotikit.playUri(spotifyUri: 'spotify:track:11dFghVXANMlKmJXsNCbNl');
    }
  });

  await Spotikit.authenticateSpotify();
}
```

## 6. Listen to Playback State
```dart
Spotikit.onPlaybackStateChanged.listen((s) {
  print('Now: ${s.name} by ${s.artist}');
});
```

## 7. Play by Search Query
```dart
await Spotikit.playSong(query: 'Where is my mind');
```

## 8. Fetch Full Track Metadata
```dart
final full = await Spotikit.getPlayingTrackFull();
print(full?.albumName);
```

## 9. Logout
```dart
await Spotikit.logout();
```

## 10. Minimal Error Handling
Wrap calls with `try/catch` or inspect `PlatformException` codes returned by native methods.

## 11. Next Steps
- Read the API Reference (doc/API_REFERENCE.md)
- Explore playback state details (doc/PLAYBACK_STATE.md)
- Check troubleshooting tips (doc/TROUBLESHOOTING.md)

