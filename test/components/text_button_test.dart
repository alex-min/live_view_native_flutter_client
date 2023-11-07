import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

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
