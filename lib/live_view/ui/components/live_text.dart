import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/text_align.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:xml/xml.dart';

class LiveText extends LiveStateWidget<LiveText> {
  const LiveText({required super.state, Key? key}) : super(key: key);

  @override
  State<LiveText> createState() => _LiveViewTextState();
}

class _LiveViewTextState extends StateWidget<LiveText> {
  Map<String, dynamic> lastLiveDiff = {};

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['style', 'textAlign']);
    listenInnerTextKeys();
    lastLiveDiff = diff;
  }

  @override
  Widget render(BuildContext context) {
    var text = widget.state.node.innerText == ''
        ? widget.state.node.value ?? ''
        : widget.state.node.innerText;
    return Text(
      replaceVariables(text, lastLiveDiff),
      style: getTextStyle(getAttribute('style'), context),
      textAlign: getTextAlign(getAttribute('textAlign')),
    );
  }
}
