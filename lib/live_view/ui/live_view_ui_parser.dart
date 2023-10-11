import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_center.dart';
import 'package:liveview_flutter/live_view/ui/components/live_column.dart';
import 'package:liveview_flutter/live_view/ui/components/live_container.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_list_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_row.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

class LiveViewUiParser {
  List<String> html;
  final Map<String, dynamic> _htmlVariables;
  LiveView liveView;

  LiveViewUiParser(
      {required this.html,
      required Map<String, dynamic> htmlVariables,
      required this.liveView})
      : _htmlVariables = htmlVariables;

  Widget parse() => parseHtml(html, _htmlVariables, []);

  Widget parseHtml(List<String> html, final Map<String, dynamic> variables,
      List<int> nestedState) {
    var htmlVariables = Map<String, dynamic>.from(variables);
    if (html.isEmpty) {
      return const SizedBox.shrink();
    }

    var fullHtml = html.joinWith((i) {
      if (variables.containsKey(i.toString())) {
        var injectedValue = variables[i.toString()].toString().trim();
        if (RegExp(r'^[a-zA-Z_-]+=\".*\"$').hasMatch(injectedValue)) {
          var split = injectedValue.indexOf('="');
          var key = injectedValue.substring(0, split);
          return ' $key="[[flutterState key=$i]]" ';
        }
      }
      return '[[flutterState key=$i]]';
    }).trim();

    print(fullHtml);
    return traverse(NodeState(
        liveView: liveView,
        node: XmlDocument.parse(fullHtml).nonEmptyChildren.first,
        variables: htmlVariables,
        nestedState: nestedState,
        parser: this,
        formEvents: null));
  }

  Widget traverse(NodeState state) {
    return buildWidget(state);
  }

  Widget buildWidget(NodeState state) {
    if (state.node.nodeType == XmlNodeType.ELEMENT) {
      var componentName = (state.node as XmlElement).name.qualified;

      switch (componentName) {
        case 'Scaffold':
          return LiveScaffold(state: state);
        case 'Container':
          return LiveContainer(state: state);
        case 'Text':
          return LiveText(state: state);
        case 'ElevatedButton':
          return LiveElevatedButton(state: state);
        case 'Center':
          return LiveCenter(state: state);
        case 'ListView':
          return LiveListView(state: state);
        case 'Form':
          return LiveForm(state: state);
        case 'TextField':
          return LiveTextField(state: state);
        case 'AppBar':
          return LiveAppBar(state: state);
        case 'title':
          return LiveTitleAttribute(state: state);
        case 'leading':
          return LiveLeadingAttribute(state: state);
        case 'link':
          return LiveLink(state: state);
        case 'icon':
          return LiveIconAttribute(state: state);
        case 'Icon':
          return LiveIcon(state: state);
        case 'Column':
          return LiveColumn(state: state);
        case 'Row':
          return LiveRow(state: state);
        default:
          throw Exception("unknown widget $componentName");
      }
    } else if (state.node.nodeType == XmlNodeType.TEXT) {
      return LiveDynamicComponent(state: state);
    } else {
      throw Exception('unknown node type ${state.node.nodeType}');
    }
  }
}
