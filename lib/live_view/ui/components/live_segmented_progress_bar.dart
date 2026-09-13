import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A horizontal progress bar split into proportional colored segments,
/// used for allocation overviews (e.g. net worth split across account
/// kinds).
///
/// ```xml
/// <SegmentedProgressBar
///   height="7"
///   trackColor="#26FFFFFF"
///   borderRadius="8"
///   segments="#75cda1:66.8;#88aada:33.2"
/// />
/// ```
///
/// `segments` is a `;`-separated list of `<color>:<percentage>` pairs.
/// Percentages are proportional weights; they don't need to add up to 100.
/// The track clips its segments, rounding the outer ends automatically.
class LiveSegmentedProgressBar
    extends LiveStateWidget<LiveSegmentedProgressBar> {
  const LiveSegmentedProgressBar({super.key, required super.state});

  @override
  State<LiveSegmentedProgressBar> createState() =>
      _LiveSegmentedProgressBarState();
}

class _LiveSegmentedProgressBarState
    extends StateWidget<LiveSegmentedProgressBar> {
  final attributes = ['height', 'trackColor', 'borderRadius', 'segments'];

  @override
  void onStateChange(Map<dynamic, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    final height = doubleAttribute('height') ?? 7;
    final radius = BorderRadius.circular(doubleAttribute('borderRadius') ?? 8);
    final trackColor =
        colorAttribute(context, 'trackColor') ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final segments = _parseSegments(context, getAttribute('segments') ?? '');

    return Container(
      height: height,
      decoration: BoxDecoration(color: trackColor, borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final segment in segments)
            Expanded(
              flex: segment.flex,
              child: ColoredBox(color: segment.color),
            ),
        ],
      ),
    );
  }

  List<({Color color, int flex})> _parseSegments(
    BuildContext context,
    String value,
  ) {
    final segments = <({Color color, int flex})>[];
    for (final pair in value.split(';')) {
      final parts = pair.trim().split(':');
      if (parts.length != 2) continue;
      final color = getColor(context, parts[0].trim());
      final percentage = double.tryParse(parts[1].trim());
      if (color == null || percentage == null || percentage <= 0) continue;
      segments.add((
        color: color,
        flex: (percentage * 10).round().clamp(1, 1 << 20),
      ));
    }
    return segments;
  }
}
