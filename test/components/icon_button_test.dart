import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('icon button test', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <Container>
                <IconButton icon="home" />
                <IconButton icon="home" filled="true" />
                <IconButton icon="home" filledTonal="true" />
                <Text>demo</Text>
              </Container>
            </viewBody>
          </flutter>
        """, 'icon_button_test.png'));
}
