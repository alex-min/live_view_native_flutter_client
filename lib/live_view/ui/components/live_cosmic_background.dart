import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

enum _BlobAnimation { circle, vertical, horizontal }

class _BlobConfig {
  final Color color;
  final double sizeVh;
  final double left;
  final double top;
  final Offset originOffsetFraction;
  final _BlobAnimation animation;
  final int durationSeconds;
  final bool reverse;

  const _BlobConfig({
    required this.color,
    required this.sizeVh,
    required this.left,
    required this.top,
    this.originOffsetFraction = Offset.zero,
    required this.animation,
    required this.durationSeconds,
    this.reverse = false,
  });
}

/// Paints a single blurred radial-gradient blob using [BlendMode.screen]
/// so overlapping blobs glow rather than darken, matching the web auth pages.
class _BlobPainter extends CustomPainter {
  final Color color;

  const _BlobPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
        stops: const [0.0, 0.6],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.color != color;
}

/// Replicates the animated cosmic background from the web auth pages.
///
/// The web version layers several large, semi-transparent radial gradients,
/// applies a screen blend mode in dark mode, blurs them, and animates them
/// slowly. This widget mirrors that effect using Flutter primitives.
class LiveCosmicBackground extends LiveStateWidget<LiveCosmicBackground> {
  const LiveCosmicBackground({super.key, required super.state});

  @override
  State<LiveCosmicBackground> createState() => LiveCosmicBackgroundState();
}

class LiveCosmicBackgroundState extends StateWidget<LiveCosmicBackground>
    with TickerProviderStateMixin {
  // Dark mode blob positions / colours from startup_kit/assets/css/cosmic.css
  static const List<_BlobConfig> _darkBlobs = [
    _BlobConfig(
      color: Color(0xB35353E5),
      sizeVh: 62,
      left: 0.50,
      top: 0.70,
      animation: _BlobAnimation.vertical,
      durationSeconds: 26,
    ),
    _BlobConfig(
      color: Color(0x996E63EE),
      sizeVh: 62,
      left: 0.50,
      top: 0.70,
      originOffsetFraction: Offset(-0.45, 0),
      animation: _BlobAnimation.circle,
      durationSeconds: 20,
      reverse: true,
    ),
    _BlobConfig(
      color: Color(0x8C5353E5),
      sizeVh: 62,
      left: 0.38,
      top: 0.76,
      originOffsetFraction: Offset(0.45, 0),
      animation: _BlobAnimation.circle,
      durationSeconds: 34,
    ),
    _BlobConfig(
      color: Color(0x61ED7EDC),
      sizeVh: 62,
      left: 0.50,
      top: 0.70,
      originOffsetFraction: Offset(-0.25, 0),
      animation: _BlobAnimation.horizontal,
      durationSeconds: 30,
    ),
    _BlobConfig(
      color: Color(0x8C5A5AEB),
      sizeVh: 92,
      left: 0.62,
      top: 0.80,
      originOffsetFraction: Offset(-0.55, 0.20),
      animation: _BlobAnimation.circle,
      durationSeconds: 18,
    ),
  ];

  late final List<AnimationController> _controllers;

  List<AnimationController> get controllers => _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _darkBlobs.map((blob) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: blob.durationSeconds),
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationState();
  }

  void _updateAnimationState() {
    var reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true ||
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations ||
        widget.state.liveView.disableAnimations;

    for (var controller in _controllers) {
      if (reduceMotion) {
        controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['baseColor', 'blur']);
  }

  @override
  Widget render(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var baseColor = getColor(context, getAttribute('baseColor')) ??
        const Color(0xFF2B314C);
    var blur = double.tryParse(getAttribute('blur') ?? '') ?? 26;

    return Container(
      width: size.width,
      height: size.height,
      color: baseColor,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Stack(
          children: [
            for (var i = 0; i < _darkBlobs.length; i++)
              _buildBlob(context, _darkBlobs[i], size, _controllers[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(
      BuildContext context, _BlobConfig blob, Size screen, AnimationController controller) {
    var size = screen.height * (blob.sizeVh / 100);
    var left = screen.width * blob.left - size / 2;
    var top = screen.height * blob.top - size / 2;

    Widget child = CustomPaint(
      size: Size(size, size),
      painter: _BlobPainter(blob.color),
    );

    switch (blob.animation) {
      case _BlobAnimation.circle:
        child = AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var angle = blob.reverse
                ? -controller.value * 2 * pi
                : controller.value * 2 * pi;
            var originX = size / 2 + size * blob.originOffsetFraction.dx;
            var originY = size / 2 + size * blob.originOffsetFraction.dy;
            return Transform(
              transform: Matrix4.identity()
                ..translate(originX, originY)
                ..rotateZ(angle)
                ..translate(-originX, -originY),
              child: child,
            );
          },
          child: child,
        );
      case _BlobAnimation.vertical:
        child = AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var t = sin(controller.value * 2 * pi);
            return Transform.translate(
              offset: Offset(0, size * 0.26 * t),
              child: child,
            );
          },
          child: child,
        );
      case _BlobAnimation.horizontal:
        child = AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var t = sin(controller.value * 2 * pi);
            return Transform.translate(
              offset: Offset(size * 0.38 * t, size * 0.08 * t),
              child: child,
            );
          },
          child: child,
        );
    }

    return Positioned(left: left, top: top, child: child);
  }
}
