import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveListView extends LiveStateWidget<LiveListView> {
  const LiveListView({super.key, required super.state});

  @override
  State<LiveListView> createState() => _LiveListViewState();
}

class _LiveListViewState extends StateWidget<LiveListView> {
  final attributes = [
    'scrollDirection',
    'reverse',
    'primary',
    'padding',
    'itemExtent',
    'addAutomaticKeepAlives',
    'addRepaintBoundaries',
    'addSemanticIndexes',
    'cacheExtent',
    'semanticChildCount',
    'dragStartBehavior',
    'keyboardDismissBehavior',
    'restorationId'
  ];

  @override
  void onStateChange(Map<dynamic, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return ListView(
        scrollDirection: axisAttribute('scrollDirection') ?? Axis.vertical,
        reverse: booleanAttribute('reverse') ?? false,
        primary: booleanAttribute('primary'),
        padding: marginOrPaddingAttribute('padding'),
        itemExtent: doubleAttribute('itemExtent'),
        addAutomaticKeepAlives:
            booleanAttribute('addAutomaticKeepAlives') ?? true,
        addRepaintBoundaries: booleanAttribute('addRepaintBoundaries') ?? true,
        addSemanticIndexes: booleanAttribute('addSemanticIndexes') ?? true,
        cacheExtent: doubleAttribute('cacheExtent'),
        semanticChildCount: intAttribute('semanticChildCount'),
        dragStartBehavior: dragStartBehaviorAttribute('dragStartBehavior') ??
            DragStartBehavior.start,
        keyboardDismissBehavior: scrollViewKeyboardDismissBehaviorAttribute(
                'keyboardDismissBehavior') ??
            ScrollViewKeyboardDismissBehavior.manual,
        restorationId: getAttribute('restorationId'),
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.hardEdge,
        children: multipleChildren());
  }
}
