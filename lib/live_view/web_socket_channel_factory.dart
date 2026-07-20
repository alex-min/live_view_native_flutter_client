import 'package:web_socket_channel/web_socket_channel.dart';

/// Creates a platform-appropriate WebSocket channel.
///
/// This stub is replaced at compile time by the IO or HTML implementation
/// depending on the target platform.
WebSocketChannel connect(String url, {Map<String, dynamic>? headers}) {
  throw UnsupportedError(
    'Cannot create a WebSocket channel for this platform.',
  );
}
