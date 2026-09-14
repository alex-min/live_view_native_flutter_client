import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A lightweight account-balance history chart driven by server attributes.
class LiveBalanceChart extends LiveStateWidget<LiveBalanceChart> {
  const LiveBalanceChart({super.key, required super.state});

  @override
  State<LiveBalanceChart> createState() => _LiveBalanceChartState();
}

class _LiveBalanceChartState extends StateWidget<LiveBalanceChart> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _searchExpanded = false;

  @override
  void initState() {
    _searchFocusNode.addListener(_handleSearchFocus);
    super.initState();
  }

  final attributes = [
    'points',
    'directions',
    'pointlabels',
    'pointOffset',
    'windowSize',
    'edgeMargin',
    'height',
    'collapsedHeight',
    'lineColor',
    'compacttitle',
    'searchlabel',
    'searchvalue',
    'searchevent',
  ];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocus)
      ..dispose();
    super.dispose();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    final points =
        (getAttribute('points') ?? '')
            .split(',')
            .map(double.tryParse)
            .whereType<double>()
            .toList();
    final directions = (getAttribute('directions') ?? '').split(',');
    final encodedLabels = getAttribute('pointlabels') ?? '';
    final labels =
        encodedLabels.isEmpty
            ? <String>[]
            : utf8
                .decode(base64Url.decode(base64Url.normalize(encodedLabels)))
                .split('|');
    final lineColor =
        getColor(context, getAttribute('lineColor')) ?? const Color(0xFF8D63FF);
    final scope = InfiniteListScrollScope.maybeOf(context);
    final scrollOffset =
        scope?.notifier?.hasClients == true ? scope!.notifier!.offset : 0.0;
    final collapseProgress =
        scope == null || scope.collapseExtent <= 0
            ? 0.0
            : (scrollOffset / scope.collapseExtent).clamp(0.0, 1.0);
    final expandedHeight = getDouble(getAttribute('height')) ?? 160;
    final collapsedHeight =
        getDouble(getAttribute('collapsedHeight')) ?? expandedHeight;
    final height =
        expandedHeight + (collapsedHeight - expandedHeight) * collapseProgress;
    final visibleTransaction =
        scope == null
            ? 0
            : ((scrollOffset - scope.collapseExtent).clamp(0, double.infinity) /
                    scope.itemExtent)
                .floor();
    final pointOffset = getInt(getAttribute('pointOffset')) ?? 0;
    final selectedIndexForWindow =
        (points.length - 1 - (visibleTransaction - pointOffset))
            .clamp(0, math.max(points.length - 1, 0))
            .toInt();
    final requestedWindowSize = getInt(getAttribute('windowSize')) ?? 80;
    final windowSize = math.max(2, requestedWindowSize);
    final requestedMargin = getInt(getAttribute('edgeMargin')) ?? 12;
    final edgeMargin = requestedMargin.clamp(0, windowSize ~/ 2).toInt();
    final windowStart =
        points.length <= windowSize
            ? 0
            : (selectedIndexForWindow - edgeMargin)
                .clamp(0, points.length - windowSize)
                .toInt();
    final windowEnd = math.min(points.length, windowStart + windowSize);
    final visiblePoints = points.sublist(windowStart, windowEnd);
    final visibleDirections = List.generate(visiblePoints.length, (index) {
      final sourceIndex = windowStart + index;
      return sourceIndex < directions.length ? directions[sourceIndex] : '';
    });
    final visibleLabels = List.generate(visiblePoints.length, (index) {
      final sourceIndex = windowStart + index;
      return sourceIndex < labels.length ? labels[sourceIndex] : '';
    });
    final selectedIndex = selectedIndexForWindow - windowStart;
    final frame = BalanceChartFrame(
      points: visiblePoints,
      directions: visibleDirections,
      labels: visibleLabels,
      selectedIndex: selectedIndex,
      windowStart: windowStart,
    );
    final compactOpacity = ((collapseProgress - 0.55) / 0.45).clamp(0.0, 1.0);
    final compactTitle = _decodeAttribute('compacttitle');
    final searchLabel = _decodeAttribute('searchlabel');
    final searchValue = _decodeAttribute('searchvalue');
    final showSearch = _searchExpanded || searchValue.isNotEmpty;
    if (!_searchController.selection.isValid &&
        _searchController.text != searchValue) {
      _searchController.text = searchValue;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<BalanceChartFrame>(
        tween: BalanceChartFrameTween(end: frame),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, animatedFrame, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: BalanceHistoryPainter(
                  points: animatedFrame.points,
                  directions: animatedFrame.directions,
                  labels: animatedFrame.labels,
                  selectedIndex: animatedFrame.selectedIndex,
                  windowStart: animatedFrame.windowStart,
                  scaleMinimum: animatedFrame.minimum,
                  scaleMaximum: animatedFrame.maximum,
                  lineColor: lineColor,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  tooltipColor: Theme.of(context).colorScheme.inverseSurface,
                  tooltipTextColor:
                      Theme.of(context).colorScheme.onInverseSurface,
                  topInset: 12 + 52 * compactOpacity,
                ),
              ),
              if (compactTitle.isNotEmpty || searchLabel.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    ignoring: false,
                    child: Opacity(
                      opacity: 1,
                      child: SizedBox(
                        key: const ValueKey('balance_chart_compact_header'),
                        height: 48,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final expandedSearchWidth = math.min(
                              220.0,
                              math.max(150.0, constraints.maxWidth * 0.62),
                            );
                            return Row(
                              children: [
                                AnimatedContainer(
                                  key: const ValueKey(
                                    'balance_chart_search_control',
                                  ),
                                  width: showSearch ? expandedSearchWidth : 38,
                                  height: 38,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child:
                                        showSearch
                                            ? TextField(
                                              key: const ValueKey(
                                                'balance_chart_search_field',
                                              ),
                                              controller: _searchController,
                                              focusNode: _searchFocusNode,
                                              onChanged: _sendSearch,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: searchLabel,
                                                prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                ),
                                                prefixIconConstraints:
                                                    const BoxConstraints(
                                                      minWidth: 38,
                                                    ),
                                                suffixIcon: IconButton(
                                                  key: const ValueKey(
                                                    'balance_chart_search_close',
                                                  ),
                                                  tooltip: searchLabel,
                                                  onPressed: _closeSearch,
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 17,
                                                  ),
                                                ),
                                                suffixIconConstraints:
                                                    const BoxConstraints(
                                                      minWidth: 38,
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                border: InputBorder.none,
                                              ),
                                            )
                                            : IconButton(
                                              key: const ValueKey(
                                                'balance_chart_search_button',
                                              ),
                                              tooltip: searchLabel,
                                              onPressed: _openSearch,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                    width: 38,
                                                    height: 38,
                                                  ),
                                              icon: const Icon(
                                                Icons.search_rounded,
                                                size: 19,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Opacity(
                                    opacity: compactOpacity,
                                    child: Text(
                                      compactTitle,
                                      maxLines: 2,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                        fontSize: 13,
                                        height: 1.05,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _decodeAttribute(String name) {
    final value = getAttribute(name) ?? '';
    if (value.isEmpty) return '';
    return utf8.decode(base64Url.decode(base64Url.normalize(value)));
  }

  void _sendSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final event = getAttribute('searchevent');
      if (event == null || event.isEmpty) return;
      liveView.sendEvent(
        ExecLiveEvent(
          type: 'form',
          name: event,
          value: Uri(queryParameters: {'search': value}).query,
        ),
      );
    });
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _sendSearch('');
    }
    _searchFocusNode.unfocus();
    setState(() => _searchExpanded = false);
  }

  void _handleSearchFocus() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() => _searchExpanded = false);
    }
  }
}

