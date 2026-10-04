import 'dart:async';

import 'package:event_hub/event_hub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:http_query_string/http_query_string.dart' as qs;
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/exec/mount_exec_tracker.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest_parser.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_prefetch_document.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_coordinator.dart';
import 'package:liveview_flutter/live_view/cache/persistent_live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/live_view_fallback_pages.dart';
import 'package:liveview_flutter/live_view/plugin.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/live_go_back_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/routes/live_router_delegate.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_footer_button.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_view.dart';
import 'package:liveview_flutter/live_view/webdocs.dart';
import 'package:liveview_flutter/platform_name.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:universal_html/html.dart" as web_html;
import 'package:uuid/uuid.dart';

import './ui/live_view_ui_parser.dart';
import 'http_client_factory.dart'
    if (dart.library.html) 'http_client_factory_html.dart'
    if (dart.library.io) 'http_client_factory_io.dart'
    as http_client_factory;
import 'web_socket_channel_factory.dart'
    if (dart.library.html) 'web_socket_channel_factory_html.dart'
    if (dart.library.io) 'web_socket_channel_factory_io.dart'
    as web_socket;

enum ViewType { deadView, liveView, cached }

class LiveSocket {
  PhoenixSocket create({
    required String url,
    required Map<String, dynamic> params,
    required Map<String, String> headers,
  }) {
    return PhoenixSocket(
      url,
      webSocketChannelFactory: (uri) {
        final queryParams = qs.Decoder().convert(uri.query).entries.toList();
        queryParams.addAll(params.entries.toList());
        final query = qs.Encoder().convert(Map.fromEntries(queryParams));
        final newUri = uri.replace(query: query).toString();

        return web_socket.connect(newUri, headers: headers);
      },
      socketOptions: PhoenixSocketOptions(
        reconnectDelays: const [
          Duration.zero,
          Duration(milliseconds: 1000),
          Duration(milliseconds: 2000),
          Duration(milliseconds: 4000),
          Duration(milliseconds: 8000),
        ],
      ),
    );
  }
}

enum ClientType { liveView, httpOnly, webDocs }

class LiveView {
  static const cacheRendererVersion = '1';

  static Future<LiveView> withPersistentCache({
    LiveViewFallbackPages fallbackPages = const LiveViewFallbackPages(),
    http.Client Function()? httpClientFactory,
    void Function(ViewType)? onViewTypeRendered,
  }) async => LiveView(
    fallbackPages: fallbackPages,
    cacheCoordinator: LiveViewCacheCoordinator(
      store: await PersistentLiveViewCacheStore.create(),
    ),
    httpClientFactory: httpClientFactory,
    onViewTypeRendered: onViewTypeRendered,
  );

  final List<Plugin> _installedPlugins = [];
  bool catchExceptions = true;
  bool disableAnimations = false;
  ClientType clientType = ClientType.liveView;

  late http.Client httpClient;
  late final http.Client _initialHttpClient;
  final http.Client Function() _httpClientFactory;
  var liveSocket = LiveSocket();

  Widget? onErrorWidget;
  late LiveRootView rootView;
  String? _csrf;
  late String host;
  late String _clientId;
  late String? _session;
  late String? _phxStatic;
  late String _liveViewId;
  late String currentUrl;
  String? cookie;
  late String endpointScheme;
  int mount = 0;
  EventHub eventHub = EventHub();
  bool isLiveReloading = false;

  // Widgets marked persistent="true" are skipped by the parser and hoisted
  // here instead; RootScaffold renders them above the page body so they
  // survive page navigation like the bottom navigation bar. Presence is
  // driven by the current page: [persistentChromeDeclared] is reset on every
  // real page change and set by the parser whenever a persistent widget is
  // rendered, so the chrome is dropped only when a page stops declaring it.
  // While present, the first parsed instance is kept as-is so a push never
  // rebuilds it.
  List<Widget> persistentChrome = [];
  bool persistentChromeDeclared = false;

  /// Whether the current page's body rendered since it became current. The
  /// persistent chrome is only dropped when the current page rendered
  /// without declaring one — an interrupted navigation (a new live-patch
  /// before the arriving page's first render) must not drop it.
  bool persistentChromePageRendered = false;

  String? redirectToUrl;

  PhoenixSocket? _socket;
  late PhoenixSocket _liveReloadSocket;

  PhoenixChannel? _channel;
  StreamSubscription<Message>? _channelMessageSubscription;
  String? _channelUrl;
  String? _renderedUrl;
  ViewType? _renderedViewType;
  LiveCacheSnapshot? _pendingCachedSnapshot;
  bool _replaceWithPendingCachedSnapshot = false;
  final List<(String, ExecLiveEvent)> _cachedRenderEvents = [];
  int _navigationGeneration = 0;
  Push? _pendingLeavePush;
  bool _isJoiningChannel = false;

  List<Widget>? lastRender;

  /// Whether the current URL's channel has joined and its full render has
  /// replaced the loading/previous route.
  ///
  /// A URL changes before asynchronous LiveView navigation finishes. Tests
  /// and clients that need to sequence navigation must wait for this signal,
  /// rather than treating [currentUrl] alone as proof that the route is ready.
  bool get isCurrentRouteReady =>
      _channel?.state == PhoenixChannelState.joined &&
      _channelUrl == currentUrl &&
      _renderedUrl == currentUrl &&
      _renderedViewType == ViewType.liveView &&
      redirectToUrl == null;

  bool get isShowingCachedRender => _renderedViewType == ViewType.cached;

  // dynamic global state
  late StateNotifier changeNotifier;
  late LiveConnectionNotifier connectionNotifier;
  late ThemeSettings themeSettings;
  LiveGoBackNotifier goBackNotifier = LiveGoBackNotifier();

