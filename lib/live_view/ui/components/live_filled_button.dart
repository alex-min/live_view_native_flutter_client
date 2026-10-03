import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveFilledButton extends LiveStateWidget<LiveFilledButton> {
  const LiveFilledButton({super.key, required super.state});

  @override
  State<LiveFilledButton> createState() => _LiveFilledButtonState();
}

class _LiveFilledButtonState extends StateWidget<LiveFilledButton> {
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
    return FilledButton(
      style: buttonStyleAttribute(context, 'style'),
      autofocus: booleanAttribute('autofocus') ?? false,
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
      onPressed: () {
        if (getAttribute('type') == 'submit') {
          FormFieldEvent(
            name: getAttribute('name') ?? 'unamed-filled-button-$unamedInput',
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
