# Spotikit API Reference

> **Version 1.0.0** - First stable release

This document summarizes the primary Dart API surface. For detailed usage see README and example app.

## Initialization & Auth
| Method | Description |
|--------|-------------|
| `Spotikit.initialize({clientId, clientSecret, redirectUri, scope})` | Initializes plugin & stores config. Must be called once. |
| `Spotikit.authenticateSpotify()` | Launches Spotify login (Authorization Code). Emits auth state events. |
| `Spotikit.onAuthStateChanged` | Stream emitting `AuthSuccess`, `AuthFailure`, `AuthCancelled`. |
| `Spotikit.getAccessToken()` | Returns (possibly refreshed) access token used for Web API calls. |
| `Spotikit.logout()` | Disconnect + clear tokens. |

## Connection / Remote
| Method | Description |
|--------|-------------|
| `Spotikit.connectToSpotify()` | Connects App Remote (control channel). |
| `Spotikit.disconnect()` | Disconnects remote. |

## Playback Control
| Method | Description |
|--------|-------------|
| `Spotikit.playUri({spotifyUri})` | Start playback for given URI. |
| `Spotikit.pause()` | Pause current track. |
| `Spotikit.resume()` | Resume playback. |
| `Spotikit.skipTrack()` | Skip to next track. |
| `Spotikit.previousTrack()` | Previous track. |
| `Spotikit.isPlaying()` | Boolean playback status (true if not paused). |
| `Spotikit.seekTo({positionMs})` | Seek to absolute position (milliseconds). |
| `Spotikit.skipForward({seconds})` | Relative forward seek (default 5s). |
| `Spotikit.skipBackward({seconds})` | Relative backward seek (floor at 0). |

## Playback State & Metadata
| Method / Stream | Description |
|-----------------|-------------|
| `Spotikit.onPlaybackStateChanged` | Stream of `SpotifyPlaybackState` (realtime). |
| `Spotikit.getPlayingTrackInfo()` | Basic playing info (artist, name, uri, paused). |
| `Spotikit.getPlayingTrackFull()` | Full track metadata via Web API (album name, images, etc.). |

## Search & Content
| Method | Description |
|--------|-------------|
| `Spotikit.playSong({query})` | Search for first track and play it. |

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
| imageUri | String? | Raw image URI from App Remote |
| progress | double | position / duration (0..1) |
| id | String | Track ID extracted from URI |

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


