import 'package:liveview_flutter/live_view/socket/message.dart';

abstract class LiveChannel {
  Stream<LiveMessage> get messages;
  String get topic;
  Map<String, dynamic> get parameters;

  Future<void> join();

  Future<void> push(
    String event, [
    Map<String, dynamic> payload = const {},
  ]);

  Future<void> close();
}
