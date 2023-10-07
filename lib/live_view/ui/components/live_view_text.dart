import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveViewText extends LiveStateWidget<LiveTextField> {
  const LiveViewText({required super.state, Key? key}) : super(key: key);

  @override
  State<LiveViewText> createState() => _LiveViewTextState();
}

class _LiveViewTextState extends StateWidget<LiveViewText> {
  Map<String, dynamic> lastLiveDiff = {};

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(['style']);
    listenInnerTextKeys();
    lastLiveDiff = diff;
  }

  @override
  Widget render(BuildContext context) {
    return Text(
      replaceVariables(widget.state.node.text, lastLiveDiff),
      style: textStyle(getAttribute('style'), context),
    );
  }
}
