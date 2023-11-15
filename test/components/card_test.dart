import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('icon button test', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <Card margin="10" color="green">
                <Text>demo</Text>
                <Text>demo</Text>
                <Text>demo</Text>
              </Card>
            </viewBody>
          </flutter>
        """, 'card_test.png'));
}
