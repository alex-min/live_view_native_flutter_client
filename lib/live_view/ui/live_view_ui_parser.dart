import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_action_chip.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_autocomplete.dart';
import 'package:liveview_flutter/live_view/ui/components/live_avatar_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_badge.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cached_networked_image.dart';
import 'package:liveview_flutter/live_view/ui/components/live_card.dart';
import 'package:liveview_flutter/live_view/ui/components/live_center.dart';
import 'package:liveview_flutter/live_view/ui/components/live_checkbox.dart';
import 'package:liveview_flutter/live_view/ui/components/live_column.dart';
import 'package:liveview_flutter/live_view/ui/components/live_container.dart';
import 'package:liveview_flutter/live_view/ui/components/live_content_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_disabled_hint_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer_header.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dropdown_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_end_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_expanded.dart';
import 'package:liveview_flutter/live_view/ui/components/live_filled_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_hint_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_selected_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_list_tile.dart';
import 'package:liveview_flutter/live_view/ui/components/live_list_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_material_banner.dart';
import 'package:liveview_flutter/live_view/ui/components/live_modal.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_footer_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_positioned.dart';
import 'package:liveview_flutter/live_view/ui/components/live_row.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold_message.dart';
import 'package:liveview_flutter/live_view/ui/components/live_segmented_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_stack.dart';
import 'package:liveview_flutter/live_view/ui/components/live_subtitle_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_tooltip.dart';
import 'package:liveview_flutter/live_view/ui/components/live_trailing_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_underline_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_view_body.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/errors/parsing_error_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

class LiveViewUiParser {
  List<String> html;
  final Map<String, dynamic> _htmlVariables;
  LiveView liveView;
  String urlPath;
  ViewType viewType;

  LiveViewUiParser(
      {required this.html,
      required Map<String, dynamic> htmlVariables,
      required this.liveView,
      required this.urlPath,
      required this.viewType})
      : _htmlVariables = htmlVariables;

  (List<Widget>, NodeState?) parse() => parseHtml(html, _htmlVariables, []);

  String recursiveRender(
    List<String> html,
    Map<String, dynamic> variables,
    Map<String, dynamic> components,
    String? componentId,
    List<String> nestedState,
  ) {
    return html.joinWith((i) {
      if (variables.containsKey(i.toString())) {
        var injectedValue = variables[i.toString()].toString().trim();

        if (variables[i.toString()] is num &&
            components.containsKey(injectedValue)) {
          return recursiveRender(
            List<String>.from(components[injectedValue]?["s"] ?? []),
            Map<String, dynamic>.from(components[injectedValue]),
            components,
            injectedValue,
            nestedState,
          );
        }

        if (RegExp(r'^[ a-zA-Z_-]+=\".*\"$').hasMatch(injectedValue)) {
          var split = injectedValue.indexOf('="');
          var key = injectedValue.substring(0, split);
          return ' $key="[[flutterState key=$i]]" ';
        }
      }
      if (componentId != null) {
        return '[[flutterState key=$i component=$componentId]]';
      }

      return '[[flutterState key=$i]]';
    }).trim();
  }

  (List<Widget>, NodeState?) parseHtml(
    List<String> html,
    final Map<String, dynamic> variables,
    List<String> nestedState,
  ) {
    var htmlVariables = Map<String, dynamic>.from(variables);
    if (html.isEmpty) {
      return ([const SizedBox.shrink()], null);
    }

    var fullHtml = recursiveRender(
      html,
      variables,
      variables['c'] ?? {},
      null,
      nestedState,
    );

    late XmlDocument xml;

    // this is always injected in the xml and breaks the xml parser
    // the xml parser doesn't support html-like attributes without a property
    fullHtml = fullHtml.replaceFirst(RegExp('<div.*data-phx-main '), '<div ');

    try {
      xml = XmlDocument.parse(fullHtml);
    } catch (e) {
      try {
        xml = XmlDocument.parse("<flutter>$fullHtml</flutter>");
      } catch (e) {
        return ([ParsingErrorView(xml: fullHtml, url: urlPath)], null);
      }
    }

    var state = NodeState(
      urlPath: urlPath,
      liveView: liveView,
      node: xml.nonEmptyChildren.first,
      variables: htmlVariables,
      nestedState: nestedState,
      parser: this,
      viewType: viewType,
    );
    return (traverse(state), state);
  }

  static List<Widget> traverse(NodeState state) {
    return buildWidget(state);
  }

  static List<Widget> buildWidget(NodeState state) {
    if (state.node.nodeType == XmlNodeType.COMMENT) {
      return [const SizedBox.shrink()];
    } else if (state.node.nodeType == XmlNodeType.ELEMENT) {
      var componentName = (state.node as XmlElement).name.qualified;

      return LiveViewUiRegistry.instance.buildWidget(componentName, state);
    } else if (state.node.nodeType == XmlNodeType.TEXT) {
      return renderDynamicComponent(state);
    } else {
      reportError('unknown node type ${state.node.nodeType}');
      return [const SizedBox.shrink()];
    }
  }

