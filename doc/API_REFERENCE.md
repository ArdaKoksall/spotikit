# Spotikit API Reference

> **Version 1.0.0** - First stable release

This document summarizes the primary Dart API surface. For detailed usage see README and example app.

## Getting the Instance
```dart
final spotikit = Spotikit.instance;
```

## Initialization & Auth
| Method | Description |
|--------|-------------|
| `spotikit.initialize({clientId, clientSecret, redirectUri, scope})` | Initializes plugin & stores config. Must be called once. |
| `spotikit.authenticateSpotify()` | Launches Spotify login (Authorization Code). Emits auth state events. |
| `spotikit.onAuthStateChanged` | Stream emitting `AuthSuccess`, `AuthFailure`, `AuthCancelled`. |
| `spotikit.getAccessToken()` | Returns (possibly refreshed) access token used for Web API calls. |
| `spotikit.logout()` | Disconnect + clear tokens. |
| `spotikit.configureLogging({loggingEnabled, errorLoggingEnabled})` | Enable/disable logging. |

## Connection / Remote
| Method | Description |
|--------|-------------|
| `spotikit.connectToSpotify()` | Connects App Remote (control channel). Returns `true` if successful. |
| `spotikit.disconnect()` | Disconnects remote. |

## Playback Control
| Method | Description |
|--------|-------------|
| `spotikit.playUri({spotifyUri})` | Start playback for given URI. |
| `spotikit.pause()` | Pause current track. |
| `spotikit.resume()` | Resume playback. |
| `spotikit.skipTrack()` | Skip to next track. |
| `spotikit.previousTrack()` | Previous track. |
| `spotikit.isPlaying()` | Boolean playback status (true if not paused). |
| `spotikit.seekTo({positionMs})` | Seek to absolute position (milliseconds). |
| `spotikit.skipForward({seconds})` | Relative forward seek (default 5s). |
| `spotikit.skipBackward({seconds})` | Relative backward seek (floor at 0). |

## Playback State & Metadata
| Method / Stream | Description |
|-----------------|-------------|
| `spotikit.onPlaybackStateChanged` | Stream of `SpotifyPlaybackState` (realtime). |
| `spotikit.getPlayingTrackInfo()` | Basic playing info (artist, name, uri, paused). |
| `spotikit.getPlayingTrackFull()` | Full track metadata via Web API (album name, images, etc.). |

## Search & Content
| Method | Description |
|--------|-------------|
| `spotikit.playSong({query})` | Search for first track and play it. |

## Models
### AuthState
- `AuthSuccess` (accessToken)
- `AuthFailure` (error, message?)
- `AuthCancelled`

### SpotifyPlaybackState
| Field | Type | Notes |
|-------|------|-------|
| uri | String | Full spotify URI (e.g. `spotify:track:...`) |
| name | String | Track name |
| artist | String | Primary artist name |
| isPaused | bool | Playback paused flag |
| positionMs | int | Current position in track |
| durationMs | int | Track duration |
| imageUrl | String? | Raw image URL from App Remote |
| progress | double | Computed: positionMs / durationMs (0..1) |
| id | String | Computed: Track ID extracted from URI |

### SpotifyTrack (from Web API)
Includes: id, name, artistName, albumName, durationMs, popularity, explicit, externalUrl, releaseDate, albumImages.

## Error Handling Strategy
- Most control methods log and swallow exceptions (returning silently)
- Some return booleans (`connectToSpotify`, `isPlaying`)
- Access token retrieval can throw PlatformException if not authenticated

Future improvements will introduce unified exception types & more transparent propagation.

## Threading & Streams
- Streams are broadcast; cancel your subscription when done.
- The plugin holds singletons; calling `initialize` multiple times is idempotent for channel handler.

## Token Lifecycle
- Stored in SharedPreferences (Android) with expiry timestamp
- `getAccessToken` triggers refresh if expired

## Limitations
- Android only (iOS planned for future release)
- No queue, shuffle, repeat, volume APIs yet
- No explicit EventChannel (uses invokeMethod callbacks for now)

## Pending Roadmap (API Additions)
- Last known playback cache getter
- onTrackChanged filtered stream
- Shuffle/repeat controls
- Queue operations
- User & playlist endpoints