  /// Deduplicates `onMount` exec firings across rebuilds and diffs.
  final MountExecTracker mountTracker = MountExecTracker();
  bool _isGoingBack = false;
  late LiveRouterDelegate router;
  bool throttleSpammyCalls = true;
  LiveCacheManifest? cacheManifest;
  final LiveViewCacheCoordinator? cacheCoordinator;
  final void Function(ViewType)? onViewTypeRendered;
  int _cacheRenderGeneration = 0;
  bool _resetHistoryOnNextRender = false;
  Future<int> _cachePrefetchComplete = Future<int>.value(0);

  Future<int> get cachePrefetchComplete => _cachePrefetchComplete;

  // Tracks the last phx-trigger-action value per form so that offstage forms
  // (which are rebuilt and lose their local state) don't re-submit when the
  // action attribute is still "true" on a previous route.
  final Map<String, String> _lastFormTriggerActions = {};

  // Scroll offsets for server-rendered lists that opt into restoration. Keep
  // this on the LiveView instance so navigating away can replace a route
  // without losing the list's position.
  final Map<String, double> _scrollOffsets = {};

  /// Typed form values per page, kept on the LiveView instance so they
  /// survive the widget rebuilds server diffs trigger (each rebuild
  /// re-parses the form subtree into fresh widget instances).
  final Map<String, Map<String, dynamic>> _formValues = {};

  Map<String, dynamic>? formValuesFor(String urlPath) => _formValues[urlPath];

  /// Field names currently backed by a mounted form, per page. Server renders
  /// rebuild form subtrees into fresh widget instances before the old form is
  /// unmounted, so a form being recreated registers its fields before the
  /// previous instance unregisters them; only when the last instance of a
  /// field is gone (form actually closed) is the remembered value dropped.
  final Map<String, Map<String, int>> _liveFormFields = {};

  void registerLiveFormField(String urlPath, String name) {
    final page = _liveFormFields.putIfAbsent(urlPath, () => {});
    page[name] = (page[name] ?? 0) + 1;
  }

  void unregisterLiveFormField(String urlPath, String name) {
    final page = _liveFormFields[urlPath];
    if (page == null) {
      return;
    }
    final count = (page[name] ?? 0) - 1;
    if (count > 0) {
      page[name] = count;
      return;
    }
    page.remove(name);
    // The last form holding this field left the tree: drop the remembered
    // value so a form reopened later starts from server-rendered values
    // instead of resurrecting stale input.
    _formValues[urlPath]?.remove(name);
  }

  void rememberFormValue(String urlPath, String name, dynamic value) {
    _formValues.putIfAbsent(urlPath, () => {})[name] = value;
  }

  void forgetFormValue(String urlPath, String name) {
    _formValues[urlPath]?.remove(name);
  }

  void forgetFormValues(String urlPath) {
    _formValues.remove(urlPath);
  }

  String _scrollOffsetKey(String urlPath, String restorationId) =>
      '$urlPath|$restorationId';

  double? restoredScrollOffset(String urlPath, String restorationId) =>
      _scrollOffsets[_scrollOffsetKey(urlPath, restorationId)];

  void rememberScrollOffset(
    String urlPath,
    String restorationId,
    double offset,
  ) {
    _scrollOffsets[_scrollOffsetKey(urlPath, restorationId)] = offset;
  }

  /// Holds all fallback widgets that will be used in the live view lifecycle
  LiveViewFallbackPages fallbackPages;

  LiveView({
    this.fallbackPages = const LiveViewFallbackPages(),
    this.cacheCoordinator,
    this.onViewTypeRendered,
    http.Client Function()? httpClientFactory,
  }) : _httpClientFactory =
           httpClientFactory ?? http_client_factory.createHttpClient {
    _initialHttpClient = _httpClientFactory();
    httpClient = _initialHttpClient;
    currentUrl = '/';
    router = LiveRouterDelegate(this);
    changeNotifier = StateNotifier();
    connectionNotifier = LiveConnectionNotifier();
    themeSettings = ThemeSettings();
    themeSettings.httpClient = httpClient;
    rootView = LiveRootView(view: this);

    LiveViewUiParser.registerDefaultComponents();
    FlutterExecAction.registerDefaultExecs();

    router.pushPage(
      url: 'loading',
      widget: connectingWidget(),
      rootState: null,
    );
  }

  void connectToDocs() {
    if (!kIsWeb) {
      return;
    }
    bindWebDocs(this);
  }

  Future<void> connect(String address) async {
    await _loadCookies();

    _clientId = const Uuid().v4();
    var endpoint = Uri.parse(address);
    host = "${endpoint.host}:${endpoint.port}";
    themeSettings.httpClient = httpClient;
    themeSettings.host = "${endpoint.scheme}://$host";
    bool initialized = false;

    currentUrl = endpoint.path == "" ? "/" : endpoint.path;
    if (endpoint.query.isNotEmpty) {
      currentUrl = '$currentUrl?${endpoint.query}';
    }
    endpointScheme = endpoint.scheme;
    try {
      var response = await deadViewGetQuery(currentUrl);

      // The HTTP client no longer follows redirects automatically, so follow
      // dead-view redirects until we land on the real initial page.
      while ((response.statusCode == 302 || response.statusCode == 301) &&
          response.headers['location'] != null) {
        var location = response.headers['location']!;
        var uri = Uri.parse(location);
        currentUrl = uri.path.isEmpty ? '/' : uri.path;
        if (uri.query.isNotEmpty) {
          currentUrl = '$currentUrl?${uri.query}';
        }
        response = await deadViewGetQuery(currentUrl);
      }

      initialized = true;

      if (response.statusCode > 300) {
        if (response.statusCode == 404) {
          router.pushPage(
            url: 'error',
            widget: [fallbackPages.buildNotFoundError(this, endpoint)],
            rootState: null,
          );
        } else {
          router.pushPage(
            url: 'error',
            widget: [fallbackPages.buildCompilationError(this, response)],
            rootState: null,
          );
        }
      }
    } catch (e, stack) {
      if (_isConnectionException(e)) {
        router.pushPage(
          url: 'error',
          widget: [
            fallbackPages.buildNoServerError(
              this,
              FlutterErrorDetails(exception: e, stack: stack),
            ),
          ],
          rootState: null,
        );
      } else {
        router.pushPage(
          url: 'error',
          widget: [
            fallbackPages.buildFlutterError(
              this,
              FlutterErrorDetails(exception: e, stack: stack),
            ),
          ],
          rootState: null,
        );
      }
    }

    if (!initialized) {
      return autoReconnect(address);
    }
    await reconnect();
  }

