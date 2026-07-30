import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// Renders an `<overlayChild>` slot in the nearest `Overlay`, anchored below
/// the `<child>` slot, like a dropdown floating over the page content.
///
/// ```xml
/// <OverlayPortal>
///   <child><TextField name="search" /></child>
///   <overlayChild><Card>...</Card></overlayChild>
/// </OverlayPortal>
/// ```
///
/// The overlay is always shown; the server controls visibility by rendering
/// an empty `<overlayChild>` when the dropdown should be closed.
class LiveOverlayPortal extends LiveStateWidget<LiveOverlayPortal> {
  const LiveOverlayPortal({super.key, required super.state});

  @override
  State<LiveOverlayPortal> createState() => _LiveOverlayPortalState();
}

class _LiveOverlayPortalState extends StateWidget<LiveOverlayPortal> {
  final attributes = ['offsetX', 'offsetY'];

  final _link = LayerLink();
  final _targetKey = GlobalKey();
  final _controller = OverlayPortalController();
  double? _overlayWidth;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  /// The overlay entry builds during the same frame as the trigger, before
  /// layout, so the target width is read after the frame and cached.
  void _measureTriggerWidth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var renderObject = _targetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        return;
      }
      var width = renderObject.size.width;
      if (mounted && width != _overlayWidth) {
        setState(() => _overlayWidth = width);
      }
    });
  }

  @override
  Widget render(BuildContext context) {
    if (!_controller.isShowing) {
      _controller.show();
    }

    var triggerNodes = childrenNodesOf(node, 'child');
    var overlayNodes = childrenNodesOf(node, 'overlayChild');

    var trigger =
        triggerNodes.isEmpty
            ? const SizedBox.shrink()
            : singleChild(
              state: widget.state.copyWith(node: triggerNodes.first),
            );

    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) {
        _measureTriggerWidth();
        return CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(
            doubleAttribute('offsetX') ?? 0,
            doubleAttribute('offsetY') ?? 0,
          ),
          child: UnconstrainedBox(
            // The overlay entry imposes the full overlay size; the content
            // must size to itself instead.
            alignment: Alignment.topLeft,
            child: SizedBox(
              // Falls back to a sane width on the first frame, before the
              // trigger width has been measured.
              width: _overlayWidth ?? 320,
              child:
                  overlayNodes.isEmpty
                      ? const SizedBox.shrink()
                      : singleChild(
                        state: widget.state.copyWith(node: overlayNodes.first),
                      ),
            ),
          ),
        );
      },
      child: Align(
        // The parent may impose tight constraints; the target must hug the
        // trigger so the overlay anchors right below it.
        alignment: Alignment.topCenter,
        child: CompositedTransformTarget(
          key: _targetKey,
          link: _link,
          child: trigger,
        ),
      ),
    );
  }
}
