import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveOutlinedButton extends LiveStateWidget<LiveOutlinedButton> {
  const LiveOutlinedButton({super.key, required super.state});

  @override
  State<LiveOutlinedButton> createState() => _LiveOutlinedButtonState();
}

class _LiveOutlinedButtonState extends StateWidget<LiveOutlinedButton> {
  final unnamedInput = const Uuid().v4();

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

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
  Widget render(BuildContext context) {
    return OutlinedButton(
      style: buttonStyleAttribute(context, 'style'),
      autofocus: booleanAttribute('autofocus') ?? false,
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
      onPressed: () {
        if (getAttribute('type') == 'submit') {
          FormFieldEvent(
            name:
                getAttribute('name') ?? 'unnamed-outlined-button-$unnamedInput',
            data: null,
            type: FormFieldEventType.submit,
          ).dispatch(context);
        }
        executeTapEventsManually();
      },
      child: AbsorbPointer(child: singleChild()),
    );
  }
}
