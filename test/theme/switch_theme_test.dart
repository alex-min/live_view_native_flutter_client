import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

var redButtonTheme = jsonHttpResponse({
  "elevatedButtonTheme": {
    "style": {"backgroundColor": "#ff0000"}
  }
});

var blueButtonTheme = jsonHttpResponse({
  "elevatedButtonTheme": {
    "style": {"backgroundColor": "#0000ff"}
  }
});

main() async {
  testWidgets('themes defaults are set properly', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    expect(view.themeSettings.lightTheme, null);
    expect(view.themeSettings.darkTheme, null);
    expect(view.themeSettings.themeMode, ThemeMode.system);
  });

  testGoldens('switching themes', (tester) async {
    await loadAppFonts();
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '<ElevatedButton ',
        '>button theme</ElevatedButton>',
      ],
      '0': 'phx-click="${FlutterExec.encode([
            FlutterExecAction(
                name: 'switchTheme',
                value: {'theme': 'default', 'mode': 'dark'}),
          ])}"',
    }, onRequest: (request) {
      if (request.url.path == '/flutter/themes/default/dark.json') {
        return redButtonTheme;
      }
      return null;
    });

    await tester.runLiveView(view);

    await tester.tap(find.byType(LiveElevatedButton));

    expect(view.themeSettings.lightTheme, null);
    expect(view.themeSettings.darkTheme, null);
    expect(view.themeSettings.themeMode, ThemeMode.dark);

    await tester.pumpAndSettle();

    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('switch_theme_test.png'));
  });

  testWidgets('loads a theme from the storage', (tester) async {
    var once = false;
    var (view, server) = await connect(LiveView(), onRequest: (request) {
      if (request.url.path == '/flutter/themes/default/light.json' &&
          once == false) {
        once = true;
        return redButtonTheme;
      }
      return null;
    });

    view.themeSettings = ThemeSettings()..httpClient = view.httpClient;
    await view.themeSettings.loadCurrentTheme();

    expect(
        view.themeSettings.lightTheme?.elevatedButtonTheme.style
            ?.backgroundColor
            ?.resolve({}),
        const Color.fromARGB(255, 255, 0, 0));
  });

  testWidgets('refetches the theme when switching', (tester) async {
    var count = 0;
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '<ElevatedButton ',
        '>button theme</ElevatedButton>',
      ],
      '0': 'phx-click="${FlutterExec.encode([
            FlutterExecAction(
                name: 'switchTheme',
                value: {'theme': 'default', 'mode': 'light'}),
          ])}"',
    }, onRequest: (request) {
      if (request.url.path == '/flutter/themes/default/light.json') {
        count++;
        return count == 1 ? redButtonTheme : blueButtonTheme;
      }
      return null;
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
        view.themeSettings.lightTheme?.elevatedButtonBgColor, BasicColors.red);

    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(
        view.themeSettings.lightTheme?.elevatedButtonBgColor, BasicColors.blue);
  });
}
