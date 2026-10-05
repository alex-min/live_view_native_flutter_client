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
  static const Duration flipDuration = Duration(milliseconds: 380);
  static const double _perspective = 0.0016;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: flipDuration,
  );
  bool _flipped = false;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['flipped', 'onFlip']);
    final serverFlipped = getAttribute('flipped') == 'true';
    if (serverFlipped != _flipped) {
      _flipped = serverFlipped;
      _animateTo(_flipped);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(bool flipped) {
    _controller.animateTo(
      flipped ? 1 : 0,
      curve: Curves.easeInOut,
      duration: flipDuration,
    );
  }

  void _onTap() {
    _flipped = !_flipped;
    _animateTo(_flipped);
    final raw = getAttribute('onFlip');
    if (raw == null) return;
    for (final exec in FlutterExec.parse(raw, 'onFlip', null)) {
      exec.conditionalHandler(context, this);
    }
  }

  Widget _face(Widget child, double angle, bool visible) {
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainSize: true,
      maintainAnimation: true,
      child: Transform(
        alignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..setEntry(3, 0, _perspective)
              ..rotateY(angle),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              _face(front, angle, angle <= pi / 2),
              _face(back, angle + pi, angle > pi / 2),
            ],
          ),
        );
      },
    );
  }
}
