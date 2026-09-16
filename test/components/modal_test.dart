import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets(
    'modal test',
    (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <modal close-event="hideModal">
                <title>
                  <AppBar>
                    <title>demo modal</title>
                  </AppBar>
                </title>
                <content>
                  <Container>
                    <Text>Modal Content</Text> 
                  </Container>
                </content>
              </modal>
              <Container> 
                <Text>demo</Text>
              </Container>
            </viewBody>
          </flutter>
        """, 'modal_test.png'),
  );

  testWidgets('navigate to another page and back', (tester) async {
    var modal = {
      's': [
        """<modal close-event="hideModal">
            <title>
              <AppBar>
                <title>demo modal</title>
              </AppBar>
            </title>
            <content>
              <Container>
                <Text>Modal Content</Text>
              </Container>
            </content>
          </modal>""",
      ],
    };
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
            <viewBody>""",
          """<Container> 
                <Text>demo</Text>
              </Container>
            </viewBody>
          </flutter>""",
        ],
        '0': modal,
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('modal_opened_test.png'),
    );

    final backIcon = find.byIcon(Icons.close);
    expect(backIcon, findsOneWidget);
    await tester.tap(backIcon);
    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.event('hideModal'),
    ]);
    view.handleDiffMessage({'0': ""});
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('modal_closed_test.png'),
    );

    view.handleDiffMessage({'0': modal});
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('modal_opened_test.png'),
    );
  });

  testWidgets('dialog presentation renders and dismisses with close event', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <flutter>
            <viewBody>
              <modal presentation="dialog" close-event="cancel_delete">
                <title><Text>Delete transaction</Text></title>
                <content><Text>This cannot be undone.</Text></content>
              </modal>
            </viewBody>
          </flutter>
          ''',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Delete transaction'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(server.lastChannelAction, liveEvents.event('cancel_delete'));
  });
}
