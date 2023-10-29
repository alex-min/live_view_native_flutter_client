import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveSegmentedButton extends LiveStateWidget<LiveSegmentedButton> {
  const LiveSegmentedButton({super.key, required super.state});

  @override
  State<LiveSegmentedButton> createState() => _LiveSegmentedButtonState();
}

class _LiveSegmentedButtonState extends StateWidget<LiveSegmentedButton> {
  bool allowSetInitialValue = true;

  @override
  HandleClickState handleClickState() => HandleClickState.manual;
  List<String> attributes = [
    'initialValue',
    'name',
    'style',
    'showSelectedIcon',
    'emptySelectionAllowed',
    'multiSelectionEnabled'
  ];

  var unamedInput = const Uuid().v4();
  Set<String>? selected;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      sendInitialFormState();
    });
    super.initState();
  }

  void sendInitialFormState() {
    reloadAttributes(node, attributes);
    FormFieldEvent(
      name: getAttribute('name') ?? "unamed-segmented-button-$unamedInput",
      data: getAttribute('initialValue'),
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  @override
  void onWipeState() {
    selected = null;
    allowSetInitialValue = true;
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    if (allowSetInitialValue) {
      var initialValue = getAttribute('initialValue');
      selected = initialValue == null ? <String>{} : <String>{initialValue};
      allowSetInitialValue = false;
    }
  }

  @override
  Widget render(BuildContext context) {
    var buttons = childrenNodesOf(node, 'ButtonSegment').map((button) {
      var attributes = bindChildVariableAttributes(
          button, ['label', 'name', 'icon'], widget.state.variables);
      Widget? label;
      Widget? icon;

      var children =
          StateChild.multipleChildren(widget.state.copyWith(node: button));
      if (attributes['icon'] != null) {
        icon = Icon(getIcon(attributes['icon']!));
      }
      if (attributes['label'] != null) {
        label = Text(attributes['label']!);
      }
      icon ??= StateChild.extractChild<LiveIcon>(children);
      label ??= StateChild.extractChild<LiveText>(children);

      return (
        attributes,
        ButtonSegment<String>(
            icon: icon,
            value: attributes['name'] ?? button.hashCode.toString(),
            label: label)
      );
    }).toList();

    var result = {
      for (var (attributes, button) in buttons)
        attributes['name'] ?? button.hashCode.toString(): (button, attributes)
    };

    return SegmentedButton<String>(
        showSelectedIcon: booleanAttribute('showSelectedIcon') ?? true,
        style: buttonStyleAttribute(context, 'style'),
        segments: result.values.map((b) => b.$1).toList(),
        emptySelectionAllowed:
            booleanAttribute('emptySelectionAllowed') ?? false,
        multiSelectionEnabled:
            booleanAttribute('multiSelectionEnabled') ?? false,
        onSelectionChanged: (tapped) {
          var oldSelection = selected;
          setState(() {
            selected = tapped;
          });

          // child item taped
          if (selected?.firstOrNull != null) {
            executeTapEventsManually(
                fromAttributes: result[selected?.firstOrNull]?.$2 ?? {});
            // untapping event
          } else if (booleanAttribute('multiSelectionEnabled') != true &&
              oldSelection?.firstOrNull != null) {
            executeTapEventsManually(
                fromAttributes: result[oldSelection?.firstOrNull]?.$2 ?? {});
          }

          // tapping itself
          executeTapEventsManually();

          // form change event
          FormFieldEvent(
            name:
                getAttribute('name') ?? "unamed-segmented-button-$unamedInput",
            data: booleanAttribute('multiSelectionEnabled') == true
                ? selected?.toList()
                : selected?.firstOrNull,
            type: FormFieldEventType.change,
          ).dispatch(context);
        },
        selected: selected ?? <String>{});
  }
}
