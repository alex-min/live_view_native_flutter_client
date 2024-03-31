import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/plugin.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';

class MyWidget extends LiveStateWidget<MyWidget> {
  const MyWidget({super.key, required super.state});

  @override
  State<MyWidget> createState() => _MyWidget();
}

class _MyWidget extends StateWidget<MyWidget> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) => const Text('MyComponent');
}

List<dynamic> myPluginActions = [];

class MyPluginExec extends Exec {
  Map<String, dynamic>? attributes;
  MyPluginExec({required this.attributes});

  @override
  void handler(BuildContext context, StateWidget widget) {
    myPluginActions.add(attributes!['phx-my-plugin']);
  }
}

class BasicPlugin extends Plugin {
  @override
  String get name => "my_plugin";

  @override
  registerWidgets(LiveViewUiRegistry registry) {
    registry.add(['MyComponent'], (state) => [MyWidget(state: state)]);
  }

  @override
  registerExecs(LiveViewExecRegistry registry) {
    registry.add(['phx-my-plugin'],
        (value, attributes) => MyPluginExec(attributes: attributes),
        triggers: [LiveViewExecTrigger.onTap]);
  }
}
