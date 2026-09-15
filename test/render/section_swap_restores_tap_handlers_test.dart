import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

/// Regression test for the transaction form's category picker (an if/else
/// switching between the form and a comprehension-based picker section).
///
/// The payloads are real captures from the StartupKit server: the initial
/// render of the transaction form, the diff sent when the picker opens and
/// the diff sent when it closes. Closing must fully replace the picker
/// section: merging the close diff into the accumulated variables used to
/// keep the picker's comprehension keys (`d`, `p`, leftover slots), so the
/// form's "No category" row re-rendered without its `<ListTile>` wrapper and
/// its tap handler silently did nothing.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/render/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('section swap back restores tap handlers', (tester) async {
    final initial = _fixture('category_picker_initial_render.json');
    final openDiff = _fixture('category_picker_open_diff.json');
    final closeDiff = _fixture('category_picker_close_diff.json');

    final (view, socket) = await connect(
      LiveView(),
      rendered: initial,
      viewType: ViewType.liveView,
    );
    await tester.runLiveView(view);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No category'), findsWidgets);
    expect(find.text('Select category'), findsNothing);

    Future<void> tapNoCategory() async {
      await tester.tap(find.text('No category').hitTestable().last);
      await tester.pump(const Duration(milliseconds: 100));
    }

    void expectPickerSent() {
      expect(
        socket.lastChannelActions?.where((a) => a.eventName == 'event'),
        isNotEmpty,
        reason: 'Tapping the row should push the phx-click event',
      );
      socket.lastChannel!.actions.clear();
    }

    // First open: the picker replaces the form's category row.
    await tapNoCategory();
    expectPickerSent();
    view.handleDiffMessage(openDiff);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Select category'), findsOneWidget);

    // Closing restores the form row, including its ListTile tap handler.
    view.handleDiffMessage(closeDiff);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Select category'), findsNothing);
    expect(find.text('No category'), findsWidgets);

    // Reopening must work: the restored row pushes the event again (before
    // the fix the merged section lost its ListTile wrapper and the tap was
    // silently swallowed).
    await tapNoCategory();
    expectPickerSent();
  });
}
