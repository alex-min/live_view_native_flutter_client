import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_content_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveMaterialBanner extends LiveStateWidget<LiveMaterialBanner> {
  const LiveMaterialBanner({super.key, required super.state});

  @override
  State<LiveMaterialBanner> createState() => _LiveMaterialBannerState();
}

class _LiveMaterialBannerState extends StateWidget<LiveMaterialBanner> {
  final attributes = [
    'content',
    'contentTextStyle',
    'elevation',
    'leading',
    'backgroundColor',
    'surfaceTintColor',
    'shadowColor',
    'dividerColor',
    'padding',
    'margin',
    'leadingPadding',
    'forceActionsBelow',
    'overflowAlignment'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    Widget? content = StateChild.extractChild<LiveContentAttribute>(children);
    content ??= StateChild.extractChild<LiveText>(children);
    content ??= textWidgetFromAttribute('content');
    content ??= const Text('');

    Widget? leading = StateChild.extractChild<LiveLeadingAttribute>(children);
    leading ??= iconWidgetFromAttribute('leading');

    return MaterialBanner(
        content: content,
        actions: children,
        leading: leading,
        contentTextStyle: textStyleAttribute('contentTextStyle', context),
        elevation: doubleAttribute('elevation'),
        backgroundColor: colorAttribute(context, 'backgroundColor'),
        surfaceTintColor: colorAttribute(context, 'surfaceTintColor'),
        shadowColor: colorAttribute(context, 'shadowColor'),
        dividerColor: colorAttribute(context, 'dividerColor'),
        padding: marginOrPaddingAttribute('padding'),
        margin: marginOrPaddingAttribute('margin'),
        leadingPadding: marginOrPaddingAttribute('leadingPadding'),
        forceActionsBelow: booleanAttribute('forceActionsBelow') ?? false,
        overflowAlignment: overflowBarAlignmentAttribute('overflowAlignment') ??
            OverflowBarAlignment.end,
        onVisible: null // TODO: onVisible
        );
  }
}
