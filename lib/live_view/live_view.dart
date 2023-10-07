import 'dart:convert';

import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:uuid/uuid.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:provider/provider.dart';
import './ui/live_view_ui_parser.dart';

class LiveEvent {
  final String type;
  final String name;
  final String value;

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

class LiveView {
  late String _csrf;
  late String _host;
  late String _clientId;
  late String _session;
  late String _phxStatic;
  late String _liveViewId;
  late String _baseUrl;
  late String _cookie;

  late PhoenixSocket _socket;
  late PhoenixSocket _liveReloadSocket;

  late PhoenixChannel _channel;

  late m.Widget rootWidget;

  final Function() onReload;

  late StateNotifier _changeNotifier;
  late LiveConnectionNotifier _connectionNotifier;

  LiveView({required this.onReload}) {
    rootWidget = connectingWidget();
    _changeNotifier = StateNotifier();
    _connectionNotifier = LiveConnectionNotifier();
  }

  Future<String?> connect(String address) async {
    _baseUrl = address;
    var endpoint = Uri.parse(address);
    var r = await http.get(endpoint);
    var content = html.parse(r.body);

    _host = "${endpoint.host}:${endpoint.port}";
    _clientId = const Uuid().v4();
    _cookie = r.headers['set-cookie']!.split(' ')[0];

    _readInitialSession(content);
    await _websocketConnect();
    await _setupLiveReload();
    await _setupPhoenixChannel();

    return _csrf;
  }

  _readInitialSession(Document content) {
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

  _fullsocketParams() => {
        'session': _session,
        'static': _phxStatic,
        'url': _baseUrl,
        'params': _socketParams()
      };

  _websocketConnect() async {
    _socket = PhoenixSocket("ws://$_host/live/websocket",
        socketOptions: PhoenixSocketOptions(
          params: _socketParams(),
          headers: {'Cookie': _cookie},
        ));

    await _socket.connect();
  }

  _setupPhoenixChannel() async {
    _channel = _socket.addChannel(
        topic: "lv:$_liveViewId", parameters: _fullsocketParams());

    _channel.messages.listen(handleMessage);

    if (_channel.state != PhoenixChannelState.joined) {
      await _channel.join().future;
    }
  }

  _setupLiveReload() async {
    _liveReloadSocket =
        PhoenixSocket("ws://$_host/phoenix/live_reload/socket/websocket",
            socketOptions: PhoenixSocketOptions(
              params: _socketParams(),
              headers: {'Cookie': _cookie},
            ));
    var liveReload = _liveReloadSocket.addChannel(
        topic: "phoenix:live_reload", parameters: _fullsocketParams());
    liveReload.messages.listen(liveReloadMessage);

    await _liveReloadSocket.connect();
    if (liveReload.state != PhoenixChannelState.joined) {
      await liveReload.join().future;
    }
  }

  handleMessage(Message event) {
    print("message received: $event");
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

    rootWidget = MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _changeNotifier),
          ChangeNotifierProvider.value(value: _connectionNotifier),
        ],
        child: LiveViewUiParser(
                html: elements,
                htmlVariables: _extractVariables(rendered),
                onEvent: onEvent,
                liveView: this)
            .parse());
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

  liveReloadMessage(Message event) async {
    if (event.event.value == 'assets_change') {
      _socket.removeChannel(_channel);
      _socket.close();
      _liveReloadSocket.close();
      _changeNotifier.emptyData();
      _channel.close();
      rootWidget = connectingWidget();
      onReload();

      connect(_baseUrl);
    }
  }

  onEvent(String eventName, String value) {
    if (eventName == 'phx-click') {
      _channel.push('event', {'type': 'click', 'event': value, 'value': {}});
    }
  }

  sendEvent(LiveEvent event) {
    _channel.push('event',
        {'type': event.type, 'event': event.name, 'value': event.value});
  }

  Widget connectingWidget() {
    return const m.Scaffold(body: m.Text('Connecting....'));
  }
}
