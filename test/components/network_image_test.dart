import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('Image resolves relative src against the live view origin',
      (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <viewBody>
              <Image src="/images/logo.png" width="64" height="64" />
            </viewBody>
          </flutter>
        """
      ]
    });

    await tester.runLiveView(view);
    await tester.pump();

    var image = find.byType(CachedNetworkImage).evaluate().first.widget
        as CachedNetworkImage;

    expect(image.imageUrl, 'http://localhost:9999/images/logo.png');
    expect(image.width, 64);
    expect(image.height, 64);
  });

  testWidgets('Image keeps absolute src unchanged', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <viewBody>
              <Image imageUrl="https://example.com/icon.png" />
            </viewBody>
          </flutter>
        """
      ]
    });

    await tester.runLiveView(view);
    await tester.pump();

    var image = find.byType(CachedNetworkImage).evaluate().first.widget
        as CachedNetworkImage;

    expect(image.imageUrl, 'https://example.com/icon.png');
  });
}
