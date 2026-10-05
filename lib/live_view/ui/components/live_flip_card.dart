import 'dart:math';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A card with two faces that flips around the vertical axis.
///
/// The first child is the front face, the second the back face. Tapping the
/// card (anywhere except on nested interactive controls, which win the
/// gesture arena) rotates the card 180° around its Y axis with a perspective
/// tween and fires the `onFlip` exec so the server can mirror the state.
/// When the server changes the `flipped` attribute (mount, patch, reconnect)
/// the card animates to match without firing the exec again.
///
/// While pressed, the card tilts in 3D to follow the pointer (like a
/// collectible card tilted into the light); a small drag is still a tap, a
/// larger one only tilts. A subtle holographic foil overlays the card.
///
/// Server usage:
/// ```xml
/// <FlipCard flipped="false" onFlip='[["phx-click", {"name": "flip"}]]'>
///   <Container><Text>term</Text></Container>
///   <Container><Text>definition</Text></Container>
/// </FlipCard>
/// ```
class LiveFlipCard extends LiveStateWidget<LiveFlipCard> {
  const LiveFlipCard({super.key, required super.state});

  /// Test hook: how many pan updates the card received.
  static int debugPanCount = 0;

  @override
  State<LiveFlipCard> createState() => _LiveFlipCardState();
}

class _LiveFlipCardState extends StateWidget<LiveFlipCard> {
  static const Duration flipDuration = Duration(milliseconds: 380);
  static const Duration tiltSettleDuration = Duration(milliseconds: 320);
  static const double _perspective = 0.0016;

  /// Maximum tilt in radians (~11.5°): the card tips into the light, it
  /// never rotates far enough to hurt readability.
  static const double _maxTilt = 0.20;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: flipDuration,
  );
  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: tiltSettleDuration,
  );
  Animation<Offset>? _tiltTween;
  bool _flipped = false;

  /// Current tilt as radians: dx rotates around X (vertical drag), dy
  /// around Y (horizontal drag).
  Offset _tilt = Offset.zero;

  /// Pointer position relative to the card, 0..1 on both axes, feeding the
  /// glare highlight.
  Offset _pointer = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _tiltController.addListener(() {
      final tween = _tiltTween;
      if (tween != null && _tiltController.isAnimating) {
        setState(() => _tilt = tween.value);
      }
    });
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['flipped', 'onFlip']);
    final serverFlipped = getAttribute('flipped') == 'true';
    if (serverFlipped != _flipped) {
      _flipped = serverFlipped;
      _resetTilt();
      _animateTo(_flipped);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  void _animateTo(bool flipped) {
    _controller.animateTo(
      flipped ? 1 : 0,
      curve: Curves.easeInOut,
      duration: flipDuration,
    );
  }

  void _resetTilt() {
    _tiltTween = null;
    _tiltController.stop();
    if (_tilt != Offset.zero) setState(() => _tilt = Offset.zero);
  }

  void _onTap() {
    _flipped = !_flipped;
    _resetTilt();
    _animateTo(_flipped);
    final raw = getAttribute('onFlip');
    if (raw == null) return;
    for (final exec in FlutterExec.parse(raw, 'onFlip', null)) {
      exec.conditionalHandler(context, this);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    LiveFlipCard.debugPanCount++;
    if (_controller.isAnimating) return;
    final renderObject = context.findRenderObject();
    final size = renderObject is RenderBox ? renderObject.size : Size.zero;
    if (size.width == 0 || size.height == 0) return;
    setState(() {
      _tilt = Offset(
        (_tilt.dx - details.delta.dy / size.height * 2.2).clamp(
          -_maxTilt,
          _maxTilt,
        ),
        (_tilt.dy + details.delta.dx / size.width * 2.2).clamp(
          -_maxTilt,
          _maxTilt,
        ),
      );
      _pointer = Offset(
        (details.localPosition.dx / size.width).clamp(0.0, 1.0),
        (details.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_tilt == Offset.zero) return;
    _tiltTween = Tween<Offset>(
      begin: _tilt,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tiltController, curve: Curves.easeOut));
    _tiltController.forward(from: 0).whenComplete(() {
      // the last tick reports isAnimating false before the listener runs,
      // so land exactly on flat here
      if (mounted && _tilt != Offset.zero) {
        setState(() => _tilt = Offset.zero);
      }
    });
  }

  /// The transform for a face. A fully flat card (no flip, no tilt) must be
  /// the identity: applying the perspective term without a rotation would
  /// skew the card.
  Matrix4 _transform(double flipAngle) {
    if (flipAngle == 0 && _tilt == Offset.zero) return Matrix4.identity();
    return Matrix4.identity()
      ..setEntry(3, 0, _perspective)
      ..rotateY(flipAngle + _tilt.dy)
      ..rotateX(_tilt.dx);
  }

  Widget _face(Widget child, double angle, bool visible) {
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainSize: true,
      maintainAnimation: true,
      child: Transform(
        alignment: Alignment.center,
        transform: _transform(angle),
        child: child,
      ),
    );
  }

  @override
  Widget render(BuildContext context) {
    final children = multipleChildren();
    final front =
        children.isNotEmpty ? children.first : const SizedBox.shrink();
    final back = children.length > 1 ? children[1] : const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * pi;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _face(front, angle, angle <= pi / 2),
              _face(back, angle + pi, angle > pi / 2),
              // The foil floats above whichever face shows; it must not
              // steal gestures from the card or its controls.
              Positioned.fill(
                child: IgnorePointer(
                  child: FoilOverlay(tilt: _tilt, pointer: _pointer),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A subtle holographic foil: a diagonal rainbow gradient that slides with
/// the tilt, a faint deterministic sparkle field, and a soft glare following
/// the pointer. Kept at low opacity so card text stays readable.
class FoilOverlay extends StatelessWidget {
  final Offset tilt;
  final Offset pointer;

  const FoilOverlay({super.key, required this.tilt, required this.pointer});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Opacity(
            key: const ValueKey('foil-rainbow'),
            opacity: 0.14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // the rainbow slides across the card as it tilts
                  begin: Alignment(-1.0 + tilt.dy * 2.5, -1.0),
                  end: Alignment(1.0 + tilt.dy * 2.5, 1.0),
                  colors: const [
                    Color(0x33ff6b6b),
                    Color(0x33ffd93d),
                    Color(0x334ade80),
                    Color(0x334d9dff),
                    Color(0x33c86bff),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            key: const ValueKey('foil-sparkle'),
            opacity: 0.10,
            child: CustomPaint(painter: _SparklePainter(), size: Size.infinite),
          ),
          Opacity(
            key: const ValueKey('foil-glare'),
            opacity: 0.12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(pointer.dx * 2 - 1, pointer.dy * 2 - 1),
                  radius: 0.75,
                  colors: const [Color(0x40ffffff), Color(0x00ffffff)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed field of tiny dots standing in for foil sparkle; deterministic so
/// tests and repaint-less frames stay stable.
class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x80ffffff);
    var seed = 42;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(next() * size.width, next() * size.height),
        0.7 + next() * 0.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
