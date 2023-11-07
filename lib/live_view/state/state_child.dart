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
        return LiveViewUiParser.traverse(state.copyWith(node: children[0]))
            .first;
      default:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: multipleChildren(state));
    }
  }

  static List<Widget> multipleChildren(NodeState state) {
    return state.node.nonEmptyChildren.map((child) {
      return LiveViewUiParser.traverse(state.copyWith(node: child)).first;
    }).toList();
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
