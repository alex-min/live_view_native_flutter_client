import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_coordinator.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets(
    'the authenticated manifest survives restart and isolates user changes',
    (tester) async {
      await _ensureServer();
      SharedPreferences.setMockInitialValues({});
      final renderedTypes = <ViewType>[];
      final view = await LiveView.withPersistentCache(
        onViewTypeRendered: renderedTypes.add,
      );
      view.catchExceptions = false;
      view.disableAnimations = true;
      view.throttleSpammyCalls = false;

      await tester.pumpWidget(_TestApp(view: view));
      await view.connect('http://$_serverHost:$_serverPort/');
      await _signUpAndOnboard(tester, view);

      await _waitForCachedRoutes(tester, view, const [
        '/dashboard',
        '/accounts',
        '/transactions',
        '/users/settings',
      ]);

      await _expectRapidCachedTabSwitching(tester, view);

      for (final route in const [
        '/dashboard',
        '/transactions',
        '/users/settings',
        '/accounts',
      ]) {
        await _expectCachedThenFresh(tester, view, route, renderedTypes);
      }

      final firstCoordinator = view.cacheCoordinator!;
      final firstNamespace = firstCoordinator.namespace;
      final persistedDashboard = await firstCoordinator.loadForNavigation(
        Uri.parse('/dashboard'),
      );
      expect(firstNamespace, isNotNull);
      expect(firstNamespace?.manifestVersion, 'finance-v2');
      expect(persistedDashboard, isNotNull);

      await view.disconnect();
      await tester.pumpWidget(const SizedBox.shrink());

      final restartedRenderedTypes = <ViewType>[];
      final restartedView = await LiveView.withPersistentCache(
        onViewTypeRendered: restartedRenderedTypes.add,
      );
      restartedView.catchExceptions = false;
      restartedView.disableAnimations = true;
      restartedView.throttleSpammyCalls = false;
      expect(
        restartedView.cacheCoordinator?.store,
        isNot(same(firstCoordinator.store)),
      );
      expect(
        await restartedView.cacheCoordinator?.loadForNavigation(
          Uri.parse('/dashboard'),
        ),
        isNull,
        reason: 'Persisted user data stays hidden before identity confirmation',
      );

      await tester.pumpWidget(_TestApp(view: restartedView));
      await restartedView.connect('http://$_serverHost:$_serverPort/accounts');
      await _waitForUrl(tester, restartedView, '/accounts');
      await _waitForCachePolicy(tester, restartedView);

      expect(restartedView.cacheCoordinator?.namespace, firstNamespace);
      final restoredDashboard = await restartedView.cacheCoordinator
          ?.loadForNavigation(Uri.parse('/dashboard'));
      expect(restoredDashboard, isNotNull);
      expect(restoredDashboard?.storedAt, persistedDashboard?.storedAt);

      await _expectCachedThenFresh(
        tester,
        restartedView,
        '/dashboard',
        restartedRenderedTypes,
      );

      await restartedView.execHrefClick('/users/log_out', method: 'DELETE');
      await _waitForUrl(tester, restartedView, '/');
      await _waitForLogoutInvalidation(tester, restartedView, firstNamespace!);

      expect(restartedView.router.pages, hasLength(1));
      expect(restartedView.router.pages.single.page.name, '/');

      final secondUserRenderStart = restartedRenderedTypes.length;
      await _signUpAndOnboard(tester, restartedView);
      await _waitForCachedRoutes(tester, restartedView, const [
        '/dashboard',
        '/accounts',
        '/transactions',
        '/users/settings',
      ]);

      final secondNamespace = restartedView.cacheCoordinator?.namespace;
      expect(secondNamespace, isNotNull);
      expect(secondNamespace, isNot(firstNamespace));
      expect(
        restartedRenderedTypes.skip(secondUserRenderStart),
        isNot(contains(ViewType.cached)),
        reason: 'A new identity must not render the prior user snapshots',
      );
      expect(
        await restartedView.cacheCoordinator?.store.readSnapshot(
          firstNamespace,
          Uri.parse('/dashboard'),
        ),
        isNull,
      );
      final secondUserManifest =
          await restartedView.cacheCoordinator?.store.readManifest(
        LiveViewCacheCoordinator.manifestStorageKey(firstNamespace),
      );
      expect(secondUserManifest?.manifest.identity, secondNamespace?.identity);
      expect(
        secondUserManifest?.manifest.identity,
        isNot(firstNamespace.identity),
      );

      await _expectCachedThenFresh(
        tester,
        restartedView,
        '/dashboard',
        restartedRenderedTypes,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _expectRapidCachedTabSwitching(
  WidgetTester tester,
  LiveView view,
) async {
  final observedRoutes = <String?>[];
  void observeRoute() {
    observedRoutes.add(view.router.pages.lastOrNull?.page.name);
  }

  view.router.addListener(observeRoute);
  try {
    for (final route in const [
      '/accounts',
      '/transactions',
      '/users/settings',
      '/dashboard',
    ]) {
      unawaited(view.livePatch(route));
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(Router),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
        reason: '$route must not gain a transient root SafeArea',
      );
    }
    await _waitForUrl(tester, view, '/dashboard');
  } finally {
    view.router.removeListener(observeRoute);
  }

  expect(
    observedRoutes.whereType<String>().where(
          (route) => route.startsWith('loading;'),
        ),
    isEmpty,
    reason: 'cached bottom-bar routes must never fall back to a loader',
  );
}

Future<void> _waitForLogoutInvalidation(
  WidgetTester tester,
  LiveView view,
  LiveCacheNamespace namespace,
) async {
  final coordinator = view.cacheCoordinator!;
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump();
    final snapshot = await coordinator.store.readSnapshot(
      namespace,
      Uri.parse('/dashboard'),
    );
    final manifest = await coordinator.store.readManifest(
      LiveViewCacheCoordinator.manifestStorageKey(namespace),
    );
    if (coordinator.namespace == null && snapshot == null && manifest == null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Timed out waiting for logout cache invalidation');
}

Future<void> _waitForCachePolicy(WidgetTester tester, LiveView view) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump();
    if (view.cacheCoordinator?.namespace != null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Timed out waiting for the cache policy to be confirmed');
}

Future<void> _waitForCachedRoutes(
  WidgetTester tester,
  LiveView view,
  List<String> routes,
) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump();
    final coordinator = view.cacheCoordinator;
    if (coordinator != null && coordinator.namespace != null) {
      final snapshots = await Future.wait(
        routes.map((route) => coordinator.loadForNavigation(Uri.parse(route))),
      );
      if (snapshots.every((snapshot) => snapshot != null)) {
        return;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final coordinator = view.cacheCoordinator;
  throw Exception(
    'Timed out waiting for all manifest routes to be cached '
    '(parsed=${view.cacheManifest?.routes.map((route) => route.href).toList()}, '
    'active=${coordinator?.manifest?.routes.map((route) => route.href).toList()}, '
    'namespace=${coordinator?.namespace})',
  );
}

Future<void> _expectCachedThenFresh(
  WidgetTester tester,
  LiveView view,
  String route,
  List<ViewType> renderedTypes,
) async {
  final firstNewRender = renderedTypes.length;
  final observedRoutes = <String?>[];
  void observeRoute() {
    observedRoutes.add(view.router.pages.lastOrNull?.page.name);
  }

  view.router.addListener(observeRoute);
  try {
    await view.livePatch(route);
    await _waitForUrl(tester, view, route);
  } finally {
    view.router.removeListener(observeRoute);
  }
  expect(
    observedRoutes,
    isNot(contains('loading;$route')),
    reason: '$route should not show a loader when its snapshot is available',
  );
  expect(
    renderedTypes.skip(firstNewRender),
    contains(ViewType.cached),
    reason: '$route should display its snapshot',
  );
  expect(view.isShowingCachedRender, isFalse);
}

Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register');
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(seconds: 1));
  await tester.pumpAndSettle();

  await _waitFor(tester, find.byType(TextField));
  final email =
      'cache-integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'SuperSecret123!';
  final fields = find.byType(TextField);
  expect(fields, findsNWidgets(3));
  await tester.enterText(fields.at(0), email);
  await tester.pump();
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.enterText(fields.at(2), password);
  await tester.pump();
  await Future<void>.delayed(const Duration(seconds: 1));
  await tester.pump();
  await tester.enterText(fields.at(0), email);
  await tester.pump();

  final submitButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await tester.tap(submitButton);
  await _waitForUrl(tester, view, '/users/accept-tos');
  final acceptButton = find.byType(ElevatedButton).last;
  await tester.ensureVisible(acceptButton);
  await tester.tap(acceptButton);
  await _waitForUrl(tester, view, '/users/onboarding/currency');
  await _waitFor(tester, find.textContaining('EUR (€)'));

  final nextButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await tester.tap(nextButton.last);
  await _waitForUrl(tester, view, '/accounts');
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var attempt = 0; attempt < seconds; attempt++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var attempt = 0; attempt < seconds * 10; attempt++) {
    await tester.pump();
    if (view.currentUrl == url && view.isCurrentRouteReady) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

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

  for (var attempt = 0; attempt < 60; attempt++) {
    if (await _serverReady()) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  throw Exception('StartupKit server did not start');
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
