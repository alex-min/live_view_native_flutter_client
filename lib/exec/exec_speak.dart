import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/tts/tts_service.dart';

/// Speaks [text] with text-to-speech, in [lang] when given (e.g. `vi-VN`).
///
/// Server usage:
/// ```xml
/// <Text phx-click='[["speak", {"text": "xin chào", "lang": "vi-VN"}]]'>
/// <Text phx-on-mount='[["speak", {"text": "xin chào", "lang": "vi-VN"}]]'>
/// ```
class ExecSpeak extends Exec {
  final String? text;
  final String? lang;

  ExecSpeak({this.text, this.lang});

  @override
  void handler(BuildContext context, StateWidget widget) {
    TtsService.instance.speak(text: text, lang: lang);
  }
}
