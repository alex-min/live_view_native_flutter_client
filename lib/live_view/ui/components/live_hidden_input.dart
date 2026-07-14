import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveHiddenInput extends LiveStateWidget<LiveHiddenInput> {
  const LiveHiddenInput({super.key, required super.state});

  @override
  State<LiveHiddenInput> createState() => _LiveHiddenInputState();
}

class _LiveHiddenInputState extends StateWidget<LiveHiddenInput> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['name', 'value']);

    // Dispatch after the current frame so the widget is mounted inside the
    // Form's NotificationListener.
    Future.microtask(() {
      if (!mounted) return;
      FormFieldEvent(
        name: getAttribute('name') ?? 'unamed-hidden-input',
        data: getAttribute('value') ?? '',
        type: FormFieldEventType.initField,
      ).dispatch(context);
    });
  }

  @override
  Widget render(BuildContext context) {
    return const SizedBox.shrink();
  }
}
