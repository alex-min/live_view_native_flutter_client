import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <MaterialBanner content="hello" leading="home" backgroundColor="amberShade400">
                <ElevatedButton>action 1</ElevatedButton>
                <ElevatedButton>action 2</ElevatedButton>
              </MaterialBanner>
              <MaterialBanner backgroundColor="amberShade300">
                <Container as="content">hello</Container>
                <Text as="leading">icon</Text>
                <ElevatedButton>action 1</ElevatedButton>
                <ElevatedButton>action 2</ElevatedButton>
              </MaterialBanner>
              <Text>hello</Text>
            </viewBody>
          </flutter>
        """, 'material_banner_test.png'));
}
