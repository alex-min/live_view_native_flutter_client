import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/error_404.dart';
import 'package:liveview_flutter/live_view/ui/errors/flutter_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/no_server_error_view.dart';

class LiveViewFallbackPages {
  final bool _debugMode;
  final Widget Function(LiveView, [String?])? _connectingBuilder;
  final Widget Function(LiveView, String)? _loadingBuilder;
  final Widget Function(LiveView, Uri)? _notFoundErrorBuilder;
  final Widget Function(LiveView, Response)? _compilationErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _noServerErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _flutterErrorBuilder;

  /// Constructs the fallback widgets
  ///
  /// [debugMode] determines if the fallback widget should be ignored in debug mode
  const LiveViewFallbackPages({
    bool debugMode = kDebugMode,
    Widget Function(LiveView, [String?])? connectingBuilder,
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
    return _wrapper(
      liveView,
      customBuilder: _loadingBuilder,
      param: url,
      defaultBuilder: () => Builder(
        builder: (context) => Container(
          color: Theme.of(context).colorScheme.background,
          child: Center(
            child: CircularProgressIndicator(
              value: liveView.disableAnimations == false ? null : 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the widget to be displayed when the client is connecting
  Widget buildConnecting(LiveView liveView, [String? url]) {
    return _wrapper(
      liveView,
      customBuilder: _connectingBuilder,
      param: url,
      defaultBuilder: () => Builder(
        builder: (context) => Container(
          color: Theme.of(context).colorScheme.background,
          child: Center(
            child: CircularProgressIndicator(
              value: liveView.disableAnimations == false ? null : 1,
            ),
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
    return _wrapper(
      liveView,
      customBuilder: _compilationErrorBuilder,
      param: response,
      defaultBuilder: () => CompilationErrorView(html: response.body),
    );
  }

  /// Returns the widget to be displayed in case when the requested
  /// page is not found
  Widget buildNotFoundError(LiveView liveView, Uri endpoint) {
    return _wrapper(
      liveView,
      customBuilder: _notFoundErrorBuilder,
      param: endpoint,
      defaultBuilder: () => Error404(url: endpoint.toString()),
    );
  }

  /// Returns the widget to be displayed in case of an error in the server
  Widget buildNoServerError(LiveView liveView, FlutterErrorDetails details) {
    return _wrapper(
      liveView,
      customBuilder: _noServerErrorBuilder,
      param: details,
      defaultBuilder: () => NoServerError(error: details),
    );
  }

  /// Returns the widget to be displayed in case of an error in the Flutter
  Widget buildFlutterError(LiveView liveView, FlutterErrorDetails details) {
    return _wrapper(
      liveView,
      customBuilder: _flutterErrorBuilder,
      param: details,
      defaultBuilder: () => FlutterErrorView(error: details),
    );
  }

  Widget _wrapper<T>(
    LiveView liveView, {
    required Widget Function(LiveView, T)? customBuilder,
    required T param,
    required Widget Function() defaultBuilder,
  }) {
    if (!_debugMode && customBuilder != null) {
      return customBuilder(liveView, param);
    }

    return defaultBuilder();
  }
}
