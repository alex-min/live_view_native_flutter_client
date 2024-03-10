import 'package:liveview_flutter/exec/exec.dart';

typedef ExecBuilder = Exec Function(
    Map<String, dynamic>? value, Map<String, dynamic>? attributes);

class LiveViewExecRegistry {
  LiveViewExecRegistry._internal();

  static final LiveViewExecRegistry _instance =
      LiveViewExecRegistry._internal();

  final Map<String, ExecBuilder> _execs = {};

  static LiveViewExecRegistry get instance => _instance;

  void add(List<String> execNames, ExecBuilder execBuilder) {
    for (var execName in execNames) {
      _execs[execName] = execBuilder;
    }
  }

  Exec? exec(
    String name, {
    Map<String, dynamic>? value,
    Map<String, dynamic>? attributes,
  }) {
    if (_execs.containsKey(name)) {
      return _execs[name]!.call(value, attributes);
    }

    return null;
  }
}
