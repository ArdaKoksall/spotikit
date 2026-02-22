import 'dart:async';

import 'package:flutter/services.dart';
import 'package:spotikit/models/spotify/playback_state.dart';
import 'package:spotikit/models/spotify/spotify_track_info.dart';

import 'spotikit_platform_interface.dart';

/// An implementation of [SpotikitPlatform] that uses method channels.
class MethodChannelSpotikit extends SpotikitPlatform {
  static const MethodChannel _channel = MethodChannel('spotikit');

  final StreamController<SpotifyPlaybackState> _playbackController =
      StreamController<SpotifyPlaybackState>.broadcast();

  bool _isMethodCallHandlerSet = false;

  MethodChannelSpotikit() {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    if (_isMethodCallHandlerSet) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isMethodCallHandlerSet = true;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'playbackState':
        try {
          final map = call.arguments as Map<dynamic, dynamic>;
          final state = SpotifyPlaybackState.fromMap(map);
          _playbackController.add(state);
        } catch (_) {}
        break;
      default:
        break;
    }
  }

  @override
  Stream<SpotifyPlaybackState> get playbackStateStream =>
      _playbackController.stream;

  @override
  Future<void> initialize({
    required String clientId,
    required String redirectUri,
    required bool connectToRemote,
  }) async {
    await _channel.invokeMethod('initialize', {
      'clientId': clientId,
      'redirectUri': redirectUri,
      'connectToRemote': connectToRemote,
    });
    if (connectToRemote) await connectToSpotify();
  }

  @override
  Future<bool> connectToSpotify() async {
    try {
      final String? result = await _channel.invokeMethod<String>(
        _Methods.connectToSpotify,
      );
      return result == "Connected" || result == "Already connected";
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> playUri({required String spotifyUri}) async {
    try {
      await _channel.invokeMethod(_Methods.play, {'spotifyUri': spotifyUri});
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _channel.invokeMethod(_Methods.pause);
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    try {
      await _channel.invokeMethod(_Methods.resume);
    } catch (_) {}
  }

  @override
  Future<void> skipTrack() async {
    try {
      await _channel.invokeMethod(_Methods.skipTrack);
    } catch (_) {}
  }

  @override
  Future<void> previousTrack() async {
    try {
      await _channel.invokeMethod(_Methods.previousTrack);
    } catch (_) {}
  }

  @override
  Future<SpotifyTrackInfo?> getPlayingTrackInfo() async {
    try {
      final Map? result = await _channel.invokeMapMethod(_Methods.getTrackInfo);
      if (result == null) return null;
      return SpotifyTrackInfo.fromMap(result);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<String>(_Methods.disconnect);
    } catch (_) {}
  }

  @override
  Future<void> logout() async {
    try {
      await _channel.invokeMethod(_Methods.logout);
    } catch (_) {}
  }

  @override
  Future<bool> isPlaying() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        _Methods.isPlaying,
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> seekTo({required int positionMs}) async {
    try {
      await _channel.invokeMethod(_Methods.seekTo, {'positionMs': positionMs});
    } catch (_) {}
  }

  @override
  Future<void> skipForward({int seconds = 5}) async {
    try {
      await _channel.invokeMethod(_Methods.skipForward, {'seconds': seconds});
    } catch (_) {}
  }

  @override
  Future<void> skipBackward({int seconds = 5}) async {
    try {
      await _channel.invokeMethod(_Methods.skipBackward, {'seconds': seconds});
    } catch (_) {}
  }
}

class _Methods {
  static const String connectToSpotify = 'connectToSpotify';
  static const String play = 'play';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String skipTrack = 'skipTrack';
  static const String previousTrack = 'previousTrack';
  static const String getTrackInfo = 'getTrackInfo';
  static const String disconnect = 'disconnect';
  static const String logout = 'logout';
  static const String isPlaying = 'isPlaying';
  static const String skipForward = 'skipForward';
  static const String skipBackward = 'skipBackward';
  static const String seekTo = 'seekTo';
}
