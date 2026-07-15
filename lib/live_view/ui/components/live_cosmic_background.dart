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
  final Curve curve;

  const _BlobConfig({
    required this.color,
    required this.sizeVh,
    required this.left,
    required this.top,
    this.originOffsetFraction = Offset.zero,
    required this.animation,
    required this.durationSeconds,
    this.reverse = false,
    this.curve = Curves.linear,
  });
}

/// Paints the cosmic blob layer. The blobs are drawn with [BlendMode.screen]
/// so overlapping gradients glow rather than darken, matching the web auth pages.
class _CosmicBlobsPainter extends CustomPainter {
  final List<_BlobConfig> blobs;
  final Size screen;
  final List<AnimationController> controllers;

  _CosmicBlobsPainter(this.blobs, this.screen, this.controllers)
      : super(repaint: Listenable.merge(controllers));

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < blobs.length; i++) {
      _paintBlob(canvas, blobs[i], controllers[i]);
    }
  }

  void _paintBlob(Canvas canvas, _BlobConfig blob, AnimationController controller) {
    var value = blob.curve.transform(controller.value);
    var blobSize = screen.height * (blob.sizeVh / 100);
    var left = screen.width * blob.left - blobSize / 2;
    var top = screen.height * blob.top - blobSize / 2;

    Offset translation = Offset.zero;
    double rotation = 0;
    var originX = blobSize / 2 + blobSize * blob.originOffsetFraction.dx;
    var originY = blobSize / 2 + blobSize * blob.originOffsetFraction.dy;

    switch (blob.animation) {
      case _BlobAnimation.circle:
        rotation = blob.reverse ? -value * 2 * pi : value * 2 * pi;
      case _BlobAnimation.vertical:
        translation = Offset(0, blobSize * 0.60 * sin(value * 2 * pi));
      case _BlobAnimation.horizontal:
        translation = Offset(
          blobSize * 0.75 * sin(value * 2 * pi),
          blobSize * 0.25 * sin(value * 2 * pi),
        );
    }

    canvas.save();
    canvas.translate(left + translation.dx, top + translation.dy);
    if (rotation != 0) {
      canvas.translate(originX, originY);
      canvas.rotate(rotation);
      canvas.translate(-originX, -originY);
    }

    var paint = Paint()
      ..shader = RadialGradient(
        colors: [blob.color, blob.color.withAlpha(0)],
        stops: const [0.0, 0.6],
      ).createShader(Rect.fromLTWH(0, 0, blobSize, blobSize))
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Rect.fromLTWH(0, 0, blobSize, blobSize), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CosmicBlobsPainter old) => true;
}

/// Replicates the animated cosmic background from the web auth pages.
///
/// The web version layers several large, semi-transparent radial gradients,
/// applies a screen blend mode in dark mode, blurs them, and animates them
/// slowly. This widget mirrors that effect using a single painter that
/// repaints every frame so the blur layer updates correctly.
class LiveCosmicBackground extends LiveStateWidget<LiveCosmicBackground> {
  const LiveCosmicBackground({super.key, required super.state});

  @override
  State<LiveCosmicBackground> createState() => LiveCosmicBackgroundState();
}

class LiveCosmicBackgroundState extends StateWidget<LiveCosmicBackground> {
  // Blob layout mirroring the web auth background. The positions follow the
  // light-mode CSS spread (the reference screenshot shows blobs scattered
  // across the screen) while the colours and blend mode use the dark-mode
  // palette. Durations and amplitudes are tuned so the motion is clearly
  // visible even through the heavy blur.
  static const List<_BlobConfig> _darkBlobs = [
    _BlobConfig(
      color: Color(0xB35353E5),
      sizeVh: 62,
      left: 0.78,
      top: 0.24,
      animation: _BlobAnimation.vertical,
      durationSeconds: 10,
      curve: Curves.easeInOut,
    ),
    _BlobConfig(
      color: Color(0x996E63EE),
      sizeVh: 62,
      left: 0.13,
      top: 0.36,
      originOffsetFraction: Offset(-0.65, 0),
      animation: _BlobAnimation.circle,
      durationSeconds: 8,
      reverse: true,
      curve: Curves.easeInOut,
    ),
    _BlobConfig(
      color: Color(0x8C5353E5),
      sizeVh: 62,
      left: 0.27,
      top: 0.78,
      originOffsetFraction: Offset(0.65, 0),
      animation: _BlobAnimation.circle,
      durationSeconds: 13,
      curve: Curves.linear,
    ),
    _BlobConfig(
      color: Color(0x61ED7EDC),
      sizeVh: 62,
      left: 0.73,
      top: 0.82,
      originOffsetFraction: Offset(-0.37, 0),
      animation: _BlobAnimation.horizontal,
      durationSeconds: 11,
      curve: Curves.easeInOut,
    ),
    _BlobConfig(
      color: Color(0x8C5A5AEB),
      sizeVh: 92,
      left: 0.18,
      top: 0.18,
      originOffsetFraction: Offset(-1.20, 0.37),
      animation: _BlobAnimation.circle,
      durationSeconds: 7,
      curve: Curves.easeInOut,
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

    // Ensure tickers run even if an ancestor disabled them; reduced-motion
    // checks are still handled by _updateAnimationState.
    return TickerMode(
      enabled: true,
      child: Container(
        width: size.width,
        height: size.height,
        color: baseColor,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            size: size,
            painter: _CosmicBlobsPainter(_darkBlobs, size, _controllers),
          ),
        ),
      ),
    );
  }
}
