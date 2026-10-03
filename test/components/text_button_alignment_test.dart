import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  testWidgets('a TextButton honors the alignment declared in its style', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
              <flutter>
                <viewBody>
                  <Row>
                    <Expanded>
                      <TextButton style="padding: 0; minimumSize: 0; tapTargetSize: shrinkWrap; alignment: centerStart">
                        <Column crossAxisAlignment="start">
                          <Text>AAAAAAAAAAAAAAAAAAAA</Text>
                          <Text>BB</Text>
                        </Column>
                      </TextButton>
                    </Expanded>
                  </Row>
                </viewBody>
              </flutter>
            """,
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final buttonLeft = tester.getTopLeft(find.byType(TextButton)).dx;
    expect(tester.getTopLeft(find.text('BB')).dx, buttonLeft);
  });

  testWidgets(
    'a TextButton keeps Material default centering when no alignment is declared',
    (tester) async {
      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
              <flutter>
                <viewBody>
                  <Row>
                    <Expanded>
                      <TextButton style="padding: 0; minimumSize: 0; tapTargetSize: shrinkWrap">
                        <Column crossAxisAlignment="start">
                          <Text>AAAAAAAAAAAAAAAAAAAA</Text>
                          <Text>BB</Text>
                        </Column>
                      </TextButton>
                    </Expanded>
                  </Row>
                </viewBody>
              </flutter>
            """,
          ],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      final buttonLeft = tester.getTopLeft(find.byType(TextButton)).dx;
      expect(tester.getTopLeft(find.text('BB')).dx, greaterThan(buttonLeft));
    },
  );
}
