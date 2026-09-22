import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot_sanitizer.dart';

void main() {
  const sanitizer = LiveCacheSnapshotSanitizer();

  test('accepts and detaches a normal full render', () {
    var rendered = <String, dynamic>{
      's': [
        '<flutter><Text id="account-name">Cookie preferences</Text>',
        '</flutter>',
      ],
      '0': {
        's': ['<Text>', '</Text>'],
        '0': 'Current session activity',
      },
      'c': {
        '12': {
          's': ['<Icon>account_balance</Icon>'],
        },
      },
    };

    var sanitized = sanitizer.sanitize(rendered);

    expect(sanitized, equals(rendered));
    expect(sanitized, isNot(same(rendered)));
    expect(sanitized!['0'], isNot(same(rendered['0'])));
    expect(sanitized['s'], isNot(same(rendered['s'])));
  });

  test('rejects bootstrap values at any nesting level', () {
    for (var key in [
      '_csrf_token',
      'csrfToken',
      'data-phx-session',
      'phx_static',
      'cookie',
      'set-cookie',
      'liveViewId',
    ]) {
      expect(
        sanitizer.sanitize({
          's': ['safe'],
          'nested': {key: 'secret'},
        }),
        isNull,
        reason: 'Expected $key to be rejected',
      );
    }
  });

  test('rejects bootstrap material embedded in rendered statics', () {
    for (var staticValue in [
      '<meta name="csrf-token" content="secret">',
      '<input name="_csrf_token" value="secret">',
      '<div data-phx-session="signed">',
      '<div data-phx-static="signed">',
      '<div data-phx-main id="phx-root">',
      'Set-Cookie: session=secret',
      '<script>document.cookie</script>',
    ]) {
      expect(
        sanitizer.sanitize({
          's': [staticValue],
        }),
        isNull,
        reason: 'Expected $staticValue to be rejected',
      );
    }
  });

  test('rejects values that cannot be represented safely as JSON', () {
    expect(sanitizer.sanitize({'value': double.nan}), isNull);
    expect(sanitizer.sanitize({'value': Object()}), isNull);
    expect(
      sanitizer.sanitize({
        'value': <dynamic, dynamic>{1: 'non-string key'},
      }),
      isNull,
    );
  });

  test('rejects excessively deep rendered trees', () {
    dynamic nested = 'leaf';
    for (var i = 0; i < LiveCacheSnapshotSanitizer.maximumDepth + 1; i++) {
      nested = <String, dynamic>{'0': nested};
    }

    expect(sanitizer.sanitize({'s': <String>[], '0': nested}), isNull);
  });
}
