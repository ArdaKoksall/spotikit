import 'package:flutter/foundation.dart';

import 'album_image.dart';

@immutable
class SpotifyTrack {
  final String id;
  final String name;
  final String artistName;
  final String? albumName;
  final int durationMs;
  final int popularity;
  final bool explicit;
  final String? externalUrl;
  final String? releaseDate;
  final List<AlbumImage>? albumImages;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistName,
    this.albumName,
    required this.durationMs,
    required this.popularity,
    this.explicit = false,
    this.externalUrl,
    this.releaseDate,
    this.albumImages,
  });

  static SpotifyTrack? fromJson(Map<String, dynamic> json) {
    try {
      return SpotifyTrack(
        id: json['id']!,
        name: json['name']!,
        artistName: json['artists']![0]['name']!,
        albumName: json['album']?['name'],
        durationMs: json['duration_ms']!,
        popularity: json['popularity']!,
        explicit: json['explicit'] ?? false,
        externalUrl: json['external_urls']?['spotify'],
        releaseDate: json['album']?['release_date'],
        albumImages: json['album']?['images'] != null
            ? (json['album']['images'] as List)
                  .map((img) => AlbumImage.fromJson(img))
                  .toList()
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artistName': artistName,
      'albumName': albumName,
      'durationMs': durationMs,
      'popularity': popularity,
      'explicit': explicit,
      'externalUrl': externalUrl,
      'releaseDate': releaseDate,
      'albumImages': albumImages?.map((img) => img.toJson()).toList(),
    };
  }

  double get durationSeconds => durationMs / 1000.0;

  String get durationFormatted {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '$name by $artistName ($albumName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotifyTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  String? get largeImageUrl =>
      albumImages?.where((img) => img.width == 640).firstOrNull?.url;

  String? get mediumImageUrl =>
      albumImages?.where((img) => img.width == 300).firstOrNull?.url;

  String? get smallImageUrl =>
      albumImages?.where((img) => img.width == 64).firstOrNull?.url;

  String? get bestImageUrl => largeImageUrl ?? mediumImageUrl ?? smallImageUrl;
}
