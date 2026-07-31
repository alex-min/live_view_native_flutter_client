import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A locale-aware currency amount display:
///
/// ```xml
/// <CurrencyAmount text="1 000,50 €" color="#F44336"
///                 style="textTheme: headlineMedium" />
/// ```
///
/// A thin wrapper around the Text mapping: the server formats the amount
/// per the user's locale and computes the color (red when negative); this
/// widget only renders the given [text] with a [color] merged into the
/// regular text style.
class LiveCurrencyAmount extends LiveStateWidget<LiveCurrencyAmount> {
  const LiveCurrencyAmount({super.key, required super.state});

  @override
  State<LiveCurrencyAmount> createState() => _LiveCurrencyAmountState();
}

class _LiveCurrencyAmountState extends StateWidget<LiveCurrencyAmount> {
  final attributes = ['text', 'color', 'style'];

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    var style = [
      if (getAttribute('color') case String color when color != '')
        'color: $color',
      if (getAttribute('style') case String extra when extra != '') extra,
    ].join('; ');

    return Text(
      HtmlUnescape().convert(getAttribute('text') ?? ''),
      style: getTextStyle(style == '' ? null : style, context),
    );
  }
}