  static void registerDefaultComponents() {
    LiveViewUiRegistry.instance
      ..add(['Scaffold'], (state) => [LiveScaffold(state: state)])
      ..add(['Container'], (state) => [LiveContainer(state: state)])
      ..add(['Tooltip'], (state) => [LiveTooltip(state: state)])
      ..add(['Text'], (state) => [LiveText(state: state)])
      ..add(['ElevatedButton'], (state) => [LiveElevatedButton(state: state)])
      ..add(['Center'], (state) => [LiveCenter(state: state)])
      ..add(['ListView'], (state) => [LiveListView(state: state)])
      ..add(['Form'], (state) => [LiveForm(state: state)])
      ..add(['TextField'], (state) => [LiveTextField(state: state)])
      ..add(['AppBar'], (state) => [LiveAppBar(state: state)])
      ..add(['title'], (state) => [LiveTitleAttribute(state: state)])
      ..add(['leading'], (state) => [LiveLeadingAttribute(state: state)])
      ..add(['link'], (state) => [LiveLink(state: state)])
      ..add(['icon'], (state) => [LiveIconAttribute(state: state)])
      ..add(['label'], (state) => [LiveLabelAttribute(state: state)])
      ..add(['selectedIcon'],
          (state) => [LiveIconSelectedAttribute(state: state)])
      ..add(['Icon'], (state) => [LiveIcon(state: state)])
      ..add(['Column'], (state) => [LiveColumn(state: state)])
      ..add(['Row'], (state) => [LiveRow(state: state)])
      ..add(['PersistentFooterButton'],
          (state) => [LivePersistentFooterButton(state: state)])
      ..add(['BottomSheet'], (state) => [LiveBottomSheet(state: state)])
      ..add(['Drawer'], (state) => [LiveDrawer(state: state)])
      ..add(['EndDrawer'], (state) => [LiveEndDrawer(state: state)])
      ..add(['DrawerHeader'], (state) => [LiveDrawerHeader(state: state)])
      ..add(['BottomNavigationBar'],
          (state) => [LiveBottomNavigationBar(state: state)])
      ..add(['BottomAppBar'], (state) => [LiveBottomAppBar(state: state)])
      ..add(['DropdownButton'], (state) => [LiveDropdownButton(state: state)])
      ..add(['BottomNavigationBarItem'], (state) => [const SizedBox.shrink()])
      ..add(['Positioned'], (state) => [LivePositioned(state: state)])
      ..add(['Stack'], (state) => [LiveStack(state: state)])
      ..add(['NavigationRail'], (state) => [LiveNavigationRail(state: state)])
      ..add(['NavigationRailDestination'], (state) => [const SizedBox.shrink()])
      ..add(['CachedNetworkImage'],
          (state) => [LiveCachedNetworkImage(state: state)])
      ..add(['Expanded'], (state) => [LiveExpanded(state: state)])
      ..add(['FilledButton'], (state) => [LiveFilledButton(state: state)])
      ..add(['viewBody'], (state) => [LiveViewBody(state: state)])
      ..add(['modal'], (state) => [LiveModal(state: state)])
      // Those xml nodes are transparent and aren't rendered in the client
      // We just traverse them
      ..add(['compiled-lvn-stylesheet', 'div', 'flutter'], (state) {
        List<Widget> ret = [];
        for (var node in state.node.nonEmptyChildren) {
          ret.addAll(traverse(state.copyWith(node: node)));
        }
        return ret;
      })
      ..add(['Checkbox'], (state) => [LiveCheckbox(state: state)])
      ..add(['SegmentedButton'], (state) => [LiveSegmentedButton(state: state)])
      ..add(['LiveButtonSegment'], (state) => [const SizedBox.shrink()])
      ..add(['FloatingActionButton'],
          (state) => [LiveFloatingActionButton(state: state)])
      ..add(['avatar'], (state) => [LiveAvatarAttribute(state: state)])
      ..add(['ActionChip'], (state) => [LiveActionChip(state: state)])
      ..add(['content'], (state) => [LiveContentAttribute(state: state)])
      ..add(['MaterialBanner'], (state) => [LiveMaterialBanner(state: state)])
      ..add(['TextButton'], (state) => [LiveTextButton(state: state)])
      ..add(['Autocomplete'], (state) => [LiveAutocomplete(state: state)])
      ..add(['Badge'], (state) => [LiveBadge(state: state)])
      ..add(['hint'], (state) => [LiveHintAttribute(state: state)])
      ..add(['disabledHint'],
          (state) => [LiveDisabledHintAttribute(state: state)])
      ..add(['underline'], (state) => [LiveUnderlineAttribute(state: state)])
      ..add(['IconButton'], (state) => [LiveIconButton(state: state)])
      ..add(['Card'], (state) => [LiveCard(state: state)])
      ..add(['subtitle'], (state) => [LiveSubtitleAttribute(state: state)])
      ..add(['trailing'], (state) => [LiveTrailingAttribute(state: state)])
      ..add(['ListTile'], (state) => [LiveListTile(state: state)])
      ..add(['ScaffoldMessage'], (state) => [LiveScaffoldMessage(state: state)])
      ..add(['meta', 'csrf-token', 'iframe'],
          (state) => [const SizedBox.shrink()]);
  }
}
