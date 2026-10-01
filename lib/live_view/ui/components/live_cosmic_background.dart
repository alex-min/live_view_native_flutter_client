import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A lightweight, static ambient wash matching the web cosmic background.
///
/// The gradients are painted directly without timers, image filters, or blend
/// modes, so displaying the background does not schedule continuous frames.
class LiveCosmicBackground extends LiveStateWidget<LiveCosmicBackground> {
  const LiveCosmicBackground({super.key, required super.state});

  @override
  State<LiveCosmicBackground> createState() => LiveCosmicBackgroundState();
}

class LiveCosmicBackgroundState extends StateWidget<LiveCosmicBackground> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['baseColor']);
  }

  @override
  Widget render(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final baseColor =
        getColor(context, getAttribute('baseColor')) ??
        Theme.of(context).scaffoldBackgroundColor;
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: baseColor,
      child: CustomPaint(
        size: size,
        painter: CosmicAmbientPainter(colors: colors),
      ),
    );
  }
}

@visibleForTesting
class CosmicAmbientPainter extends CustomPainter {
  final ColorScheme colors;

  const CosmicAmbientPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      size,
      center: const Alignment(0.64, -0.76),
      radius: size.longestSide * 0.48,
      color: colors.primary.withValues(alpha: 0.3),
    );
    _paintGlow(
      canvas,
      size,
      center: const Alignment(-0.76, -0.16),
      radius: size.longestSide * 0.42,
      color: colors.secondary.withValues(alpha: 0.2),
    );
    _paintGlow(
      canvas,
      size,
      center: const Alignment(0.16, 0.5),
      radius: size.longestSide * 0.44,
      color: colors.tertiary.withValues(alpha: 0.16),
    );
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Alignment center,
    required double radius,
    required Color color,
  }) {
    final offset = center.alongSize(size);
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: offset, radius: radius));
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CosmicAmbientPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