@visibleForTesting
class BalanceChartFrame {
  final List<double> points;
  final List<String> directions;
  final List<String> labels;
  final int selectedIndex;
  final int windowStart;
  final double minimum;
  final double maximum;

  BalanceChartFrame({
    required this.points,
    required this.directions,
    this.labels = const [],
    required this.selectedIndex,
    required this.windowStart,
    double? minimum,
    double? maximum,
  }) : minimum = minimum ?? (points.isEmpty ? 0 : points.reduce(math.min)),
       maximum = maximum ?? (points.isEmpty ? 1 : points.reduce(math.max));
}

@visibleForTesting
class BalanceChartFrameTween extends Tween<BalanceChartFrame> {
  BalanceChartFrameTween({super.begin, required super.end});

  @override
  BalanceChartFrame lerp(double t) {
    final target = end!;
    final source = begin ?? target;
    final count = math.max(source.points.length, target.points.length);
    final points = List.generate(count, (index) {
      final position = count <= 1 ? 0.0 : index / (count - 1);
      return _sample(source.points, position) +
          (_sample(target.points, position) -
                  _sample(source.points, position)) *
              t;
    });

    return BalanceChartFrame(
      points: points,
      directions: target.directions,
      labels: target.labels,
      selectedIndex: target.selectedIndex,
      windowStart: target.windowStart,
      minimum: source.minimum + (target.minimum - source.minimum) * t,
      maximum: source.maximum + (target.maximum - source.maximum) * t,
    );
  }

  double _sample(List<double> values, double position) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    final scaled = position * (values.length - 1);
    final lower = scaled.floor();
    final upper = math.min(lower + 1, values.length - 1);
    final fraction = scaled - lower;
    return values[lower] + (values[upper] - values[lower]) * fraction;
  }
}

