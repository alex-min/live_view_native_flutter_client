import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('form change fires for a TextField nested in a Stack', (
    tester,
  ) async {
    var (view, server) = await connect(LiveView());
    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """
          <Form phx-change="search_currency" phx-submit="save_currency">
            <Stack clipBehavior="none">
              <Column crossAxisAlignment="start">
                <hidden name="user[default_currency]" value="EUR" />
                <TextField name="_currency_query" label="Change currency" />
              </Column>
            </Stack>
            <SizedBox height="16.0" />
            <ElevatedButton type="submit">Save</ElevatedButton>
          </Form>
        """,
      ],
    });
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'dollar');

    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'search_currency',
        'user%5Bdefault_currency%5D=EUR&_currency_query=dollar&_target=_currency_query',
      ),
    );
  });
}
