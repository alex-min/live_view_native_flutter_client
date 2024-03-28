import 'package:liveview_flutter/live_view/socket/channel.dart';

abstract class LiveSocket {
  String get url;

  Future<void> create({
    required String url,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  });

  Future<void> connect();
  Future<void> close();

  LiveChannel addChannel({
    required String topic,
    Map<String, dynamic>? parameters,
  });
}
