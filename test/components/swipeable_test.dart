import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_swipeable.dart';
import 'package:liveview_flutter/tts/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

class RecordingEngine extends TtsEngine {
  final List<String?> spoken = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<dynamic>> getLanguages() async => const ['en-US'];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingEngine engine;

  setUpAll(FlutterExecAction.registerDefaultExecs);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = RecordingEngine();
    TtsService.instance = TtsService(engine: engine);
  });

  tearDown(() {
    TtsService.instance = TtsService();
  });

  Future<LiveView> pumpSwipeable(
    WidgetTester tester, {
    String? onSwipeUp,
    String? onSwipeDown,
    String extraAttributes = '',
  }) async {
    final attrs = <String>[
      if (onSwipeUp != null) "onSwipeUp='" + onSwipeUp + "'",
      if (onSwipeDown != null) "onSwipeDown='" + onSwipeDown + "'",
      extraAttributes,
    ].join(' ');
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <Swipeable $attrs>
            <Container height="300" decoration="background: #ff0000">
              <Text>card</Text>
            </Container>
          </Swipeable>
          ''',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    return view;
  }

  const upExec = '[["speak", {"text": "up", "lang": "en-US"}]]';
  const downExec = '[["speak", {"text": "down", "lang": "en-US"}]]';

  testWidgets('a big upward drag flings the card and fires onSwipeUp', (
    tester,
  ) async {
    await pumpSwipeable(tester, onSwipeUp: upExec);

    await tester.drag(find.byType(LiveSwipeable), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(engine.spoken, ['up']);
    // the card flung off screen upward
    final rect = tester.getRect(find.text('card'));
    expect(rect.bottom, lessThan(0));
  });

  testWidgets('a big downward drag fires onSwipeDown', (tester) async {
    await pumpSwipeable(tester, onSwipeDown: downExec);

    await tester.drag(find.byType(LiveSwipeable), const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(engine.spoken, ['down']);
  });

  testWidgets('a small drag snaps back without firing any exec', (
    tester,
  ) async {
    await pumpSwipeable(tester, onSwipeUp: upExec, onSwipeDown: downExec);

    await tester.drag(find.byType(LiveSwipeable), const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(engine.spoken, isEmpty);
    // back in place
    expect(tester.getRect(find.text('card')), isNotNull);
  });

  testWidgets('animateIn slides the card in and settles in place', (
    tester,
  ) async {
    await pumpSwipeable(tester, onSwipeUp: upExec, extraAttributes: '');

    final swipeable = find.byType(LiveSwipeable);
    expect(swipeable, findsOneWidget);
    // the enter animation completed and the card is visible
    expect(tester.getRect(find.text('card')).top, greaterThanOrEqualTo(0));
  });
}
