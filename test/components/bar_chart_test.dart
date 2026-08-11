import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  Future<LiveView> renderChart(WidgetTester tester, String xml) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<flutter><viewBody>$xml</viewBody></flutter>'],
      },
    );
    await tester.runLiveView(view);
    await tester.pump();
    return view;
  }

  testWidgets('renders income and expense bars at the requested size', (
    tester,
  ) async {
    await renderChart(
      tester,
      '<BarChart income="1200.5" expense="450" '
      'incomeLabel="Income" expenseLabel="Expenses" '
      'height="140" width="180" />',
    );

    expect(find.byType(charts.BarChart), findsOneWidget);
    final sizedBox = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.byType(charts.BarChart),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(sizedBox.width, 180);
    expect(sizedBox.height, 140);
  });

  testWidgets('accepts zero and invalid server values without crashing', (
    tester,
  ) async {
    await renderChart(tester, '<BarChart income="" expense="invalid" />');

    expect(find.byType(charts.BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
