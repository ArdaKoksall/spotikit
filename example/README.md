# Spotikit Example App

Demonstrates how to use the spotikit plugin for Spotify integration on Android.

## Setup

1. Get a Spotify Developer account at https://developer.spotify.com/dashboard
2. Create an app and note your Client ID and Client Secret
3. Add your redirect URI (e.g., `your.app://callback`) in the Spotify dashboard
4. Create a `.env` file in this directory with your credentials:
   ```
   SPOTIFY_CLIENT_ID=your_client_id
   SPOTIFY_CLIENT_SECRET=your_client_secret
   SPOTIFY_REDIRECT_URI=your.app://callback
   ```
5. Run the initialization script from the example directory:
   ```
   dart run spotikit:android_init
   ```

## Running

```bash
flutter run
```

## Features Demonstrated

- Authentication with Spotify
- Realtime playback state streaming
- Play, pause, skip controls
- Search and play functionality
- Full track metadata retrieval

## More Information

See the main [Spotikit documentation](../doc/GETTING_STARTED.md) for detailed setup instructions.
