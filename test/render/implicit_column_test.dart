import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

bool? checkValue() =>
    (find.byType(Checkbox).evaluate().first.widget as Checkbox).value;

main() async {
  testWidgets('implicit columns behaves like html',
      (tester) => tester.checkScreenshot("""
          <Container>
            <Text>multiple</Text>
            <Text>lines</Text>
            <Text>in a container supporting a single child</Text>
          </Container>
        """, 'implicit_column_test.png'));
}
