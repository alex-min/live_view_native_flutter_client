import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('icon button test', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <Container>
                <ListTile tileColor="cyan">
                  <Text as="title">my list tile</Text>
                  <Text as="subtitle">subtitle here</Text>
                </ListTile>
                <Text>hello</Text>
              </Container>
            </viewBody>
          </flutter>
        """, 'list_title_test.png'));
}
