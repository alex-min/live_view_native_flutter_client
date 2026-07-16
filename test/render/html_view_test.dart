import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders basic HTML tags from escaped inner HTML',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          '<HtmlView style="textTheme: bodyMedium; color: @theme.colorScheme.onSurface">&lt;h1&gt;Title&lt;/h1&gt;&lt;p&gt;Some &lt;b&gt;bold&lt;/b&gt; and &lt;i&gt;italic&lt;/i&gt; text.&lt;/p&gt;</HtmlView>'
        ],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(HtmlWidget), findsOneWidget);

    var htmlWidget =
        find.byType(HtmlWidget).evaluate().first.widget as HtmlWidget;
    expect(htmlWidget.html, contains('<h1>Title</h1>'));
    expect(htmlWidget.html, contains('<b>bold</b>'));
    expect(htmlWidget.html, contains('<i>italic</i>'));
  });

  testWidgets('decodes HTML entities before rendering', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          '<HtmlView>&lt;p&gt;Foo &amp; Bar&lt;/p&gt;</HtmlView>'
        ],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var htmlWidget =
        find.byType(HtmlWidget).evaluate().first.widget as HtmlWidget;
    expect(htmlWidget.html, '<p>Foo & Bar</p>');
  });

  testWidgets('applies style attribute to HtmlWidget', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          '<HtmlView style="textTheme: bodyMedium; color: @theme.colorScheme.onSurface"><b>styled</b></HtmlView>'
        ],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var htmlWidget =
        find.byType(HtmlWidget).evaluate().first.widget as HtmlWidget;
    expect(htmlWidget.textStyle, isNotNull);
    expect(
      htmlWidget.textStyle!.color,
      Theme.of(tester.element(find.byType(HtmlWidget)))
          .colorScheme
          .onSurface,
    );
  });

  testWidgets('handles dynamic HTML content variables', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<HtmlView>[[flutterState key=0]]</HtmlView>'],
        '0': '<b>dynamic</b>'
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var htmlWidget =
        find.byType(HtmlWidget).evaluate().first.widget as HtmlWidget;
    expect(htmlWidget.html, '<b>dynamic</b>');
  });
}
