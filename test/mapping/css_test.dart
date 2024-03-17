import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';

void main() {
  test('basic cases', () {
    expect(parseCss(''), []);

    expect(parseCss('hello: world'), [('hello', 'world')]);
    expect(parseCss('    hello  :   world    '), [('hello', 'world')]);

    expect(parseCss('hello: world; a: b'), [('hello', 'world'), ('a', 'b')]);
    expect(parseCss('  hello  : world     ; a  : b  '),
        [('hello', 'world'), ('a', 'b')]);

    expect(parseCss('a: b; c:'), [('a', 'b')]);
    expect(parseCss('background: @theme.appBarTheme.backgroundColor'),
        [('background', '@theme.appBarTheme.backgroundColor')]);
  });

  test('nested css', () {
    expect(parseCss('a: b; hello: { myprop: 1; something: 2 }; d: e'),
        [('a', 'b'), ('hello', 'myprop: 1; something: 2'), ('d', 'e')]);
    expect(parseCss('hello: { myprop: 1; world: { a: 1 }; b: 2 };'),
        [('hello', 'myprop: 1; world: { a: 1 }; b: 2')]);

    expect(parseCss('a: {b: 2}'), [('a', 'b: 2')]);
    expect(parseCss('a: {b: 2'), [('a', 'b: 2')]);
  });

  test('multiline css', () {
    expect(parseCss("""
          pressed: {
            fontWeight: bold
          }
          disabled: {
            fontWeight: w100
          }
        """),
        [('pressed', 'fontWeight: bold'), ('disabled', 'fontWeight: w100')]);
  });
}
