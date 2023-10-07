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
  final FormEvents? formEvents;

  NodeState({
    required this.node,
    required this.variables,
    required this.parser,
    required this.nestedState,
    required this.liveView,
    required this.formEvents,
  });

  NodeState copyWith(
          {XmlNode? node,
          final Map<String, dynamic>? variables,
          LiveViewUiParser? parser,
          List<int>? nestedState,
          LiveView? liveView,
          FormEvents? formEvents}) =>
      NodeState(
        node: node ?? this.node,
        formEvents: formEvents ?? this.formEvents,
        variables: variables ?? this.variables,
        parser: parser ?? this.parser,
        nestedState: nestedState ?? this.nestedState,
        liveView: liveView ?? this.liveView,
      );
}
