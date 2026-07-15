import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Creates a browser-backed HTTP client (web) that sends/receives cookies
/// across origins. This is required for Phoenix LiveView session validation
/// when the Flutter web client is served from a different port than Phoenix.
http.Client createHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
