import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/inputDecoration.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:uuid/uuid.dart';

class LiveTextField extends LiveStateWidget<LiveTextField> {
  const LiveTextField({super.key, required super.state});

  @override
  State<LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends StateWidget<LiveTextField> {
  List<String> attributes = [
    'name',
    'initialValue',
    'decoration',
    'obscureText',
    'errors',
    'keyboardType',
    'maxLines',
    'minLines',
    'maxLength',
    'expands',
    'readOnly',
    'autocorrect',
    'enableSuggestions',
    'showCursor',
    'obscuringCharacter'
  ];
  final key = GlobalKey<FormFieldState>();
  var unamedInput = const Uuid().v4();
  List<FormError> errors = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      parseErrors();
      validateInput();
      sendInitialState();
    });
    super.initState();
  }

  @override
  void onWipeState() {
    errors = [];
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    parseErrors();
    validateInput();
  }

  void validateInput() => key.currentState?.validate();
  void sendInitialState() {
    reloadAttributes(node, attributes);
    FormFieldEvent(
      name: getAttribute('name') ?? "unamed-text-field-$unamedInput",
      data: getAttribute('initialValue') ?? '',
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  void parseErrors() {
    reloadAttributes(node, attributes);
    List<dynamic>? serverErrors = tryJsonDecode(getAttribute('errors'));
    if (serverErrors == null) {
      return;
    }
    errors = serverErrors
        .map((e) => FormError(
              message: e['message'],
              options: e['options'],
            ))
        .toList();
  }

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var icon = StateChild.extractChild<LiveIconAttribute>(children);
    var keyboardType = textInputTypeAttribute('keyboardType');
    return TextFormField(
        obscuringCharacter: getAttribute('obscuringCharacter') ?? '•',
        showCursor: booleanAttribute('showCursor'),
        enableSuggestions: booleanAttribute('enableSuggestions') ?? true,
        autocorrect: booleanAttribute('autocorrect') ?? false,
        expands: booleanAttribute('expands') ?? false,
        readOnly: booleanAttribute('readOnly') ?? false,
        keyboardType: keyboardType,
        maxLength: intAttribute('maxLength'),
        minLines: intAttribute('minLines'),
        maxLines: getAttribute('maxLines') == 'unlimited'
            ? null
            : intAttribute('maxLines') ?? 1,
        autovalidateMode: AutovalidateMode.disabled,
        validator: (_) {
          var message = errors.map((e) => e.message).join('\n');
          return message == '' ? null : message;
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
        initialValue: getAttribute('initialValue'));
  }
}
