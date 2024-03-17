import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveTextButton extends LiveStateWidget<LiveTextButton> {
  const LiveTextButton({super.key, required super.state});

  @override
  State<LiveTextButton> createState() => _LiveTextButtonState();
}

class _LiveTextButtonState extends StateWidget<LiveTextButton> {
  var unamedInput = const Uuid().v4();

  @override
  handleClickState() => HandleClickState.manual;

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
    return TextButton(
        style: buttonStyleAttribute(context, 'style'),
        autofocus: booleanAttribute('autofocus') ?? false,
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
        onPressed: () {
          if (getAttribute('type') == 'submit') {
            FormFieldEvent(
                    name: getAttribute('name') ??
                        'unamed-text-button-$unamedInput',
                    data: null,
                    type: FormFieldEventType.submit)
                .dispatch(context);
          }
          executeTapEventsManually();
        },
        child: AbsorbPointer(child: singleChild()));
  }
}
