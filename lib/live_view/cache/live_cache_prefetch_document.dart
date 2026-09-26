import 'package:liveview_flutter/live_view/cache/live_cache_manifest_parser.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot_sanitizer.dart';
import 'package:xml/xml.dart';

class LiveCachePrefetchDocument {
  final LiveCacheManifestParser manifestParser;
  final LiveCacheSnapshotSanitizer sanitizer;

  const LiveCachePrefetchDocument({
    this.manifestParser = const LiveCacheManifestParser(),
    this.sanitizer = const LiveCacheSnapshotSanitizer(),
  });

  LiveCachePrefetchDocumentResult extract(
    String body, {
    required LiveCacheNamespace namespace,
  }) {
    XmlDocument document;
    try {
      var withoutDocumentChrome = body
          .replaceAll(RegExp(r'<!doctype[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<meta\b[^>]*>', caseSensitive: false), '');
      document = XmlDocument.parse(
        '<live-cache-prefetch-document>$withoutDocumentChrome'
        '</live-cache-prefetch-document>',
      );
    } on XmlParserException {
      return const LiveCachePrefetchDocumentResult.policyMissing();
    }

    XmlElement? manifestElement;
    XmlElement? root;
    for (var element in document.descendants.whereType<XmlElement>()) {
      if (manifestElement == null &&
          element.name.local == 'live-cache-manifest') {
        manifestElement = element;
      }
      if (root == null && element.getAttribute('data-phx-main') != null) {
        root = element;
      }
    }
    if (manifestElement == null || root == null) {
      return const LiveCachePrefetchDocumentResult.policyMissing();
    }
    var manifest = manifestParser.parse(manifestElement);
    if (manifest != null &&
        (manifest.scope != namespace.scope ||
            manifest.identity != namespace.identity)) {
      return const LiveCachePrefetchDocumentResult.sessionChanged();
    }
    if (manifest == null || manifest.version != namespace.manifestVersion) {
      return const LiveCachePrefetchDocumentResult.policyMissing();
    }

    root.removeAttribute('data-phx-session');
    root.removeAttribute('data-phx-static');
    root.removeAttribute('data-phx-main');
    root.removeAttribute('id');
    var secrets = root.descendants
        .whereType<XmlElement>()
        .where((element) => element.getAttribute('name') == '_csrf_token')
        .toList(growable: false);
    for (var secret in secrets) {
      secret.remove();
    }

    var rendered = <String, dynamic>{
      's': [root.toXmlString()],
    };
    var sanitized = sanitizer.sanitize(rendered);
    if (sanitized == null) {
      return const LiveCachePrefetchDocumentResult.unsafe();
    }
    return LiveCachePrefetchDocumentResult.rendered(sanitized);
  }
}

class LiveCachePrefetchDocumentResult {
  final Map<String, dynamic>? rendered;
  final bool policyConfirmed;
  final bool sessionChanged;

  const LiveCachePrefetchDocumentResult.rendered(
    Map<String, dynamic> this.rendered,
  ) : policyConfirmed = true,
      sessionChanged = false;

  const LiveCachePrefetchDocumentResult.unsafe()
    : rendered = null,
      policyConfirmed = true,
      sessionChanged = false;

  const LiveCachePrefetchDocumentResult.policyMissing()
    : rendered = null,
      policyConfirmed = false,
      sessionChanged = false;

  const LiveCachePrefetchDocumentResult.sessionChanged()
    : rendered = null,
      policyConfirmed = false,
      sessionChanged = true;
}
