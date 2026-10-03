import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/audio/audio_player_service.dart';

class FakeAudioPlayerEngine extends AudioPlayerEngine {
  final List<String?> calls = [];
  String? lastUrl;
  bool fail = false;

  @override
  Future<void> stop() async {
    if (fail) throw Exception('stop failed');
    calls.add('stop');
  }

  @override
  Future<void> setUrl(String url) async {
    if (fail) throw Exception('setUrl failed');
    calls.add('setUrl');
    lastUrl = url;
  }

  @override
  Future<void> seek(Duration position) async {
    if (fail) throw Exception('seek failed');
    calls.add('seek');
  }

  @override
  Future<void> play() async {
    if (fail) throw Exception('play failed');
    calls.add('play');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioPlayerEngine engine;
  late AudioPlayerService service;

  setUp(() {
    engine = FakeAudioPlayerEngine();
    service = AudioPlayerService(engine: engine);
    AudioPlayerService.instance = service;
  });

  tearDown(() {
    AudioPlayerService.instance = AudioPlayerService();
  });

  test(
    'plays the url from the beginning after stopping current playback',
    () async {
      await service.play('https://example.com/audio.mp3');

      expect(engine.calls, ['stop', 'setUrl', 'seek', 'play']);
      expect(engine.lastUrl, 'https://example.com/audio.mp3');
    },
  );

  test('empty or missing url is a no-op', () async {
    await service.play(null);
    await service.play('');
    await service.play('   ');

    expect(engine.calls, isEmpty);
  });

  test('playback failures are swallowed, not thrown', () async {
    engine.fail = true;

    expect(
      () async => await service.play('https://example.com/audio.mp3'),
      returnsNormally,
    );
    expect(engine.lastUrl, isNull);
  });
}
