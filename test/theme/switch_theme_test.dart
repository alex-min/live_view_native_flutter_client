import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

var redButtonTheme = jsonHttpResponse({
  "elevatedButtonTheme": {
    "style": {"backgroundColor": "#ff0000"},
  },
});

var blueButtonTheme = jsonHttpResponse({
  "elevatedButtonTheme": {
    "style": {"backgroundColor": "#0000ff"},
  },
});

main() async {
  testWidgets('themes defaults are set properly', (tester) async {
    var (view, _) = await connect(LiveView());

    await tester.runLiveView(view);

    expect(view.themeSettings.lightTheme, null);
    expect(view.themeSettings.darkTheme, null);
    // visitors without a stored choice follow the OS appearance (light in tests)
    expect(view.themeSettings.themeMode, ThemeMode.system);
    expect(view.themeSettings.getDisplayedThemeMode(), ThemeMode.light);
    expect(view.themeSettings.themeName, 'cosmic');
  });

  testGoldens('switching themes', (tester) async {
    await loadAppFonts();
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<ElevatedButton ', '>button theme</ElevatedButton>'],
        '0':
            'phx-click="${FlutterExec.encode([
              FlutterExecAction(name: 'switchTheme', value: {'theme': 'default', 'mode': 'dark'}),
            ])}"',
      },
      onRequest: (request) {
        if (request.url.path == '/flutter/themes/default/dark.json') {
          return redButtonTheme;
        }
        return null;
      },
    );

    await tester.runLiveView(view);

    await tester.tap(find.byType(LiveElevatedButton));

    expect(view.themeSettings.lightTheme, null);
    expect(view.themeSettings.darkTheme, null);
    expect(view.themeSettings.themeMode, ThemeMode.dark);

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('switch_theme_test.png'),
    );
  });

  testWidgets('loads a theme from the storage', (tester) async {
    var once = false;
    var (view, _) = await connect(
      LiveView(),
      onRequest: (request) {
        if (request.url.path == '/flutter/themes/cosmic/light.json' &&
            once == false) {
          once = true;
          return redButtonTheme;
        }
        return null;
      },
    );

    view.themeSettings = ThemeSettings()..httpClient = view.httpClient;
    await view.themeSettings.loadCurrentTheme();

    expect(
      view.themeSettings.lightTheme?.elevatedButtonTheme.style?.backgroundColor
          ?.resolve({}),
      const Color.fromARGB(255, 255, 0, 0),
    );
  });

  test(
    'does not decode and notify twice when the downloaded theme is cached',
    () async {
      SharedPreferences.setMockInitialValues({
        'themeData:cosmic/light': redButtonTheme.body,
      });
      final settings = ThemeSettings();
      settings.host = 'http://localhost:9999';
      settings.httpClient = MockClient((_) async => redButtonTheme);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.fetchCurrentTheme();

      expect(notifications, 1);
      expect(settings.lightTheme?.elevatedButtonBgColor, BasicColors.red);
    },
  );

  test('ignores an obsolete theme response after a newer selection', () async {
    SharedPreferences.setMockInitialValues({});
    final darkResponse = Completer<http.Response>();
    final lightResponse = Completer<http.Response>();
    final settings = ThemeSettings();
    settings.host = 'http://localhost:9999';
    settings.httpClient = MockClient((request) {
      if (request.url.path == '/flutter/themes/cosmic-dark/dark.json') {
        return darkResponse.future;
      }
      if (request.url.path == '/flutter/themes/cosmic/light.json') {
        return lightResponse.future;
      }
      throw StateError('Unexpected theme request: ${request.url}');
    });

    final selectingDark = settings.setTheme('cosmic-dark', 'dark');
    await pumpEventQueue();
    final selectingLight = settings.setTheme('cosmic', 'light');
    await pumpEventQueue();

    lightResponse.complete(blueButtonTheme);
    await selectingLight;
    darkResponse.complete(redButtonTheme);
    await selectingDark;

    expect(settings.themeName, 'cosmic');
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.lightTheme?.elevatedButtonBgColor, BasicColors.blue);
    expect(settings.darkTheme, isNull);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('themeData:cosmic/light'),
      blueButtonTheme.body,
    );
    expect(preferences.getString('themeData:cosmic-dark/dark'), isNull);
  });

  testWidgets('refetches the theme when switching', (tester) async {
    var count = 0;
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<ElevatedButton ', '>button theme</ElevatedButton>'],
        '0':
            'phx-click="${FlutterExec.encode([
              FlutterExecAction(name: 'switchTheme', value: {'theme': 'default', 'mode': 'light'}),
            ])}"',
      },
      sharedPreferences: {'themeName': 'default', 'themeMode': 'system'},
      onRequest: (request) {
        if (request.url.path == '/flutter/themes/default/light.json') {
          count++;
          return count == 1 ? redButtonTheme : blueButtonTheme;
        }
        return null;
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
      view.themeSettings.lightTheme?.elevatedButtonBgColor,
      BasicColors.red,
    );

    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(
      view.themeSettings.lightTheme?.elevatedButtonBgColor,
      BasicColors.blue,
    );
  });

  testWidgets('toggleTheme switches between light and dark', (tester) async {
    var toggleAction = FlutterExec.encode([
      FlutterExecAction(name: 'toggleTheme'),
    ]);

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<IconButton phx-click="$toggleAction" icon="dark_mode" />'],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    // visitors without a stored choice follow the OS appearance (light in tests)
    expect(view.themeSettings.themeMode, ThemeMode.system);
    expect(view.themeSettings.getDisplayedThemeMode(), ThemeMode.light);

    await tester.tap(find.byType(LiveIconButton));
    await tester.pumpAndSettle();

    expect(view.themeSettings.themeMode, ThemeMode.dark);

    await tester.tap(find.byType(LiveIconButton));
    await tester.pumpAndSettle();

    expect(view.themeSettings.themeMode, ThemeMode.light);
  });

  testWidgets('toggleTheme persists the selected mode across reconnects', (
    tester,
  ) async {
    var toggleAction = FlutterExec.encode([
      FlutterExecAction(name: 'toggleTheme'),
    ]);

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<IconButton phx-click="$toggleAction" icon="dark_mode" />'],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LiveIconButton));
    await tester.pumpAndSettle();

    expect(view.themeSettings.themeMode, ThemeMode.dark);

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeName'), 'cosmic');
    expect(prefs.getString('themeMode'), 'dark');

    var freshThemeSettings =
        ThemeSettings()
          ..httpClient = view.httpClient
          ..host = view.themeSettings.host;
    await freshThemeSettings.loadPreferences();

    expect(freshThemeSettings.themeMode, ThemeMode.dark);
  });
}
