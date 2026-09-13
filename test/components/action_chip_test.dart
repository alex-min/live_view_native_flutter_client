import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

bool? checkValue() =>
    (find.byType(Checkbox).evaluate().first.widget as Checkbox).value;

main() async {
  testWidgets(
    'looks okay',
    (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody>
              <Container>
                <!-- All three are the same -->
                <ActionChip label="hello" icon="home" />
                <ActionChip>
                  <label>hello</label>
                  <Icon name="home" />
                </ActionChip>
                <ActionChip>
                  <Text>hello</Text>
                  <avatar><Icon name="home" /></avatar>
                </ActionChip>
              </Container>
            </viewBody>
          </flutter>
        """, 'action_chip_test.png'),
  );

  testWidgets('phx click works', (tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container>
            <ActionChip label="hello" phx-click="server_event" icon="home" />
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      server.lastChannelAction,
      liveEvents.phxClick({}, eventName: 'server_event'),
    );
  });

  testWidgets('side attribute renders a bordered stadium chip', (tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container>
            <ActionChip label="chip" side="1 #FF0000" />
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.side?.width, 1.0);
    expect(chip.side?.color, const Color(0xFFFF0000));
    final shape = chip.shape;
    expect(shape, isA<StadiumBorder>());
    expect((shape as StadiumBorder).side.width, 1.0);
    expect(shape.side.color, const Color(0xFFFF0000));
  });

  testWidgets('chip without side keeps the default borderless shape', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container>
            <ActionChip label="chip" />
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.side, isNull);
    expect(chip.shape, isNull);
  });
}
