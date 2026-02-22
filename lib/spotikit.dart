library;

import 'dart:async';
import 'package:logger/logger.dart';
import 'package:spotikit/models/spotikit_exception.dart';

import 'models/spotify/spotify_track_info.dart';
import 'models/spotify/playback_state.dart';
import 'platform/spotikit_platform_interface.dart';

export 'platform/spotikit_platform_interface.dart';
export 'platform/spotikit_method_channel.dart';

/// The main entry point for the Spotikit plugin.
///
/// Use [Spotikit.instance] to access the singleton instance.
///
/// Example:
/// ```dart
/// await Spotikit.instance.initialize(
///   clientId: 'your_client_id',
///   redirectUri: 'your_redirect_uri',
/// );
/// ```
class Spotikit {
  static final Spotikit instance = Spotikit.internal();
  factory Spotikit() => instance;

  Spotikit.internal();

  final _SpotikitLog _log = _SpotikitLog();

  SpotikitPlatform get _platform => SpotikitPlatform.instance;

  /// Stream of playback state updates from the native platform.
  Stream<SpotifyPlaybackState> get onPlaybackStateChanged =>
      _platform.playbackStateStream;

  /// Initializes the Spotikit plugin with the required configuration.
  ///
  /// [clientId] - Spotify application client ID
  /// [redirectUri] - OAuth redirect URI used by the Spotify App Remote
  /// [connectToRemote] - Whether to connect to Spotify App Remote immediately
  ///
  /// Throws [SpotikitException] if initialization fails.
  Future<void> initialize({
    required String clientId,
    required String redirectUri,
    bool connectToRemote = false,
  }) async {
    try {
      await _platform.initialize(
        clientId: clientId,
        redirectUri: redirectUri,
        connectToRemote: connectToRemote,
      );
      _log.log("Spotikit initialized successfully.");
    } catch (e) {
      throw SpotikitException('Failed to initialize Spotikit: $e');
    }
  }

  /// Configures logging options.
  ///
  /// [loggingEnabled] - Enable or disable general logging (default: false)
  /// [errorLoggingEnabled] - Enable or disable error logging (default: true)
  void configureLogging({
    bool loggingEnabled = false,
    bool errorLoggingEnabled = true,
  }) {
    _log.logConfig(
      loggingEnabled: loggingEnabled,
      errorLoggingEnabled: errorLoggingEnabled,
    );
  }

  /// Connects to the Spotify App Remote.
  ///
  /// Returns `true` if connection was successful or already connected.
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

  /// Plays the specified Spotify URI.
  ///
  /// [spotifyUri] - The Spotify URI to play (e.g., 'spotify:track:xxx')
  Future<void> playUri({required String spotifyUri}) async {
    try {
      await _platform.playUri(spotifyUri: spotifyUri);
    } catch (e) {
      _log.error("Error during play: $e");
    }
  }

  /// Pauses the current playback.
  Future<void> pause() async {
    try {
      await _platform.pause();
    } catch (e) {
      _log.error("Error during pause: $e");
    }
  }

  /// Resumes the current playback.
  Future<void> resume() async {
    try {
      await _platform.resume();
    } catch (e) {
      _log.error("Error during resume: $e");
    }
  }

  /// Skips to the next track.
  Future<void> skipTrack() async {
    try {
      await _platform.skipTrack();
    } catch (e) {
      _log.error("Error during skipTrack: $e");
    }
  }

  /// Goes back to the previous track.
  Future<void> previousTrack() async {
    try {
      await _platform.previousTrack();
    } catch (e) {
      _log.error("Error during previousTrack: $e");
    }
  }

  /// Gets basic information about the currently playing track from the App Remote.
  ///
  /// Returns `null` if no track is playing.
  Future<SpotifyTrackInfo?> getPlayingTrackInfo() async {
    try {
      return await _platform.getPlayingTrackInfo();
    } catch (e) {
      _log.error("Error retrieving track info: $e");
      return null;
    }
  }

  /// Disconnects from the Spotify App Remote.
  Future<void> disconnect() async {
    try {
      await _platform.disconnect();
      _log.log("Spotify disconnected successfully.");
    } catch (e) {
      _log.error("Error during disconnect: $e");
    }
  }

  /// Logs out from Spotify and disconnects the App Remote.
  Future<void> logout() async {
    try {
      await _platform.logout();
    } catch (e) {
      _log.error("Error during logout: $e");
    }
  }

  /// Checks if music is currently playing.
  ///
  /// Returns `true` if playing, `false` otherwise.
  Future<bool> isPlaying() async {
    try {
      return await _platform.isPlaying();
    } catch (e) {
      _log.error("Error checking if playing: $e");
      return false;
    }
  }

  /// Seeks to the specified position in the current track.
  ///
  /// [positionMs] - Position in milliseconds
  Future<void> seekTo({required int positionMs}) async {
    try {
      await _platform.seekTo(positionMs: positionMs);
    } catch (e) {
      _log.error("Error during seekTo: $e");
    }
  }

  /// Skips forward by the specified number of seconds.
  ///
  /// [seconds] - Number of seconds to skip forward (default: 5)
  Future<void> skipForward({int seconds = 5}) async {
    try {
      await _platform.skipForward(seconds: seconds);
    } catch (e) {
      _log.error("Error during skipForward: $e");
    }
  }

  /// Skips backward by the specified number of seconds.
  ///
  /// [seconds] - Number of seconds to skip backward (default: 5)
  Future<void> skipBackward({int seconds = 5}) async {
    try {
      await _platform.skipBackward(seconds: seconds);
    } catch (e) {
      _log.error("Error during skipBackward: $e");
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

  void logConfig({
    required bool loggingEnabled,
    required bool errorLoggingEnabled,
  }) {
    _loggingEnabled = loggingEnabled;
    _errorLoggingEnabled = errorLoggingEnabled;
  }
}
