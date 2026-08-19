import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A server-driven list that requests another page when scrolling near its end.
///
/// Set `phx-load-more` to the LiveView event, `hasMore` to whether another page
/// exists, and change `loadKey` whenever the server finishes loading a page.
class LiveInfiniteList extends LiveStateWidget<LiveInfiniteList> {
  const LiveInfiniteList({super.key, required super.state});

  @override
  State<LiveInfiniteList> createState() => _LiveInfiniteListState();
}

class _LiveInfiniteListState extends StateWidget<LiveInfiniteList> {
  static const _defaultLoadMoreThreshold = 200.0;

  final ScrollController _scrollController = ScrollController();
  bool _requestInFlight = false;
  String? _loadKey;

  final attributes = [
    'phx-load-more',
    'hasMore',
    'loadKey',
    'loadMoreThreshold',
    'scrollDirection',
    'reverse',
    'padding',
    'itemExtent',
    'addAutomaticKeepAlives',
    'addRepaintBoundaries',
    'addSemanticIndexes',
    'cacheExtent',
    'semanticChildCount',
    'dragStartBehavior',
    'keyboardDismissBehavior',
    'restorationId',
  ];

  @override
  void initState() {
    _scrollController.addListener(_requestNextPageIfNeeded);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNextPageIfNeeded();
    });
  }

  @override
  void onStateChange(Map<dynamic, dynamic> diff) {
    final previousLoadKey = _loadKey;
    reloadAttributes(node, attributes);
    _loadKey = getAttribute('loadKey');

    if (previousLoadKey != null && previousLoadKey != _loadKey) {
      _requestInFlight = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestNextPageIfNeeded();
      });
    }
  }

  void _requestNextPageIfNeeded() {
    if (!mounted ||
        _requestInFlight ||
        getAttribute('phx-load-more') == null ||
        !(booleanAttribute('hasMore') ?? true) ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final threshold =
        doubleAttribute('loadMoreThreshold') ?? _defaultLoadMoreThreshold;

    if (position.extentAfter > threshold) {
      return;
    }

    _requestInFlight = true;
    liveView.sendEvent(
      ExecLiveEvent(
        type: 'phx-click',
        name: getAttribute('phx-load-more')!,
        value: getPhxValues(computedAttributes.attributes),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_requestNextPageIfNeeded)
      ..dispose();
    super.dispose();
  }

  @override
  Widget render(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: axisAttribute('scrollDirection') ?? Axis.vertical,
      reverse: booleanAttribute('reverse') ?? false,
      primary: false,
      padding: marginOrPaddingAttribute('padding'),
      itemExtent: doubleAttribute('itemExtent'),
      addAutomaticKeepAlives:
          booleanAttribute('addAutomaticKeepAlives') ?? true,
      addRepaintBoundaries: booleanAttribute('addRepaintBoundaries') ?? true,
      addSemanticIndexes: booleanAttribute('addSemanticIndexes') ?? true,
      cacheExtent: doubleAttribute('cacheExtent'),
      semanticChildCount: intAttribute('semanticChildCount'),
      dragStartBehavior:
          dragStartBehaviorAttribute('dragStartBehavior') ??
          DragStartBehavior.start,
      keyboardDismissBehavior:
          scrollViewKeyboardDismissBehaviorAttribute(
            'keyboardDismissBehavior',
          ) ??
          ScrollViewKeyboardDismissBehavior.manual,
      restorationId: getAttribute('restorationId'),
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.hardEdge,
      children: multipleChildren(
        state: widget.state.copyWith(variables: currentVariables),
      ),
    );
  }
}
