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
import 'package:liveview_flutter/live_view/ui/components/live_flex.dart';
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
import 'package:liveview_flutter/live_view/ui/components/live_safe_area.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold.dart';
import 'package:liveview_flutter/live_view/ui/components/live_scaffold_message.dart';
import 'package:liveview_flutter/live_view/ui/components/live_segmented_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_single_child_scroll_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_sized_box.dart';
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
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

var uuid = const Uuid();

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
    var res = html
        .map((part) => part == '' ? '<div></div>' : part)
        .toList()
        .joinWith((i) {
      if (variables.containsKey(i.toString())) {
        var currentVariable = variables[i.toString()];
        var injectedValue = currentVariable.toString().trim();

        if (currentVariable is num && components.containsKey(injectedValue)) {
          return recursiveRender(
            List<String>.from(components[injectedValue]?["s"] ?? []),
            Map<String, dynamic>.from(components[injectedValue]),
            components,
            injectedValue,
            nestedState,
          );
        }

        while (currentVariable is Map) {
          currentVariable = currentVariable[i.toString()];
          injectedValue = currentVariable.toString().trim();
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

    return res;
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
      node: xml.root,
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
    if (state.node.nodeType == XmlNodeType.TEXT ||
        state.variables.containsKey('d')) {
      return renderDynamicComponent(state);
    } else if (state.node.nodeType == XmlNodeType.DOCUMENT) {
      List<Widget> ret = [];
      for (var node in state.node.nonEmptyChildren) {
        ret.addAll(traverse(state.copyWith(node: node)));
      }
      return ret;
    } else if (state.node.nodeType == XmlNodeType.COMMENT) {
      return [const SizedBox.shrink()];
    } else if (state.node.nodeType == XmlNodeType.ELEMENT) {
      var componentName = (state.node as XmlElement).name.qualified;
      return LiveViewUiRegistry.instance.buildWidget(componentName, state);
    } else {
      reportError('unknown node type ${state.node.nodeType}');
      return [const SizedBox.shrink()];
    }
  }

  static void registerDefaultComponents() {
    LiveViewUiRegistry.instance
      ..add(['Scaffold'],
          (state) => [LiveScaffold(state: state, key: Key(uuid.v4()))])
      ..add(['Container'],
          (state) => [LiveContainer(state: state, key: Key(uuid.v4()))])
      ..add(['Tooltip'],
          (state) => [LiveTooltip(state: state, key: Key(uuid.v4()))])
      ..add(['Text'], (state) => [LiveText(state: state, key: Key(uuid.v4()))])
      ..add(['ElevatedButton'],
          (state) => [LiveElevatedButton(state: state, key: Key(uuid.v4()))])
      ..add(['Center'],
          (state) => [LiveCenter(state: state, key: Key(uuid.v4()))])
      ..add(['ListView'],
          (state) => [LiveListView(state: state, key: Key(uuid.v4()))])
      ..add(['Form'], (state) => [LiveForm(state: state, key: Key(uuid.v4()))])
      ..add(['TextField'],
          (state) => [LiveTextField(state: state, key: Key(uuid.v4()))])
      ..add(['AppBar'],
          (state) => [LiveAppBar(state: state, key: Key(uuid.v4()))])
      ..add(['title'],
          (state) => [LiveTitleAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['leading'],
          (state) => [LiveLeadingAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['link'], (state) => [LiveLink(state: state, key: Key(uuid.v4()))])
      ..add(['icon'],
          (state) => [LiveIconAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['label'],
          (state) => [LiveLabelAttribute(state: state, key: Key(uuid.v4()))])
      ..add(
          ['selectedIcon'],
          (state) =>
              [LiveIconSelectedAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['Icon'], (state) => [LiveIcon(state: state, key: Key(uuid.v4()))])
      ..add(['Column'],
          (state) => [LiveColumn(state: state, key: Key(uuid.v4()))])
      ..add(['Row'], (state) => [LiveRow(state: state, key: Key(uuid.v4()))])
      ..add(['Flex'], (state) => [LiveFlex(state: state, key: Key(uuid.v4()))])
      ..add(
          ['PersistentFooterButton'],
          (state) =>
              [LivePersistentFooterButton(state: state, key: Key(uuid.v4()))])
      ..add(['BottomSheet'],
          (state) => [LiveBottomSheet(state: state, key: Key(uuid.v4()))])
      ..add(['Drawer'],
          (state) => [LiveDrawer(state: state, key: Key(uuid.v4()))])
      ..add(['EndDrawer'],
          (state) => [LiveEndDrawer(state: state, key: Key(uuid.v4()))])
      ..add(['DrawerHeader'],
          (state) => [LiveDrawerHeader(state: state, key: Key(uuid.v4()))])
      ..add(
          ['BottomNavigationBar'],
          (state) =>
              [LiveBottomNavigationBar(state: state, key: Key(uuid.v4()))])
      ..add(['BottomAppBar'],
          (state) => [LiveBottomAppBar(state: state, key: Key(uuid.v4()))])
      ..add(['DropdownButton'],
          (state) => [LiveDropdownButton(state: state, key: Key(uuid.v4()))])
      ..add(['BottomNavigationBarItem'], (state) => [const SizedBox.shrink()])
      ..add(['Positioned'],
          (state) => [LivePositioned(state: state, key: Key(uuid.v4()))])
      ..add(
          ['Stack'], (state) => [LiveStack(state: state, key: Key(uuid.v4()))])
      ..add(['NavigationRail'],
          (state) => [LiveNavigationRail(state: state, key: Key(uuid.v4()))])
      ..add(['NavigationRailDestination'], (state) => [const SizedBox.shrink()])
      ..add([
        'CachedNetworkImage'
      ], (state) => [LiveCachedNetworkImage(state: state, key: Key(uuid.v4()))])
      ..add(['Expanded'],
          (state) => [LiveExpanded(state: state, key: Key(uuid.v4()))])
      ..add(['FilledButton'],
          (state) => [LiveFilledButton(state: state, key: Key(uuid.v4()))])
      ..add(['viewBody'],
          (state) => [LiveViewBody(state: state, key: Key(uuid.v4()))])
      ..add(
          ['modal'], (state) => [LiveModal(state: state, key: Key(uuid.v4()))])
      // Those xml nodes are transparent and aren't rendered in the client
      // We just traverse them
      ..add(['compiled-lvn-stylesheet', 'div', 'flutter'], (state) {
        List<Widget> ret = [];
        for (var node in state.node.nonEmptyChildren) {
          ret.addAll(traverse(state.copyWith(node: node)));
        }
        return ret;
      })
      ..add(['Checkbox'],
          (state) => [LiveCheckbox(state: state, key: Key(uuid.v4()))])
      ..add(['SafeArea'],
          (state) => [LiveSafeArea(state: state, key: Key(uuid.v4()))])
      ..add(['SegmentedButton'],
          (state) => [LiveSegmentedButton(state: state, key: Key(uuid.v4()))])
      ..add(['LiveButtonSegment'], (state) => [const SizedBox.shrink()])
      ..add(
          ['FloatingActionButton'],
          (state) =>
              [LiveFloatingActionButton(state: state, key: Key(uuid.v4()))])
      ..add(['avatar'],
          (state) => [LiveAvatarAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['ActionChip'],
          (state) => [LiveActionChip(state: state, key: Key(uuid.v4()))])
      ..add(['content'],
          (state) => [LiveContentAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['MaterialBanner'],
          (state) => [LiveMaterialBanner(state: state, key: Key(uuid.v4()))])
      ..add(['TextButton'],
          (state) => [LiveTextButton(state: state, key: Key(uuid.v4()))])
      ..add(['Autocomplete'],
          (state) => [LiveAutocomplete(state: state, key: Key(uuid.v4()))])
      ..add(
          ['Badge'], (state) => [LiveBadge(state: state, key: Key(uuid.v4()))])
      ..add(['hint'],
          (state) => [LiveHintAttribute(state: state, key: Key(uuid.v4()))])
      ..add(
          ['disabledHint'],
          (state) =>
              [LiveDisabledHintAttribute(state: state, key: Key(uuid.v4()))])
      ..add([
        'underline'
      ], (state) => [LiveUnderlineAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['IconButton'],
          (state) => [LiveIconButton(state: state, key: Key(uuid.v4()))])
      ..add(['Card'], (state) => [LiveCard(state: state, key: Key(uuid.v4()))])
      ..add(['subtitle'],
          (state) => [LiveSubtitleAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['trailing'],
          (state) => [LiveTrailingAttribute(state: state, key: Key(uuid.v4()))])
      ..add(['ListTile'],
          (state) => [LiveListTile(state: state, key: Key(uuid.v4()))])
      ..add(['ScaffoldMessage'],
          (state) => [LiveScaffoldMessage(state: state, key: Key(uuid.v4()))])
      ..add(['meta', 'csrf-token', 'iframe'],
          (state) => [const SizedBox.shrink()])
      ..add(
          ['SingleChildScrollView'],
          (state) =>
              [LiveSingleChildScrollView(state: state, key: Key(uuid.v4()))])
      ..add(['SizedBox'],
          (state) => [LiveSizedBox(state: state, key: Key(uuid.v4()))]);
  }
}
