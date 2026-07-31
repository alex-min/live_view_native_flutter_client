import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('DropdownButton renders its icon and underline children', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <viewBody>
              <ListTile>
                <title><Text>Integration account</Text></title>
                <trailing>
                  <DropdownButton>
                    <icon><Icon name="more_vert" /></icon>
                    <underline><SizedBox height="0.0" /></underline>
                    <DropdownMenuItem label="Modifier" value="edit-1" live-patch="/accounts/1/edit" />
                    <DropdownMenuItem label="Marquer comme inactif" value="toggle-1" phx-click="toggle_inactive" phx-value-id="1" />
                  </DropdownButton>
                </trailing>
              </ListTile>
            </viewBody>
          </flutter>
          """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    // the icon child must be the <icon> widget, not another attribute child
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(dropdown.icon, isA<LiveIconAttribute>());
  });
}
