import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';

/// A server-driven list that can either append pages or virtualize a large,
/// fixed-height data set.
///
/// Set `phx-load-more` to the LiveView event, `hasMore` to whether another page
/// exists, and change `loadKey` whenever the server finishes loading a page.
///
/// For a virtual list, set `phx-load-page`, `totalCount`, `pageSize`,
/// `loadedStart`, `loadedCount`, and `itemExtent`. Only the loaded range is
/// rendered inside a fixed full-data-set extent, so the scrollbar is accurate
/// and jumping to any position requests that page directly.
class LiveInfiniteList extends LiveStateWidget<LiveInfiniteList> {
  const LiveInfiniteList({super.key, required super.state});

  @override
  State<LiveInfiniteList> createState() => _LiveInfiniteListState();
}

/// Shares a collapsible list's live scroll position with its pinned header.
class InfiniteListScrollScope extends InheritedNotifier<ScrollController> {
  final double collapseExtent;
  final double itemExtent;

  const InfiniteListScrollScope({
    super.key,
    required ScrollController controller,
    required this.collapseExtent,
    required this.itemExtent,
    required super.child,
  }) : super(notifier: controller);

  static InfiniteListScrollScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InfiniteListScrollScope>();

  @override
  bool updateShouldNotify(InfiniteListScrollScope oldWidget) =>
      collapseExtent != oldWidget.collapseExtent ||
      itemExtent != oldWidget.itemExtent ||
      notifier != oldWidget.notifier;
}

class _LiveInfiniteListState extends StateWidget<LiveInfiniteList> {
  static const _defaultLoadMoreThreshold = 200.0;

  final ScrollController _scrollController = ScrollController();
  bool _requestInFlight = false;
  String? _loadKey;
  bool _initialScrollApplied = false;

  final attributes = [
    'phx-load-more',
    'phx-load-page',
    'hasMore',
    'loadKey',
    'loadMoreThreshold',
    'totalCount',
    'pageSize',
    'loadedStart',
    'loadedCount',
    'loadPageThreshold',
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
    'collapsibleHeaderHeight',
    'collapsedHeaderHeight',
    'initialScrollIndex',
    'initialScrollAlignment',
  ];

