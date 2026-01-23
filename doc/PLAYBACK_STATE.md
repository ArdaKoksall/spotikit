# Playback State Stream

> **Version 1.0.0** - First stable release

`Spotikit.onPlaybackStateChanged` emits `SpotifyPlaybackState` objects whenever the Spotify App Remote SDK reports a change.

## Emission Triggers
- Track changes (new URI)
- Pause / resume
- Position updates (SDK-driven)
- (Potential future) shuffle / repeat / volume (not yet exposed)

## Data Model
| Field | Description |
|-------|-------------|
| `uri` | Full Spotify track URI (`spotify:track:<id>`) |
| `name` | Track title |
| `artist` | Primary artist name |
| `isPaused` | True if playback is paused |
| `positionMs` | Current position within the track (ms) |
| `durationMs` | Track duration (ms) |
| `imageUri` | Raw image URI (can be resolved through App Remote image API in future) |
| `progress` | Convenience getter: `positionMs / durationMs` (0..1) |
| `id` | Track ID extracted from URI |

## Example Usage
```dart
final sub = Spotikit.onPlaybackStateChanged.listen((state) {
  final pct = (state.progress * 100).toStringAsFixed(1);
  debugPrint('Playing ${state.name} by ${state.artist} ($pct%)');
});
```

## Recommended UI Pattern
Use stream subscription + a periodic timer (e.g. 500ms) while playing to animate progress smoothly between native updates.

```dart
Timer? ticker;
final sub = Spotikit.onPlaybackStateChanged.listen((s) {
  setState(() => playback = s);
  ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
    if (playback == null || playback!.isPaused) return;
    setState(() {}); // rebuild progress slider
  });
});
```

Cancel timer & subscription on dispose.

## Known Limitations
- Image URI not auto-resolved to HTTP URL yet
- No filtering; consumers may implement their own distinct change detection
- Position increments tied to native callbacks (supplement with timer as above)

## Planned Enhancements
- Distinct onTrackChanged stream
- Cached last state getter `Spotikit.lastPlaybackState` (not yet implemented)
- EventChannel migration to reduce method overhead

