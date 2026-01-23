import 'package:flutter/foundation.dart';

@immutable
class SpotifyPlaybackState {
  final String uri; // Full Spotify URI e.g., spotify:track:123
  final String name;
  final String artist;
  final bool isPaused;
  final int positionMs;
  final int durationMs;
  final String? imageUrl; // Raw image URI from Spotify SDK (if provided)

  const SpotifyPlaybackState({
    required this.uri,
    required this.name,
    required this.artist,
    required this.isPaused,
    required this.positionMs,
    required this.durationMs,
    this.imageUrl,
  });

  factory SpotifyPlaybackState.fromMap(Map<dynamic, dynamic> map) {
    return SpotifyPlaybackState(
      uri: map['uri'] as String,
      name: map['name'] as String,
      artist: map['artist'] as String,
      isPaused: map['isPaused'] as bool,
      positionMs: map['positionMs'] as int,
      durationMs: map['durationMs'] as int,
      imageUrl: map['imageUri'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uri': uri,
    'name': name,
    'artist': artist,
    'isPaused': isPaused,
    'positionMs': positionMs,
    'durationMs': durationMs,
    'imageUrl': imageUrl,
  };

  double get progress => durationMs == 0 ? 0 : positionMs / durationMs;
  String get id => uri.split(":").last;
}
