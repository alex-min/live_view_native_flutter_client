import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/button_style.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/input_decoration.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';

void main() {
  testWidgets('unknown properties warn for every CSS style parser', (
    tester,
  ) async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              getTextStyle('height: 1.2', context);
              getButtonStyle(context, 'elevation: 2');
              getDecoration(context, 'opacity: 0.5');
              getInputDecoration(context, 'floatingLabel: always');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    } finally {
      debugPrint = previousDebugPrint;
    }

    expect(
      messages,
      containsAll(<String>[
        'LiveView text style warning: unknown property "height"',
        'LiveView button style warning: unknown property "elevation"',
        'LiveView decoration style warning: unknown property "opacity"',
        'LiveView input decoration style warning: unknown property "floatingLabel"',
      ]),
    );
  });
}
