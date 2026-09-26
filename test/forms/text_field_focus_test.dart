import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('keeps focus when validation reparses the form', (tester) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<flutter><viewBody>', '</viewBody></flutter>'],
        '0': {
          's': [
            '<Column><Card><Container><Form phx-change="validate">'
                '<TextField name="email" errors="',
            '" /></Form></Container></Card></Column>',
          ],
          '0': '[]',
        },
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.enterText(field, 'a');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    view.handleDiffMessage({
      '0': {'0': '[{"message":"must be an email","options":{}}]'},
    });
    await tester.pumpAndSettle();

    expect(field, findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(tester.widget<TextField>(field).controller?.text, 'a');
    expect(find.text('must be an email'), findsOneWidget);
  });
  for (var selection in [
    const TextSelection.collapsed(offset: 1),
    const TextSelection(baseOffset: 3, extentOffset: 1),
  ]) {
    testWidgets('preserves $selection across validation rebuilds', (
      tester,
    ) async {
      final (view, _) = await connect(
        LiveView(),
        rendered: {
          's': ['<flutter><viewBody>', '</viewBody></flutter>'],
          '0': {
            's': [
              '<Form phx-change="validate"><TextField name="phone" keyboardType="phone" errors="',
              '" /></Form>',
            ],
            '0': '[]',
          },
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, '1111');
      final controller = tester.widget<TextField>(field).controller!;
      final focusNode = tester.widget<TextField>(field).focusNode!;
      var focusChanges = 0;
      void onFocusChanged() => focusChanges++;
      focusNode.addListener(onFocusChanged);
      addTearDown(() => focusNode.removeListener(onFocusChanged));
      controller.selection = selection;
      view.handleDiffMessage({
        '0': {'0': '[{"message":"invalid phone","options":{}}]'},
      });
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(tester.widget<TextField>(field).focusNode, same(focusNode));
      expect(focusChanges, 0);
      expect(controller.selection, selection);

      for (var i = 0; i < 2; i++) {
        final value = tester.widget<TextField>(field).controller!.value;
        tester.testTextInput.updateEditingValue(
          value.copyWith(
            text: value.text.replaceRange(
              value.selection.start,
              value.selection.end,
              '2',
            ),
            selection: TextSelection.collapsed(
              offset: value.selection.start + 1,
            ),
          ),
        );
        await tester.pump();
        view.handleDiffMessage({
          '0': {'0': '[{"message":"invalid phone $i","options":{}}]'},
        });
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.selection,
          TextSelection.collapsed(offset: 2 + i),
        );
      }
      expect(focusChanges, 0);
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(
        tester.widget<TextField>(field).controller!.text,
        selection.isCollapsed ? '122111' : '1221',
      );
    });
  }
  testWidgets('delayed validation keeps local typing and the input connection', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<flutter><viewBody>', '</viewBody></flutter>'],
        '0': {
          's': [
            '<Column><Card><Form phx-change="validate"><TextField name="phone" initialValue="',
            '" errors="',
            '" /></Form></Card></Column>',
          ],
          '0': '',
          '1': '[]',
        },
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    await tester.enterText(field, '1111');
    const editing = TextEditingValue(
      text: '122111',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 3),
    );
    tester.testTextInput.updateEditingValue(editing);
    await tester.pump();
    final controller = tester.widget<TextField>(field).controller!;
    final editor = tester.state<EditableTextState>(find.byType(EditableText));
    tester.testTextInput.log.clear();
    for (final staleText in ['1111', '12111']) {
      view.handleDiffMessage({
        '0': {
          '0': staleText,
          '1': '[{"message":"invalid phone","options":{}}]',
        },
      });
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editor),
      );
      expect(controller.value, editing);
      expect(editor.widget.focusNode.hasFocus, isTrue);
    }
    expect(
      tester.testTextInput.log.where(
        (call) => [
          'TextInput.setClient',
          'TextInput.clearClient',
          'TextInput.show',
          'TextInput.hide',
        ].contains(call.method),
      ),
      isEmpty,
    );
  });

  testWidgets('same-named fields in separate forms have independent editors', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<viewBody><Column><Form><TextField name="phone" /></Form><Form><TextField name="phone" /></Form></Column></viewBody>',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields[0].controller, isNot(same(fields[1].controller)));
  });
}
