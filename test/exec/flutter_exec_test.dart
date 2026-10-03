import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/exec_audio.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/exec_speak.dart';
import 'package:liveview_flutter/exec/exec_switch_theme.dart';
import 'package:liveview_flutter/exec/exec_toggle_theme.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';

void main() {
  setUpAll(FlutterExecAction.registerDefaultExecs);

  test('parses action without value', () {
    var execs = FlutterExec.parse('[["toggleTheme"]]', 'phx-click', null);

    expect(execs.length, 1);
    expect(execs.first, isA<ExecToggleTheme>());
  });

  test('parses action with value', () {
    var execs = FlutterExec.parse(
      '[["switchTheme", {"theme": "default", "mode": "dark"}]]',
      'phx-click',
      null,
    );

    expect(execs.length, 1);
    expect(execs.first, isA<ExecSwitchTheme>());
  });

  test('parses speak with text and lang from a phx-click payload', () {
    var execs = FlutterExec.parse(
      '[["speak", {"text": "xin chào", "lang": "vi-VN"}]]',
      'phx-click',
      null,
    );

    expect(execs.length, 1);
    expect(execs.first, isA<ExecSpeak>());
    var speak = execs.first as ExecSpeak;
    expect(speak.text, 'xin chào');
    expect(speak.lang, 'vi-VN');
  });

  test('parses speak from a phx-on-mount payload', () {
    var execs = FlutterExec.parse(
      '[["speak", {"text": "xin chào", "lang": "vi-VN"}]]',
      'phx-on-mount',
      null,
    );

    expect(execs.length, 1);
    expect(execs.first, isA<ExecSpeak>());
  });

  test('parses playAudio with url from a phx-click payload', () {
    var execs = FlutterExec.parse(
      '[["playAudio", {"url": "https://example.com/audio.mp3"}]]',
      'phx-click',
      null,
    );

    expect(execs.length, 1);
    expect(execs.first, isA<ExecPlayAudio>());
    expect((execs.first as ExecPlayAudio).url, 'https://example.com/audio.mp3');
  });

  test('parses playAudio from a phx-on-mount payload', () {
    var execs = FlutterExec.parse(
      '[["playAudio", {"url": "https://example.com/audio.mp3"}]]',
      'phx-on-mount',
      null,
    );

    expect(execs.length, 1);
    expect(execs.first, isA<ExecPlayAudio>());
  });

  test('plain string phx-on-mount pushes a server event', () {
    var execs = FlutterExec.parse('some_event', 'phx-on-mount', null);

    expect(execs.length, 1);
    expect(execs.first, isA<ExecLiveEvent>());
    expect((execs.first as ExecLiveEvent).name, 'some_event');
  });
}