  void autoReconnect(String address) {
    Timer(const Duration(seconds: 5), () => connect(address));
  }

  Map<String, String> httpHeaders() {
    var headers = {
      'Accept-Language': WidgetsBinding.instance.platformDispatcher.locales
          .map((l) => l.toLanguageTag())
          .where((e) => e != 'C')
          .toSet()
          .toList()
          .join(', '),
      'User-Agent': 'Flutter Live View - ${getPlatformName()}',
      'Accept': 'text/flutter',
    };

    if (cookie != null) {
      headers['Cookie'] = cookie!;
    }

    return headers;
  }

  Future<void> disconnect() async {
    _pendingLeavePush?.cancelTimeout();
    _pendingLeavePush = null;
    unawaited(_channelMessageSubscription?.cancel() ?? Future.value());
    _channelMessageSubscription = null;
    _channelUrl = null;
    _channel?.close();
    _socket?.dispose();
  }

  Future<void> reconnect() async {
    await themeSettings.loadPreferences();
    await themeSettings.fetchCurrentTheme();
    await _websocketConnect();
    await _setupLiveReload();
    await _setupPhoenixChannel();
  }

  Future<void> _loadCookies() async {
    var prefs = await SharedPreferences.getInstance();
    cookie = prefs.getString('cookie');
  }

  Future<void> _parseAndSaveCookie(String cookieValue) async {
    var merged = _mergeCookies(cookie, cookieValue);
    cookie = merged.isEmpty ? null : merged;
    var prefs = await SharedPreferences.getInstance();
    if (cookie == null) {
      await prefs.remove('cookie');
    } else {
      await prefs.setString('cookie', cookie!);
    }
  }

