import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/persistent_live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'persistent factory enables the disk-backed cache coordinator',
    () async {
      SharedPreferences.setMockInitialValues({});

      var view = await LiveView.withPersistentCache();

      expect(view.cacheCoordinator, isNotNull);
      expect(view.cacheCoordinator?.store, isA<PersistentLiveViewCacheStore>());
    },
  );
}
