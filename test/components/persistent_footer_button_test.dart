import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

bool? checkValue() =>
    (find.byType(Checkbox).evaluate().first.widget as Checkbox).value;

main() async {
  testWidgets('looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <PersistentFooterButton><ElevatedButton>hello</ElevatedButton></PersistentFooterButton>
            <PersistentFooterButton><ElevatedButton>hello</ElevatedButton></PersistentFooterButton>
            <viewBody>
              <Column>
                <Text>hello</Text>
              </Column>
            </viewBody>
          </flutter>
        """, 'persistent_footer_button_test.png'));
}
