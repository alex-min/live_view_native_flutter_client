import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('modal test', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <modal close-event="hideModal">
                <title>
                  <AppBar>
                    <title>demo modal</title>
                  </AppBar>
                </title>
                <content>
                  <Container>
                    <Text>Modal Content</Text> 
                  </Container>
                </content>
              </modal>
              <Container> 
                <Text>demo</Text>
              </Container>
            </viewBody>
          </flutter>
        """, 'modal_test.png'));
}
