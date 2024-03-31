import 'package:liveview_flutter/exec/exec.dart';

typedef ExecBuilder = Exec Function(
    Map<String, dynamic>? value, Map<String, dynamic>? attributes);

enum LiveViewExecTrigger { onTap, onWindowResize }

class LiveViewExecRegistry {
  LiveViewExecRegistry._internal();

  static final LiveViewExecRegistry _instance =
      LiveViewExecRegistry._internal();

  final Map<String, ExecBuilder> _execs = {};
  final Map<LiveViewExecTrigger, List<String>> _execsByTriggers = {};

  static LiveViewExecRegistry get instance => _instance;

  List<String> execsByTrigger(LiveViewExecTrigger trigger) =>
      _execsByTriggers[trigger] ?? [];

  void add(List<String> execNames, ExecBuilder execBuilder,
      {List<LiveViewExecTrigger> triggers = const []}) {
    for (var execName in execNames) {
      _execs[execName] = execBuilder;
    }
    for (var trigger in triggers) {
      _execsByTriggers[trigger] ??= [];
      for (var execName in execNames) {
        if (!_execsByTriggers[trigger]!.contains(execName)) {
          _execsByTriggers[trigger]!.add(execName);
        }
      }
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
