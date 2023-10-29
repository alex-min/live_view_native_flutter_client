import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';

MaterialStateProperty<TextStyle?>? materialTextStyle() =>
    (find.byType(FilledButton).evaluate().first.widget as FilledButton)
        .style
        ?.textStyle;

Future<void> setStyle(WidgetTester tester, String style) async {
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
    return FilledButton(
      onPressed: () {},
      style: ButtonStyle(textStyle: getMaterialTextStyle(style, context)),
      child: const Text('hello'),
    );
  })));
  await tester.pumpAndSettle();
}

main() {
  testWidgets('material text style', (tester) async {
    await setStyle(tester, 'hello');
    expect(materialTextStyle()!.resolve({}), const TextStyle());

    await setStyle(tester, 'fontWeight: bold');
    expect(materialTextStyle()!.resolve({}),
        const TextStyle(fontWeight: FontWeight.bold));

    await setStyle(tester, """'
          pressed: {
            fontWeight: bold
          }
          disabled: {
            fontWeight: w100
          }
        """);
    var style = materialTextStyle()!;
    expect(style.resolve({MaterialState.pressed}),
        const TextStyle(fontWeight: FontWeight.bold));
    expect(style.resolve({MaterialState.disabled}),
        const TextStyle(fontWeight: FontWeight.w100));
  });
}
