import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A fixed logical canvas scaled to available width, retaining its aspect ratio.
/// Optional fonts is a JSON family -> server URL map; loaded once per URL.
class LiveScaledBox extends LiveStateWidget<LiveScaledBox> {
  const LiveScaledBox({super.key, required super.state});
  @override
  State<LiveScaledBox> createState() => _ScaledBoxState();
}

class _ScaledBoxState extends StateWidget<LiveScaledBox> {
  static final Map<String, Future<void>> _fonts = {};
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'width',
      'height',
      'fonts',
      'style',
      'borderRadius',
    ]);
    final sources = jsonDecode(getAttribute('fonts') ?? '{}') as Map;
    for (final entry in sources.entries) {
      final url = Uri.parse(
        '${liveView.endpointScheme}://${liveView.host}',
      ).resolve(entry.value as String);
      final key = '${entry.key}:$url';
      _fonts
          .putIfAbsent(key, () async {
            final response = await http.get(url);
            if (response.statusCode != 200) {
              throw StateError('Font request failed');
            }
            final loader = FontLoader(entry.key as String);
            loader.addFont(
              Future.value(ByteData.sublistView(response.bodyBytes)),
            );
            await loader.load();
          })
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object _) {
            _fonts.remove(key);
          });
    }
  }

  @override
  Widget render(BuildContext context) {
    final width = doubleAttribute('width') ?? 100;
    final height = doubleAttribute('height') ?? 100;
    return AspectRatio(
      aspectRatio: width / height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              doubleAttribute('borderRadius') ?? 0,
            ),
            child: DefaultTextStyle.merge(
              style: getTextStyle(getAttribute('style'), context),
              child: singleChild(),
            ),
          ),
        ),
      ),
    );
  }
}
