import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A lightweight account-balance history chart driven by server attributes.
class LiveBalanceChart extends LiveStateWidget<LiveBalanceChart> {
  const LiveBalanceChart({super.key, required super.state});

  @override
  State<LiveBalanceChart> createState() => _LiveBalanceChartState();
}

class _LiveBalanceChartState extends StateWidget<LiveBalanceChart> {
  final attributes = ['points', 'directions', 'height', 'lineColor'];

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
    final lineColor =
        getColor(context, getAttribute('lineColor')) ?? const Color(0xFF8D63FF);

    return SizedBox(
      height: getDouble(getAttribute('height')) ?? 160,
      width: double.infinity,
      child: CustomPaint(
        painter: BalanceHistoryPainter(
          points: points,
          directions: directions,
          lineColor: lineColor,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

@visibleForTesting
class BalanceHistoryPainter extends CustomPainter {
  final List<double> points;
  final List<String> directions;
  final Color lineColor;
  final Color gridColor;

  const BalanceHistoryPainter({
    required this.points,
    required this.directions,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.isEmpty) return;

    const horizontalPadding = 8.0;
    const verticalPadding = 12.0;
    final width = math.max(0, size.width - horizontalPadding * 2);
    final height = math.max(0, size.height - verticalPadding * 2);
    final minimum = points.reduce(math.min);
    final maximum = points.reduce(math.max);
    final range = math.max(maximum - minimum, 1.0);

    final gridPaint =
        Paint()
          ..color = gridColor.withValues(alpha: 0.55)
          ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = verticalPadding + height * row / 2;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    Offset offsetFor(int index) {
      final x =
          points.length == 1
              ? size.width / 2
              : horizontalPadding + width * index / (points.length - 1);
      final normalized = (points[index] - minimum) / range;
      return Offset(x, verticalPadding + height * (1 - normalized));
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
          ..lineTo(
            offsetFor(points.length - 1).dx,
            size.height - verticalPadding,
          )
          ..lineTo(offsetFor(0).dx, size.height - verticalPadding)
          ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.02),
          ],
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

    for (var index = 0; index < points.length; index++) {
      final direction = index < directions.length ? directions[index] : '';
      final color = switch (direction) {
        'income' => const Color(0xFF25A36B),
        'expense' => const Color(0xFFE55276),
        _ => lineColor,
      };
      final point = offsetFor(index);
      canvas.drawCircle(point, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(BalanceHistoryPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.directions != directions ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
