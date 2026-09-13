import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_segmented_progress_bar.dart';

import '../test_helpers.dart';

main() {
  Future<LiveView> renderBar(
    WidgetTester tester, {
    String segments = '#75cda1:66.8;#88aada:33.2',
  }) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container width="300">
            <SegmentedProgressBar height="7" trackColor="#26FFFFFF" borderRadius="8" segments="$segments" />
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    return view;
  }

  testWidgets('segments are proportionally laid out inside a rounded track', (
    tester,
  ) async {
    await renderBar(tester);

    final bar = tester.widget<Container>(
      find.descendant(
        of: find.byType(LiveSegmentedProgressBar),
        matching: find.byType(Container),
      ),
    );
    expect(bar.constraints?.maxHeight, 7);
    expect(
      (bar.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(8),
    );
    expect(bar.clipBehavior, Clip.antiAlias);

    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(LiveSegmentedProgressBar),
        matching: find.byType(Row),
      ),
    );
    expect(row.children.length, 2);
    final first = row.children[0] as Expanded;
    final second = row.children[1] as Expanded;
    expect(first.flex, 668);
    expect(second.flex, 332);
    expect((first.child as ColoredBox).color, const Color(0xFF75CDA1));
    expect((second.child as ColoredBox).color, const Color(0xFF88AADA));
  });

  testWidgets('drops empty and zero segments', (tester) async {
    await renderBar(tester, segments: '#75cda1:100;;#88aada:0');

    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(LiveSegmentedProgressBar),
        matching: find.byType(Row),
      ),
    );
    expect(row.children.length, 1);
  });
}