  /// Minimal cookie jar: keeps every name/value pair so cookies set by
  /// different responses (session, support visitor, ...) accumulate instead
  /// of replacing each other. Several set-cookie headers may be folded into
  /// one comma-joined value, so split only where a new name=value pair
  /// starts — never inside an Expires date.
  String _mergeCookies(String? existing, String setCookieHeader) {
    var jar = <String, String>{};
    for (var pair in existing?.split(';') ?? <String>[]) {
      var index = pair.indexOf('=');
      if (index > 0) {
        jar[pair.substring(0, index).trim()] = pair.substring(index + 1).trim();
      }
    }
    for (var part in setCookieHeader.split(RegExp(r',(?=[^;,]+=)'))) {
      var segments = part.split(';');
      var pair = segments.first.trim();
      var index = pair.indexOf('=');
      if (index <= 0) {
        continue;
      }
      var name = pair.substring(0, index).trim();
      var value = pair.substring(index + 1).trim();
      var attributes = segments.skip(1).join(';').toLowerCase();
      var deleted =
          value == '' &&
          (attributes.contains('max-age=0') ||
              attributes.contains('expires=thu, 01 jan 1970'));
      if (deleted) {
        jar.remove(name);
      } else {
        jar[name] = value;
      }
    }
    return jar.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  bool _isConnectionException(Object e) {
    var message = e.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('connection closed') ||
        message.contains('connection reset') ||
        message.contains('connection timed out');
  }

  void _readInitialSession(Document content) {
    try {
      _csrf =
          (content
              .querySelector('meta[name="csrf-token"]')
              ?.attributes['content']) ??
          (content
              .getElementsByTagName('csrf-token')
              .first
              .attributes['value'])!;

      _session =
          (content
              .querySelector('[data-phx-session]')
              ?.attributes['data-phx-session'])!;
      _phxStatic =
          (content
              .querySelector('[data-phx-static]')
              ?.attributes['data-phx-static'])!;

      _liveViewId =
          (content.querySelector('[data-phx-main]')?.attributes['id'])!;

      var themeName =
          content.querySelector('html')?.attributes['data-theme-name'];
      var themeMode =
          content.querySelector('html')?.attributes['data-theme-mode'];
      if (themeName != null && themeMode != null) {
        // The server renders its default theme for visitors and for users
        // without an explicit pick; adopting it blindly would clobber a
        // locally saved or OS-driven choice, so the default is mirrored
        // rather than persisted.
        unawaited(themeSettings.adoptServerTheme(themeName, themeMode));
      }
    } catch (e, stack) {
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildFlutterError(
            this,
            FlutterErrorDetails(
              exception: Exception(
                "Unable to load the meta tags, please add the csrf-token, data-phx-session and data-phx-static tags in ${content.outerHtml}",
              ),
              stack: stack,
            ),
          ),
        ],
        rootState: null,
      );
    }
  }

  String get websocketScheme => endpointScheme == 'https' ? 'wss' : 'ws';

  Map<String, dynamic> _requiredSocketParams() => {
    '_platform': 'flutter',
    '_format': 'flutter',
    '_lvn': {'os': getPlatformName()},
    'vsn': '2.0.0',
  };

  Map<String, dynamic> _socketParams() => {
    ..._requiredSocketParams(),
    '_csrf_token': _csrf,
    // Phoenix compares `_mounts` with the integer 0 to decide whether the
    // disconnected render's flash should be carried into the first live
    // render; a string "0" never matches and redirect flashes get dropped.
    '_mounts': mount,
    '_mount_attempts': 0,
    'client_id': _clientId,
  };

  Map<String, dynamic> _fullsocketParams({bool redirect = false}) {
    var params = {
      'session': _session,
      'static': _phxStatic,
      'params': _socketParams(),
    };
    var nextUrl = "$endpointScheme://$host$currentUrl";
    if (redirect) {
      params['redirect'] = nextUrl;
    } else {
      params['url'] = nextUrl;
    }
    return params;
  }

  Future<void> _websocketConnect() async {
    _socket = liveSocket.create(
      url: "$websocketScheme://$host/live/websocket",
      params: _socketParams(),
      headers: httpHeaders(),
    );

    await _socket?.connect();
  }

  _setupPhoenixChannel({bool redirect = false}) async {
    if (_isJoiningChannel) return;
    _isJoiningChannel = true;

    try {
      // This may run from the subscription's own phx_close callback. Awaiting
      // cancellation there would deadlock until that callback returns.
      unawaited(_channelMessageSubscription?.cancel() ?? Future.value());
      final channel = _socket!.addChannel(
        topic: "lv:$_liveViewId",
        parameters: _fullsocketParams(redirect: redirect),
      );
      _channel = channel;
      _channelUrl = currentUrl;

      _channelMessageSubscription = channel.messages.listen(
        (event) => handleMessage(event, sourceChannel: channel),
      );

      if (_channel?.state != PhoenixChannelState.joined &&
          _channel?.state != PhoenixChannelState.joining) {
        var response = await _channel?.join().future;
        if (response?.isError == true && redirectToUrl != null) {
          var reason = response?.response?['reason'];
          if (reason == 'unauthorized') {
            // Cross-live_session redirect rejected by the server. Fall back to a
            // full dead-view navigation so the new session can be established
            // and the target page is rendered immediately instead of staying on
            // a loader while waiting for the websocket.
            var target = redirectToUrl!;
            redirectToUrl = null;
            _isJoiningChannel = false;
            await disconnect();
            await execHrefClick(target);
          } else {
            // Other join failures (e.g. stale session) cannot be recovered by
            // reloading the same dead view; doing so would loop forever.
            redirectToUrl = null;
          }
        } else {
          redirectToUrl = null;
        }
      }
    } finally {
      _isJoiningChannel = false;
    }
  }

  Future<void> redirectTo(String path) async {
    redirectToUrl = path;
    _channelUrl = null;

    if (_channel?.state != PhoenixChannelState.joined) {
      _pendingCachedSnapshot = null;
      _replaceWithPendingCachedSnapshot = false;
      await disconnect();
      await execHrefClick(path);
      return;
    }

    _pendingLeavePush = _channel?.push('phx_leave', {});
    await _pendingLeavePush?.future;
    _pendingLeavePush = null;
  }

  Future<void> _setupLiveReload() async {
    if (endpointScheme == 'https') {
      return;
    }

    _liveReloadSocket = liveSocket.create(
      url: "$websocketScheme://$host/phoenix/live_reload/socket/websocket",
      params: _requiredSocketParams(),
      headers: {'Accept': 'text/flutter'},
    );
    var liveReload = _liveReloadSocket.addChannel(
      topic: "phoenix:live_reload",
      parameters: {},
    );
    liveReload.messages.listen(handleLiveReloadMessage);

    try {
      await _liveReloadSocket.connect();
      if (liveReload.state != PhoenixChannelState.joined) {
        await liveReload.join().future;
      }
    } catch (e) {
      debugPrint('no live reload available');
    }
  }

  handleMessage(Message event, {PhoenixChannel? sourceChannel}) {
    // Channels can still deliver buffered diffs and redirect replies after a
    // live navigation. Never let the previous page mutate or navigate the
    // newly joined page.
    if (sourceChannel != null && !identical(sourceChannel, _channel)) {
      return;
    }
    if (event.event.value == 'phx_close') {
      if (redirectToUrl != null) {
        currentUrl = redirectToUrl!;
        var snapshot = _pendingCachedSnapshot;
        var replaceWithSnapshot = _replaceWithPendingCachedSnapshot;
        _pendingCachedSnapshot = null;
        _replaceWithPendingCachedSnapshot = false;
        if (snapshot?.route == Uri.parse(currentUrl)) {
          unawaited(
            handleRenderedMessage(
              snapshot!.rendered,
              viewType: ViewType.cached,
              replacePage: replaceWithSnapshot,
            ),
          );
        }
        _setupPhoenixChannel(redirect: true);
      }
      return;
    }
    if (event.event.value == 'live_redirect') {
      // Sent by push_navigate/push_patch on the server: navigate within the
      // live session instead of reloading the dead view.
      var to = event.payload?['to'];
      if (to is String) {
        unawaited(livePatch(to));
      }
      return;
    }
    if (event.event.value == 'redirect') {
      var to = event.payload?['to'];
      if (to is String) {
        redirectToUrl = null;
        unawaited(disconnect().then((_) => execHrefClick(to)));
      }
      return;
    }
    if (event.event.value == 'diff') {
      return handleDiffMessage(event.payload!);
    }
    if (event.payload == null || !event.payload!.containsKey('response')) {
      return;
    }
    if (event.payload!['response']?.containsKey('rendered') ?? false) {
      handleRenderedMessage(
        event.payload!['response']!['rendered'],
        viewType: ViewType.liveView,
        sourceChannel: sourceChannel,
      );
    } else if (event.payload!['response']?.containsKey('diff') ?? false) {
      handleDiffMessage(event.payload!['response']!['diff']);
    } else if (event.payload!['response']?['live_redirect'] is Map) {
      // push_navigate/push_patch answers an event with a channel reply
      // embedding the live redirect in the response.
      var redirect = event.payload!['response']!['live_redirect'] as Map;
      var to = redirect['to'];
      if (to is String) {
        unawaited(livePatch(to));
      }
    } else if (event.payload!['response']?['redirect'] is Map) {
      // Some redirects (e.g. after a phx-click event) come back as a channel
      // reply with the redirect embedded in the response.
      var redirect = event.payload!['response']!['redirect'] as Map;
      var to = redirect['to'];
      if (to is String) {
        redirectToUrl = null;
        unawaited(disconnect().then((_) => execHrefClick(to)));
      }
    }
  }

  Future<void> handleRenderedMessage(
    Map<String, dynamic> rendered, {
    ViewType viewType = ViewType.liveView,
    PhoenixChannel? sourceChannel,
    bool replacePage = false,
  }) async {
    var cacheGeneration = ++_cacheRenderGeneration;
    var renderedUrl = currentUrl;
    var wasCached = isShowingCachedRender;
    // A full render replaces whatever diffs were targeting the previous page,
    // so drop stale diff state before the new widgets read it.
    changeNotifier.emptyData();
    if (viewType != ViewType.cached) {
      cacheManifest = null;
    }
    var expandedRendered = expandVariables(rendered);
    if (viewType != ViewType.cached) {
      cacheManifest = const LiveCacheManifestParser().parseRendered(
        expandedRendered,
      );
    }
    var elements = List<String>.from(rendered['s']);

    var render =
        LiveViewUiParser(
          html: elements,
          htmlVariables: expandedRendered,
          liveView: this,
          urlPath: currentUrl,
          viewType: viewType,
        ).parse();
    lastRender = render.$1;
    if (_renderedUrl != currentUrl) {
      // Navigated to another page: form values from the previous page must
      // not leak into same-named fields.
      _formValues.clear();
    }
    _renderedUrl = currentUrl;
    _renderedViewType = viewType;
    onViewTypeRendered?.call(viewType);
    clearFormTriggerActions(currentUrl);
    // A new render replaces the whole tree: mount execs must fire again.
    mountTracker.reset();
    connectionNotifier.wipeState();
    // Cache policy is optional. Only an explicit session boundary resets history.
    var resetsSession =
        viewType != ViewType.cached && _resetHistoryOnNextRender;
    if (resetsSession) {
      _resetHistoryOnNextRender = false;
      router.history.clear();
    }
    var noTransition =
        viewType == ViewType.cached ||
        wasCached ||
        cacheCoordinator?.hasRoute(Uri.parse(currentUrl)) == true;
    if (resetsSession || replacePage) {
      router.replacePages(
        url: currentUrl,
        widget: render.$1,
        rootState: render.$2,
        noTransition: noTransition,
      );
    } else {
      router.updatePage(
        url: currentUrl,
        widget: render.$1,
        rootState: render.$2,
        noTransition: noTransition,
      );
    }
    _storeAuthoritativeRender(
      rendered,
      viewType: viewType,
      sourceChannel: sourceChannel,
      renderedUrl: renderedUrl,
      generation: cacheGeneration,
    );
    if (viewType == ViewType.liveView) {
      _flushCachedRenderEvents(renderedUrl);
    }
  }

  void dispatchEvent(ExecLiveEvent event) {
    if (sendEvent(event)) {
      return;
    }
    if (isShowingCachedRender && _renderedUrl == currentUrl) {
      _cachedRenderEvents.add((currentUrl, event));
    }
  }

  void _flushCachedRenderEvents(String renderedUrl) {
    var events =
        _cachedRenderEvents
            .where((pending) => pending.$1 == renderedUrl)
            .map((pending) => pending.$2)
            .toList();
    _cachedRenderEvents.clear();
    for (var event in events) {
      sendEvent(event);
    }
  }

  void _storeAuthoritativeRender(
    Map<String, dynamic> rendered, {
    required ViewType viewType,
    required PhoenixChannel? sourceChannel,
    required String renderedUrl,
    required int generation,
  }) {
    var coordinator = cacheCoordinator;
    var manifest = cacheManifest;
    if (coordinator == null ||
        manifest == null ||
        viewType != ViewType.liveView ||
        sourceChannel == null ||
        !identical(sourceChannel, _channel) ||
        _channelUrl != renderedUrl ||
        currentUrl != renderedUrl) {
      return;
    }

    var locale =
        WidgetsBinding.instance.platformDispatcher.locales.firstOrNull
            ?.toLanguageTag() ??
        'und';
    var displayedTheme = themeSettings.getDisplayedThemeMode().name;
    var namespace = LiveCacheNamespace(
      origin: '$endpointScheme://$host',
      scope: manifest.scope,
      identity: manifest.identity,
      manifestVersion: manifest.version,
      rendererVersion: cacheRendererVersion,
      locale: locale,
      theme: '${themeSettings.themeName}/$displayedTheme',
    );
    var route = Uri.parse(renderedUrl);
    var priorNamespace = coordinator.namespace;
    var changesUser =
        priorNamespace?.scope == LiveCacheScope.user &&
        namespace.scope == LiveCacheScope.user &&
        (priorNamespace?.origin != namespace.origin ||
            priorNamespace?.identity != namespace.identity);
    if (changesUser) {
      router.retainOnlyCurrentPage();
    }

    unawaited(() async {
      var accepted = await coordinator.acceptManifest(
        namespace: namespace,
        manifest: manifest,
      );
      if (!accepted ||
          generation != _cacheRenderGeneration ||
          !identical(sourceChannel, _channel) ||
          _channelUrl != renderedUrl ||
          currentUrl != renderedUrl) {
        return;
      }
      var ownership = coordinator.claimFullRender(
        channel: sourceChannel,
        route: route,
      );
      if (ownership != null) {
        var stored = await coordinator.storeFullRender(ownership, rendered);
        if (stored &&
            generation == _cacheRenderGeneration &&
            identical(sourceChannel, _channel) &&
            currentUrl == renderedUrl) {
          var prefetchedNamespace = coordinator.namespace;
          _cachePrefetchComplete = coordinator.prefetch(_prefetchRoute).then((
            count,
          ) {
            if (prefetchedNamespace?.scope == LiveCacheScope.user &&
                coordinator.namespace == null) {
              _resetHistoryOnNextRender = true;
              router.retainOnlyCurrentPage();
            }
            return count;
          });
        }
      }
    }());
  }

  Future<LiveCachePrefetchResult> _prefetchRoute(Uri route) async {
    var namespace = cacheCoordinator?.namespace;
    if (namespace == null) {
      return const LiveCachePrefetchResult.stop();
    }
    var origin = Uri.parse(namespace.origin);
    var requestedTarget = origin.resolveUri(route);
    var target = _withFlutterFormat(requestedTarget);
    var prefetchClient =
        identical(httpClient, _initialHttpClient)
            ? _httpClientFactory()
            : httpClient;
    var closePrefetchClient = !identical(prefetchClient, httpClient);

    try {
      for (var redirectCount = 0; redirectCount <= 5; redirectCount++) {
        var request =
            http.Request('GET', target)
              ..followRedirects = false
              ..headers.addAll(httpHeaders());
        var response = await http.Response.fromStream(
          await prefetchClient.send(request),
        );
        if (response.headers['x-live-view-session-reset'] == 'true' ||
            response.headers['x-live-view-session'] == 'anonymous' ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          return const LiveCachePrefetchResult.stop();
        }
        if (response.statusCode == 301 || response.statusCode == 302) {
          var location = response.headers['location'];
          if (location == null || redirectCount == 5) {
            return const LiveCachePrefetchResult.skip();
          }
          var redirected = target.resolve(location);
          if (!_sameOrigin(origin, redirected)) {
            return const LiveCachePrefetchResult.stop();
          }
          target = _withFlutterFormat(redirected);
          continue;
        }
        if (response.statusCode != 200) {
          return const LiveCachePrefetchResult.skip();
        }

        var extracted = const LiveCachePrefetchDocument().extract(
          response.body,
          namespace: namespace,
        );
        if (extracted.sessionChanged) {
          return const LiveCachePrefetchResult.stop();
        }
        if (!extracted.policyConfirmed) {
          return const LiveCachePrefetchResult.skip();
        }
        var finalTarget = _withoutFlutterFormat(target);
        if (finalTarget.path != requestedTarget.path ||
            finalTarget.query != requestedTarget.query) {
          return const LiveCachePrefetchResult.skip();
        }
        var presentation = extracted.rendered;
        return presentation == null
            ? const LiveCachePrefetchResult.skip()
            : LiveCachePrefetchResult.rendered(presentation);
      }
    } on Object {
      return const LiveCachePrefetchResult.skip();
    } finally {
      if (closePrefetchClient) {
        prefetchClient.close();
      }
    }
    return const LiveCachePrefetchResult.skip();
  }

  Uri _withFlutterFormat(Uri uri) {
    var query = Map<String, dynamic>.from(uri.queryParametersAll);
    query['_format'] = 'flutter';
    return uri.replace(queryParameters: query);
  }

  Uri _withoutFlutterFormat(Uri uri) {
    var query = Map<String, dynamic>.from(uri.queryParametersAll)
      ..remove('_format');
    return uri.replace(queryParameters: query);
  }

  bool _sameOrigin(Uri expected, Uri candidate) =>
      expected.scheme == candidate.scheme &&
      expected.host == candidate.host &&
      expected.port == candidate.port;

  handleDiffMessage(Map<String, dynamic> diff) {
    _handleDiffEvents(diff);
    mountTracker.recordDiff(diff);
    changeNotifier.setDiff(diff);
  }

  void _handleDiffEvents(Map<String, dynamic> diff) {
    var events = diff['e'];
    if (events is! List) {
      return;
    }

    for (var event in events) {
      if (event is! List || event.isEmpty) {
        continue;
      }
      var name = event[0];
      var payload = event.length > 1 ? event[1] : null;
      if (name == 'set_theme' && payload is Map) {
        var theme = payload['theme'];
        var mode = payload['mode'];
        if (theme is String && mode is String) {
          unawaited(switchTheme(theme, mode));
        }
      }
      if (name == 'clear-composer' && payload is Map) {
        var field = payload['field'];
        if (field is String) {
          // Forget the value first so a server diff rebuilding the field
          // doesn't restore the text the server just asked to clear, then
          // let the fields themselves reset their editing controllers.
          forgetFormValue(currentUrl, field);
          eventHub.fire('clear-composer', {'field': field});
        }
      }
    }
  }

  Future<void> handleLiveReloadMessage(Message event) async {
    if (event.event.value == 'assets_change' && isLiveReloading == false) {
      eventHub.fire('live-reload:start');
      isLiveReloading = true;

      _socket?.close();
      _channel?.close();
      connectionNotifier.wipeState();
      redirectToUrl = null;
      await connect("$endpointScheme://$host$currentUrl");
      isLiveReloading = false;
      eventHub.fire('live-reload:end');
    }
  }

  bool sendEvent(ExecLiveEvent event) {
    var eventData = {
      'type': event.type,
      'event': event.name,
      'value': event.value,
    };

    if (clientType == ClientType.webDocs) {
      web_html.window.parent?.postMessage({
        'type': 'event',
        'data': eventData,
      }, "*");
      return true;
    }

    // Match LiveView JS's `view.isConnected()` guard. A channel is owned by
    // the URL it joined for and is invalidated as soon as navigation starts,
    // so an old-but-still-joined channel cannot receive the next page's event.
    // Errored, joining and leaving channels also reject pushes.
    if (_channel?.state == PhoenixChannelState.joined &&
        _channelUrl == currentUrl &&
        _renderedUrl == currentUrl &&
        _renderedViewType == ViewType.liveView) {
      _channel?.push('event', eventData);
      return true;
    }

    return false;
  }

  List<Widget> connectingWidget() {
    return [InternalView(child: fallbackPages.buildConnecting(this))];
  }

  List<Widget> loadingWidget(String url) {
    var previousWidgets = router.lastRealPage?.widgets ?? [];

    List<Widget> ret = [
      InternalView(child: fallbackPages.buildLoading(this, url)),
    ];

    // we keep the previous navigation items to avoid flickering with the load screen
    // the loading page doesn't stay very long but it's enough to cause a flickering
    var previousNavigation =
        previousWidgets
            .where(
              (element) =>
                  element is LiveDrawer ||
                  element is LiveAppBar ||
                  element is LiveBottomNavigationBar ||
                  element is LiveBottomAppBar ||
                  element is LiveNavigationRail ||
                  element is LiveFloatingActionButton ||
                  element is LivePersistentFooterButton ||
                  element is LiveBottomSheet,
            )
            .toList();

    ret.addAll(previousNavigation);

    return ret;
  }

  Future<void> switchTheme(String? themeName, String? themeMode) async {
    if (themeName == null || themeMode == null) {
      return;
    }
    await themeSettings.setTheme(themeName, themeMode);
    await themeSettings.save();
  }

  Future<void> saveCurrentTheme() => themeSettings.save();

  Future<void> livePatch(String url, {bool replace = false}) async {
    // Guard against duplicate taps: stale junk pages stay in the navigator
    // tree, so a single tap can reach both the current page and an obscured
    // stale copy of the same link, firing livePatch twice for the same url.
    if (router.pages.lastOrNull?.page.name == 'loading;$url') {
      return;
    }
    var navigationGeneration = ++_navigationGeneration;
    while ((redirectToUrl != null ||
            _isJoiningChannel ||
            _channel?.state == PhoenixChannelState.joining ||
            _channel?.state == PhoenixChannelState.leaving) &&
        navigationGeneration == _navigationGeneration) {
      // A cached route becomes visible before its replacement channel has
      // finished joining. Keep that snapshot on screen and defer a subsequent
      // tab transition instead of clearing the next snapshot and falling back
      // to a dead HTTP navigation.
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (navigationGeneration != _navigationGeneration) {
      return;
    }

    _cachedRenderEvents.clear();
    LiveCacheSnapshot? snapshot;
    var coordinator = cacheCoordinator;
    var cacheRoute = coordinator?.hasRoute(Uri.parse(url)) ?? false;
    if (coordinator != null) {
      snapshot = await coordinator.loadForNavigation(Uri.parse(url));
      if (navigationGeneration != _navigationGeneration) {
        return;
      }
    }
    _pendingCachedSnapshot = snapshot;
    _replaceWithPendingCachedSnapshot = snapshot != null && replace;
    changeNotifier.emptyData();
    if (clientType == ClientType.webDocs) {
      web_html.window.parent?.postMessage({
        'type': 'live-patch',
        'url': url,
      }, "*");
    }
    final rootState = router.pages.lastOrNull?.rootState;
    if (snapshot != null) {
      // Keep the current page visible until the cached target is ready. The
      // channel close handler swaps the snapshot in without flashing a loader.
    } else if (!cacheRoute && replace) {
      router.replacePages(
        url: 'loading;$url',
        widget: loadingWidget(url),
        rootState: rootState,
      );
    } else if (!cacheRoute) {
      router.pushPage(
        url: 'loading;$url',
        widget: loadingWidget(url),
        rootState: rootState,
      );
    }
    unawaited(redirectTo(url));
  }

  Future<void> postForm(Map<String, dynamic> formValues, {String? url}) {
    if (isShowingCachedRender) {
      return Future<void>.value();
    }
    return deadViewPostQuery(url ?? currentUrl, formValues);
  }

  String _formTriggerKey(String urlPath, String action) => '$urlPath|$action';

  String? getFormTriggerAction(String urlPath, String action) =>
      _lastFormTriggerActions[_formTriggerKey(urlPath, action)];

  void setFormTriggerAction(String urlPath, String action, String value) {
    _lastFormTriggerActions[_formTriggerKey(urlPath, action)] = value;
  }

  void clearFormTriggerActions(String urlPath) {
    var prefix = _formTriggerKey(urlPath, '');
    _lastFormTriggerActions.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Servers signal logout/session renewal explicitly, independently of caching.
  /// Process this before following redirects so old snapshots cannot be reused.
  Future<void> _handleSessionResponse(http.Response response) async {
    var reset = response.headers['x-live-view-session-reset'] == 'true';
    var lostSession =
        response.headers['x-live-view-session'] == 'anonymous' &&
        cacheCoordinator?.namespace?.scope == LiveCacheScope.user;
    if (!reset && !lostSession) return;
    _cacheRenderGeneration += 1;
    _resetHistoryOnNextRender = true;
    _pendingCachedSnapshot = null;
    _replaceWithPendingCachedSnapshot = false;
    _cachedRenderEvents.clear();
    cacheManifest = null;
    await cacheCoordinator?.invalidateActiveUser();
  }

  Future<http.Response> deadViewPostQuery(
    String url,
    Map<String, dynamic> formValues,
  ) async {
    formValues['_csrf_token'] = _csrf;

    // Dead-view form submissions are infrequent and may follow several
    // minutes of websocket-only activity. A Connection: close request header
    // cannot stop the HTTP client from selecting an already-stale pooled
    // socket, so default clients use a fresh connection for the whole POST.
    // Keep explicitly injected clients intact for embedders and tests.
    var postClient =
        identical(httpClient, _initialHttpClient)
            ? _httpClientFactory()
            : httpClient;
    var closePostClient = !identical(postClient, httpClient);
    late http.Response r;
    try {
      r = await postClient.post(
        shortUrlToUri(url),
        headers: {
          ...httpHeaders(),
          'connection': 'close',
          'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: formValues,
      );
    } finally {
      if (closePostClient) {
        postClient.close();
      }
    }
    await disconnect();

    await _handleSessionResponse(r);

    if (r.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(r.headers['set-cookie']!);
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      var content = html.parse(r.body);
      _readInitialSession(content);
    }

    if ((r.statusCode == 302 || r.statusCode == 301) &&
        r.headers['location'] != null) {
      await execHrefClick(r.headers['location']!);
      return r;
    }

    handleRenderedMessage({
      's': [r.body],
    }, viewType: ViewType.deadView);

    return r;
  }

  /// Uploads a file to a dead-view endpoint (e.g. a Phoenix controller
  /// accepting a multipart form). Mirrors [deadViewPostQuery]: the session
  /// cookie and CSRF token are attached, response cookies are merged, and a
  /// redirect triggers client-side navigation.
  Future<http.Response> deadViewUploadQuery(
    String url,
    String field,
    String filePath, {
    Map<String, String> formValues = const {},
  }) async {
    var request = http.MultipartRequest('POST', shortUrlToUri(url));
    // A streamed multipart body cannot be replayed after a redirect; the
    // redirect is followed below with a plain GET like deadViewPostQuery.
    request.followRedirects = false;
    request.headers.addAll({...httpHeaders(), 'x-csrf-token': _csrf ?? ''});
    request.fields['_csrf_token'] = _csrf ?? '';
    request.fields.addAll(formValues);
    request.files.add(await http.MultipartFile.fromPath(field, filePath));

    var r = await http.Response.fromStream(await httpClient.send(request));

    await disconnect();

    await _handleSessionResponse(r);

    if (r.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(r.headers['set-cookie']!);
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      var content = html.parse(r.body);
      _readInitialSession(content);
    }

    if ((r.statusCode == 302 || r.statusCode == 301) &&
        r.headers['location'] != null) {
      await execHrefClick(r.headers['location']!);
      return r;
    }

    handleRenderedMessage({
      's': [r.body],
    }, viewType: ViewType.deadView);

    return r;
  }

  Future<http.Response> deadViewDeleteQuery(String url) async {
    // Logout may follow a long websocket-only session. Avoid reusing a stale
    // pooled HTTP connection for this session-changing request.
    var deleteClient =
        identical(httpClient, _initialHttpClient)
            ? _httpClientFactory()
            : httpClient;
    var closeDeleteClient = !identical(deleteClient, httpClient);
    late http.Response r;
    try {
      r = await deleteClient.delete(
        shortUrlToUri(url),
        headers: {
          ...httpHeaders(),
          'connection': 'close',
          'x-csrf-token': _csrf ?? '',
        },
      );
    } finally {
      if (closeDeleteClient) deleteClient.close();
    }

    await _handleSessionResponse(r);

    if (r.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(r.headers['set-cookie']!);
    }

    if (r.statusCode == 200) {
      var content = html.parse(r.body);
      _readInitialSession(content);
    }
    return r;
  }

  Future<http.Response> deadViewGetQuery(String url) async {
    Future<http.Response> send(http.Client client) async {
      var request = http.Request('GET', shortUrlToUri(url));
      request.followRedirects = false;
      request.headers.addAll(httpHeaders());
      return http.Response.fromStream(await client.send(request));
    }

    late http.Response r;
    try {
      r = await send(httpClient);
    } on Object catch (error) {
      if (!identical(httpClient, _initialHttpClient) ||
          !_isConnectionException(error)) {
        rethrow;
      }
      var retryClient = _httpClientFactory();
      try {
        r = await send(retryClient);
      } finally {
        retryClient.close();
      }
    }

    await _handleSessionResponse(r);

    if (r.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(r.headers['set-cookie']!);
    }

    if (r.statusCode == 200) {
      var content = html.parse(r.body);
      _readInitialSession(content);
    }
    return r;
  }

  Future<void> execHrefClick(
    String url, {
    String method = 'GET',
    bool waitForConnection = true,
    bool showLoadingPage = true,
  }) async {
    if (isShowingCachedRender && method.toUpperCase() != 'GET') {
      return;
    }
    if (showLoadingPage) {
      router.pushPage(
        url: 'loading;$url',
        widget: loadingWidget(url),
        rootState: router.pages.lastOrNull?.rootState,
      );
    }

    http.Response response;
    if (method.toUpperCase() == 'DELETE') {
      response = await deadViewDeleteQuery(url);
    } else {
      response = await deadViewGetQuery(url);
    }

    if ((response.statusCode == 302 || response.statusCode == 301) &&
        response.headers['location'] != null) {
      await execHrefClick(response.headers['location']!);
      return;
    }

    currentUrl = url;
    redirectToUrl = url;

    handleRenderedMessage({
      's': [response.body],
    }, viewType: ViewType.deadView);
    final connectionTransition =
        _socket?.isConnected == true
            ? (_channel?.leave().future ?? Future<void>.value())
            : reconnect();
    if (waitForConnection) {
      await connectionTransition;
    } else {
      unawaited(connectionTransition);
    }
  }

  Uri shortUrlToUri(String url) {
    var uri = Uri.parse("$endpointScheme://$host$url");
    var queryParams = Map<String, dynamic>.from(uri.queryParametersAll);
    queryParams['_format'] = 'flutter';

    return uri.replace(queryParameters: queryParams);
  }

  Future<void> goBack() async {
    if (clientType == ClientType.webDocs) {
      web_html.window.parent?.postMessage({'type': 'go-back'}, "*");
      return;
    }
    if (_isGoingBack) return;

    _isGoingBack = true;
    try {
      await router.popRoute();
    } finally {
      _isGoingBack = false;
    }
  }

  Future<void> installPlugins(List<Plugin> plugins) async {
    for (var plugin in plugins) {
      plugin.registerWidgets(LiveViewUiRegistry.instance);
      plugin.registerExecs(LiveViewExecRegistry.instance);
    }
    _installedPlugins.addAll(plugins);
  }
}
