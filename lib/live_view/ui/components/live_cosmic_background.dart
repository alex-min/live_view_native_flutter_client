import 'dart:async';
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

/// Paints the cosmic blob layer. In dark mode the blobs use [BlendMode.screen]
/// so overlapping gradients glow; in light mode they use [BlendMode.multiply]
/// to darken the white background, matching the web auth pages.
class _CosmicBlobsPainter extends CustomPainter {
  final List<_BlobConfig> blobs;
  final Size screen;
  final ValueNotifier<double> time;
  final BlendMode blendMode;

  _CosmicBlobsPainter(this.blobs, this.screen, this.time, this.blendMode)
    : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    var elapsed = time.value;
    for (var i = 0; i < blobs.length; i++) {
      _paintBlob(canvas, blobs[i], elapsed);
    }
  }

  void _paintBlob(Canvas canvas, _BlobConfig blob, double elapsed) {
    var progress = (elapsed / blob.durationSeconds) % 1.0;
    var value = blob.curve.transform(progress);
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

    var paint =
        Paint()
          ..shader = RadialGradient(
            colors: [blob.color, blob.color.withAlpha(0)],
            stops: const [0.0, 0.6],
          ).createShader(Rect.fromLTWH(0, 0, blobSize, blobSize))
          ..blendMode = blendMode;
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
  // Blob layout mirroring the web auth background. Positions follow the
  // light-mode CSS spread (blobs scattered across the screen). Colours and
  // blend mode switch between light and dark palettes. Durations and
  // amplitudes are tuned so the motion is clearly visible even through the
  // heavy blur.
  static const List<_BlobConfig> _lightBlobs = [
    _BlobConfig(
      color: Color(0x8C5353E5),
      sizeVh: 62,
      left: 0.78,
      top: 0.24,
      animation: _BlobAnimation.vertical,
      durationSeconds: 10,
      curve: Curves.easeInOut,
    ),
    _BlobConfig(
      color: Color(0x75D94FC3),
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
      color: Color(0x6BEC6FD0),
      sizeVh: 62,
      left: 0.27,
      top: 0.78,
      originOffsetFraction: Offset(0.65, 0),
      animation: _BlobAnimation.circle,
      durationSeconds: 13,
      curve: Curves.linear,
    ),
    _BlobConfig(
      color: Color(0x66D94FC3),
      sizeVh: 62,
      left: 0.73,
      top: 0.82,
      originOffsetFraction: Offset(-0.37, 0),
      animation: _BlobAnimation.horizontal,
      durationSeconds: 11,
      curve: Curves.easeInOut,
    ),
    _BlobConfig(
      color: Color(0x6B635AEB),
      sizeVh: 92,
      left: 0.18,
      top: 0.18,
      originOffsetFraction: Offset(-1.20, 0.37),
      animation: _BlobAnimation.circle,
      durationSeconds: 7,
      curve: Curves.easeInOut,
    ),
  ];

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

  late final ValueNotifier<double> _time;
  Timer? _timer;

  ValueNotifier<double> get time => _time;

  @override
  void initState() {
    super.initState();
    _time = ValueNotifier(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationState();
  }

  void _updateAnimationState() {
    var reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations == true ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations ||
        widget.state.liveView.disableAnimations;

    if (reduceMotion) {
      _stopAnimation();
      return;
    }

    if (_timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _time.value += 0.016;
      });
    }
  }

  void _stopAnimation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAnimation();
    _time.dispose();
    super.dispose();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['baseColor', 'blur']);
  }

  @override
  Widget render(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var baseColor =
        getColor(context, getAttribute('baseColor')) ??
        Theme.of(context).scaffoldBackgroundColor;
    var blur = double.tryParse(getAttribute('blur') ?? '') ?? 26;
    var isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size.width,
      height: size.height,
      color: baseColor,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: CustomPaint(
          size: size,
          painter: _CosmicBlobsPainter(
            isDark ? _darkBlobs : _lightBlobs,
            size,
            _time,
            isDark ? BlendMode.screen : BlendMode.multiply,
          ),
        ),
      ),
    );
  }
}
