import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

extension FindText on CommonFinders {
  String? firstText() => (byType(Text).evaluate().single.widget as Text).data;
  T firstOf<T>() => byType(T).evaluate().single.widget as T;
  List<String> allTexts() =>
      (byType(Text).evaluate().map((e) => (e.widget as Text).data ?? ''))
          .toList();
}

extension ValueText on FormBuilderTextField {
  String get value =>
      (key! as GlobalKey<FormBuilderFieldState>).currentState!.value;
}

extension RunLiveView on WidgetTester {
  Future<void> runLiveView(LiveView view) async {
    return pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(body: view.rootWidget);
    })));
  }
}
