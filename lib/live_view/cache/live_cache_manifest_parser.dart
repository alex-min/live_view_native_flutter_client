import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:xml/xml.dart';

class LiveCacheManifestParser {
  const LiveCacheManifestParser();

  LiveCacheManifest? parse(XmlElement element) {
    if (element.name.local != 'live-cache-manifest') {
      return null;
    }

    var version = element.getAttribute('version')?.trim();
    var scope = _parseScope(element.getAttribute('scope'));
    var identity = element.getAttribute('identity')?.trim();
    var strategy = _parseStrategy(element.getAttribute('strategy'));

    if (version == null ||
        version.isEmpty ||
        scope == null ||
        strategy == null ||
        (scope == LiveCacheScope.user &&
            (identity == null || identity.isEmpty))) {
      return null;
    }

    var routeElements = element.childElements.toList();
    if (routeElements.length > LiveCacheManifest.maximumRouteCount ||
        routeElements.any((child) => child.name.local != 'live-cache-route')) {
      return null;
    }

    var routes = <LiveCacheRoute>[];
    var routeKeys = <String>{};
    for (var routeElement in routeElements) {
      var route = _parseRoute(routeElement);
      if (route == null || !routeKeys.add(route.href.toString())) {
        return null;
      }
      routes.add(route);
    }

    return LiveCacheManifest(
      version: version,
      scope: scope,
      identity: identity?.isEmpty == true ? null : identity,
      strategy: strategy,
      routes: List.unmodifiable(routes),
    );
  }

  LiveCacheScope? _parseScope(String? value) {
    return switch (value) {
      'public' => LiveCacheScope.public,
      'user' => LiveCacheScope.user,
      'memory' => LiveCacheScope.memory,
      _ => null,
    };
  }

  LiveCacheStrategy? _parseStrategy(String? value) {
    return switch (value) {
      'stale-while-revalidate' => LiveCacheStrategy.staleWhileRevalidate,
      _ => null,
    };
  }

  LiveCacheRoute? _parseRoute(XmlElement element) {
    var hrefValue = element.getAttribute('href')?.trim();
    var maxAgeValue = element.getAttribute('max-age');
    var priorityValue = element.getAttribute('priority') ?? 'normal';
    var href = hrefValue == null ? null : Uri.tryParse(hrefValue);
    var maxAge = int.tryParse(maxAgeValue ?? '');
    var priority = switch (priorityValue) {
      'normal' => LiveCachePriority.normal,
      'high' => LiveCachePriority.high,
      _ => null,
    };

    if (href == null ||
        !_isSafeRelativeRoute(hrefValue!, href) ||
        maxAge == null ||
        maxAge <= 0 ||
        priority == null) {
      return null;
    }

    return LiveCacheRoute(
      href: href,
      maxAge: Duration(seconds: maxAge),
      priority: priority,
    );
  }

  bool _isSafeRelativeRoute(String source, Uri href) {
    return source.startsWith('/') &&
        !source.startsWith('//') &&
        !href.hasScheme &&
        !href.hasAuthority &&
        !href.hasFragment &&
        href.path.startsWith('/');
  }
}
