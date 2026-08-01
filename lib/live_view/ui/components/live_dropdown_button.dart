import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/alignment_directional.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/ui/components/live_disabled_hint_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_hint_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_underline_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class LiveDropdownButton extends LiveStateWidget<LiveDropdownButton> {
  const LiveDropdownButton({super.key, required super.state});

  @override
  State<LiveDropdownButton> createState() => _LiveDropdownButtonState();
}

class _LiveDropdownButtonState extends StateWidget<LiveDropdownButton> {
  final attributes = [
    'name',
    'initialValue',
    'hint',
    'disabledHint',
    'elevation',
    'style',
    'underline',
    'icon',
    'iconDisabledColor',
    'iconEnabledColor',
    'iconSize',
    'isDense',
    'isExpanded',
    'itemHeight',
    'focusColor',
    'autofocus',
    'dropdownColor',
    'menuMaxHeight',
    'enableFeedback',
    'padding',
  ];
  final childAttributes = ['label', 'value', 'enabled', 'alignment'];
  @override
  handleClickState() => HandleClickState.manual;

  var unamedInput = const Uuid().v4();
  String? initialValue;

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  void onFormInitialize() {
    FormFieldEvent(
      name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
      data: getAttribute('initialValue'),
      type: FormFieldEventType.initField,
    ).dispatch(context);
    initialValue = getAttribute('initialValue');
  }

  @override
  Widget render(BuildContext context) {
    Map<String?, Map<String, String?>> attributesMapping = {};
    var countNoValue = 0;
    var buttons =
        dropdownItemNodes().map((button) {
          var attributes = bindChildVariableAttributes(
            button,
            childAttributes,
            widget.state.variables,
          );
          Widget? child =
              attributes['label'] != null ? Text(attributes['label']!) : null;

          if (attributes['value'] == null) {
            countNoValue++;
          }

          child ??= singleChild(state: widget.state.copyWith(node: button));

          attributesMapping[attributes['value']] = attributes;

          return DropdownMenuItem<String>(
            value: attributes['value'],
            enabled: getBoolean(attributes['enabled']) ?? true,
            alignment:
                getAlignmentDirectional(attributes['alignment']) ??
                AlignmentDirectional.centerStart,
            child: child,
          );
        }).toList();

    if (countNoValue > 1) {
      throw Exception(
        "They are $countNoValue items in <DropdownButton> without any value, flutter only allows one since its picked up as a default",
      );
    }

    Widget? hint = textWidgetFromAttributeOrChild<LiveHintAttribute>(
      widget.state,
      'hint',
    );
    Widget? disabledHint =
        textWidgetFromAttributeOrChild<LiveDisabledHintAttribute>(
          widget.state,
          'disabledHint',
        );
    Widget? underline = textWidgetFromAttributeOrChild<LiveUnderlineAttribute>(
      widget.state,
      'underline',
    );
    Widget? icon = textWidgetFromAttributeOrChild<LiveIconAttribute>(
      widget.state,
      'icon',
    );

    return DropdownButton(
      items: buttons,
      value: initialValue,
      hint: hint,
      disabledHint: disabledHint,
      icon: icon,
      iconDisabledColor: colorAttribute(context, 'iconDisabledColor'),
      iconEnabledColor: colorAttribute(context, 'iconEnabledColor'),
      iconSize: doubleAttribute('iconSize') ?? 24.0,
      isDense: booleanAttribute('isDense') ?? false,
      isExpanded: booleanAttribute('isExpanded') ?? false,
      onTap: () => executeTapEventsManually(),
      elevation: intAttribute('elevation') ?? 8,
      style: textStyleAttribute('style', context),
      itemHeight: doubleAttribute('itemHeight') ?? kMinInteractiveDimension,
      focusNode: null, // TODO: FocusNode
      focusColor: colorAttribute(context, 'focusColor'),
      autofocus: booleanAttribute('autofocus') ?? false,
      dropdownColor: colorAttribute(context, 'dropdownColor'),
      menuMaxHeight: doubleAttribute('menuMaxHeight'),
      enableFeedback: booleanAttribute('enableFeedback'),
      borderRadius: null, // TODO: BorderRadius
      padding: marginOrPaddingAttribute('padding'),
      underline: underline,
      onChanged: (value) {
        setState(() => initialValue = value);
        FormFieldEvent(
          name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
          data: value,
          type: FormFieldEventType.change,
        ).dispatch(context);

        // children
        if (attributesMapping[value] != null) {
          executeTapEventsManually(fromAttributes: attributesMapping[value]);
        }
      },
    );
  }

  /// Static <DropdownMenuItem> children plus items generated by a
  /// comprehension (`<%= for ... %>`). Comprehensions land in the node tree
  /// as text placeholders holding `[[flutterState key=N]]`; their items live
  /// in the state variables, so we rebuild each item's XML from the statics
  /// ('s') and the per-entry dynamics ('0', '1', ...) and parse it.
  List<XmlNode> dropdownItemNodes() {
    var items = childrenNodesOf(node, 'DropdownMenuItem').toList();

    for (var child in node.children.whereType<XmlText>()) {
      for (var elementKey in extractDynamicKeys(child.value ?? '')) {
        var vars = widget.state.variables[elementKey.key];
        if (vars is! Map || vars['s'] is! List || vars['d'] is! List) {
          continue;
        }
        var statics = List<String>.from(vars['s']);
        if (statics.isEmpty) {
          continue;
        }
        for (var i = 0; i < (vars['d'] as List).length; i++) {
          var entry = vars[i.toString()];
          if (entry is! Map) {
            continue;
          }
          // Dynamic fragments are already valid XML as sent by the server
          // (e.g. ` label="Bonus"`), insert them verbatim.
          var xml = StringBuffer(statics.first);
          for (var j = 1; j < statics.length; j++) {
            xml.write('${entry[(j - 1).toString()] ?? ''}');
            xml.write(statics[j]);
          }
          try {
            var item = XmlDocument.parse(xml.toString()).rootElement;
            if (item.name.qualified == 'DropdownMenuItem') {
              items.add(item);
            }
          } on XmlParserException {
            // ignore malformed dynamic content
          }
        }
      }
    }
    return items;
  }
}
