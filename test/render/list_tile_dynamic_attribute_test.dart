import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';

import '../test_helpers.dart';

main() async {
  // A ListTile inside a comprehension whose row carries a Map dynamic holding
  // the <leading> attribute (a server-side `if` around <leading> renders as
  // a LiveDynamicComponent child of the ListTile).
  Map<String, dynamic> rendered(dynamic leadingDynamic) => {
    's': ['<Column>', '</Column>'],
    '0': {
      's': ['<ListTile><title><Text>', '</Text></title>', '</ListTile>'],
      'd': [
        ['my title', leadingDynamic],
      ],
    },
  };

  testWidgets('list tile attribute inside a dynamic renders', (tester) async {
    var view =
        LiveView()..handleRenderedMessage(
          rendered({
            's': [
              '<leading><Container><Text>category icon</Text></Container></leading>',
            ],
          }),
        );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), contains('my title'));
    expect(find.allTexts(), contains('category icon'));

    var tile = find.firstOf<ListTile>();
    expect(tile.leading, isA<LiveDynamicComponent>());
  });

  testWidgets('list tile attribute with an empty dynamic stays absent', (
    tester,
  ) async {
    var view = LiveView()..handleRenderedMessage(rendered(''));

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), contains('my title'));
    expect(find.allTexts(), isNot(contains('category icon')));

    var tile = find.firstOf<ListTile>();
    expect(tile.leading, isNull);
  });
}
