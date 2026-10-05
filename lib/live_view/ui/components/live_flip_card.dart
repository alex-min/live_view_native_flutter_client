import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A card with two faces that flips around the vertical axis.
///
/// The first child is the front face, the second the back face. Tapping the
/// card (anywhere except on nested interactive controls, which win the
/// gesture arena) rotates the card 180° around its Y axis with a perspective
/// tween and fires the `onFlip` exec so the server can mirror the state.
/// When the server changes the `flipped` attribute (patch, reconnect) the
/// card animates to match — except on a fresh mount, where it snaps straight
/// to the server's face so a remount can never replay the flip.
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

  @override
  State<LiveFlipCard> createState() => _LiveFlipCardState();
}

class _LiveFlipCardState extends StateWidget<LiveFlipCard> {
  static const Duration defaultFlipDuration = Duration(milliseconds: 380);
  static const Duration tiltSettleDuration = Duration(milliseconds: 320);
  static const double _perspective = 0.0016;

  /// Maximum tilt in radians (~11.5°): the card tips into the light, it
  /// never rotates far enough to hurt readability.
  static const double _maxTilt = 0.20;

  /// The single driver of the flip angle: value 0 = front, 1 = back. Nothing
  /// else writes the angle; server state only ever adjusts the target.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: defaultFlipDuration,
  );
  late final AnimationController _tiltController = AnimationController(
    vsync: this,
    duration: tiltSettleDuration,
  );
  Animation<Offset>? _tiltTween;

  /// Single source of truth for which face should show.
  bool _flipped = false;

  /// Whether the widget is established (has applied its first server
  /// state). Until then a mismatched `flipped` attribute means a fresh
  /// mount or recreation: snap, never animate, so a remount cannot replay
  /// the flip.
  bool _attributesLoaded = false;

  /// Current tilt as radians: dx rotates around X (vertical drag), dy
  /// around Y (horizontal drag).
  Offset _tilt = Offset.zero;

  /// Pointer position relative to the card, 0..1 on both axes, feeding the
  /// glare highlight.
  Offset _pointer = const Offset(0.5, 0.5);
  bool _interacting = false;

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
    reloadAttributes(node, ['flipped', 'onFlip', 'flip-duration']);
    _controller.duration = _flipDuration;
    final serverFlipped = getAttribute('flipped') == 'true';
    if (serverFlipped == _flipped && _attributesLoaded) return;
    final firstLoad = !_attributesLoaded;
    _attributesLoaded = true;
    _flipped = serverFlipped;

    final settledAtTarget =
        _flipped ? _controller.value == 1 : _controller.value == 0;
    if (settledAtTarget || (!firstLoad && _controller.isAnimating)) {
      // either already showing the server's face, or our own gesture is
      // animating toward it: the controller is the only driver
      return;
    }
    if (firstLoad) {
      // Fresh mount / reconnect / recreation: land on the server's face
      // immediately. Animating here would replay a flip the user already
      // watched (or never asked for).
      _resetTilt();
      _controller
        ..stop()
        ..value = _flipped ? 1 : 0;
      return;
    }
    _resetTilt();
    _animateTo(_flipped);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  /// Optional server override of the flip length, in milliseconds. An absent
  /// or invalid `flip-duration` keeps the default so existing templates
  /// behave unchanged.
  Duration get _flipDuration {
    final ms = int.tryParse(getAttribute('flip-duration') ?? '');
    if (ms == null || ms <= 0) return defaultFlipDuration;
    return Duration(milliseconds: ms);
  }

  void _animateTo(bool flipped) {
    _controller
        .animateTo(
          flipped ? 1 : 0,
          curve: Curves.easeInOut,
          duration: _controller.duration,
        )
        .whenComplete(() {
          // rest exactly flat: no tilt may survive a completed flip
          if (mounted && _tilt != Offset.zero) {
            setState(() => _tilt = Offset.zero);
          }
        });
  }

  void _resetTilt() {
    _tiltTween = null;
    _tiltController.stop();
    if (_tilt != Offset.zero ||
        _interacting ||
        _pointer != const Offset(0.5, 0.5)) {
      setState(() {
        _tilt = Offset.zero;
        _pointer = const Offset(0.5, 0.5);
        _interacting = false;
      });
    }
  }

  void _onHover(PointerHoverEvent event) {
    if (_controller.isAnimating) return;
    final renderObject = context.findRenderObject();
    final size = renderObject is RenderBox ? renderObject.size : Size.zero;
    if (size.width == 0 || size.height == 0) return;
    final pointer = Offset(
      (event.localPosition.dx / size.width).clamp(0.0, 1.0),
      (event.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    _tiltController.stop();
    _tiltTween = null;
    setState(() {
      _pointer = pointer;
      _tilt = Offset(
        (0.5 - pointer.dy) * 2 * _maxTilt,
        (pointer.dx - 0.5) * 2 * _maxTilt,
      );
      _interacting = true;
    });
  }

  void _toggle() {
    // one gesture, one flip: taps during the tween are ignored
    if (_controller.isAnimating) return;
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
    if (_controller.isAnimating) return;
    final renderObject = context.findRenderObject();
    final size = renderObject is RenderBox ? renderObject.size : Size.zero;
    if (size.width == 0 || size.height == 0) return;
    setState(() {
      _interacting = true;
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
    setState(() {
      _interacting = false;
      _pointer = const Offset(0.5, 0.5);
    });
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
  /// skew the card. Angles are normalized so a face resting at 2π (the back
  /// face when the front is up) takes the identity shortcut too.
  Matrix4 _transform(double flipAngle) {
    final angle = flipAngle % (2 * pi);
    if (angle == 0 && _tilt == Offset.zero) return Matrix4.identity();
    return Matrix4.identity()
      ..setEntry(3, 2, -_perspective)
      ..rotateY(angle + _tilt.dy)
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
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: FoilOverlay(
                  tilt: _tilt,
                  pointer: _pointer,
                  interacting: _interacting,
                ),
              ),
            ),
          ],
        ),
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
        return MouseRegion(
          onHover: _onHover,
          onExit: (_) => _onPanEnd(DragEndDetails()),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: () => _onPanEnd(DragEndDetails()),
            child: LayoutBuilder(
              builder:
                  (context, constraints) => Stack(
                    alignment: Alignment.center,
                    fit:
                        constraints.hasBoundedWidth &&
                                constraints.hasBoundedHeight
                            ? StackFit.expand
                            : StackFit.loose,
                    children: [
                      _face(front, angle, angle <= pi / 2),
                      _face(back, angle + pi, angle > pi / 2),
                    ],
                  ),
            ),
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
  final bool interacting;

  const FoilOverlay({
    super.key,
    required this.tilt,
    required this.pointer,
    required this.interacting,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            key: const ValueKey('foil-rainbow'),
            opacity: interacting ? 0.38 : 0.24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.8 + pointer.dx * 1.6, -1.2 + tilt.dx),
                  end: Alignment(0.2 + pointer.dx * 1.6, 1.2 + tilt.dx),
                  colors: const [
                    Color(0x55f80e35),
                    Color(0x55eedf10),
                    Color(0x5521e985),
                    Color(0x550dbde9),
                    Color(0x55c929f1),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            key: const ValueKey('foil-sparkle'),
            opacity: interacting ? 0.18 : 0.10,
            child: CustomPaint(painter: _SparklePainter(), size: Size.infinite),
          ),
          Opacity(
            key: const ValueKey('foil-glare'),
            opacity: interacting ? 0.32 : 0.08,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(pointer.dx * 2 - 1, pointer.dy * 2 - 1),
                  radius: 0.7,
                  colors: const [Color(0x88ffffff), Color(0x00ffffff)],
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
