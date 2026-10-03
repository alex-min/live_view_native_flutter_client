import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Thin wrapper over just_audio [AudioPlayer] so [AudioPlayerService] stays
/// testable: tests inject a fake player and never touch the real platform
/// channel.
class AudioPlayerEngine {
  AudioPlayer? _player;

  AudioPlayer get player => _player ??= AudioPlayer();

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> setUrl(String url) async {
    await player.setUrl(url);
  }
}

/// Audio playback singleton used by the `playAudio` exec.
///
/// All failures (network errors, unsupported formats, platform channel
/// errors) are logged, never thrown, so an audio problem can never break the
/// view rendering.
class AudioPlayerService {
  final AudioPlayerEngine _engine;

  AudioPlayerService({AudioPlayerEngine? engine})
    : _engine = engine ?? AudioPlayerEngine();

  static AudioPlayerService _instance = AudioPlayerService();

  static AudioPlayerService get instance => _instance;

  @visibleForTesting
  static set instance(AudioPlayerService service) => _instance = service;

  /// Plays [url] from the beginning, cancelling any in-flight playback first
  /// so fast successive calls (card skipping) never overlap. An empty url is
  /// a no-op.
  Future<void> play(String? url) async {
    if (url == null || url.trim().isEmpty) {
      return;
    }
    try {
      await _engine.stop();
      await _engine.setUrl(url);
      await _engine.seek(Duration.zero);
      await _engine.play();
    } catch (e) {
      log('AudioPlayerService.play failed: $e');
    }
  }
}
