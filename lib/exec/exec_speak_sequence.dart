import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/tts/tts_service.dart';

/// Speaks a sequence of utterances one after another, e.g. a flashcard term
/// followed by its example sentence after a short pause.
///
/// Server usage:
/// ```xml
/// <Text phx-on-mount='[["speakSequence", {"steps": [
///   {"text": "虽然", "lang": "zh-CN"},
///   {"text": "他说虽然没关系", "lang": "zh-CN", "delayMs": 1000}
/// ]}]]'>
/// ```
///
/// `delayMs` on a step is the pause inserted after the previous utterance
/// completed, before this step speaks. The last step is fire-and-forget.
class ExecSpeakSequence extends Exec {
  final List<SpeakStep> steps;

  ExecSpeakSequence({required this.steps});

  factory ExecSpeakSequence.fromPayload(Map<String, dynamic>? payload) {
    final rawSteps = payload?['steps'];
    final steps = <SpeakStep>[];
    if (rawSteps is List) {
      for (final raw in rawSteps) {
        if (raw is Map) {
          steps.add(
            SpeakStep(
              text: raw['text']?.toString() ?? '',
              lang: raw['lang']?.toString(),
              delayBefore: Duration(
                milliseconds: int.tryParse('${raw['delayMs'] ?? 0}') ?? 0,
              ),
            ),
          );
        }
      }
    }
    return ExecSpeakSequence(steps: steps);
  }

  @override
  void handler(BuildContext context, StateWidget widget) {
    TtsService.instance.speakSequence(steps);
  }
}
