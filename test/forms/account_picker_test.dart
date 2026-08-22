import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'tapping the back arrow on the account picker sends close event',
    (tester) async {
      tester.setScreenSize(const Size(400, 800));

      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
          <flutter>
            <viewBody>
              <Column>
                <Row>
                  <IconButton icon="arrow_back" phx-click="close_account_picker" />
                  <Text>Select account</Text>
                </Row>
                <ListTile phx-click="select_account" phx-value-id="1">
                  <title><Text>Checking</Text></title>
                </ListTile>
                <ListTile phx-click="select_account" phx-value-id="2">
                  <title><Text>Savings</Text></title>
                </ListTile>
              </Column>
            </viewBody>
          </flutter>
          """,
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      expect(find.text('Select account'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(
        server.lastChannelActions?.last,
        liveEvents.phxClick({}, eventName: 'close_account_picker'),
      );
    },
  );

  testWidgets(
    'tapping a ListTile sends its phx-click event with phx-value data',
    (tester) async {
      tester.setScreenSize(const Size(400, 800));

      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
          <flutter>
            <viewBody>
              <Column>
                <ListTile phx-click="select_account" phx-value-id="1">
                  <title><Text>Checking</Text></title>
                </ListTile>
              </Column>
            </viewBody>
          </flutter>
          """,
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Checking'));
      await tester.pumpAndSettle();

      expect(
        server.lastChannelActions?.last,
        liveEvents.phxClick({'id': '1'}, eventName: 'select_account'),
      );
    },
  );

  testWidgets(
    'the account field is a dropdown on large screens and a trigger on small screens',
    (tester) async {
      tester.setScreenSize(const Size(900, 800));

      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
            <flutter>
              <viewBody>
                <Column>
                  <DropdownButton
                    id="desktop-account-dropdown"
                    name="transaction[account_id]"
                    initialValue="1"
                    isExpanded="true"
                    phx-responsive="${baseActions.show}"
                    phx-responsive-when="window_width >= 768"
                  >
                    <DropdownMenuItem label="Checking" value="1" />
                    <DropdownMenuItem label="Savings" value="2" />
                  </DropdownButton>
                  <ListTile
                    id="mobile-account-trigger"
                    phx-click="open_account_picker"
                    phx-responsive="${baseActions.hide}"
                    phx-responsive-when="window_width >= 768"
                  >
                    <title><Text>Checking</Text></title>
                  </ListTile>
                </Column>
              </viewBody>
            </flutter>
            """,
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);

      tester.setScreenSize(const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Checking'), findsOneWidget);
    },
  );
}
