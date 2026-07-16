import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:xml/xml.dart';

/// Renders a small subset of HTML markup using `flutter_widget_from_html`.
///
/// This is intended for trusted content such as terms of service, where the
/// server sends raw HTML that would otherwise be stripped down to a single
/// plain text line.
///
/// Supported formatting includes headings, paragraphs, lists, bold/italic/
/// underline, and basic links.
class LiveHtmlView extends LiveStateWidget<LiveHtmlView> {
  const LiveHtmlView({required super.state, Key? key}) : super(key: key);

  @override
  State<LiveHtmlView> createState() => _LiveHtmlViewState();
}

class _LiveHtmlViewState extends StateWidget<LiveHtmlView> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['style', 'textAlign']);
    listenInnerTextKeys();
  }

  @override
  Widget render(BuildContext context) {
    var html = widget.state.node.innerText == ''
        ? widget.state.node.value ?? ''
        : widget.state.node.innerText;

    html = HtmlUnescape()
        .convert(replaceVariables(html, currentVariables))
        .trim();

    if (html.isEmpty) {
      return const SizedBox.shrink();
    }

    return HtmlWidget(
      html,
      textStyle: getTextStyle(getAttribute('style'), context),
    );
  }
}
