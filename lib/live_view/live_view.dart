import 'dart:async';
import 'dart:developer';
import 'dart:io';

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
import 'package:web_socket_channel/io.dart';

import './ui/live_view_ui_parser.dart';

enum ViewType { deadView, liveView }

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

        return IOWebSocketChannel.connect(newUri, headers: headers);
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
  final List<Plugin> _installedPlugins = [];
  bool catchExceptions = true;
  bool disableAnimations = false;
  ClientType clientType = ClientType.liveView;

  http.Client httpClient = http.Client();
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

  String? redirectToUrl;

  PhoenixSocket? _socket;
  late PhoenixSocket _liveReloadSocket;

  PhoenixChannel? _channel;

  List<Widget>? lastRender;

  // dynamic global state
  late StateNotifier changeNotifier;
  late LiveConnectionNotifier connectionNotifier;
  late ThemeSettings themeSettings;
  LiveGoBackNotifier goBackNotifier = LiveGoBackNotifier();
  late LiveRouterDelegate router;
  bool throttleSpammyCalls = true;

  /// Holds all fallback widgets that will be used in the live view lifecycle
  LiveViewFallbackPages fallbackPages;

  LiveView({
    this.fallbackPages = const LiveViewFallbackPages(),
  }) {
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
    endpointScheme = endpoint.scheme;
    try {
      var response = await deadViewGetQuery(currentUrl);
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
    } on SocketException catch (e, stack) {
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildNoServerError(
            this,
            FlutterErrorDetails(exception: e, stack: stack),
          )
        ],
        rootState: null,
      );
    } catch (e, stack) {
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildFlutterError(
            this,
            FlutterErrorDetails(exception: e, stack: stack),
          )
        ],
        rootState: null,
      );
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
    cookie = Cookie.fromSetCookieValue(cookieValue).toString();
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookie', cookie.toString());
  }

  void _readInitialSession(Document content) {
    try {
      _csrf = (content
              .querySelector('meta[name="csrf-token"]')
              ?.attributes['content']) ??
          (content
              .getElementsByTagName('csrf-token')
              .first
              .attributes['value'])!;

      _session = (content
          .querySelector('[data-phx-session]')
          ?.attributes['data-phx-session'])!;
      _phxStatic = (content
          .querySelector('[data-phx-static]')
          ?.attributes['data-phx-static'])!;

      _liveViewId =
          (content.querySelector('[data-phx-main]')?.attributes['id'])!;
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
        '_mounts': mount.toString(),
        'client_id': _clientId,
      };

  Map<String, dynamic> _fullsocketParams({bool redirect = false}) {
    var params = {
      'session': _session,
      'static': _phxStatic,
      'params': _socketParams()
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
    _channel = _socket!.addChannel(
      topic: "lv:$_liveViewId",
      parameters: _fullsocketParams(redirect: redirect),
    );

    _channel?.messages.listen(handleMessage);

    if (_channel?.state != PhoenixChannelState.joined) {
      await _channel?.join().future;
    }
  }

  Future<void> redirectTo(String path) async {
    redirectToUrl = path;
    await _channel?.push('phx_leave', {}).future;
  }

  Future<void> _setupLiveReload() async {
    if (endpointScheme == 'https') {
      return;
    }

    _liveReloadSocket = liveSocket.create(
      url: "$websocketScheme://$host/phoenix/live_reload/socket/websocket",
      params: _requiredSocketParams(),
      headers: {
        'Accept': 'text/flutter',
      },
    );
    var liveReload = _liveReloadSocket
        .addChannel(topic: "phoenix:live_reload", parameters: {});
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

  handleMessage(Message event) async {
    if (event.isReply &&
        event.payload?["status"] == "error" &&
        event.payload?.containsKey("response") == true) {
      var response = Map<String, dynamic>.from(event.payload!["response"]);

      if (response["reason"] == "unauthorized" ||
          response["reason"] == "stale") {
        log("ERROR: unauthorized live_redirect. Falling back to page request $response");
        // Fallback to page request
        // TODO: Handle unauthorized navigation
        goBack();
        return;
      }

      if (response.containsKey("redirect")) {
        var redirect = Map<String, dynamic>.from(response["redirect"]);
        return handleRedirect(redirect);
      }
    }

    if (event.event.value == 'phx_close') {
      if (redirectToUrl != null) {
        currentUrl = redirectToUrl!;
        _setupPhoenixChannel(redirect: true);
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
      handleRenderedMessage(event.payload!['response']!['rendered'],
          viewType: ViewType.liveView);
    } else if (event.payload!['response']?.containsKey('diff') ?? false) {
      handleDiffMessage(event.payload!['response']!['diff']);
    }
  }

  handleRedirect(Map<String, dynamic> redirect) async {
    var nextUrl = redirect["to"];
    if (nextUrl == null) return;

    log("redirecting to $nextUrl");
    _channel?.leave();
    _channel?.close();
    _socket?.removeChannel(_channel!);
    _channel = null;
    currentUrl = nextUrl;
    _setupPhoenixChannel(redirect: true);
    return;
  }

  handleRenderedMessage(Map<String, dynamic> rendered,
      {ViewType viewType = ViewType.liveView}) {
    var elements = List<String>.from(rendered['s']);

    var render = LiveViewUiParser(
      html: elements,
      htmlVariables: expandVariables(rendered),
      liveView: this,
      urlPath: currentUrl,
      viewType: viewType,
    ).parse();
    lastRender = render.$1;
    connectionNotifier.wipeState();
    router.updatePage(url: currentUrl, widget: render.$1, rootState: render.$2);
  }

  handleDiffMessage(Map<String, dynamic> diff) {
    changeNotifier.setDiff(diff);
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

  sendEvent(ExecLiveEvent event) {
    var eventData = {
      'type': event.type,
      'event': event.name,
      'value': event.value
    };

    if (clientType == ClientType.webDocs) {
      web_html.window.parent
          ?.postMessage({'type': 'event', 'data': eventData}, "*");
    } else if (_channel?.state != PhoenixChannelState.closed) {
      _channel?.push('event', eventData);
    }
  }

  List<Widget> connectingWidget() {
    return [InternalView(child: fallbackPages.buildConnecting(this))];
  }

  List<Widget> loadingWidget(String url) {
    var previousWidgets = router.lastRealPage?.widgets ?? [];

    List<Widget> ret = [
      InternalView(child: fallbackPages.buildLoading(this, url))
    ];

    // we keep the previous navigation items to avoid flickering with the load screen
    // the loading page doesn't stay very long but it's enough to cause a flickering
    var previousNavigation = previousWidgets
        .where((element) =>
            element is LiveDrawer ||
            element is LiveAppBar ||
            element is LiveBottomNavigationBar ||
            element is LiveBottomAppBar ||
            element is LiveNavigationRail ||
            element is LiveFloatingActionButton ||
            element is LivePersistentFooterButton ||
            element is LiveBottomSheet)
        .toList();

    ret.addAll(previousNavigation);

    return ret;
  }

  Future<void> switchTheme(String? themeName, String? themeMode) async {
    if (themeName == null || themeMode == null) {
      return;
    }
    return themeSettings.setTheme(themeName, themeMode);
  }

  Future<void> saveCurrentTheme() => themeSettings.save();

  Future<void> livePatch(String url) async {
    if (clientType == ClientType.webDocs) {
      web_html.window.parent
          ?.postMessage({'type': 'live-patch', 'url': url}, "*");
    }
    router.pushPage(
      url: 'loading;$url',
      widget: loadingWidget(url),
      rootState: router.pages.lastOrNull?.rootState,
    );
    redirectTo(url);
  }

  Future<void> postForm(Map<String, dynamic> formValues) async {
    deadViewPostQuery(currentUrl, formValues);
  }

  Future<http.Response> deadViewPostQuery(
      String url, Map<String, dynamic> formValues) async {
    formValues['_csrf_token'] = _csrf;
    var r = await httpClient.post(shortUrlToUri(currentUrl),
        headers: httpHeaders(), body: formValues);

    if (r.headers['set-cookie'] != null) {
      _parseAndSaveCookie(r.headers['set-cookie']!);
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
      's': [r.body]
    }, viewType: ViewType.deadView);

    return r;
  }

  Future<http.Response> deadViewGetQuery(String url) async {
    var r = await httpClient.get(shortUrlToUri(url), headers: httpHeaders());
    if (r.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(r.headers['set-cookie']!);
    }

    if (r.statusCode == 200) {
      var content = html.parse(r.body);
      _readInitialSession(content);
    }
    return r;
  }

  Future<void> execHrefClick(String url) async {
    router.pushPage(
      url: 'loading;$url',
      widget: loadingWidget(url),
      rootState: router.pages.lastOrNull?.rootState,
    );
    var response = await deadViewGetQuery(url);

    currentUrl = url;
    redirectToUrl = url;

    handleRenderedMessage({
      's': [response.body]
    }, viewType: ViewType.deadView);

    await _channel?.push('phx_leave', {}).future;
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
    }
    await router.navigatorKey?.currentState?.maybePop();
    router.notify();
  }

  Future<void> installPlugins(List<Plugin> plugins) async {
    for (var plugin in plugins) {
      plugin.registerWidgets(LiveViewUiRegistry.instance);
      plugin.registerExecs(LiveViewExecRegistry.instance);
    }
    _installedPlugins.addAll(plugins);
  }
}
