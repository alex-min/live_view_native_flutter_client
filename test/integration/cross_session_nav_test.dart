import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  testWidgets('tap Sign in navigates across live_sessions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = _RealHttpOverrides();

    final view = LiveView();
    view.httpClient = IOClient(HttpClient());
    view.catchExceptions = false;

    await tester.pumpWidget(view.rootView);

    await tester.runAsync(() async {
      await view.connect('http://localhost:4000/');

      for (var i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (view.router.pages.isNotEmpty &&
            view.router.pages.last.page.name == 'error') {
          break;
        }
        if (view.router.pages.isNotEmpty) {
          await tester.pump();
          if (find.text('StartupKit').evaluate().isNotEmpty) {
            break;
          }
        }
      }
    });

    await tester.pumpAndSettle();

    expect(find.text('StartupKit'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    // Wait for the cross-session reconnect to complete.
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('Sign in to your account').evaluate().isNotEmpty) {
          break;
        }
      }
    });

    await tester.pumpAndSettle();

    expect(
      view.router.pages.isNotEmpty &&
          view.router.pages.last.page.name == 'error',
      isFalse,
      reason: 'Client navigated to error page',
    );
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.runAsync(() => view.disconnect());
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
