import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';

class LiveCacheNamespace {
  final String origin;
  final LiveCacheScope scope;
  final String? identity;
  final String manifestVersion;
  final String rendererVersion;
  final String locale;
  final String theme;

  const LiveCacheNamespace({
    required this.origin,
    required this.scope,
    required this.identity,
    required this.manifestVersion,
    required this.rendererVersion,
    required this.locale,
    required this.theme,
  });

  @override
  bool operator ==(Object other) =>
      other is LiveCacheNamespace &&
      origin == other.origin &&
      scope == other.scope &&
      identity == other.identity &&
      manifestVersion == other.manifestVersion &&
      rendererVersion == other.rendererVersion &&
      locale == other.locale &&
      theme == other.theme;

  @override
  int get hashCode => Object.hash(
    origin,
    scope,
    identity,
    manifestVersion,
    rendererVersion,
    locale,
    theme,
  );
}
