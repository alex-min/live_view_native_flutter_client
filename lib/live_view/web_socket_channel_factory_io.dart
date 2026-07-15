import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Creates an IO-backed WebSocket channel (mobile/desktop).
WebSocketChannel connect(String url, {Map<String, dynamic>? headers}) {
  return IOWebSocketChannel.connect(url, headers: headers);
}
