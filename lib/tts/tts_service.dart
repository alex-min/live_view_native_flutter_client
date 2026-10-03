import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over [FlutterTts] so [TtsService] stays testable: tests
/// inject a fake engine and never touch the real TTS platform channel.
class TtsEngine {
  FlutterTts? _tts;

  Future<void> init() async {
    _tts ??= FlutterTts();
  }

  Future<List<dynamic>> getLanguages() async => await _tts!.getLanguages;

  Future<void> setLanguage(String language) async {
    await _tts!.setLanguage(language);
  }

  Future<void> stop() async {
    await _tts!.stop();
  }

  Future<void> speak(String text) async {
    await _tts!.speak(text);
  }
}

/// Text-to-speech singleton used by the `speak` exec.
///
/// All failures (missing engine voices, platform channel errors) are logged,
/// never thrown, so a TTS problem can never break the view rendering.
class TtsService {
  final TtsEngine _engine;
  bool _initialized = false;

  TtsService({TtsEngine? engine}) : _engine = engine ?? TtsEngine();

  static TtsService _instance = TtsService();

  static TtsService get instance => _instance;

  @visibleForTesting
  static set instance(TtsService service) => _instance = service;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _engine.init();
    _initialized = true;
  }

  /// Speaks [text] in [lang] (e.g. `vi-VN`).
  ///
  /// Cancels any in-flight speech first so fast successive calls (card
  /// skipping) never overlap. An empty text is a no-op. The language follows
  /// a fallback chain: exact match, then its prefix (`vi-VN` -> `vi`), then
  /// the engine default.
  Future<void> speak({String? text, String? lang}) async {
    if (text == null || text.trim().isEmpty) {
      return;
    }
    try {
      await _ensureInitialized();
      await _applyLanguage(lang);
      // stop() cancels both queued and in-flight utterances.
      await _engine.stop();
      await _engine.speak(text);
    } catch (e) {
      log('TtsService.speak failed: $e');
    }
  }

  Future<void> _applyLanguage(String? language) async {
    if (language == null || language.trim().isEmpty) {
      return;
    }
    try {
      final languages = await _engine.getLanguages();
      if (languages.contains(language)) {
        await _engine.setLanguage(language);
        return;
      }
      final prefix = language.split('-').first;
      if (prefix != language && languages.contains(prefix)) {
        await _engine.setLanguage(prefix);
        return;
      }
      log('TtsService: no voice for "$language", keeping engine default');
    } catch (e) {
      log('TtsService: language resolution failed for "$language": $e');
    }
  }
}
