library;

import 'dart:async';
import 'package:logger/logger.dart';

import 'api/spotify_api.dart';
import 'models/auth_state.dart';
import 'models/spotify/spotify_track.dart';
import 'models/spotify/spotify_track_info.dart';
import 'models/spotify/playback_state.dart';
import 'platform/spotikit_platform_interface.dart';

export 'platform/spotikit_platform_interface.dart';
export 'platform/spotikit_method_channel.dart';

class Spotikit {
  static final Spotikit instance = Spotikit.internal();
  factory Spotikit() => instance;

  Spotikit.internal() {
    accessTokenStream.listen((token) {
      _api.setAccessToken(token);
    }, onError: (_) {});
  }

  final _SpotikitLog _log = _SpotikitLog();

  final SpotifyApi _api = SpotifyApi();
  SpotifyApi get api => _api;

  /// Returns the platform-specific implementation.
  SpotikitPlatform get _platform => SpotikitPlatform.instance;

  Stream<String?> get accessTokenStream => _platform.accessTokenStream;

  Stream<AuthState> get onAuthStateChanged => _platform.authStateStream;
  Stream<SpotifyPlaybackState> get onPlaybackStateChanged =>
      _platform.playbackStateStream;

  static const String _defaultScope =
      "user-read-playback-state user-modify-playback-state user-read-currently-playing app-remote-control streaming playlist-read-private playlist-read-collaborative playlist-modify-public playlist-modify-private user-library-modify user-library-read user-top-read user-read-playback-position user-read-recently-played user-follow-read user-follow-modify user-read-email user-read-private";

  Future<bool> initialize({
    required String clientId,
    required String redirectUri,
    required String clientSecret,
    String scope = _defaultScope,
  }) async {
    try {
      final result = await _platform.initialize(
        clientId: clientId,
        redirectUri: redirectUri,
        clientSecret: clientSecret,
        scope: scope,
      );
      if (result) {
        _log.log("Spotikit initialized successfully.");
      }
      return result;
    } catch (e) {
      _log.error("Error during initialization: $e");
    }
    return false;
  }

  Future<void> fullInitialize({
    required String clientId,
    required String redirectUri,
    required String clientSecret,
    String scope = _defaultScope,
  }) async {
    await initialize(
      clientId: clientId,
      redirectUri: redirectUri,
      clientSecret: clientSecret,
      scope: scope,
    );
    if (!await authenticateSpotify()) return;
    if (!await connectToSpotify()) return;

    _log.log("Spotikit initialized and connected to remote successfully.");
  }

  void enableLogging() {
    _log.enableLogging();
  }


  Future<bool> connectToSpotify() async {
    try {
      final result = await _platform.connectToSpotify();
      if (result) {
        _log.log("Spotify is connected!");
      }
      return result;
    } catch (e) {
      _log.error('Unexpected error: $e');
    }
    return false;
  }

  Future<bool> authenticateSpotify() async {
    try {
      final result = await _platform.authenticateSpotify();
      if (result) {
        _log.log("Spotify authentication started.");
      }
      return result;
    } catch (e) {
      _log.error("Error during Spotify authentication: $e");
    }
    return false;
  }

  Future<String?> getAccessToken() async {
    try {
      return await _platform.getAccessToken();
    } catch (e) {
      _log.error("Error retrieving access token: $e");
      return null;
    }
  }

  Future<void> playUri({required String spotifyUri}) async {
    try {
      await _platform.playUri(spotifyUri: spotifyUri);
    } catch (e) {
      _log.error("Error during play: $e");
    }
  }

  Future<void> pause() async {
    try {
      await _platform.pause();
    } catch (e) {
      _log.error("Error during pause: $e");
    }
  }

  Future<void> resume() async {
    try {
      await _platform.resume();
    } catch (e) {
      _log.error("Error during resume: $e");
    }
  }

  Future<void> skipTrack() async {
    try {
      await _platform.skipTrack();
    } catch (e) {
      _log.error("Error during skipTrack: $e");
    }
  }

  Future<void> previousTrack() async {
    try {
      await _platform.previousTrack();
    } catch (e) {
      _log.error("Error during previousTrack: $e");
    }
  }

  Future<SpotifyTrackInfo?> getPlayingTrackInfo() async {
    try {
      return await _platform.getPlayingTrackInfo();
    } catch (e) {
      _log.error("Error retrieving basic track info: $e");
      return null;
    }
  }

  Future<SpotifyTrack?> getPlayingTrackFull() async {
    try {
      final trackInfo = await _platform.getPlayingTrackInfo();
      if (trackInfo == null) return null;

      final id = trackInfo.uri.split(":").last;

      final SpotifyTrack? track = await _api.getTrackById(id: id);
      if (track == null) {
        _log.error("Failed to fetch full track info from Spotify API.");
        return null;
      }

      return track;
    } catch (e) {
      _log.error("Error retrieving full track info: $e");
      return null;
    }
  }

  Future<void> disconnect() async {
    try {
      await _platform.disconnect();
      _log.log("Spotify disconnected successfully.");
    } catch (e) {
      _log.error("Error during disconnect: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _platform.logout();
    } catch (e) {
      _log.error("Error during logout: $e");
    }
  }

  Future<bool> isPlaying() async {
    try {
      return await _platform.isPlaying();
    } catch (e) {
      _log.error("Error checking if playing: $e");
      return false;
    }
  }

  Future<void> seekTo({required int positionMs}) async {
    try {
      await _platform.seekTo(positionMs: positionMs);
    } catch (e) {
      _log.error("Error during seekTo: $e");
    }
  }

  Future<void> skipForward({int seconds = 5}) async {
    try {
      await _platform.skipForward(seconds: seconds);
    } catch (e) {
      _log.error("Error during skipForward: $e");
    }
  }

  Future<void> skipBackward({int seconds = 5}) async {
    try {
      await _platform.skipBackward(seconds: seconds);
    } catch (e) {
      _log.error("Error during skipBackward: $e");
    }
  }

  Future<void> playSong({required String query}) async {
    try {
      final searchResult = await _api.searchAndGetFirstTrackId(query: query);

      if (searchResult == null) {
        _log.error("No track found for query: $query");
        return;
      }

      await playUri(spotifyUri: "spotify:track:$searchResult");
    } catch (e) {
      _log.error("Error during playSong: $e");
    }
  }
}

class _SpotikitLog {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  bool _loggingEnabled = false;
  bool _errorLoggingEnabled = true;

  void log(String message) {
    if (_loggingEnabled) {
      _logger.i(message);
    }
  }

  void error(String message) {
    if (_errorLoggingEnabled) {
      _logger.e(message);
    }
  }

  void enableLogging({bool errorLogging = true}) {
    _loggingEnabled = true;
    _errorLoggingEnabled = errorLogging;
  }

  void disableErrorLogging() {
    _errorLoggingEnabled = false;
  }

  void disableLogging() {
    _loggingEnabled = false;
  }
}
