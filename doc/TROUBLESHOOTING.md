# Troubleshooting

> **Version 1.0.0** - First stable release

## Authentication Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| `spotifyAuthFailed` with `cancelled` | User closed login view | Prompt user to retry |
| `token_exchange_failed` | Network / invalid secret | Verify client secret & redirect URI match dashboard |
| `NO_TOKEN` error on API calls | Not authenticated yet | Call `authenticateSpotify()` first, wait for `AuthSuccess` |

## Connection Problems
| Symptom | Cause | Fix |
|---------|-------|-----|
| `CONNECTION_ERROR` | Spotify app not installed / network | Install official Spotify app, ensure it is logged in |
| `NOT_CONNECTED` on control methods | App Remote not connected | Call `connectToSpotify()` after auth success |
| Delayed playback response | Spotify app cold start | Wait a moment; consider showing loading state |

## Playback State Not Emitting
| Symptom | Cause | Fix |
|---------|-------|-----|
| No events after connect | Permission scope missing | Ensure `app-remote-control` scope included |
| Null track info | Nothing is playing | Start playback with `playUri` |

## Seek / Skip Not Working
| Symptom | Cause | Fix |
|---------|-------|-----|
| Seek ignored | Position out of range | Clamp UI slider 0..1 before mapping to ms |
| Skip throws error | Not connected | Reconnect remote |

## Access Token Expired Frequently
- Ensure refresh token provided (Authorization Code flow only)
- Let plugin refresh automatically by calling `getAccessToken` instead of caching externally

## Logging
Enable early:
```dart
Spotikit.enableLogging();
```
Logs include auth, connection, and error diagnostics.

## Reset State
```dart
await Spotikit.logout(); // clears tokens, disconnects
```

## Still Stuck?
Open an issue with:
- Plugin version
- Device + Android version
- Steps to reproduce
- Relevant log excerpts

