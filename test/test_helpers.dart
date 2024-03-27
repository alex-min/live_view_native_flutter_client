// ignore_for_file: overridden_fields

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response jsonHttpResponse(dynamic data) {
  return http.Response(jsonEncode(data), 200,
      headers: {'content-type': 'application/json'});
}

class BasicColors {
  static Color red = const Color.fromARGB(255, 255, 0, 0);
  static Color blue = const Color.fromARGB(255, 0, 0, 255);
}

extension ButtonColor on ThemeData {
  Color? get elevatedButtonBgColor =>
      elevatedButtonTheme.style?.backgroundColor?.resolve({});
}

extension TakeKeys on Map {
  Map<String, dynamic> takeKeys(List<String> keys) =>
      Map.fromEntries(keys.map((key) => MapEntry(key, this[key])));
}

extension FindText on CommonFinders {
  String? firstText() => allTexts().firstOrNull;

  T firstOf<T>() => byType(T).evaluate().first.widget as T;
  List<String> allTexts() =>
      (byType(Text).evaluate().map((e) => (e.widget as Text).data ?? ''))
          .toList();
}

extension ValueText on FormBuilderTextField {
  String get value =>
      (key! as GlobalKey<FormBuilderFieldState>).currentState!.value;
}

extension RunLiveView on WidgetTester {
  Future<void> runLiveView(LiveView view) async {
    view.throttleSpammyCalls = false;
    view.catchExceptions = false;
    view.disableAnimations = true;
    await pumpWidget(view.rootView);
  }

  void setScreenSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
  }

  Future<void> checkScreenshot(String content, String filename) async {
    await loadAppFonts();
    var (view, _) = await connect(LiveView(), rendered: {
      's': [content],
    });

    await runLiveView(view);
    await pumpAndSettle();

    await expectLater(find.byType(MaterialApp), matchesGoldenFile(filename));
  }
}

class FakePushMessage extends Push {
  FakePhoenixChannel channel;
  FakePushMessage(this.channel) : super(channel);

  @override
  Future<PushResponse> get future async {
    return PushResponse(status: '200', response: '');
  }
}

class EventSent {
  final String eventName;
  final Map<String, dynamic>? payload;

  const EventSent(this.eventName, this.payload);

  @override
  String toString() => "EventSent(eventName: $eventName, payload: $payload)";

