import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';

import 'test_helpers.dart';

/// Bottom-tab pages (compact zero-height app bar) hide their app bar, so the
/// scaffold leaves the body edge-to-edge and the body must pad itself below
/// the status bar. Pages with a real app bar, or no app bar at all, must not
/// change.
void main() {
  Future<LiveView> pumpPage(
    WidgetTester tester,
    Map<String, dynamic> rendered, {
    required double topPadding,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(top: topPadding);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    var (view, _) = await connect(LiveView(), rendered: rendered);
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    return view;
  }

  Map<String, dynamic> pageWith(String appBar) => {
    's': [
      '''
      <csrf-token value="token"></csrf-token>
      <div id="phx-1" data-phx-session="session" data-phx-static="static" data-phx-main>
        <flutter extendBodyBehindAppBar="true">
      ''',
      '''
          <viewBody>
            <Container><Text>Body content</Text></Container>
          </viewBody>
        </flutter>
      </div>
    ''',
    ],
    '0': {
      's': [appBar],
    },
  };

  testWidgets('compact app bar page pads the body below the status bar', (
    tester,
  ) async {
    await pumpPage(
      tester,
      pageWith(
        '<AppBar toolbarHeight="0" primary="false" backgroundColor="#00FFFFFF" />',
      ),
      topPadding: 24,
    );

    expect(tester.getTopLeft(find.text('Body content')).dy, 24);
  });

  testWidgets('a real app bar keeps the body edge-to-edge behind it', (
    tester,
  ) async {
    await pumpPage(
      tester,
      pageWith('''
        <AppBar backgroundColor="#00FFFFFF">
          <title><Text>Details</Text></title>
        </AppBar>
      '''),
      topPadding: 24,
    );

    // no extra SafeArea around the body: the app bar covers the status bar
    // and padding again would double-pad the content
    expect(
      find.descendant(
        of: find.byType(Router<Object?>),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });

  testWidgets('ambient background stays edge-to-edge, content pads', (
    tester,
  ) async {
    await pumpPage(
      tester,
      pageWith(
        '<AppBar toolbarHeight="0" primary="false" backgroundColor="#00FFFFFF" />',
      ).map((key, value) {
        if (key == 's') {
          return MapEntry(
            key,
            (value as List<String>).map((chunk) {
              return chunk.replaceAll(
                '<viewBody>',
                '<viewBody cosmicBackground="true">',
              );
            }).toList(),
          );
        }
        return MapEntry(key, value);
      }),
      topPadding: 24,
    );

    // the cosmic background still paints behind the status bar…
    expect(tester.getTopLeft(find.byType(LiveCosmicBackground)).dy, 0);
    // …while the page content sits below it
    expect(tester.getTopLeft(find.text('Body content')).dy, 24);
  });

  testWidgets('a page without an app bar keeps handling insets itself', (
    tester,
  ) async {
    await pumpPage(tester, {
      's': [
        '''
        <csrf-token value="token"></csrf-token>
        <div id="phx-1" data-phx-session="session" data-phx-static="static" data-phx-main>
          <flutter extendBodyBehindAppBar="true">
            <viewBody>
              <SafeArea><Container><Text>Auth page</Text></Container></SafeArea>
            </viewBody>
          </flutter>
        </div>
      ''',
      ],
    }, topPadding: 24);

    // the page's own SafeArea consumed the status-bar padding exactly once
    expect(tester.getTopLeft(find.text('Auth page')).dy, 24);
  });
}
