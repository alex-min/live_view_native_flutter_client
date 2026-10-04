import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A card the user drags vertically to send away.
///
/// The child follows the finger while dragging. Releasing past a distance or
/// velocity threshold flings the card off screen in the drag direction and
/// fires the matching exec (`onSwipeUp` / `onSwipeDown`, e.g. a server event
/// or client command); a smaller drag snaps back in place. Taps are handled
/// by the usual `phx-click` attribute. With `animateIn` the card slides up
/// from below on first layout, so the next card of a deck feels like it
/// comes from under the previous one.
///
/// Server usage:
/// ```xml
/// <Swipeable
///   phx-click="reveal"
///   onSwipeUp='[["event", {"name": "reveal"}]]'
///   animateIn="true">
///   <Container padding="24"><Text>term</Text></Container>
/// </Swipeable>
/// ```
class LiveSwipeable extends LiveStateWidget<LiveSwipeable> {
  const LiveSwipeable({super.key, required super.state});

  @override
  State<LiveSwipeable> createState() => _LiveSwipeableState();
}

class _LiveSwipeableState extends StateWidget<LiveSwipeable> {
  static const double flingDistanceThreshold = 96;
  static const double flingVelocityThreshold = 400;
  static const Duration flingDuration = Duration(milliseconds: 240);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: flingDuration,
  );
  Tween<double>? _tween;
  double _offset = 0;
  double _height = 0;
  bool _enterStarted = false;
  bool _flung = false;

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, ['animateIn', 'onSwipeUp', 'onSwipeDown']);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final tween = _tween;
      if (tween != null && _controller.isAnimating) {
        setState(() => _offset = tween.evaluate(_controller));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _animateIn => getAttribute('animateIn') == 'true';

  void _runExecs(String attribute) {
    final raw = getAttribute(attribute);
    if (raw == null) return;
    for (final exec in FlutterExec.parse(raw, attribute, null)) {
      exec.conditionalHandler(context, this);
    }
  }

  Future<void> _animateOffset(double target) {
    final completer = Completer<void>();
    _tween = Tween<double>(begin: _offset, end: target);
    _controller
      ..stop()
      ..reset()
      ..forward().whenComplete(() {
        if (!completer.isCompleted) completer.complete();
      });
    return completer.future;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final distance = _offset.abs();
    final flungUp =
        _offset < 0 &&
        (distance > flingDistanceThreshold ||
            velocity < -flingVelocityThreshold);
    final flungDown =
        _offset > 0 &&
        (distance > flingDistanceThreshold ||
            velocity > flingVelocityThreshold);

    if (flungUp || flungDown) {
      _flingAway(up: flungUp);
    } else {
      _animateOffset(0);
    }
  }

  Future<void> _flingAway({required bool up}) async {
    _flung = true;
    await _animateOffset(up ? -_height * 1.2 : _height * 1.2);
    if (!mounted) return;
    _runExecs(up ? 'onSwipeUp' : 'onSwipeDown');
  }

  @override
  Widget render(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height;

        if (_animateIn && !_enterStarted && _height > 0) {
          _enterStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _offset = _height * 0.18);
            _animateOffset(0);
          });
        }

        return GestureDetector(
          onVerticalDragUpdate:
              _flung
                  ? null
                  : (details) => setState(
                    () =>
                        _offset = (_offset + details.delta.dy).clamp(
                          -_height,
                          _height,
                        ),
                  ),
          onVerticalDragEnd: _flung ? null : _onDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(0, _offset),
            child: singleChild(),
          ),
        );
      },
    );
  }
}
