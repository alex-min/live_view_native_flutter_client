import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/button_style.dart';

Future<ButtonStyle?> loadStyle(WidgetTester tester, String style) async {
  ButtonStyle? loadedStyle;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          loadedStyle = getButtonStyle(context, style);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return loadedStyle;
}

void main() {
  testWidgets('parse text style', (tester) async {
    var style = await loadStyle(tester, 'textStyle: { fontWeight: bold }');
    expect(
      style?.textStyle?.resolve({}),
      const TextStyle(fontWeight: FontWeight.bold),
    );
  });

  testWidgets('parse colors', (tester) async {
    var style = await loadStyle(
      tester,
      'backgroundColor: #5353E5; foregroundColor: #FFFFFF',
    );
    expect(style?.backgroundColor?.resolve({}), const Color(0xFF5353E5));
    expect(style?.foregroundColor?.resolve({}), Colors.white);
  });

  testWidgets('parse padding', (tester) async {
    var style = await loadStyle(tester, 'padding: { 12 24 }');
    expect(
      style?.padding?.resolve({}),
      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    );
  });

  testWidgets('parse size', (tester) async {
    var style = await loadStyle(tester, 'minimumSize: { infinity 48 }');
    expect(style?.minimumSize?.resolve({}), const Size(double.infinity, 48));
  });

  testWidgets('parse single value size', (tester) async {
    var style = await loadStyle(tester, 'minimumSize: 0');
    expect(style?.minimumSize?.resolve({}), Size.zero);
  });

  testWidgets('parse tap target size', (tester) async {
    var style = await loadStyle(tester, 'tapTargetSize: shrinkWrap');
    expect(style?.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
  });

  testWidgets('parse radius shape', (tester) async {
    var style = await loadStyle(tester, 'shape: { radius 30 }');
    expect(
      style?.shape?.resolve({}),
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  });

  testWidgets('parse circle shape', (tester) async {
    var style = await loadStyle(tester, 'shape: circle');
    expect(style?.shape?.resolve({}), const CircleBorder());
  });
}
