import 'dart:convert';

import 'package:event_hub/event_hub.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:liveview_flutter/live_view/reactive/live_go_back_notifier.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/routes/live_router_delegate.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_view.dart';
import 'package:uuid/uuid.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import './ui/live_view_ui_parser.dart';

class LiveEvent {
  final String type;
  final String name;
  final dynamic value;

  LiveEvent({required this.type, required this.name, required this.value});

  @override
  String toString() => jsonEncode({'type': type, 'name': name, 'value': value});

  @override
  bool operator ==(Object other) {
    if (other is LiveEvent) {
      return other.hashCode == hashCode;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([type, name, value]);
}

class LiveSocket {
  PhoenixSocket create(
          {required String url,
          required Map<String, String>? params,
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

  http.Client httpClient = http.Client();
  var liveSocket = LiveSocket();

  Widget? onErrorWidget;
  late LiveRootView rootView;
  late String _csrf;
  late String _host;
  late String _clientId;
  late String _session;
  late String _phxStatic;
  late String _liveViewId;
  late String _baseUrl;
  late String _currentUrl;
  late String _cookie;
  late String endpointScheme;
  EventHub eventHub = EventHub();

  String? redirectToUrl;

  PhoenixSocket? _socket;
  late PhoenixSocket _liveReloadSocket;

  late PhoenixChannel _channel;

  List<m.Widget>? lastRender;

  // dynamic global state
  late StateNotifier changeNotifier;
  late LiveConnectionNotifier connectionNotifier;
  late ThemeSettings themeSettings;
  LiveGoBackNotifier goBackNotifier = LiveGoBackNotifier();
  late LiveRouterDelegate router;

  LiveView() {
    _currentUrl = '/';
    router = LiveRouterDelegate(this);
    changeNotifier = StateNotifier();
    connectionNotifier = LiveConnectionNotifier();
    themeSettings = ThemeSettings();
    themeSettings.httpClient = httpClient;
    rootView = LiveRootView(view: this);

    router.pushPage(url: 'loading', widget: connectingWidget());
  }

  Future<String?> connect(String address) async {
    _baseUrl = address;
    _currentUrl = address;
    var endpoint = Uri.parse(address);
    endpointScheme = endpoint.scheme;
    var r = await httpClient.get(endpoint);
    var content = html.parse(r.body);

    _host = "${endpoint.host}:${endpoint.port}";
    _clientId = const Uuid().v4();
    if (r.statusCode != 200) {
      _setupLiveReload();
      router
          .pushPage(url: 'error', widget: [CompilationErrorView(html: r.body)]);
      return null;
    }
    _cookie = r.headers['set-cookie']!.split(' ')[0];

    themeSettings.httpClient = httpClient;
    themeSettings.host = "${endpoint.scheme}://$_host";
    await themeSettings.loadPreferences();
    await themeSettings.fetchCurrentTheme();
    _readInitialSession(content);
    await _websocketConnect();
    await _setupLiveReload();
    await _setupPhoenixChannel();

    return _csrf;
  }

  void _readInitialSession(Document content) {
    _csrf = (content
        .querySelector('meta[name="csrf-token"]')
        ?.attributes['content'])!;
    _session = (content
        .querySelector('[data-phx-session]')
        ?.attributes['data-phx-session'])!;
    _phxStatic = (content
        .querySelector('[data-phx-static]')
        ?.attributes['data-phx-static'])!;

    _liveViewId = (content.querySelector('[data-phx-main]')?.attributes['id'])!;
  }

  _socketParams() => {
        '_csrf_token': _csrf,
        '_mounts': '0',
        'client_id': _clientId,
        '_platform': 'flutter',
        'vsn': '2.0.0'
      };

  Map<String, dynamic> _fullsocketParams({bool redirect = false}) {
    var params = {
      'session': _session,
      'static': _phxStatic,
      'params': _socketParams()
    };
    if (redirect) {
      params['redirect'] = _currentUrl;
    } else {
      params['url'] = _currentUrl;
    }
    return params;
  }

  _websocketConnect() async {
    _socket = liveSocket.create(
      url: "ws://$_host/live/websocket",
      params: _socketParams(),
      headers: {'Cookie': _cookie},
    );

    await _socket?.connect();
  }

  _setupPhoenixChannel({bool redirect = false}) async {
    _channel = _socket!.addChannel(
        topic: "lv:$_liveViewId",
        parameters: _fullsocketParams(redirect: redirect));

    _channel.messages.listen(handleMessage);

    if (_channel.state != PhoenixChannelState.joined) {
      await _channel.join().future;
    }
  }

  Future<void> redirectTo(String url) async {
    _channel.push('phx_leave', {}).future;
    redirectToUrl = "$endpointScheme://$_host$url";
  }

  _setupLiveReload() async {
    _liveReloadSocket = liveSocket.create(
        url: "ws://$_host/phoenix/live_reload/socket/websocket",
        params: {'_platform': 'flutter', 'vsn': '2.0.0'},
        headers: {});
    var liveReload = _liveReloadSocket
        .addChannel(topic: "phoenix:live_reload", parameters: {});
    liveReload.messages.listen(handleLiveReloadMessage);

    await _liveReloadSocket.connect();
    if (liveReload.state != PhoenixChannelState.joined) {
      await liveReload.join().future;
    }
  }

  handleMessage(Message event) {
    if (event.event.value == 'phx_close') {
      if (redirectToUrl != null) {
        _currentUrl = redirectToUrl!;
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

    var path = Uri.parse(_currentUrl).path;
    if (path == "") {
      path = "/";
    }
    var render = LiveViewUiParser(
            html: elements,
            htmlVariables: _extractVariables(rendered),
            liveView: this)
        .parse();
    lastRender = render;
    connectionNotifier.wipeState();
    router.updatePage(url: path, widget: render);
  }

  handleDiffMessage(Map<String, dynamic> diff) {
    changeNotifier.setDiff(diff);
  }

  Map<String, dynamic> _extractVariables(Map<String, dynamic> rendered) {
    Map<String, dynamic> ret = {};

    rendered.forEach((key, value) {
      if (RegExp(r'^[0-9]+$').hasMatch(key)) {
        ret[key] = value;
      }
    });

    return ret;
  }

  Future<void> handleLiveReloadMessage(Message event) async {
    if (event.event.value == 'assets_change') {
      _socket?.dispose();
      _liveReloadSocket.dispose();
      changeNotifier.emptyData();

      connectionNotifier.wipeState();
      await connect(_baseUrl);
    }
  }

  sendEvent(LiveEvent event) {
    if (_channel.state != PhoenixChannelState.closed) {
      _channel.push('event',
          {'type': event.type, 'event': event.name, 'value': event.value});
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

    // we keep the previous appbar & bottom bar to avoid flickering with the load screen
    // the loading page doesn't stay very long but it's enough to cause a flickering
    var previousNavigation = previousWidgets
        .where((element) =>
            element is LiveAppBar || element is LiveBottomNavigationBar)
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
}
