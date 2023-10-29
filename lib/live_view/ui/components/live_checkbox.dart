import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveCheckbox extends LiveStateWidget<LiveCheckbox> {
  const LiveCheckbox({super.key, required super.state});

  @override
  State<LiveCheckbox> createState() => _LiveCheckboxState();
}

class _LiveCheckboxState extends StateWidget<LiveCheckbox> {
  var unamedInput = const Uuid().v4();
  bool _isChecked = false;
  bool _initialBoot = true;

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

  @override
  void onWipeState() {
    _initialBoot = true;
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['checked', 'name']);
    if (_initialBoot) {
      _isChecked = booleanAttribute('checked') ?? false;
      _initialBoot = false;
    }
  }

  @override
  Widget render(BuildContext context) {
    return Checkbox(
      value: _isChecked,
      onChanged: (val) {
        setState(() {
          _isChecked = val ?? false;
        });
        FormFieldEvent(
          name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
          data: _isChecked ? 'on' : null,
          type: FormFieldEventType.change,
        ).dispatch(context);
        executeTapEventsManually();
      },
    );
  }
}
