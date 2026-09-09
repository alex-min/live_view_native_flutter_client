import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/shape_border.dart';

void main() {
  test('parses a rounded rectangle with a custom radius', () {
    final shape = getShapeBorder('RoundedRectangleBorder: 20');

    expect(shape, isA<RoundedRectangleBorder>());
    expect(
      (shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(20),
    );
  });

  test('rejects an invalid rounded rectangle radius', () {
    expect(getShapeBorder('RoundedRectangleBorder: wide'), isNull);
  });
}
