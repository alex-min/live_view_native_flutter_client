import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testGoldens('segmented buttons looks okay', (tester) async {
    await tester.checkScreenshot("""
          <Row>
            <SegmentedButton initialValue="2" name="button-group">
              <ButtonSegment name="1" label="my label" icon="home" />
              <ButtonSegment name="2" label="my label" icon="home" />
              <ButtonSegment name="3" label="my label" icon="home" />
            </SegmentedButton>
          </Row>
        """, 'live_segmented_button.png');

    await tester.checkScreenshot("""
          <Row>
            <SegmentedButton initialValue="2" name="button-group">
              <ButtonSegment name="1" icon="home"><Text>my label</Text></ButtonSegment>
              <ButtonSegment name="2" label="my label">
                <Icon name="home" />
              </ButtonSegment>
              <ButtonSegment name="3" label="my label" icon="home" />
            </SegmentedButton>
          </Row>
        """, 'live_segmented_button.png');
  });

  testWidgets('inside a form', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Form phx-change="changed">
            <SegmentedButton initialValue="1" name="button-group" emptySelectionAllowed="true">
              <ButtonSegment name="1" label="first option" icon="home" />
              <ButtonSegment name="2" label="second option" icon="home" />
              <ButtonSegment name="3" label="third option" icon="home" />
            </SegmentedButton>
          </Form>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text("second option"));
    await tester.pumpAndSettle();

    expect(
        server.lastChannelAction,
        const EventSent('event', {
          'type': 'form',
          'event': 'changed',
          'value': 'button-group=2&_target=button-group',
        }));

    expect(find.firstOf<SegmentedButton<String>>().selected, {'2'});

    await tester.tap(find.text("second option"));
    await tester.pumpAndSettle();

    expect(
        server.lastChannelAction,
        const EventSent('event', {
          'type': 'form',
          'event': 'changed',
          'value': '_target=button-group',
        }));

    expect(find.firstOf<SegmentedButton<String>>().selected, <String>{});
  });

  testWidgets('initial value cannot be reset', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <SegmentedButton """,
        """ name="button-group">
            <ButtonSegment name="1" label="first option" icon="home" />
            <ButtonSegment name="2" label="second option" icon="home" />
            <ButtonSegment name="3" label="third option" icon="home" />
          </SegmentedButton>
        """
      ],
      '0': 'initialValue="1"'
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstOf<SegmentedButton<String>>().selected, {'1'});

    view.handleDiffMessage({'0': 'initialValue="2"'});
    await tester.pumpAndSettle();
    expect(find.firstOf<SegmentedButton<String>>().selected, {'1'});
  });

  testWidgets('with multiple selection', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Row>
            <Form phx-change="changed">
              <SegmentedButton initialValue="1" name="button-group" multiSelectionEnabled="true">
                <ButtonSegment name="1" label="first option" icon="home" />
                <ButtonSegment name="2" label="second option" icon="home" />
                <ButtonSegment name="3" label="third option" icon="home" />
              </SegmentedButton>
            </Form>
          </Row>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstOf<SegmentedButton<String>>().selected, {'1'});

    await tester.tap(find.text("second option"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("third option"));
    await tester.pumpAndSettle();

    expect(find.firstOf<SegmentedButton<String>>().selected, {'1', '2', '3'});

    expect(
        server.lastChannelAction,
        const EventSent('event', {
          'type': 'form',
          'event': 'changed',
          'value':
              'button-group%5B0%5D=1&button-group%5B1%5D=2&button-group%5B2%5D=3&_target=button-group',
        }));
  });

  testWidgets('phx click on the child and the parent', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Row>
            <Form>
              <SegmentedButton phx-click="parent_event" name="button-group" emptySelectionAllowed="true">
                <ButtonSegment phx-click="child_event" name="1" label="first option" icon="home" />
                <ButtonSegment name="2" label="second option" icon="home" />
                <ButtonSegment name="3" label="third option" icon="home" />
              </SegmentedButton>
            </Form>
          </Row>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text("first option"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("first option"));
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({}, eventName: 'child_event'),
      liveEvents.phxClick({}, eventName: 'parent_event'),
      liveEvents.phxClick({}, eventName: 'child_event'),
      liveEvents.phxClick({}, eventName: 'parent_event'),
    ]);
  });
}
