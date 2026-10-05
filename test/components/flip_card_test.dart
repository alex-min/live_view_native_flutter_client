import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_flip_card.dart';
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

  Future<LiveView> pumpCard(
    WidgetTester tester, {
    String flipped = 'false',
    String? onFlip,
    bool withSpeaker = false,
  }) async {
    final speaker =
        withSpeaker
            ? '''
        <IconButton
          phx-click='[["speak", {"text": "sentence", "lang": "en-US"}]]'
          icon="volume_up"
        />'''
            : '';
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <FlipCard flipped="$flipped" ${onFlip != null ? "onFlip='" + onFlip + "'" : ''}>
            <Container height="300" decoration="background: #ff0000">
              <Text>front</Text>
              $speaker
            </Container>
            <Container height="300" decoration="background: #0000ff">
              <Text>back</Text>
            </Container>
          </FlipCard>
          ''',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    return view;
  }

  const flipExec = '[["speak", {"text": "flipped", "lang": "en-US"}]]';

  testWidgets('both faces are built and the front faces the viewer', (
    tester,
  ) async {
    await pumpCard(tester, onFlip: flipExec);

    expect(find.text('front'), findsOneWidget);
    expect(find.text('back'), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);

    // front visible, back culled at rest
    final frontVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('front'), matching: find.byType(Visibility)),
    );
    final backVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('back'), matching: find.byType(Visibility)),
    );
    expect(frontVis.visible, isTrue);
    expect(backVis.visible, isFalse);
  });

  testWidgets('tapping flips the card and fires onFlip once per tap', (
    tester,
  ) async {
    await pumpCard(tester, onFlip: flipExec);

    await tester.tap(find.byType(LiveFlipCard));
    await tester.pumpAndSettle();
    expect(engine.spoken, ['flipped']);

    // after the flip the back face shows the answer
    final frontVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('front'), matching: find.byType(Visibility)),
    );
    final backVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('back'), matching: find.byType(Visibility)),
    );
    expect(frontVis.visible, isFalse);
    expect(backVis.visible, isTrue);

    await tester.tap(find.byType(LiveFlipCard));
    await tester.pumpAndSettle();
    expect(engine.spoken, ['flipped', 'flipped']);
  });

  testWidgets('the flipped attribute drives the card without firing onFlip', (
    tester,
  ) async {
    await pumpCard(tester, flipped: 'true', onFlip: flipExec);

    await tester.pumpAndSettle();

    final backVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('back'), matching: find.byType(Visibility)),
    );
    expect(backVis.visible, isTrue);
    // server-driven: no exec fired
    expect(engine.spoken, isEmpty);
  });

  testWidgets('tapping a nested speaker does not flip the card', (
    tester,
  ) async {
    await pumpCard(tester, onFlip: flipExec, withSpeaker: true);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(engine.spoken, ['sentence']);
    final backVis = tester.widget<Visibility>(
      find.ancestor(of: find.text('back'), matching: find.byType(Visibility)),
    );
    expect(backVis.visible, isFalse);
  });
}
