import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_subtitle_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_trailing_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveListTile extends LiveStateWidget<LiveListTile> {
  const LiveListTile({super.key, required super.state});

  @override
  State<LiveListTile> createState() => _LiveListTileState();
}

class _LiveListTileState extends StateWidget<LiveListTile> {
  @override
  handleClickState() => HandleClickState.manual;

  final attributes = [
    'isThreeLine',
    'dense',
    'visualDensity',
    'shape',
    'selected',
    'iconColor',
    'textColor',
    'titleTextStyle',
    'subtitleTextStyle',
    'leadingAndTrailingTextStyle',
    'contentPadding',
    'enabled',
    'mouseCursor',
    'focusColor',
    'hoverColor',
    'splashColor',
    'autofocus',
    'tileColor',
    'selectedTileColor',
    'enabledFeedback',
    'horizontalTitleGap',
    'minVerticalPadding',
    'minLeadingWidth',
    'titleAlignment'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var title = StateChild.extractChild<LiveTitleAttribute>(children);
    var leading = StateChild.extractChild<LiveLeadingAttribute>(children);
    var subtitle = StateChild.extractChild<LiveSubtitleAttribute>(children);
    var trailing = StateChild.extractChild<LiveTrailingAttribute>(children);

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: booleanAttribute('isThreeLine') ?? false,
      dense: booleanAttribute('dense'),
      visualDensity: visualDensityAttribute('visualDensity'),
      shape: shapeBorderAttribute('shape'),
      style: null, // TODO: ListTileStyle
      selectedColor: colorAttribute(context, 'selected'),
      iconColor: colorAttribute(context, 'iconColor'),
      textColor: colorAttribute(context, 'textColor'),
      titleTextStyle: textStyleAttribute('titleTextStyle', context),
      subtitleTextStyle: textStyleAttribute('subtitleTextStyle', context),
      leadingAndTrailingTextStyle:
          textStyleAttribute('leadingAndTrailingTextStyle', context),
      contentPadding: marginOrPaddingAttribute('contentPadding'),
      enabled: booleanAttribute('enabled') ?? true,
      onTap: () => executeTapEventsManually(),
      onLongPress: null, // TODO: onLongPress
      onFocusChange: null, // TODO: onFocusChange
      mouseCursor: mouseCursorAttribute('mouseCursor'),
      focusColor: colorAttribute(context, 'focusColor'),
      hoverColor: colorAttribute(context, 'hoverColor'),
      splashColor: colorAttribute(context, 'splashColor'),
      focusNode: null, // TODO: FocusNode
      autofocus: booleanAttribute('autofocus') ?? false,
      tileColor: colorAttribute(context, 'tileColor'),
      selectedTileColor: colorAttribute(context, 'selectedTileColor'),
      enableFeedback: booleanAttribute('enabledFeedback'),
      horizontalTitleGap: doubleAttribute('horizontalTitleGap'),
      minVerticalPadding: doubleAttribute('minVerticalPadding'),
      minLeadingWidth: doubleAttribute('minLeadingWidth'),
      titleAlignment: listTileTitleAlignmentAttribute('titleAligment'),
    );
  }
}
