import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Creates an HTML-backed WebSocket channel (web browser).
WebSocketChannel connect(String url, {Map<String, dynamic>? headers}) {
  // Browser WebSocket handshakes do not support custom headers.
  return HtmlWebSocketChannel.connect(url);
}
