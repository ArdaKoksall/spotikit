import 'package:dio/dio.dart';
import 'package:spotikit/models/spotify/spotify_track.dart';

enum SearchType { album, artist, playlist, track, show, episode, audiobook }

class SpotifyApi {
  static const String _baseUrl = 'https://api.spotify.com/v1/';

  final Dio _dio;
  String? _accessToken;

  SpotifyApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            return handler.next(options);
          } else {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Access token is not set.',
              ),
            );
          }
        },
      ),
    );
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<SpotifyTrack?> getTrackById({required String id}) async {
    try {
      final response = await _dio.get('tracks/$id');

      if (response.statusCode == 200) {
        return SpotifyTrack.fromJson(response.data);
      }

      print(
        'Spotify API returned ${response.statusCode}: ${response.statusMessage}',
      );
      return null;
    } on DioException catch (e) {
      _logDioError(e);
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }

  Future<dynamic> search({
    required String query,
    required SearchType type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        'search',
        queryParameters: {
          'q': query,
          'type': type.name,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      print(
        'Spotify API returned ${response.statusCode}: ${response.statusMessage}',
      );
      return null;
    } on DioException catch (e) {
      _logDioError(e);
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }

  Future<String?> searchAndGetFirstTrackId({required String query}) async {
    final result = await search(query: query, type: SearchType.track, limit: 1);

    final items = result?['tracks']?['items'];
    if (items != null && items.isNotEmpty) {
      return items[0]['id'];
    }

    print('No tracks found for query: $query');
    return null;
  }

  void _logDioError(DioException e) {
    if (e.response != null) {
      print('Spotify API error ${e.response?.statusCode}: ${e.response?.data}');
    } else {
      print('Spotify API error: ${e.message}');
    }
  }
}
