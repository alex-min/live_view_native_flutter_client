import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/tts/tts_service.dart';

import '../test_helpers.dart';

class FakeTtsEngine extends TtsEngine {
  final List<String> spoken = [];
  final List<String> languageCalls = [];

  @override
  Future<List<dynamic>> getLanguages() async => ['vi', 'en-US'];

  @override
  Future<void> setLanguage(String language) async {
    languageCalls.add(language);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

class CountingMountExec extends Exec {
  static int count = 0;

  @override
  void handler(BuildContext context, StateWidget widget) {
    count += 1;
  }
}

Map<String, dynamic> _rendered() => {
  's': ['<Column>', '', '<Text>count: ', '</Text>', '</Column>'],
  '0': {
    's': ['<Text phx-on-mount=\'[["testOnMountCount"]]\'>spoken</Text>'],
  },
  '1': '1',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LiveViewExecRegistry.instance.add(
      ['testOnMountCount'],
      (_, __) => CountingMountExec(),
      triggers: [LiveViewExecTrigger.onMount],
    );
  });

  setUp(() {
    CountingMountExec.count = 0;
  });

  testWidgets('onMount fires once on insert and not on unrelated diffs', (
    tester,
  ) async {
    var (view, _) = await connect(LiveView(), rendered: _rendered());

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(CountingMountExec.count, 1);

    // An assign change keeps the element: the exec must not re-fire, even
    // though the client re-creates widget subtrees on every diff.
    view.handleDiffMessage({'1': '2'});
    await tester.pumpAndSettle();

    expect(find.allTexts(), contains('2'));
    expect(CountingMountExec.count, 1);
  });

  testWidgets('onMount fires again when the element is removed and re-added', (
    tester,
  ) async {
    var (view, _) = await connect(LiveView(), rendered: _rendered());

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(CountingMountExec.count, 1);

    // Swap the section to a branch without the mounted element.
    view.handleDiffMessage({
      '0': {
        's': ['<Text>other</Text>'],
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('spoken'), findsNothing);
    expect(CountingMountExec.count, 1);

    // Swap back: the element is inserted again, the exec fires once more.
    view.handleDiffMessage({
      '0': {
        's': ['<Text phx-on-mount=\'[["testOnMountCount"]]\'>spoken</Text>'],
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('spoken'), findsOneWidget);
    expect(CountingMountExec.count, 2);
  });

  testWidgets('onMount fires again after a page change', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: _rendered());

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(CountingMountExec.count, 1);

    // A full re-render (navigation) rebuilds the tree: mount execs fire again.
    view.handleRenderedMessage(_rendered());
    await tester.pumpAndSettle();

    expect(CountingMountExec.count, 2);
  });

  testWidgets('speak fires from phx-on-mount and from phx-click', (
    tester,
  ) async {
    var engine = FakeTtsEngine();
    TtsService.instance = TtsService(engine: engine);
    addTearDown(() {
      TtsService.instance = TtsService();
    });

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<Text phx-on-mount=\'[["speak", {"text": "auto", "lang": "vi-VN"}]]\' '
              'phx-click=\'[["speak", {"text": "tapped", "lang": "vi-VN"}]]\'>spoken</Text>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(engine.spoken, ['auto']);

    await tester.tap(find.text('spoken'));
    await tester.pumpAndSettle();

    expect(engine.spoken, ['auto', 'tapped']);
    expect(engine.languageCalls, ['vi', 'vi']);
  });
}
