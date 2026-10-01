import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/error_404.dart';
import 'package:liveview_flutter/live_view/ui/errors/flutter_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/missing_page_component.dart';
import 'package:liveview_flutter/live_view/ui/errors/no_server_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/parsing_error_view.dart';
import 'package:liveview_flutter/live_view/ui/loading/reload_widget.dart';

void main() {
  final error = FlutterErrorDetails(exception: StateError('example'));
  final views = <(String, Widget)>[
    ('404', const Error404(url: '/missing')),
    ('compilation', const CompilationErrorView(html: '<div>error</div>')),
    ('server', NoServerError(error: error)),
    ('missing body', const MissingPageComponent(url: '/', html: '<flutter/>')),
    ('Flutter', FlutterErrorView(error: error)),
    ('parsing', const ParsingErrorView(xml: '', url: '/broken')),
  ];

  for (final (name, view) in views) {
    testWidgets('$name fallback uses dark theme surfaces and text', (
      tester,
    ) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      );
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData(colorScheme: scheme), home: view),
      );

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        scheme.surface,
      );
      expect(
        tester.widget<Container>(find.byType(Container).first).color,
        scheme.errorContainer,
      );
      expect(
        tester.widget<Text>(find.byType(Text).first).style?.color,
        scheme.onErrorContainer,
      );
    });
  }

  testWidgets('reload indicator uses active theme accents', (tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const Scaffold(body: ReloadWidget()),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).last);
    final gradient = (container.decoration! as BoxDecoration).gradient!;
    expect(gradient.colors, [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
    ]);
  });
}
