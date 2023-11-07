import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveFloatingActionButton
    extends LiveStateWidget<LiveFloatingActionButton> {
  const LiveFloatingActionButton({super.key, required super.state});

  @override
  State<LiveFloatingActionButton> createState() =>
      _LiveFloatingActionButtonState();
}

class _LiveFloatingActionButtonState
    extends StateWidget<LiveFloatingActionButton> {
  final attributes = [
    'foregroundColor',
    'backgroundColor',
    'focusColor',
    'hoverColor',
    'splashColor',
    'elevation',
    'focusElevation',
    'highlightElevation',
    'disabledElevation',
    'mouseCursor',
    'mini',
    'clipBehavior',
    'autofocus',
    'materialTapTargetSize',
    'enableFeedback',
    'shape',
    'isExtended',
    'icon',
  ];
  @override
  handleClickState() => HandleClickState.manual;

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    if (booleanAttribute('isExtended') == true) {
      String? textLabel = getAttribute('label');
      String? iconLabel = getAttribute('icon');

      Widget? label =
          StateChild.extractChild<LiveLabelAttribute>(multipleChildren());
      label ??= StateChild.extractChild<LiveText>(multipleChildren());
      if (textLabel != null && label == null) {
        label ??= Text(textLabel);
      }
      label ??= const Text('');

      Widget? icon =
          StateChild.extractChild<LiveIconAttribute>(multipleChildren());
      icon ??= StateChild.extractChild<LiveIcon>(multipleChildren());
      if (iconLabel != null && icon == null) {
        icon ??= Icon(getIcon(iconLabel));
      }

      return FloatingActionButton.extended(
        label: label,
        icon: icon,
        backgroundColor: colorAttribute(context, 'backgroundColor'),
        foregroundColor: colorAttribute(context, 'foregroundColor'),
        focusColor: colorAttribute(context, 'focusColor'),
        hoverColor: colorAttribute(context, 'hoverColor'),
        splashColor: colorAttribute(context, 'splashColor'),
        elevation: doubleAttribute('elevation'),
        focusElevation: doubleAttribute('focusElevation'),
        hoverElevation: doubleAttribute('hoverElevation'),
        highlightElevation: doubleAttribute('highlightElevation'),
        disabledElevation: doubleAttribute('disabledElevation'),
        mouseCursor: mouseCursorAttribute('mouseCursor'),
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
        autofocus: booleanAttribute('autofocus') ?? false,
        materialTapTargetSize:
            materialTapTargetSizeAttribute('materialTapTargetSize'),
        isExtended: true,
        enableFeedback: booleanAttribute('enableFeedback'),
        onPressed: () {
          executeTapEventsManually();
        },
        shape: shapeBorderAttribute('shape'),
      );
    }
    return FloatingActionButton(
      backgroundColor: colorAttribute(context, 'backgroundColor'),
      foregroundColor: colorAttribute(context, 'foregroundColor'),
      focusColor: colorAttribute(context, 'focusColor'),
      hoverColor: colorAttribute(context, 'hoverColor'),
      splashColor: colorAttribute(context, 'splashColor'),
      elevation: doubleAttribute('elevation'),
      focusElevation: doubleAttribute('focusElevation'),
      hoverElevation: doubleAttribute('hoverElevation'),
      highlightElevation: doubleAttribute('highlightElevation'),
      disabledElevation: doubleAttribute('disabledElevation'),
      mouseCursor: mouseCursorAttribute('mouseCursor'),
      mini: booleanAttribute('mini') ?? false,
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
      autofocus: booleanAttribute('autofocus') ?? false,
      materialTapTargetSize:
          materialTapTargetSizeAttribute('materialTapTargetSize'),
      isExtended: false,
      enableFeedback: booleanAttribute('enableFeedback'),
      onPressed: () {
        executeTapEventsManually();
      },
      shape: shapeBorderAttribute('shape'),
      child: singleChild(),
    );
  }
}
