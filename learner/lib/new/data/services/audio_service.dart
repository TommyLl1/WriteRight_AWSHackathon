import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:writeright/new/utils/logger.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _currentPlayer;
  String? _currentUrl;
  final Map<String, AudioPlayer> _playerCache = {};

  /// Play pronunciation audio from URL
  Future<void> playPronunciation(String audioUrl) async {
    try {
      // Validate URL
      if (audioUrl.trim().isEmpty) {
        throw ArgumentError('Audio URL cannot be empty');
      }

      AppLogger.info('Attempting to play audio: $audioUrl');

      // Stop current player if it's playing (regardless of URL)
      if (_currentPlayer != null && _currentPlayer!.playing) {
        AppLogger.debug('Stopping currently playing audio');
        await _currentPlayer!.stop();
      }

      // Get or create player for this URL
      AudioPlayer player;
      if (_playerCache.containsKey(audioUrl)) {
        AppLogger.debug('Using cached player for: $audioUrl');
        player = _playerCache[audioUrl]!;
        // Ensure the cached player is stopped before reusing
        if (player.playing) {
          AppLogger.debug('Stopping cached player before reuse');
          await player.stop();
        }
      } else {
        AppLogger.debug('Creating new player for: $audioUrl');
        player = AudioPlayer();
        try {
          await player.setUrl(audioUrl);
          _playerCache[audioUrl] = player;
          AppLogger.debug('Successfully loaded audio URL into new player');
        } catch (e) {
          AppLogger.error('Failed to load audio URL: $e');
          player.dispose();
          throw Exception('Failed to load audio from URL: $audioUrl');
        }
      }

      _currentPlayer = player;
      _currentUrl = audioUrl;

      // Ensure we're at the beginning and play
      await player.seek(Duration.zero);
      await player.play();

      AppLogger.info(
          'Successfully started playing pronunciation audio: $audioUrl');
    } catch (e) {
      AppLogger.error('Error playing pronunciation audio: $e');
      rethrow;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    if (_currentPlayer != null) {
      await _currentPlayer!.stop();
      _currentPlayer = null;
      _currentUrl = null;
    }
  }

  /// Check if audio is currently playing
  bool get isPlaying => _currentPlayer?.playing ?? false;

  /// Get current playing URL
  String? get currentUrl => _currentUrl;

  /// Clear the player cache (useful for debugging)
  void clearCache() {
    AppLogger.debug('Clearing audio player cache');
    for (final player in _playerCache.values) {
      player.dispose();
    }
    _playerCache.clear();
    _currentPlayer = null;
    _currentUrl = null;
  }

  /// Get cache size for debugging
  int get cacheSize => _playerCache.length;

  /// Dispose all players
  void dispose() {
    AppLogger.debug('Disposing AudioService');
    _currentPlayer = null;
    _currentUrl = null;
    for (final player in _playerCache.values) {
      player.dispose();
    }
    _playerCache.clear();
  }
}