  @override
  void initState() {
    _scrollController.addListener(_handleScroll);
    super.initState();
    // Listen to the dynamic keys of our direct children so server diffs
    // targeting them (row updates, conditionals appearing) invalidate the
    // parsed children cache and the list re-renders from the new variables.
    listenInnerTextKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_applyInitialScrollPosition()) {
        _restoreScrollOffset();
      }
      _requestNextPageIfNeeded();
    });
  }

  bool _applyInitialScrollPosition() {
    final index = intAttribute('initialScrollIndex');
    if (index == null) {
      return false;
    }
    if (_initialScrollApplied) {
      return true;
    }
    if (!mounted || !isOnCurrentRoute || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialScrollPosition();
      });
      return true;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialScrollPosition();
      });
      return true;
    }

    final itemExtent = doubleAttribute('itemExtent') ?? 0;
    if (itemExtent <= 0) {
      return false;
    }

    final headerHeight = doubleAttribute('collapsibleHeaderHeight') ?? 0;
    final collapsedHeight = doubleAttribute('collapsedHeaderHeight') ?? 0;
    final rowTop = headerHeight + index * itemExtent;
    final alignment = getAttribute('initialScrollAlignment');
    final target = switch (alignment) {
      'end' => rowTop - position.viewportDimension + itemExtent,
      'center' => rowTop - (position.viewportDimension - itemExtent) / 2,
      _ => rowTop - collapsedHeight,
    };

    _initialScrollApplied = true;
    _scrollController.jumpTo(
      target
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
    );
    return true;
  }

  void _handleScroll() {
    final restorationId = getAttribute('restorationId');
    if (restorationId != null && _scrollController.hasClients) {
      liveView.rememberScrollOffset(
        widget.state.urlPath,
        restorationId,
        _scrollController.offset,
      );
    }
    _requestNextPageIfNeeded();
  }

  void _restoreScrollOffset() {
    final restorationId = getAttribute('restorationId');
    if (!mounted ||
        !isOnCurrentRoute ||
        restorationId == null ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollOffset();
      });
      return;
    }

    final offset = liveView.restoredScrollOffset(
      widget.state.urlPath,
      restorationId,
    );
    if (offset == null) {
      return;
    }

    final restoredOffset = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(restoredOffset.toDouble());
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

    // On a LiveView navigation the initial attributes can arrive in the
    // first diff after this widget is mounted. Apply the requested position
    // once those attributes have been reloaded and the slivers have laid out.
    if (!_initialScrollApplied && intAttribute('initialScrollIndex') != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialScrollPosition();
      });
    }
  }

  void _requestNextPageIfNeeded() {
    if (!isOnCurrentRoute) {
      return;
    }

    if (_isVirtual && (intAttribute('totalCount') ?? 0) > 0) {
      _requestVisiblePageIfNeeded();
      return;
    }

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

    final sent = liveView.sendEvent(
      ExecLiveEvent(
        type: 'phx-click',
        name: getAttribute('phx-load-more')!,
        value: getPhxValues(computedAttributes.attributes),
      ),
    );
    _requestInFlight = sent;
  }

  bool get _isVirtual =>
      getAttribute('phx-load-page') != null &&
      intAttribute('totalCount') != null &&
      intAttribute('pageSize') != null &&
      doubleAttribute('itemExtent') != null;

  void _requestVisiblePageIfNeeded() {
    if (!mounted || _requestInFlight || !_scrollController.hasClients) {
      return;
    }

    final event = getAttribute('phx-load-page');
    final totalCount = intAttribute('totalCount') ?? 0;
    final pageSize = intAttribute('pageSize') ?? 0;
    final itemExtent = doubleAttribute('itemExtent') ?? 0;
    if (event == null || totalCount <= 0 || pageSize <= 0 || itemExtent <= 0) {
      return;
    }

    final position = _scrollController.position;
    final headerHeight = doubleAttribute('collapsibleHeaderHeight') ?? 0;
    final collapsedHeight = doubleAttribute('collapsedHeaderHeight') ?? 0;
    final listPixels = (position.pixels - (headerHeight - collapsedHeight))
        .clamp(0, double.infinity);
    final firstVisible = (listPixels / itemExtent).floor().clamp(
      0,
      totalCount - 1,
    );
    final lastVisible =
        ((listPixels + position.viewportDimension - collapsedHeight) /
                itemExtent)
            .ceil()
            .clamp(1, totalCount) -
        1;
    final loadedStart = intAttribute('loadedStart') ?? 0;
    final loadedCount = intAttribute('loadedCount') ?? 0;
    final loadedEnd = loadedStart + loadedCount;
    final threshold = intAttribute('loadPageThreshold') ?? 4;

    int? targetPage;
    if (lastVisible < loadedStart || firstVisible >= loadedEnd) {
      final middleVisible = (firstVisible + lastVisible) ~/ 2;
      targetPage = middleVisible ~/ pageSize;
    } else if (loadedEnd < totalCount && lastVisible + threshold >= loadedEnd) {
      targetPage = loadedEnd ~/ pageSize;
    } else if (loadedStart > 0 && firstVisible - threshold < loadedStart) {
      targetPage = (loadedStart - 1) ~/ pageSize;
    }

    if (targetPage == null) {
      return;
    }

    final sent = liveView.sendEvent(
      ExecLiveEvent(
        type: 'phx-click',
        name: event,
        value: {
          ...getPhxValues(computedAttributes.attributes),
          'offset': targetPage,
        },
      ),
    );
    _requestInFlight = sent;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget render(BuildContext context) {
    final childState = widget.state.copyWith(variables: currentVariables);

    if (_isVirtual) {
      final children = _parsedChildren(childState);
      return _renderVirtualList(children);
    }

    final children = _parsedChildren(childState);

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
      children: children,
    );
  }

  Widget _renderVirtualList(List<Widget> children) {
    final totalCount = intAttribute('totalCount') ?? 0;
    final headerHeight = doubleAttribute('collapsibleHeaderHeight');
    final collapsedHeight = doubleAttribute('collapsedHeaderHeight');
    if (headerHeight != null &&
        collapsedHeight != null &&
        children.isNotEmpty) {
      return _renderCollapsibleVirtualList(
        context,
        children.first,
        children.skip(1).toList(),
        totalCount,
        headerHeight,
        collapsedHeight,
      );
    }
    if (totalCount <= 0) {
      return ListView(
        controller: _scrollController,
        primary: false,
        padding: marginOrPaddingAttribute('padding'),
        children: children,
      );
    }

    final loadedStart = intAttribute('loadedStart') ?? 0;
    final loadedCount = intAttribute('loadedCount') ?? children.length;

    return ListView.builder(
      controller: _scrollController,
      primary: false,
      padding: marginOrPaddingAttribute('padding'),
      itemCount: totalCount,
      itemExtent: doubleAttribute('itemExtent'),
      addAutomaticKeepAlives:
          booleanAttribute('addAutomaticKeepAlives') ?? false,
      addRepaintBoundaries: booleanAttribute('addRepaintBoundaries') ?? true,
      addSemanticIndexes: booleanAttribute('addSemanticIndexes') ?? true,
      cacheExtent: doubleAttribute('cacheExtent'),
      semanticChildCount: intAttribute('semanticChildCount') ?? totalCount,
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
      itemBuilder: (context, index) {
        final loadedIndex = index - loadedStart;
        if (loadedIndex < 0 ||
            loadedIndex >= loadedCount ||
            loadedIndex >= children.length) {
          return const SizedBox.shrink();
        }
        return children[loadedIndex];
      },
    );
  }

  Widget _renderCollapsibleVirtualList(
    BuildContext context,
    Widget header,
    List<Widget> children,
    int totalCount,
    double headerHeight,
    double collapsedHeight,
  ) {
    final loadedStart = intAttribute('loadedStart') ?? 0;
    final loadedCount = intAttribute('loadedCount') ?? children.length;

    return InfiniteListScrollScope(
      controller: _scrollController,
      collapseExtent: headerHeight - collapsedHeight,
      itemExtent: doubleAttribute('itemExtent')!,
      child: CustomScrollView(
        controller: _scrollController,
        primary: false,
        restorationId: getAttribute('restorationId'),
        keyboardDismissBehavior:
            scrollViewKeyboardDismissBehaviorAttribute(
              'keyboardDismissBehavior',
            ) ??
            ScrollViewKeyboardDismissBehavior.manual,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: CollapsibleInfiniteListHeaderDelegate(
              minExtent: collapsedHeight.clamp(0, headerHeight),
              maxExtent: headerHeight,
              child: header,
            ),
          ),
          if (totalCount == 0)
            SliverToBoxAdapter(
              child:
                  children.isEmpty ? const SizedBox.shrink() : children.first,
            )
          else
            SliverFixedExtentList(
              itemExtent: doubleAttribute('itemExtent')!,
              delegate: SliverChildBuilderDelegate((context, index) {
                final loadedIndex = index - loadedStart;
                if (loadedIndex < 0 ||
                    loadedIndex >= loadedCount ||
                    loadedIndex >= children.length) {
                  return const SizedBox.shrink();
                }
                return children[loadedIndex];
              }, childCount: totalCount),
            ),
          if (intAttribute('initialScrollIndex') != null)
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.sizeOf(context).height),
            ),
        ],
      ),
    );
  }

  List<Widget>? _cachedChildren;
  Object? _cachedNode;
  Map<dynamic, dynamic>? _cachedVariables;

  /// Parses the server children once and reuses the widget instances across
  /// rebuilds. Re-parsing on every build gives children new random keys, which
  /// disposes and recreates their state (dismissing open dropdown menus and
  /// losing scroll-dependent state) whenever an ancestor rebuilds, e.g. when a
  /// popup route pushes and the surrounding focus tree updates.
  List<Widget> _parsedChildren(NodeState childState) {
    if (_cachedChildren != null &&
        identical(_cachedNode, widget.state.node) &&
        identical(_cachedVariables, currentVariables)) {
      return _cachedChildren!;
    }
    _cachedNode = widget.state.node;
    _cachedVariables = currentVariables;
    // Merged diffs can carry compact template references (integer statics
    // indexes and `p` template maps) that only make sense expanded.
    final resolvedState = childState.copyWith(
      variables: expandVariables(Map<String, dynamic>.from(currentVariables)),
    );
    _cachedChildren = _flattenDynamicChildren(
      multipleChildren(state: resolvedState),
    );
    return _cachedChildren!;
  }

  List<Widget> _flattenDynamicChildren(List<Widget> children) {
    final flattened = <Widget>[];
    for (final child in children) {
      if (child is LiveDynamicComponent) {
        final dynamicChildren = LiveDynamicComponent.initialContent(
          child.state,
        );
        if (dynamicChildren != null) {
          flattened.addAll(_flattenDynamicChildren(dynamicChildren));
        }
      } else {
        flattened.add(child);
      }
    }
    return flattened;
  }
}

@visibleForTesting
class CollapsibleInfiniteListHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget child;

  const CollapsibleInfiniteListHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ClipRect(
    child: ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: maxExtent,
        maxHeight: maxExtent,
        child: child,
      ),
    ),
  );

  @override
  bool shouldRebuild(CollapsibleInfiniteListHeaderDelegate oldDelegate) =>
      minExtent != oldDelegate.minExtent ||
      maxExtent != oldDelegate.maxExtent ||
      child != oldDelegate.child;
}
