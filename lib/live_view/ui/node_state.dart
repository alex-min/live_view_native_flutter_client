import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:xml/xml.dart';

class NodeState {
  final XmlNode node;
  final Map<String, dynamic> variables;
  final LiveViewUiParser parser;
  final List<int> nestedState;
  final LiveView liveView;
  final String urlPath;

  bool get isOnTheCurrentPage => urlPath == liveView.currentUrl;

  NodeState(
      {required this.node,
      required this.variables,
      required this.parser,
      required this.nestedState,
      required this.liveView,
      required this.urlPath});

  NodeState copyWith(
          {XmlNode? node,
          final Map<String, dynamic>? variables,
          LiveViewUiParser? parser,
          List<int>? nestedState,
          LiveView? liveView,
          FormEvents? formEvents,
          String? urlPath}) =>
      NodeState(
        node: node ?? this.node,
        variables: variables ?? this.variables,
        parser: parser ?? this.parser,
        nestedState: nestedState ?? this.nestedState,
        liveView: liveView ?? this.liveView,
        urlPath: urlPath ?? this.urlPath,
      );
}
