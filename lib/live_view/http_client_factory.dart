import 'package:http/http.dart' as http;

/// Creates a platform-appropriate HTTP client.
///
/// This stub is replaced at compile time by the IO or HTML implementation
/// depending on the target platform.
http.Client createHttpClient() {
  throw UnsupportedError('Cannot create an HTTP client for this platform.');
}
