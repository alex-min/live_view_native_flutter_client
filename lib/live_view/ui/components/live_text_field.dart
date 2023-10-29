import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:liveview_flutter/live_view/mapping/inputDecoration.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveTextField extends LiveStateWidget<LiveTextField> {
  const LiveTextField({super.key, required super.state});

  @override
  State<LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends StateWidget<LiveTextField> {
  final key = GlobalKey<FormFieldState>();
  var unamedInput = const Uuid().v4();

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      validateInput();
      sendInitialState();
    });
    super.initState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(
        node, ['name', 'value', 'decoration', 'obscureText', 'error']);
    validateInput();
    //key.currentState?.didChange(getAttribute('value'));
  }

  void validateInput() => key.currentState?.validate();
  void sendInitialState() {
    reloadAttributes(node, ['value', 'name']);
    FormFieldEvent(
      name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
      data: getAttribute('value') ?? '',
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var icon = StateChild.extractChild<LiveIconAttribute>(children);
    return TextFormField(
        validator: (_) {
          var error = getAttribute('error');
          return error == '' ? null : error;
        },
        key: key,
        obscureText: booleanAttribute('obscureText') ?? false,
        decoration: getInputDecoration(
          context,
          getAttribute('decoration'),
          icon: icon,
        ),
        onChanged: (value) {
          FormFieldEvent(
            name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
            data: value,
            type: FormFieldEventType.change,
          ).dispatch(context);
        },
        //name: getAttribute('name') ?? "unamed-attribute-${const Uuid().v4()}",
        initialValue: getAttribute('value'));
  }
}
