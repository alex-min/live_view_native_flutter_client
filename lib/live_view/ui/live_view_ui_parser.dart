import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cached_networked_image.dart';
import 'package:liveview_flutter/live_view/ui/components/live_center.dart';
import 'package:liveview_flutter/live_view/ui/components/live_checkbox.dart';
import 'package:liveview_flutter/live_view/ui/components/live_column.dart';
import 'package:liveview_flutter/live_view/ui/components/live_container.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer_header.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_expanded.dart';
import 'package:liveview_flutter/live_view/ui/components/live_filled_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_selected_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_list_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_positioned.dart';
import 'package:liveview_flutter/live_view/ui/components/live_row.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold.dart';
import 'package:liveview_flutter/live_view/ui/components/live_segmented_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_stack.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_view_body.dart';
import 'package:liveview_flutter/live_view/ui/errors/parsing_error_view.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

class LiveViewUiParser {
  List<String> html;
  final Map<String, dynamic> _htmlVariables;
  LiveView liveView;
  String urlPath;

  LiveViewUiParser(
      {required this.html,
      required Map<String, dynamic> htmlVariables,
      required this.liveView,
      required this.urlPath})
      : _htmlVariables = htmlVariables;

  List<Widget> parse() => parseHtml(html, _htmlVariables, []);

  List<Widget> parseHtml(List<String> html,
      final Map<String, dynamic> variables, List<int> nestedState) {
    var htmlVariables = Map<String, dynamic>.from(variables);
    if (html.isEmpty) {
      return [const SizedBox.shrink()];
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

    late XmlDocument xml;

    try {
      xml = XmlDocument.parse(fullHtml);
    } catch (e) {
      return [ParsingErrorView(xml: html.join(), url: urlPath)];
    }

    return traverse(NodeState(
        urlPath: urlPath,
        liveView: liveView,
        node: xml.nonEmptyChildren.first,
        variables: htmlVariables,
        nestedState: nestedState,
        parser: this));
  }

  static List<Widget> traverse(NodeState state) {
    return buildWidget(state);
  }

  static List<Widget> buildWidget(NodeState state) {
    if (state.node.nodeType == XmlNodeType.ELEMENT) {
      var componentName = (state.node as XmlElement).name.qualified;

      switch (componentName) {
        case 'Scaffold':
          return [LiveScaffold(state: state)];
        case 'Container':
          return [LiveContainer(state: state)];
        case 'Text':
          return [LiveText(state: state)];
        case 'ElevatedButton':
          return [LiveElevatedButton(state: state)];
        case 'Center':
          return [LiveCenter(state: state)];
        case 'ListView':
          return [LiveListView(state: state)];
        case 'Form':
          return [LiveForm(state: state)];
        case 'TextField':
          return [LiveTextField(state: state)];
        case 'AppBar':
          return [LiveAppBar(state: state)];
        case 'title':
          return [LiveTitleAttribute(state: state)];
        case 'leading':
          return [LiveLeadingAttribute(state: state)];
        case 'link':
          return [LiveLink(state: state)];
        case 'icon':
          return [LiveIconAttribute(state: state)];
        case 'label':
          return [LiveLabelAttribute(state: state)];
        case 'selectedIcon':
          return [LiveIconSelectedAttribute(state: state)];
        case 'Icon':
          return [LiveIcon(state: state)];
        case 'Column':
          return [LiveColumn(state: state)];
        case 'Row':
          return [LiveRow(state: state)];
        case 'Drawer':
          return [LiveDrawer(state: state)];
        case 'DrawerHeader':
          return [LiveDrawerHeader(state: state)];
        case 'BottomNavigationBar':
          return [LiveBottomNavigationBar(state: state)];
        case 'BottomNavigationBarItem':
          return [const SizedBox.shrink()];
        case 'Positioned':
          return [LivePositioned(state: state)];
        case 'Stack':
          return [LiveStack(state: state)];
        case 'NavigationRail':
          return [LiveNavigationRail(state: state)];
        case 'NavigationRailDestination':
          return [const SizedBox.shrink()];
        case 'CachedNetworkImage':
          return [LiveCachedNetworkImage(state: state)];
        case 'Expanded':
          return [LiveExpanded(state: state)];
        case 'FilledButton':
          return [LiveFilledButton(state: state)];
        case 'viewBody':
          return [LiveViewBody(state: state)];
        case 'flutter':
          return state.node.nonEmptyChildren
              .map((c) => traverse(state.copyWith(node: c)).first)
              .toList();
        case 'Checkbox':
          return [LiveCheckbox(state: state)];
        case 'SegmentedButton':
          return [LiveSegmentedButton(state: state)];
        case 'LiveButtonSegment':
          return [const SizedBox.shrink()];
        default:
          reportError("unknown widget $componentName");
          return [const SizedBox.shrink()];
      }
    } else if (state.node.nodeType == XmlNodeType.TEXT) {
      return [LiveDynamicComponent(state: state)];
    } else {
      reportError('unknown node type ${state.node.nodeType}');
      return [const SizedBox.shrink()];
    }
  }
}
