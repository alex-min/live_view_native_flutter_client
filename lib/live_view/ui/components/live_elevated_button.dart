import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveElevatedButton extends LiveStateWidget<LiveElevatedButton> {
  const LiveElevatedButton({super.key, required super.state});

  @override
  State<LiveElevatedButton> createState() => _LiveElevatedButtonState();
}

class _LiveElevatedButtonState extends StateWidget<LiveElevatedButton> {
  var unamedInput = const Uuid().v4();

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'type',
      'name',
      'style',
      'autofocus',
      'clipBehavior',
    ]);
  }

  @override
  handleClickState() => HandleClickState.manual;

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
        style: buttonStyleAttribute(context, 'style'),
        autofocus: booleanAttribute('autofocus') ?? false,
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
        onPressed: () {
          if (getAttribute('type') == 'submit') {
            FormFieldEvent(
                    name: getAttribute('name') ??
                        'unamed-elevated-button-$unamedInput',
                    data: null,
                    type: FormFieldEventType.submit)
                .dispatch(context);
          }
          executeTapEventsManually();
        },
        child: AbsorbPointer(child: singleChild()));
  }
}
