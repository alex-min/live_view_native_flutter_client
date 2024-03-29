import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/error_404.dart';
import 'package:liveview_flutter/live_view/ui/errors/flutter_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/no_server_error_view.dart';

class LiveViewFallbackWidgets {
  final bool _debugMode;
  final Widget Function(LiveView)? _connectingBuilder;
  final Widget Function(LiveView, String)? _loadingBuilder;
  final Widget Function(LiveView, Uri)? _notFoundErrorBuilder;
  final Widget Function(LiveView, Response)? _compilationErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _noServerErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _flutterErrorBuilder;

  /// Constructs the fallback widgets
  ///
  /// [debugMode] determines if the fallback widget should be ignored in debug mode
  const LiveViewFallbackWidgets({
    bool debugMode = kDebugMode,
    Widget Function(LiveView)? connectingBuilder,
    Widget Function(LiveView, String)? loadingBuilder,
    Widget Function(LiveView, Uri)? notFoundErrorBuilder,
    Widget Function(LiveView, Response)? compilationErrorBuilder,
    Widget Function(LiveView, FlutterErrorDetails)? noServerErrorBuilder,
    Widget Function(LiveView, FlutterErrorDetails)? flutterErrorBuilder,
  })  : _debugMode = debugMode,
        _connectingBuilder = connectingBuilder,
        _loadingBuilder = loadingBuilder,
        _notFoundErrorBuilder = notFoundErrorBuilder,
        _noServerErrorBuilder = noServerErrorBuilder,
        _compilationErrorBuilder = compilationErrorBuilder,
        _flutterErrorBuilder = flutterErrorBuilder;

  /// Returns the widget to be displayed when the page is loading
  Widget buildLoading(LiveView liveView, String url) {
    if (_loadingBuilder != null) {
      return _loadingBuilder(liveView, url);
    }

    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: CircularProgressIndicator(
            value: liveView.disableAnimations == false ? null : 1,
          ),
        ),
      ),
    );
  }

  /// Returns the widget to be displayed when the client is connecting
  Widget buildConnecting(LiveView liveView) {
    if (_connectingBuilder != null) {
      return _connectingBuilder(liveView);
    }

    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: CircularProgressIndicator(
            value: liveView.disableAnimations == false ? null : 1,
          ),
        ),
      ),
    );
  }

  /// Returns the widget to be displayed in case of a compilation error
  /// due to an error in the Dart code during the xml compilation
  Widget buildCompilationError(
    LiveView liveView,
    Response response,
  ) {
    if (!_debugMode && _compilationErrorBuilder != null) {
      return _compilationErrorBuilder(liveView, response);
    }

    return CompilationErrorView(html: response.body);
  }

  /// Returns the widget to be displayed in case when the requested
  /// page is not found
  Widget buildNotFoundError(LiveView liveView, Uri endpoint) {
    if (!_debugMode && _notFoundErrorBuilder != null) {
      return _notFoundErrorBuilder(liveView, endpoint);
    }

    return Error404(url: endpoint.toString());
  }

  /// Returns the widget to be displayed in case of an error in the server
  Widget buildNoServerError(LiveView liveView, FlutterErrorDetails details) {
    if (!_debugMode && _noServerErrorBuilder != null) {
      return _noServerErrorBuilder(liveView, details);
    }

    return NoServerError(error: details);
  }

  /// Returns the widget to be displayed in case of an error in the Flutter
  Widget buildFlutterError(LiveView liveView, FlutterErrorDetails details) {
    if (!_debugMode && _flutterErrorBuilder != null) {
      return _flutterErrorBuilder(liveView, details);
    }

    return FlutterErrorView(error: details);
  }
}
