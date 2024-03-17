import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class StateChild {
  static Widget singleChild(NodeState state) {
    var children = state.node.nonEmptyChildren;
    switch (children.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        var components =
            (LiveViewUiParser.traverse(state.copyWith(node: children[0])));
        if (components.isEmpty) {
          return const SizedBox.shrink();
        }
        if (components.length == 1) {
          return components.first;
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: components);
      default:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: multipleChildren(state));
    }
  }

  static List<Widget> multipleChildren(NodeState state) {
    List<Widget> ret = [];

    for (var node in state.node.nonEmptyChildren) {
      ret.addAll(LiveViewUiParser.traverse(state.copyWith(node: node)));
    }
    return ret;
  }

  static List<LiveStateWidget> extractChildren<Type extends LiveStateWidget>(
      List<Widget> children) {
    List<LiveStateWidget> ret = [];
    var refType = (Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase());
    for (var child in children) {
      if (child is Type) {
        ret.add(child);
      }
      if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        ret.add(child);
      }
    }
    children.removeWhere((e) => ret.contains(e));
    return ret;
  }

  static LiveStateWidget? extractChild<Type extends LiveStateWidget>(
      List<Widget> children) {
    LiveStateWidget? ret;
    var refType = (Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase());
    for (var child in children) {
      if (child is Type) {
        ret = child;
      }
      if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        ret = child;
      }
    }
    children.removeWhere((e) => e == ret);

    return ret;
  }

  static Type? extractWidgetChild<Type extends Widget>(List<Widget> children) {
    Type? ret;
    for (var child in children) {
      if (child is Type) {
        ret = child;
      }
    }
    children.removeWhere((e) => e == ret);

    return ret;
  }
}