@visibleForTesting
class BalanceHistoryPainter extends CustomPainter {
  final List<double> points;
  final List<String> directions;
  final List<String> labels;
  final int selectedIndex;
  final int windowStart;
  final double? scaleMinimum;
  final double? scaleMaximum;
  final Color lineColor;
  final Color backgroundColor;
  final Color tooltipColor;
  final Color tooltipTextColor;
  final double topInset;

  const BalanceHistoryPainter({
    required this.points,
    required this.directions,
    this.labels = const [],
    this.selectedIndex = -1,
    this.windowStart = 0,
    this.scaleMinimum,
    this.scaleMaximum,
    required this.lineColor,
    this.backgroundColor = Colors.transparent,
    this.tooltipColor = const Color(0xFF24212F),
    this.tooltipTextColor = Colors.white,
    this.topInset = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.isEmpty) return;

    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    const horizontalPadding = 8.0;
    final topPadding = math.min(topInset, size.height - 10);
    const bottomPadding = 10.0;
    final width = math.max(0, size.width - horizontalPadding * 2);
    final height = math.max(0, size.height - topPadding - bottomPadding);
    final minimum = scaleMinimum ?? points.reduce(math.min);
    final maximum = scaleMaximum ?? points.reduce(math.max);
    final range = math.max(maximum - minimum, 1.0);

    Offset offsetFor(int index) {
      final x =
          points.length == 1
              ? size.width / 2
              : horizontalPadding + width * index / (points.length - 1);
      final normalized = (points[index] - minimum) / range;
      return Offset(x, topPadding + height * (1 - normalized));
    }

    final line = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var index = 1; index < points.length; index++) {
      final previous = offsetFor(index - 1);
      final current = offsetFor(index);
      final midpoint = (previous.dx + current.dx) / 2;
      line.cubicTo(
        midpoint,
        previous.dy,
        midpoint,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fill =
        Path.from(line)
          ..lineTo(offsetFor(points.length - 1).dx, size.height - bottomPadding)
          ..lineTo(offsetFor(0).dx, size.height - bottomPadding)
          ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.52),
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0.02),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final direction =
          selectedIndex < directions.length ? directions[selectedIndex] : '';
      final color = switch (direction) {
        'income' => const Color(0xFF25A36B),
        'expense' => const Color(0xFFE55276),
        _ => lineColor,
      };
      final point = offsetFor(selectedIndex);
      canvas.drawCircle(point, 7.5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, Paint()..color = color);

      final label = selectedIndex < labels.length ? labels[selectedIndex] : '';
      if (label.isNotEmpty) {
        _paintTooltip(canvas, size, point, label);
      }
    }
  }

  void _paintTooltip(Canvas canvas, Size size, Offset point, String label) {
    final lines = label.split('\n');
    final amount = TextPainter(
      text: TextSpan(
        text: lines.first,
        style: TextStyle(
          color: tooltipTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: math.max(0, size.width - 28));
    final date = TextPainter(
      text: TextSpan(
        text: lines.skip(1).join(' '),
        style: TextStyle(
          color: tooltipTextColor.withValues(alpha: 0.78),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: math.max(0, size.width - 28));
    final width = math.min(
      size.width - 8,
      math.max(amount.width, date.width) + 16,
    );
    final height = date.text!.toPlainText().isEmpty ? 28.0 : 40.0;
    final rect = positionBalanceTooltip(
      size: size,
      point: point,
      width: width,
      height: height,
      topInset: topInset,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = tooltipColor.withValues(alpha: 0.96),
    );
    amount.paint(
      canvas,
      Offset(rect.left + (width - amount.width) / 2, rect.top + 5),
    );
    if (date.text!.toPlainText().isNotEmpty) {
      date.paint(
        canvas,
        Offset(rect.left + (width - date.width) / 2, rect.top + 22),
      );
    }
  }

  @override
  bool shouldRepaint(BalanceHistoryPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.directions != directions ||
      oldDelegate.labels != labels ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.windowStart != windowStart ||
      oldDelegate.scaleMinimum != scaleMinimum ||
      oldDelegate.scaleMaximum != scaleMaximum ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.tooltipColor != tooltipColor ||
      oldDelegate.tooltipTextColor != tooltipTextColor ||
      oldDelegate.topInset != topInset;
}

@visibleForTesting
Rect positionBalanceTooltip({
  required Size size,
  required Offset point,
  required double width,
  required double height,
  required double topInset,
}) {
  const edgePadding = 4.0;
  const pointGap = 12.0;
  final left = (point.dx - width / 2).clamp(
    edgePadding,
    size.width - width - edgePadding,
  );
  final minimumTop = math.min(topInset + edgePadding, size.height - height);
  final maximumTop = math.max(minimumTop, size.height - height - edgePadding);
  final above = point.dy - height - pointGap;
  final below = point.dy + pointGap;
  final top =
      above >= minimumTop
          ? above
          : below.clamp(minimumTop, maximumTop).toDouble();
  return Rect.fromLTWH(left.toDouble(), top, width, height);
}
