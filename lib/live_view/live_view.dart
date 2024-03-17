import 'dart:io';

import 'package:event_hub/event_hub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
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
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/error_404.dart';
import 'package:liveview_flutter/live_view/ui/errors/flutter_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/no_server_error_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_view.dart';
import 'package:liveview_flutter/live_view/webdocs.dart';
import 'package:liveview_flutter/platform_name.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import "package:universal_html/html.dart" as web_html;
import 'package:uuid/uuid.dart';

import './ui/live_view_ui_parser.dart';

class LiveSocket {
  PhoenixSocket create(
          {required String url,
          required Map<String, dynamic>? params,
          required Map<String, String>? headers}) =>
      PhoenixSocket(url,
          socketOptions: PhoenixSocketOptions(
            params: params,
            headers: headers,
          ));
}

class LiveView {
  bool catchExceptions = true;
  bool disableAnimations = false;
  bool webDocsMode = false;

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
  String? _cookie;
  late String endpointScheme;
  int mount = 0;
  EventHub eventHub = EventHub();
  bool isLiveReloading = false;

  String? redirectToUrl;

  PhoenixSocket? _socket;
  late PhoenixSocket _liveReloadSocket;

  PhoenixChannel? _channel;

  List<m.Widget>? lastRender;

  // dynamic global state
  late StateNotifier changeNotifier;
  late LiveConnectionNotifier connectionNotifier;
  late ThemeSettings themeSettings;
  LiveGoBackNotifier goBackNotifier = LiveGoBackNotifier();
  late LiveRouterDelegate router;
  bool throttleSpammyCalls = true;

  LiveView() {
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
        url: 'loading', widget: connectingWidget(), rootState: null);
  }

  void connectToDocs() {
    if (!kIsWeb) {
      return;
    }
    bindWebDocs(this);
  }

  Future<String?> connect(String address) async {
    _clientId = const Uuid().v4();
    var endpoint = Uri.parse(address);
    host = "${endpoint.host}:${endpoint.port}";
    themeSettings.httpClient = httpClient;
    themeSettings.host = "${endpoint.scheme}://$host";

    currentUrl = endpoint.path == "" ? "/" : endpoint.path;
    endpointScheme = endpoint.scheme;
    try {
      var response = await deadViewGetQuery(currentUrl);

      if (response.statusCode != 200) {
        _setupLiveReload();
        if (response.statusCode == 404) {
          router.pushPage(
              url: 'error',
              widget: [Error404(url: endpoint.toString())],
              rootState: null);
        } else {
          router.pushPage(
              url: 'error',
              widget: [CompilationErrorView(html: response.body)],
              rootState: null);
        }
        return null;
      }
    } on SocketException catch (e, stack) {
      router.pushPage(
          url: 'error',
          widget: [
            NoServerError(
                error: FlutterErrorDetails(exception: e, stack: stack)),
          ],
          rootState: null);
    } catch (e, stack) {
      router.pushPage(
          url: 'error',
          widget: [
            FlutterErrorView(
                error: FlutterErrorDetails(exception: e, stack: stack))
          ],
          rootState: null);
      rethrow;
    }

    await reconnect();

    return _csrf;
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
    };

    if (_cookie != null) {
      headers['Cookie'] = _cookie!;
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
            FlutterErrorView(
                error: FlutterErrorDetails(
                    exception: Exception(
                        "unable to load the meta tags, please add the csrf-token, data-phx-session and data-phx-static tags in ${content.outerHtml}"),
                    stack: stack))
          ],
          rootState: null);
    }
  }

  String get websocketScheme => endpointScheme == 'https' ? 'wss' : 'ws';

  Map<String, dynamic> _socketParams() => {
        '_csrf_token': _csrf,
        '_mounts': mount.toString(),
        'client_id': _clientId,
        '_platform': 'flutter',
        '_lvn': {'format': 'flutter', 'os': getPlatformName()},
        'vsn': '2.0.0'
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
        parameters: _fullsocketParams(redirect: redirect));

    _channel?.messages.listen(handleMessage);

    if (_channel?.state != PhoenixChannelState.joined) {
      await _channel?.join().future;
    }
  }

  Future<void> redirectTo(String path) async {
    _channel?.push('phx_leave', {}).future;
    redirectToUrl = path;
  }

  Future<void> _setupLiveReload() async {
    if (endpointScheme == 'https') {
      return;
    }

    _liveReloadSocket = liveSocket.create(
        url: "$websocketScheme://$host/phoenix/live_reload/socket/websocket",
        params: {'_platform': 'flutter', 'vsn': '2.0.0'},
        headers: {});
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

  handleMessage(Message event) {
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
      handleRenderedMessage(event.payload!['response']!['rendered']);
    } else if (event.payload!['response']?.containsKey('diff') ?? false) {
      handleDiffMessage(event.payload!['response']!['diff']);
    }
  }

  handleRenderedMessage(Map<String, dynamic> rendered) {
    var elements = List<String>.from(rendered['s']);

    var render = LiveViewUiParser(
            html: elements,
            htmlVariables: expandVariables(rendered),
            liveView: this,
            urlPath: currentUrl)
        .parse();
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

    if (webDocsMode) {
      web_html.window.parent
          ?.postMessage({'type': 'event', 'data': eventData}, "*");
    } else if (_channel?.state != PhoenixChannelState.closed) {
      _channel?.push('event', eventData);
    }
  }

  List<Widget> connectingWidget() => loadingWidget();

  List<Widget> loadingWidget() {
    var previousWidgets = router.lastRealPage?.widgets ?? [];

    List<Widget> ret = [
      InternalView(
          child: Builder(
              builder: (context) => Container(
                  color: m.Theme.of(context).colorScheme.background,
                  child: Center(
                      child: m.CircularProgressIndicator(
                          value: disableAnimations == false ? null : 1)))))
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
    if (webDocsMode) {
      web_html.window.parent
          ?.postMessage({'type': 'live-patch', 'url': url}, "*");
    }
    router.pushPage(
        url: 'loading;$url',
        widget: loadingWidget(),
        rootState: router.pages.lastOrNull?.rootState);
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
      _cookie = r.headers['set-cookie']!.split(' ')[0];
      if (_cookie?.endsWith(';') == true) {
        _cookie = _cookie!.substring(0, _cookie!.length - 1);
      }
    }
    if (r.statusCode == 200) {
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
    });

    return r;
  }

  Future<http.Response> deadViewGetQuery(String url) async {
    var r = await httpClient.get(shortUrlToUri(url));
    if (r.headers['set-cookie'] != null) {
      _cookie = r.headers['set-cookie']!.split(' ')[0];
      if (_cookie?.endsWith(';') == true) {
        _cookie = _cookie!.substring(0, _cookie!.length - 1);
      }
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
        widget: loadingWidget(),
        rootState: router.pages.lastOrNull?.rootState);
    var response = await deadViewGetQuery(url);
    handleRenderedMessage({
      's': [response.body]
    });

    redirectToUrl = url;
    _channel?.push('phx_leave', {}).future;
  }

  Uri shortUrlToUri(String url) {
    var uri = Uri.parse("$endpointScheme://$host$url");
    var queryParams = Map<String, dynamic>.from(uri.queryParametersAll);
    queryParams['_lvn[format]'] = 'flutter';

    return uri.replace(queryParameters: queryParams);
  }

  Future<void> goBack() async {
    if (webDocsMode) {
      web_html.window.parent?.postMessage({'type': 'go-back'}, "*");
    }
    router.navigatorKey?.currentState?.maybePop();
    router.notify();
  }
}
