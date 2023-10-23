import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveCachedNetworkImage extends LiveStateWidget<LiveCachedNetworkImage> {
  const LiveCachedNetworkImage({super.key, required super.state});

  @override
  State<LiveCachedNetworkImage> createState() => _LiveCachedNetworkImageState();
}

class _LiveCachedNetworkImageState extends StateWidget<LiveCachedNetworkImage> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['imageUrl', 'width', 'height']);
  }

  @override
  Widget render(BuildContext context) {
    var url = getAttribute('imageUrl')!;
    if (!url.startsWith('http')) {
      url = '${liveView.endpointScheme}://${liveView.host}/$url';
    }

    return CachedNetworkImage(
        placeholder: (context, url) => const CircularProgressIndicator(),
        imageUrl: url,
        width: doubleAttribute('width'),
        height: doubleAttribute('height'));
  }
}