  @override
  bool operator ==(Object other) {
    if (other is EventSent) {
      return other.toString() == toString();
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([toString()]);
}

class FakePhoenixChannel extends PhoenixChannel {
  @override
  final PhoenixSocket socket;
  @override
  final String topic;
  List<EventSent> actions = [];
  Map<String, dynamic>? params = {};
  PhoenixChannelState currentState = PhoenixChannelState.closed;

  FakePhoenixChannel(this.socket, this.topic, this.params)
      : super.fromSocket(socket, topic: topic, parameters: params);

  @override
  PhoenixChannelState get state => currentState;

  @override
  Push join([Duration? newTimeout]) {
    actions.add(const EventSent('join', null));
    currentState = PhoenixChannelState.joined;

    return FakePushMessage(this);
  }

  @override
  Push push(String eventName, Map<String, dynamic> payload,
      [Duration? newTimeout]) {
    if (eventName == 'phx_leave') {
      currentState = PhoenixChannelState.closed;
    }
    actions.add(EventSent(eventName, payload));
    return FakePushMessage(this);
  }
}

class FakePhoenixSocket extends PhoenixSocket {
  String url;
  PhoenixSocketOptions? socketOptions;
  List<EventSent> actions = [];
  List<FakePhoenixChannel> channelsAdded = [];

  FakePhoenixSocket(this.url, this.socketOptions) : super(url);

  @override
  Future<PhoenixSocket?> connect() async {
    actions.add(const EventSent('connect', null));
    return null;
  }

  @override
  PhoenixChannel addChannel(
      {required String topic,
      Map<String, dynamic>? parameters,
      Duration? timeout}) {
    actions.add(EventSent('addChannel', parameters));
    var channel = FakePhoenixChannel(this, topic, parameters);
    channelsAdded.add(channel);
    return channel;
  }

  @override
  String toString() => 'FakePhoenixSocket($url)';

  List<EventSent> get addChannelEvents =>
      actions.where((a) => a.eventName == 'addChannel').toList();

  List<Map<String, String?>> get navigationLogs => addChannelEvents
      .map((e) => Map<String, String?>.from(
          e.payload?.takeKeys(['url', 'redirect']) ?? {}))
      .toList();
}

class FakeLiveSocket extends LiveSocket {
  List<FakePhoenixSocket> socketsOpened = [];
  List<http.Request> httpRequestsMade = [];

  @override
  PhoenixSocket create(
      {required String url,
      required Map<String, dynamic>? params,
      required Map<String, String>? headers}) {
    var socket = FakePhoenixSocket(
        url,
        PhoenixSocketOptions(
          params: params,
          headers: headers,
        ));
    socketsOpened.add(socket);
    return socket;
  }

  FakePhoenixSocket? get liveSocket {
    for (var socket in socketsOpened) {
      if (socket.url.endsWith('/live/websocket')) {
        return socket;
      }
    }
    return null;
  }

  FakePhoenixChannel? get lastChannel => liveSocket?.channelsAdded.last;
  List<EventSent>? get lastChannelActions => lastChannel?.actions;
  EventSent? get lastChannelAction => lastChannelActions?.last;
}

Future<(LiveView, FakeLiveSocket)> connect(LiveView view,
    {Map<String, dynamic>? rendered,
    http.Response? Function(http.Request)? onRequest,
    ViewType viewType = ViewType.liveView}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  var socket = FakeLiveSocket();
  final MockClient client = MockClient((request) async {
    socket.httpRequestsMade.add(request);
    if (onRequest != null) {
      var response = onRequest(request);
      if (response != null) {
        return response;
      }
    }
    return http.Response(
        """
        <meta name="csrf-token" content="csrf" />
        <div data-phx-session="phx-session" data-phx-static="static" data-phx-main id="live_view_id"></div>
      """,
        200,
        headers: {'set-cookie': 'live_view=session'});
  });

  view.liveSocket = socket;
  view.httpClient = client;
  await view.connect('http://localhost:9999');
  if (rendered != null) {
    view.handleRenderedMessage(rendered, viewType: viewType);
  }
  return (view, socket);
}

class BaseEvents {
  final join = const EventSent('join', null);
  final phxLeave = const EventSent('phx_leave', {});
  EventSent phxClick(dynamic value, {String eventName = 'click_event'}) =>
      EventSent(
          'event', {'type': 'phx-click', 'event': eventName, 'value': value});
  EventSent phxFormValidate(String name, String value) =>
      EventSent('event', {'type': 'form', 'event': name, 'value': value});
  EventSent event(String event) =>
      EventSent('event', {'type': 'event', 'event': event, 'value': {}});
  EventSent click(dynamic value, {String eventName = 'click_event'}) =>
      EventSent('event', {'type': 'click', 'event': eventName, 'value': value});

  const BaseEvents();
}

class BaseActions {
  String show = FlutterExec.encode([FlutterExecAction(name: 'show')]);
  String hide = FlutterExec.encode([FlutterExecAction(name: 'hide')]);
  String goBack = FlutterExec.encode([FlutterExecAction(name: 'goBack')]);
  String switchTheme(String mode, {String theme = 'default'}) =>
      FlutterExec.encode([
        FlutterExecAction(
            name: 'switchTheme', value: {'mode': mode, 'theme': theme})
      ]);
  String showBottomSheet =
      FlutterExec.encode([FlutterExecAction(name: 'showBottomSheet')]);
}

var liveEvents = const BaseEvents();
var baseActions = BaseActions();
