import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:xml/xml.dart';

/// NodeState represents the state of an XML node
///
/// It contains both the node itself and the local variables associated to it
class NodeState {
  final XmlNode node;
  final Map<String, dynamic> variables;
  final LiveViewUiParser parser;
  final List<String> nestedState;
  final LiveView liveView;
  final String urlPath;
  final ViewType viewType;
  List<Widget> dynamicWidget;

  bool get isOnTheCurrentPage => urlPath == liveView.currentUrl;

  NodeState({
    required this.node,
    required this.variables,
    required this.parser,
    required this.nestedState,
    required this.liveView,
    required this.urlPath,
    required this.viewType,
    this.dynamicWidget = const [],
  });

  NodeState copyWith({
    XmlNode? node,
    final Map<String, dynamic>? variables,
    LiveViewUiParser? parser,
    List<String>? nestedState,
    LiveView? liveView,
    String? urlPath,
    List<Widget>? dynamicWidget,
    String? componentId,
    ViewType? viewType,
  }) =>
      NodeState(
        node: node ?? this.node,
        variables: variables ?? this.variables,
        parser: parser ?? this.parser,
        nestedState: nestedState ?? this.nestedState,
        liveView: liveView ?? this.liveView,
        urlPath: urlPath ?? this.urlPath,
        dynamicWidget: dynamicWidget ?? this.dynamicWidget,
        viewType: viewType ?? this.viewType,
      );
}
