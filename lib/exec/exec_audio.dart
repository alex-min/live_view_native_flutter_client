import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/audio/audio_player_service.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// Plays an audio file at [url] (e.g. a stored pronunciation recording).
///
/// Server usage:
/// ```xml
/// <Text phx-click='[["playAudio", {"url": "https://.../audio.mp3"}]]'>
/// <Text phx-on-mount='[["playAudio", {"url": "https://.../audio.mp3"}]]'>
/// ```
class ExecPlayAudio extends Exec {
  final String? url;

  ExecPlayAudio({this.url});

  @override
  void handler(BuildContext context, StateWidget widget) {
    AudioPlayerService.instance.play(url);
  }
}
