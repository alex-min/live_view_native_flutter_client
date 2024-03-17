import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <Container>
                <TextButton>hello</TextButton>
                <Text>hello</Text>
              </Container>
            </viewBody>
          </flutter>
        """, 'text_button_test.png'));
}
