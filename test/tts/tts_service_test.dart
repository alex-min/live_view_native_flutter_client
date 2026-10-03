import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/tts/tts_service.dart';

class FakeTtsEngine extends TtsEngine {
  List<String> languages;
  final List<String> languageCalls = [];
  final List<String> stops = [];
  final List<String> spoken = [];
  bool failInit = false;

  FakeTtsEngine({this.languages = const ['vi', 'en-US', 'fr-FR']});

  @override
  Future<void> init() async {
    if (failInit) {
      throw Exception('no tts engine');
    }
  }

  @override
  Future<List<dynamic>> getLanguages() async => languages;

  @override
  Future<void> setLanguage(String language) async {
    languageCalls.add(language);
  }

  @override
  Future<void> stop() async {
    stops.add('stop');
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTtsEngine engine;
  late TtsService service;

  setUp(() {
    engine = FakeTtsEngine();
    service = TtsService(engine: engine);
    TtsService.instance = service;
  });

  tearDown(() {
    TtsService.instance = TtsService();
  });

  test('speaks the text after cancelling in-flight speech', () async {
    await service.speak(text: 'xin chào', lang: 'vi-VN');

    expect(engine.stops, ['stop']);
    expect(engine.spoken, ['xin chào']);
  });

  test('uses the exact language when available', () async {
    await service.speak(text: 'hello', lang: 'en-US');

    expect(engine.languageCalls, ['en-US']);
  });

  test(
    'falls back to the language prefix when the exact one is missing',
    () async {
      await service.speak(text: 'xin chào', lang: 'vi-VN');

      expect(engine.languageCalls, ['vi']);
    },
  );

  test('keeps the engine default when no voice matches', () async {
    await service.speak(text: 'hola', lang: 'es-ES');

    expect(engine.languageCalls, isEmpty);
  });

  test('empty text is a no-op', () async {
    await service.speak(text: '   ', lang: 'vi-VN');

    expect(engine.spoken, isEmpty);
    expect(engine.stops, isEmpty);
  });

  test('missing lang speaks with the engine default', () async {
    await service.speak(text: 'hello');

    expect(engine.languageCalls, isEmpty);
    expect(engine.spoken, ['hello']);
  });

  test('init failures are swallowed, not thrown', () async {
    engine.failInit = true;

    await service.speak(text: 'hello');

    expect(engine.spoken, isEmpty);
  });
}
