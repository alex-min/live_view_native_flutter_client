import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/when/when.dart';

import '../test_helpers.dart';

Future<void> checkCondition(
    WidgetTester tester, String conditions, dynamic result) async {
  await tester.pumpWidget(
    MaterialApp(
        home: Builder(
            builder: (context) => Text(
                When(conditions: conditions).execute(context).toString()))),
  );
  expect(find.firstText(), result.toString());
}

void main() {
  testWidgets('when conditions', (tester) async {
    await checkCondition(tester, '500 > 600', false);
    await checkCondition(tester, '600 > 500', true);
    await checkCondition(tester, '700.0 > 500', true);
    await checkCondition(tester, '500 == 600', false);
    await checkCondition(tester, '500 == 500', true);
    await checkCondition(tester, '500 != 500', false);
    await checkCondition(tester, '500 != 600', true);
  });

  testWidgets('and conditions', (tester) async {
    await checkCondition(tester, '600 > 500 and 300 > 400', false);
    await checkCondition(tester, '700 > 500 and 500 > 400', true);
  });

  testWidgets('or conditions', (tester) async {
    await checkCondition(tester, '600 > 500 or 300 > 400', true);
    await checkCondition(tester, '700 > 500 or 500 > 400', true);
    await checkCondition(tester, '200 > 500 or 200 > 400', false);
  });
}
