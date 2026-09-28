import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Host and port where the StartupKit dev server is expected to run.
const _serverHost = 'localhost';
const _serverPort = 4000;

class _TestApp extends StatelessWidget {
  final LiveView view;

  const _TestApp({required this.view});

  @override
  Widget build(BuildContext context) => view.rootView;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);

  group('Email change flow', () {
    testWidgets(
      'sign up, unlock sudo mode and change email without current password',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = await LiveView.withPersistentCache();
        addTearDown(view.disconnect);
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        final email =
            'integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
        const password = 'SuperSecret123!';

        await tester.pumpWidget(_TestApp(view: view));
        // Onboarding is unreliable at mobile sizes, so run it at a large
        // viewport first and switch to mobile afterwards for the bottom
        // navigation (the bar only builds below the client's 600px desktop
        // breakpoint).
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await view.connect('http://$_serverHost:$_serverPort/');

        // Navigate to the registration form.
        final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
        await _waitFor(tester, signUpButton, seconds: 30);
        await tester.tap(signUpButton);
        await _waitForUrl(tester, view, '/users/register', seconds: 30);

        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        await _waitFor(tester, find.byType(TextField));

        final fields = find.byType(TextField);
        expect(
          fields,
          findsNWidgets(3),
          reason: 'The registration form should contain three text fields',
        );

        await tester.enterText(fields.at(0), email);
        await tester.pump();
        await tester.enterText(fields.at(1), password);
        await tester.pump();
        await tester.enterText(fields.at(2), password);
        await tester.pump();

        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pump();

        await tester.enterText(fields.at(0), email);
        await tester.pump();

        final submitButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        expect(
          submitButton,
          findsOneWidget,
          reason: 'The registration form should have a submit button',
        );
        await tester.tap(submitButton);

        // Accept the terms of service.
        await _waitForUrl(tester, view, '/users/accept-tos', seconds: 30);
        final acceptButton = find.byType(ElevatedButton).last;
        await tester.ensureVisible(acceptButton);
        await tester.tap(acceptButton);

        // Accepting the terms completes the onboarding and lands on the
        // generic home page.
        await _waitForUrl(tester, view, '/home', seconds: 30);

        // Switch to a mobile viewport so the bottom navigation bar builds.
        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpAndSettle();

        // Navigate to the settings page through the bottom navigation.
        await _waitFor(tester, find.text('Settings'), seconds: 30);
        final settingsItem = find.text('Settings').hitTestable().last;
        await tester.tap(settingsItem);
        await tester.pump();
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await tester.pumpAndSettle();
        expect(find.text(email).hitTestable(), findsWidgets);

        // Sensitive changes are locked, so unlock sudo mode first.
        final unlockButton =
            find.widgetWithText(ElevatedButton, 'Unlock').first;
        await _waitFor(tester, unlockButton, seconds: 30);
        await tester.tap(unlockButton);
        await tester.pump();
        await _waitForUrl(tester, view, '/users/sudo_mode/log_in', seconds: 30);
        await tester.pumpAndSettle();

        await _waitFor(tester, find.byType(TextField));
        await tester.enterText(find.byType(TextField), password);
        await tester.pump();

        final confirmButton = find.widgetWithText(
          ElevatedButton,
          'Confirm your password',
        );
        expect(
          confirmButton,
          findsOneWidget,
          reason: 'The sudo mode form should have a confirm button',
        );
        await tester.tap(confirmButton);

        // The POST redirect should bring us back to settings with sudo mode active.
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await tester.pumpAndSettle();

        expect(
          find.text('Sensitive changes are locked'),
          findsNothing,
          reason: 'Sudo mode should be unlocked after password confirmation',
        );

        // Phone validation must preserve a cursor positioned in the middle.
        await view.livePatch('/users/settings/phone');
        await _waitForUrl(tester, view, '/users/settings/phone', seconds: 30);
        await tester.pumpAndSettle();
        final phoneField = find.widgetWithText(TextField, 'Phone number');
        await _waitFor(tester, phoneField, seconds: 30);
        await tester.tap(phoneField);
        await _editAndWaitForValidation(
            tester,
            view,
            const TextEditingValue(
                text: '1111', selection: TextSelection.collapsed(offset: 4)));
        final phoneController =
            tester.widget<TextField>(phoneField).controller!;
        final phoneFocus = tester.widget<TextField>(phoneField).focusNode!;
        var phoneFocusChanges = 0;
        void onPhoneFocusChanged() => phoneFocusChanges++;
        phoneFocus.addListener(onPhoneFocusChanged);
        tester.widget<TextField>(phoneField).controller!.selection =
            const TextSelection.collapsed(offset: 1);
        for (var i = 0; i < 2; i++) {
          final value = tester.widget<TextField>(phoneField).controller!.value;
          await _editAndWaitForValidation(
              tester,
              view,
              value.copyWith(
                text: value.text.replaceRange(
                    value.selection.start, value.selection.end, '2'),
                selection:
                    TextSelection.collapsed(offset: value.selection.start + 1),
              ));
          expect(tester.widget<TextField>(phoneField).controller!.selection,
              TextSelection.collapsed(offset: 2 + i));
        }
        expect(tester.widget<TextField>(phoneField).controller,
            same(phoneController));
        expect(
            tester.widget<TextField>(phoneField).focusNode, same(phoneFocus));
        expect(phoneFocusChanges, 0);
        phoneFocus.removeListener(onPhoneFocusChanged);
        expect(phoneController.text, '122111');
        await view.livePatch('/users/settings');
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await tester.pumpAndSettle();

        // Open the email settings sub-page from the menu.
        final emailRow = find.text('Email').hitTestable().last;
        await _waitFor(tester, emailRow, seconds: 30);
        await tester.tap(emailRow);
        await _waitForUrl(tester, view, '/users/settings/email', seconds: 30);
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsNothing);
        expect(find.text('Back to settings'), findsNothing);
        final backButton = find
            .ancestor(
              of: find.byIcon(Icons.arrow_back),
              matching: find.byType(IconButton),
            )
            .hitTestable();
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Email').hitTestable().last);
        await _waitForUrl(tester, view, '/users/settings/email', seconds: 30);
        await tester.pumpAndSettle();

        // Change the email address.
        final emailField = find.widgetWithText(TextField, 'Email');
        await _waitFor(tester, emailField, seconds: 30);
        await tester.enterText(emailField, 'updated+$email');
        await tester.pump();

        // phx-change can replace the field controller. Refill after that
        // diff, then bring the action into the Linux test viewport.
        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pump();
        await tester.enterText(emailField, 'updated+$email');
        await tester.pump();

        final changeEmailButton = find.widgetWithText(
          ElevatedButton,
          'Change email',
        );
        expect(
          changeEmailButton,
          findsOneWidget,
          reason: 'The email form should have a change button',
        );
        await tester.ensureVisible(changeEmailButton);
        await tester.pump();
        await tester.tap(changeEmailButton);
        await tester.pump();

        // Wait for the success flash from the server (the dev server default
        // locale is French).
        await _waitFor(
          tester,
          find.text(
            'A link to confirm your email change has been sent to the new address.',
          ),
          seconds: 30,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// Polls [finder] up to [seconds] times at 200 ms intervals.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final currentPath = Uri.tryParse(view.currentUrl)?.path ?? '';
    if (currentPath == url && view.isCurrentRouteReady) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

/// Ensures the StartupKit dev server is running on [_serverHost]:[_serverPort].
///
/// If no server is listening, the dev database is migrated and seeded, then
/// `mix phx.server` is started. The server is left running so the test can
/// interact with a real Phoenix backend.
Future<void> _ensureServer() async {
  if (await _serverReady()) {
    return;
  }

  final setup = await Process.run(
    'mix',
    ['ecto.setup'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  if (setup.exitCode != 0) {
    throw Exception('mix ecto.setup failed:\n${setup.stderr}\n${setup.stdout}');
  }

  final seed = await Process.run(
    'mix',
    ['run', 'priv/repo/seeds.exs'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  if (seed.exitCode != 0) {
    throw Exception(
      'mix run seeds.exs failed:\n${seed.stderr}\n${seed.stdout}',
    );
  }

  final process = await Process.start(
    'mix',
    ['phx.server'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  process.stdout.listen(stdout.add);
  process.stderr.listen(stderr.add);

  for (var i = 0; i < 60; i++) {
    if (await _serverReady()) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  throw Exception(
    'StartupKit server did not start on $_serverHost:$_serverPort',
  );
}

Future<bool> _serverReady() async {
  try {
    final socket = await Socket.connect(
      _serverHost,
      _serverPort,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}

Future<void> _editAndWaitForValidation(
    WidgetTester tester, LiveView view, TextEditingValue value) async {
  var received = false;
  void onDiff() {
    received = true;
  }

  view.changeNotifier.addListener(onDiff);
  try {
    tester.testTextInput.updateEditingValue(value);
    for (var i = 0; i < 80 && !received; i++) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(received, isTrue, reason: 'Wait for the real validation response');
    await tester.pumpAndSettle();
  } finally {
    view.changeNotifier.removeListener(onDiff);
  }
}
