import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/spotify/playback_state.dart';
import '../models/spotify/spotify_track_info.dart';
import 'spotikit_method_channel.dart';

/// The interface that implementations of spotikit must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `spotikit` does not consider newly added methods to be breaking changes.
/// Extending this class ensures that the subclass will get the default
/// implementation, while platform implementations that merely implement the
/// interface will be broken by newly added methods.
abstract class SpotikitPlatform extends PlatformInterface {
  /// Constructs a SpotikitPlatform.
  SpotikitPlatform() : super(token: _token);

  static final Object _token = Object();

  static SpotikitPlatform _instance = MethodChannelSpotikit();

  /// The default instance of [SpotikitPlatform] to use.
  ///
  /// Defaults to [MethodChannelSpotikit].
  static SpotikitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SpotikitPlatform] when
  /// they register themselves.
  static set instance(SpotikitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of playback state updates from the native platform.
  Stream<SpotifyPlaybackState> get playbackStateStream;

  /// Initializes the Spotikit plugin with the required configuration.
  ///
  /// [clientId] - Spotify application client ID
  /// [redirectUri] - OAuth redirect URI used by the Spotify App Remote
  /// [connectToRemote] - Whether to connect to Spotify App Remote immediately
  Future<void> initialize({
    required String clientId,
    required String redirectUri,
    required bool connectToRemote,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Connects to the Spotify App Remote.
  ///
  /// Returns `true` if connection was successful or already connected.
  Future<bool> connectToSpotify() {
    throw UnimplementedError('connectToSpotify() has not been implemented.');
  }

  /// Plays the specified Spotify URI.
  ///
  /// [spotifyUri] - The Spotify URI to play (e.g., 'spotify:track:xxx')
  Future<void> playUri({required String spotifyUri}) {
    throw UnimplementedError('playUri() has not been implemented.');
  }

  /// Pauses the current playback.
  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Resumes the current playback.
  Future<void> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  /// Skips to the next track.
  Future<void> skipTrack() {
    throw UnimplementedError('skipTrack() has not been implemented.');
  }

  /// Goes back to the previous track.
  Future<void> previousTrack() {
    throw UnimplementedError('previousTrack() has not been implemented.');
  }

  /// Gets basic information about the currently playing track.
  ///
  /// Returns `null` if no track is playing.
  Future<SpotifyTrackInfo?> getPlayingTrackInfo() {
    throw UnimplementedError('getPlayingTrackInfo() has not been implemented.');
  }

  /// Disconnects from the Spotify App Remote.
  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Logs out from Spotify and disconnects the App Remote.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Checks if music is currently playing.
  ///
  /// Returns `true` if playing, `false` otherwise.
  Future<bool> isPlaying() {
    throw UnimplementedError('isPlaying() has not been implemented.');
  }

  /// Seeks to the specified position in the current track.
  ///
  /// [positionMs] - Position in milliseconds
  Future<void> seekTo({required int positionMs}) {
    throw UnimplementedError('seekTo() has not been implemented.');
  }

  /// Skips forward by the specified number of seconds.
  ///
  /// [seconds] - Number of seconds to skip forward (default: 5)
  Future<void> skipForward({int seconds = 5}) {
    throw UnimplementedError('skipForward() has not been implemented.');
  }

  /// Skips backward by the specified number of seconds.
  ///
  /// [seconds] - Number of seconds to skip backward (default: 5)
  Future<void> skipBackward({int seconds = 5}) {
    throw UnimplementedError('skipBackward() has not been implemented.');
  }
}
