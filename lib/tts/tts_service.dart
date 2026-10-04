import 'dart:async';
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

  /// Called by the engine when an utterance finishes speaking.
  void setCompletionHandler(void Function() handler) {
    _tts!.setCompletionHandler(handler);
  }
}

/// One utterance of a [TtsService.speakSequence] call.
///
/// [delayBefore] is the pause inserted after the previous utterance
/// completed; the first step's delay starts the sequence right away.
class SpeakStep {
  final String text;
  final String? lang;
  final Duration delayBefore;

  const SpeakStep({
    required this.text,
    this.lang,
    this.delayBefore = Duration.zero,
  });
}

/// Text-to-speech singleton used by the `speak` exec.
///
/// All failures (missing engine voices, platform channel errors) are logged,
/// never thrown, so a TTS problem can never break the view rendering.
class TtsService {
  final TtsEngine _engine;
  bool _initialized = false;

  /// Bumped on every new speak request: a stale [speakSequence] loop checks
  /// this between steps and aborts, so card skipping cancels pending
  /// follow-up sentences.
  int _generation = 0;

  /// Completer of the utterance a [speakSequence] loop is currently awaiting,
  /// completed early when a newer speak request cancels the sequence.
  Completer<void>? _pendingUtterance;

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
  /// Cancels any in-flight speech and pending sequence first so fast
  /// successive calls (card skipping) never overlap. An empty text is a
  /// no-op. The language follows a fallback chain: exact match, then its
  /// prefix (`vi-VN` -> `vi`), then the engine default.
  Future<void> speak({String? text, String? lang}) async {
    if (text == null || text.trim().isEmpty) {
      return;
    }
    final id = ++_generation;
    _cancelPendingUtterance();
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

  /// Speaks [steps] one after another, waiting for each utterance to finish
  /// before pausing [SpeakStep.delayBefore] and starting the next one.
  ///
  /// The last step is fire-and-forget (callers don't wait for the final
  /// utterance to complete). Empty texts are skipped; a sequence with no
  /// speakable step is a no-op. A newer [speak]/[speakSequence] call cancels
  /// the rest of the sequence.
  Future<void> speakSequence(List<SpeakStep> steps) async {
    final valid = steps.where((s) => s.text.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      return;
    }
    final id = ++_generation;
    _cancelPendingUtterance();
    try {
      await _ensureInitialized();
      for (var i = 0; i < valid.length; i++) {
        if (id != _generation) return;
        final step = valid[i];
        if (step.delayBefore > Duration.zero) {
          await Future<void>.delayed(step.delayBefore);
          if (id != _generation) return;
        }
        await _applyLanguage(step.lang);
        await _engine.stop();
        if (i == valid.length - 1) {
          await _engine.speak(step.text);
        } else {
          final done = Completer<void>();
          _pendingUtterance = done;
          _engine.setCompletionHandler(() {
            if (!done.isCompleted) done.complete();
          });
          await _engine.speak(step.text);
          await done.future;
          if (identical(_pendingUtterance, done)) {
            _pendingUtterance = null;
          }
        }
      }
    } catch (e) {
      log('TtsService.speakSequence failed: $e');
    }
  }

  void _cancelPendingUtterance() {
    final pending = _pendingUtterance;
    _pendingUtterance = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
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
