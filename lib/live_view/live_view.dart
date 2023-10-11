import 'dart:convert';

import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/routes/live_router_delegate.dart';
import 'package:uuid/uuid.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:provider/provider.dart';
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
  http.Client httpClient = http.Client();
  var liveSocket = LiveSocket();
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
  List<Function(FlutterExecAction)> _pageActions = [];

  String? redirectToUrl;

  late PhoenixSocket _socket;
  late PhoenixSocket _liveReloadSocket;

  late PhoenixChannel _channel;

  m.Widget? lastRender;

  final Function() onReload;

  // dynamic global state
  late StateNotifier _changeNotifier;
  late LiveConnectionNotifier _connectionNotifier;
  late ThemeSettings _themeSettings;

  late LiveRouterDelegate router;

  LiveView({required this.onReload}) {
    _currentUrl = '/';
    router = LiveRouterDelegate(this);
    _changeNotifier = StateNotifier();
    _connectionNotifier = LiveConnectionNotifier();
    _themeSettings = ThemeSettings();
    _themeSettings.httpClient = httpClient;

    router.pushPage(url: '/', widget: connectingWidget());
  }

  Future<String?> connect(String address) async {
    _pageActions = [];
    _baseUrl = address;
    _currentUrl = address;
    var endpoint = Uri.parse(address);
    endpointScheme = endpoint.scheme;
    var r = await httpClient.get(endpoint);
    var content = html.parse(r.body);

    _host = "${endpoint.host}:${endpoint.port}";
    _clientId = const Uuid().v4();
    _cookie = r.headers['set-cookie']!.split(' ')[0];

    _themeSettings.host = "${endpoint.scheme}://$_host";
    await _themeSettings.loadPreferences();
    await _themeSettings.fetchCurrentTheme();
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
        '_platform': 'flutterui',
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

    await _socket.connect();
  }

  _setupPhoenixChannel({bool redirect = false}) async {
    _channel = _socket.addChannel(
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
        params: _socketParams(),
        headers: {'Cookie': _cookie});
    var liveReload = _liveReloadSocket.addChannel(
        topic: "phoenix:live_reload", parameters: _fullsocketParams());
    liveReload.messages.listen(liveReloadMessage);

    await _liveReloadSocket.connect();
    if (liveReload.state != PhoenixChannelState.joined) {
      await liveReload.join().future;
    }
  }

  listenPageAction(Function(FlutterExecAction) handle) =>
      _pageActions.add(handle);

  dispatchGlobalPageAction(FlutterExecAction action) {
    for (var handle in _pageActions) {
      handle(action);
    }
  }

  handleMessage(Message event) {
    if (event.event.value == 'phx_close') {
      if (redirectToUrl != null) {
        _currentUrl = redirectToUrl!;
        _connectionNotifier.reconnect();
        _pageActions = [];
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
    var render = m.Material(
        child: LiveViewUiParser(
                html: elements,
                htmlVariables: _extractVariables(rendered),
                liveView: this)
            .parse());
    lastRender = render;
    router.updatePage(url: path, widget: render);
    onReload();
  }

  handleDiffMessage(Map<String, dynamic> diff) {
    _changeNotifier.setDiff(diff);
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

  Future<void> liveReloadMessage(Message event) async {
    if (event.event.value == 'assets_change') {
      _socket.dispose();
      _liveReloadSocket.dispose();
      _changeNotifier.emptyData();

      await connect(_baseUrl);
      _connectionNotifier.reconnect();
    }
  }

  sendEvent(LiveEvent event) {
    if (_channel.state != PhoenixChannelState.closed) {
      _channel.push('event',
          {'type': event.type, 'event': event.name, 'value': event.value});
    }
  }

  Widget connectingWidget() => loadingWidget();

  Widget loadingWidget() => Builder(
      builder: (context) => Container(
          color: m.Theme.of(context).colorScheme.background,
          child: const Center(child: m.CircularProgressIndicator())));

  Widget materialApp() {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _changeNotifier),
          ChangeNotifierProvider.value(value: _connectionNotifier),
          ChangeNotifierProvider.value(value: _themeSettings)
        ],
        child: Builder(builder: (context) {
          var theme = Provider.of<ThemeSettings>(context);
          return m.MaterialApp(
            title: 'Flutter Demo',
            themeMode: theme.themeMode,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            home: Router(
              routerDelegate: router,
              backButtonDispatcher: RootBackButtonDispatcher(),
            ),
          );
        }));
  }

  Future<void> switchTheme(String? themeName, String? themeMode) async {
    if (themeName == null || themeMode == null) {
      return;
    }
    return _themeSettings.setTheme(themeName, themeMode);
  }

  Future<void> saveCurrentTheme() => _themeSettings.save();
}
