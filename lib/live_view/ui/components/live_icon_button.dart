import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_selected_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:uuid/uuid.dart';

class LiveIconButton extends LiveStateWidget<LiveIconButton> {
  const LiveIconButton({super.key, required super.state});

  @override
  State<LiveIconButton> createState() => _LiveIconButtonState();
}

class _LiveIconButtonState extends StateWidget<LiveIconButton> {
  var unamedInput = const Uuid().v4();

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'type',
      'name',
      'style',
      'autofocus',
      'icon',
      'padding',
      'splashRadius',
      'color',
      'focusColor',
      'hoverColor',
      'highlightColor',
      'splashColor',
      'disabledColor',
      'mouseCursor',
      'tooltip',
      'enableFeedback',
      'isSelected',
      'filled',
      'filledTonal'
    ]);
  }

  @override
  handleClickState() => HandleClickState.manual;

  @override
  Widget render(BuildContext context) {
    var child =
        StateChild.extractChild<LiveIconSelectedAttribute>(multipleChildren());

    if (booleanAttribute('filledTonal') == true) {
      return IconButton.filledTonal(
          padding: marginOrPaddingAttribute('padding'),
          alignment: alignmentDirectionalAttribute('alignment'),
          splashRadius: doubleAttribute('splashRadius'),
          color: colorAttribute(context, 'color'),
          focusColor: colorAttribute(context, 'focusColor'),
          hoverColor: colorAttribute(context, 'hoverColor'),
          highlightColor: colorAttribute(context, 'highlightColor'),
          splashColor: colorAttribute(context, 'splashColor'),
          disabledColor: colorAttribute(context, 'disabledColor'),
          icon: iconWidgetFromAttribute('icon') ?? const Icon(defaultIconData),
          style: buttonStyleAttribute(context, 'style'),
          autofocus: booleanAttribute('autofocus') ?? false,
          mouseCursor: mouseCursorAttribute('mouseCursor'),
          tooltip: getAttribute('tooltip'),
          enableFeedback: booleanAttribute('enableFeedback'),
          isSelected: booleanAttribute('isSelected'),
          selectedIcon: child,
          onPressed: () {
            if (getAttribute('type') == 'submit') {
              FormFieldEvent(
                      name: getAttribute('name') ??
                          'unamed-elevated-button-$unamedInput',
                      data: null,
                      type: FormFieldEventType.submit)
                  .dispatch(context);
            }
            executeTapEventsManually();
          });
    }

    if (booleanAttribute('filled') == true) {
      return IconButton.filled(
          padding: marginOrPaddingAttribute('padding'),
          alignment: alignmentDirectionalAttribute('alignment'),
          splashRadius: doubleAttribute('splashRadius'),
          color: colorAttribute(context, 'color'),
          focusColor: colorAttribute(context, 'focusColor'),
          hoverColor: colorAttribute(context, 'hoverColor'),
          highlightColor: colorAttribute(context, 'highlightColor'),
          splashColor: colorAttribute(context, 'splashColor'),
          disabledColor: colorAttribute(context, 'disabledColor'),
          icon: iconWidgetFromAttribute('icon') ?? const Icon(defaultIconData),
          style: buttonStyleAttribute(context, 'style'),
          autofocus: booleanAttribute('autofocus') ?? false,
          mouseCursor: mouseCursorAttribute('mouseCursor'),
          tooltip: getAttribute('tooltip'),
          enableFeedback: booleanAttribute('enableFeedback'),
          isSelected: booleanAttribute('isSelected'),
          selectedIcon: child,
          onPressed: () {
            if (getAttribute('type') == 'submit') {
              FormFieldEvent(
                      name: getAttribute('name') ??
                          'unamed-elevated-button-$unamedInput',
                      data: null,
                      type: FormFieldEventType.submit)
                  .dispatch(context);
            }
            executeTapEventsManually();
          });
    }

    return IconButton(
        padding: marginOrPaddingAttribute('padding'),
        alignment: alignmentDirectionalAttribute('alignment'),
        splashRadius: doubleAttribute('splashRadius'),
        color: colorAttribute(context, 'color'),
        focusColor: colorAttribute(context, 'focusColor'),
        hoverColor: colorAttribute(context, 'hoverColor'),
        highlightColor: colorAttribute(context, 'highlightColor'),
        splashColor: colorAttribute(context, 'splashColor'),
        disabledColor: colorAttribute(context, 'disabledColor'),
        icon: iconWidgetFromAttribute('icon') ?? const Icon(defaultIconData),
        style: buttonStyleAttribute(context, 'style'),
        autofocus: booleanAttribute('autofocus') ?? false,
        mouseCursor: mouseCursorAttribute('mouseCursor'),
        tooltip: getAttribute('tooltip'),
        enableFeedback: booleanAttribute('enableFeedback'),
        isSelected: booleanAttribute('isSelected'),
        selectedIcon: child,
        onPressed: () {
          if (getAttribute('type') == 'submit') {
            FormFieldEvent(
                    name: getAttribute('name') ??
                        'unamed-elevated-button-$unamedInput',
                    data: null,
                    type: FormFieldEventType.submit)
                .dispatch(context);
          }
          executeTapEventsManually();
        });
  }
}
