import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/alignment_directional.dart';
import 'package:liveview_flutter/live_view/mapping/axis_direction.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/box_height_style.dart';
import 'package:liveview_flutter/live_view/mapping/button_style.dart';
import 'package:liveview_flutter/live_view/mapping/clip_behavior.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/curve.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/drag_start_behavior.dart';
import 'package:liveview_flutter/live_view/mapping/duration.dart';
import 'package:liveview_flutter/live_view/mapping/floating_action_button_location.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/mapping/keyboard_type.dart';
import 'package:liveview_flutter/live_view/mapping/list_title_alignment.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/mapping/material_tap_target_size.dart';
import 'package:liveview_flutter/live_view/mapping/mouse_cursor.dart';
import 'package:liveview_flutter/live_view/mapping/navigation_rail_label_type.dart';
import 'package:liveview_flutter/live_view/mapping/notched_shape.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/mapping/options_view_open_direction.dart';
import 'package:liveview_flutter/live_view/mapping/overflow_bar_alignment.dart';
import 'package:liveview_flutter/live_view/mapping/scroll_view_keyboard_dismiss_behavior.dart';
import 'package:liveview_flutter/live_view/mapping/shape_border.dart';
import 'package:liveview_flutter/live_view/mapping/text_align.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:liveview_flutter/live_view/mapping/tooltip_trigger_mode.dart';
import 'package:liveview_flutter/live_view/mapping/visual_density.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';

mixin AttributeHelpers {
  String? getAttribute(String name);

  // attributes
  double? doubleAttribute(String attribute) =>
      getDouble(getAttribute(attribute));

  int? intAttribute(String attribute) => getInt(getAttribute(attribute));
  Color? colorAttribute(BuildContext context, String attribute) =>
      getColor(context, getAttribute(attribute));

  bool? booleanAttribute(String attribute) =>
      getBoolean(getAttribute(attribute));

  Decoration? decorationAttribute(BuildContext context, String attribute) =>
      getDecoration(context, getAttribute(attribute));

  EdgeInsetsGeometry? edgeInsetsAttribute(String attribute) =>
      getMarginOrPadding(getAttribute(attribute));

  Icon getIconAttribute(String attribute) =>
      Icon(getIcon(getAttribute(attribute)));

  NavigationRailLabelType? getNavigationRailLabelTypeAttribute(attribute) =>
      getNavigationRailLabelType(getAttribute(attribute));

  ButtonStyle? buttonStyleAttribute(BuildContext context, String attribute) =>
      getButtonStyle(context, getAttribute(attribute));

  TextInputType? textInputTypeAttribute(String attribute) =>
      getTextInputType(getAttribute(attribute));

  MouseCursor? mouseCursorAttribute(String attribute) =>
      getMouseCursor(getAttribute(attribute));
  Clip? clipAttribute(String attribute) => getClip(getAttribute(attribute));

  MaterialTapTargetSize? materialTapTargetSizeAttribute(String attribute) =>
      getMaterialTapTargetSize(getAttribute(attribute));

  ShapeBorder? shapeBorderAttribute(String attribute) =>
      getShapeBorder(getAttribute(attribute));

  Axis? axisAttribute(String attribute) => getAxis(getAttribute(attribute));

  EdgeInsets? marginOrPaddingAttribute(String attribute) =>
      getMarginOrPadding(getAttribute(attribute));

  DragStartBehavior? dragStartBehaviorAttribute(String attribute) =>
      getDragStartBehavior(getAttribute(attribute));

  ScrollViewKeyboardDismissBehavior? scrollViewKeyboardDismissBehaviorAttribute(
          String attribute) =>
      getScrollViewKeyboardDismissBehavior(getAttribute(attribute));

  Curve? curveAttribute(String attribute) => getCurve(getAttribute(attribute));

  TextStyle? textStyleAttribute(String attribute, BuildContext context) =>
      getTextStyle(getAttribute(attribute), context);

  VisualDensity? visualDensityAttribute(String attribute) =>
      getVisualDensity(getAttribute(attribute));

  TextAlign? textAlignAttribute(String attribute) =>
      getTextAlign(getAttribute(attribute));

  Duration? durationAttribute(String attribute) =>
      getDuration(getAttribute(attribute));

  TooltipTriggerMode? tooltipTriggerModeAttribute(String attribute) =>
      getTooltipTriggerMode(getAttribute(attribute));

  BoxHeightStyle? boxHeightStyleAttribute(String attribute) =>
      getBoxHeightStyle(getAttribute(attribute));

  OverflowBarAlignment? overflowBarAlignmentAttribute(String attribute) =>
      getOverflowBarAlignment(getAttribute(attribute));

  OptionsViewOpenDirection? optionsViewOpenDirectionAttribute(
          String attribute) =>
      getOptionsViewOpenDirection(getAttribute(attribute));

  FloatingActionButtonLocation? floatingActionButtonLocationAttributes(
          String attribute) =>
      getFloatingActionButtonLocation(getAttribute(attribute));

  NotchedShape? notchedShapeAttribute(String attribute) =>
      getNotchedShape(getAttribute(attribute));

  AlignmentDirectional? alignmentDirectionalAttribute(String attribute) =>
      getAlignmentDirectional(getAttribute(attribute));

  ListTileTitleAlignment? listTileTitleAlignmentAttribute(String attribute) =>
      getListTitleAligment(getAttribute(attribute));

  Text? textWidgetFromAttribute(String attribute) {
    var attr = getAttribute(attribute);
    if (attr == null) {
      return null;
    }
    return Text(attr);
  }

  Widget? textWidgetFromAttributeOrChild<T>(NodeState state, String attribute) {
    return textWidgetFromAttribute(attribute) ??
        StateChild.extractChild(StateChild.multipleChildren(state));
  }

  Icon? iconWidgetFromAttribute(String attribute) {
    var attr = getAttribute(attribute);
    if (attr == null) {
      return null;
    }
    return Icon(getIcon(attr));
  }
}
