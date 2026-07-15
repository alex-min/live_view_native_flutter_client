import 'package:flutter_test/flutter_test.dart';
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
}
