import 'package:liveview_flutter/live_view/socket/channel.dart';
import 'package:liveview_flutter/live_view/socket/message.dart';
import 'package:liveview_flutter/live_view/socket/socket.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class LiveChannelImpl implements LiveChannel {
  PhoenixChannel channel;
  LiveChannelImpl({required this.channel});

  @override
  String get topic => channel.topic;

  @override
  Map<String, dynamic> get parameters => channel.parameters;

  @override
  Stream<LiveMessage> get messages {
    return channel.messages.map(
      (message) => LiveMessage(
        event: message.event.value,
        payload: message.payload,
        topic: message.topic,
        ref: message.ref,
      ),
    );
  }

  @override
  Future<void> join() async {
    if (channel.state != PhoenixChannelState.joined) {
      await channel.join().future;
    }
  }

  @override
  Future<void> push(
    String event, [
    Map<String, dynamic> payload = const {},
  ]) async {
    if (channel.state != PhoenixChannelState.closed) {
      await channel.push(event, payload).future;
    }
  }

  @override
  Future<void> close() async {
    channel.close();
  }
}

class LiveSocketImpl implements LiveSocket {
  late PhoenixSocket phoenixSocket;
  String _url = '';

  @override
  String get url => _url;

  @override
  Future<void> create({
    required String url,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    _url = url;
    phoenixSocket = PhoenixSocket(
      url,
      socketOptions: PhoenixSocketOptions(
        params: params,
        headers: headers,
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

  @override
  Future<void> connect() async {
    await phoenixSocket.connect();
  }

  @override
  LiveChannel addChannel({
    required String topic,
    Map<String, dynamic>? parameters,
  }) {
    final channel = phoenixSocket.addChannel(
      topic: topic,
      parameters: parameters,
    );

    return LiveChannelImpl(channel: channel);
  }

  @override
  Future<void> close() async {
    phoenixSocket.close();
  }
}
