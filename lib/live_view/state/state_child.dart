import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class StateChild {
  /// In Flutter, components can accept either a single child or multiple children but not both.
  /// How the client reconciles this is to add a `Column` widget if needed to behave more like HTML.
  /// Raw text elements in the xml payload are transformed into a basic Flutter `Text` widget.
  /// Those two buttons are equivalent:
  ///
  /// ```xml
  /// <ElevatedButton>Click me</ElevatedButton>
  /// <ElevatedButton><Text>Click me</Text></ElevatedButton>
  /// ```
  ///
  /// And those two buttons are exactly rendered the same way as well:
  ///
  /// ```xml
  /// <ElevatedButton>
  ///     <Column>
  ///         <Text>Click</Text>
  ///         <Text> me</Text>
  ///     </Column>
  /// </ElevatedButton>
  ///
  /// <ElevatedButton>
  ///     <Text>Click</Text>
  ///     <Text> me</Text>
  /// </ElevatedButton>
  /// ```
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

  /// Extracts multiple children from the XML nodes
  /// This is needed for widgets accepting multiple children such as List or SegmentedButton
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

  /// Sometimes Flutter doesn't map well to an XML structure and can accept widget as properties which aren't children.
  /// This is what ```extractChild``` is used for.
  ///
  /// As an example, the widget ```SegmentedButton``` accepts a list of ```ButtonSegment``` as children (which aren't widgets in Flutter).
  /// And the ```ButtonSegment``` itself accepts a text and an icon.
  ///
  /// These three ButtonSegment are equivalent:
  /// ```xml
  /// <ButtonSegment name="1" label="my label" icon="home" />
  /// <ButtonSegment name="1" icon="home">
  ///   <Text>my label</Text>
  /// </ButtonSegment>
  /// <ButtonSegment name="1">
  ///   <Text>my label</Text>
  ///   <Icon name="home" />
  /// </ButtonSegment>
  /// ```
  /// Here, Text and Icon are taken by default since the code is using
  /// ```dart
  /// icon ??= StateChild.extractChild<LiveIcon>(children);
  /// label ??= StateChild.extractChild<LiveText>(children);
  /// ```
  /// But if you want to use a different widget for the icon and label, you can use the ```as``` property
  /// ```xml
  /// <ButtonSegment name="1" icon="home">
  ///   <Row as="text">
  ///     <Text>my</Text><Text>label</Text>
  ///   </Row>
  ///   <Text as="icon">hello</Text>
  /// </ButtonSegment>
  /// ```
  /// The Row here will be picked up as the ```text``` property. This concept is useful to map unusual widgets to properties.
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
