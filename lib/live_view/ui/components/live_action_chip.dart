import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_avatar_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveActionChip extends LiveStateWidget<LiveActionChip> {
  const LiveActionChip({super.key, required super.state});

  @override
  State<LiveActionChip> createState() => _LiveActionChipState();
}

class _LiveActionChipState extends StateWidget<LiveActionChip> {
  @override
  handleClickState() => HandleClickState.manual;

  final attributes = [
    'label',
    'icon',
    'labelStyle',
    'labelPadding',
    'pressElevation',
    'tooltip',
    'clipBehavior',
    'autofocus',
    'backgroundColor',
    'disabledColor',
    'padding',
    'visualDensity',
    'materialTapTargetSize',
    'elevation',
    'shadowColor',
    'surfaceTintColor'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    Widget? label = StateChild.extractChild<LiveLabelAttribute>(children);
    label ??= StateChild.extractChild<LiveText>(children);
    label ??= textWidgetFromAttribute('label');
    label ??= const Text('');

    Widget? avatar = StateChild.extractChild<LiveAvatarAttribute>(children);
    avatar ??= StateChild.extractChild<LiveIcon>(children);
    avatar ??= iconWidgetFromAttribute('icon');

    return ActionChip(
        label: label,
        avatar: avatar,
        labelStyle: textStyleAttribute('labelStyle', context),
        labelPadding: marginOrPaddingAttribute('labelPadding'),
        pressElevation: doubleAttribute('pressElevation'),
        tooltip: getAttribute('tooltip'),
        side: null, // TODO: BorderSide
        shape: null, //TODO: OutlinedBorder
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
        focusNode: null, // TODO: FocusNode
        autofocus: booleanAttribute('autofocus') ?? false,
        color: null, //TODO: MaterialStateProperty<Color?>?
        backgroundColor: colorAttribute(context, 'backgroundColor'),
        disabledColor: colorAttribute(context, 'disabledColor'),
        padding: marginOrPaddingAttribute('padding'),
        visualDensity: visualDensityAttribute('visualDensity'),
        materialTapTargetSize:
            materialTapTargetSizeAttribute('materialTapTargetSize'),
        elevation: doubleAttribute('elevation'),
        shadowColor: colorAttribute(context, 'shadowColor'),
        surfaceTintColor: colorAttribute(context, 'surfaceTintColor'),
        iconTheme: null, //TODO: IconThemeData
        onPressed: () => executeTapEventsManually());
  }
}
