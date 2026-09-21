import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

/// Renders the widgets the parser hoisted out of the page body because they
/// are marked persistent="true".
///
/// The parser can only discover them while the page body renders, so the
/// layer syncs its children post-frame. Syncing lives in this dedicated
/// widget — instead of RootScaffold — so the extra frame only rebuilds the
/// chrome subtree and never re-mounts page content. A real page change
/// resets the declaration (loading pages keep it, since they reuse the
/// previous page's widgets without re-parsing), so the chrome is dropped
/// once a page stops declaring it.
class PersistentChromeLayer extends StatefulWidget {
  final LiveView view;
  const PersistentChromeLayer({super.key, required this.view});

  @override
  State<PersistentChromeLayer> createState() => _PersistentChromeLayerState();
}

class _PersistentChromeLayerState extends State<PersistentChromeLayer> {
  List<Widget> chrome = const [];

  @override
  void initState() {
    widget.view.router.addListener(onRouteChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.view.router.removeListener(onRouteChange);
    super.dispose();
  }

  void onRouteChange() {
    var isLoading =
        widget.view.router.pages.lastOrNull?.page.name?.startsWith(
          'loading;',
        ) ==
        true;
    if (!isLoading) {
      widget.view.persistentChromeDeclared = false;
      widget.view.persistentChromePageRendered = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  void sync() {
    if (!mounted) {
      return;
    }
    // The chrome survives until the current page rendered its body without
    // declaring one; an interrupted navigation leaves the page unrendered
    // and must not drop it.
    var keep =
        widget.view.persistentChromeDeclared ||
        !widget.view.persistentChromePageRendered;
    var desired = keep ? widget.view.persistentChrome : const <Widget>[];
    if (desired.length == chrome.length &&
        (desired.isEmpty || identical(desired.first, chrome.first))) {
      return;
    }
    if (!keep) {
      widget.view.persistentChrome = [];
    }
    setState(() => chrome = desired);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
    if (chrome.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(children: chrome);
  }
}
