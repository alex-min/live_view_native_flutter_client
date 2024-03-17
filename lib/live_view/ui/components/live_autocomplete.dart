import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveAutocomplete extends LiveStateWidget<LiveAutocomplete> {
  const LiveAutocomplete({super.key, required super.state});

  @override
  State<LiveAutocomplete> createState() => _LiveAutocompleteState();
}

class _LiveAutocompleteState extends StateWidget<LiveAutocomplete> {
  final attributes = [
    'options',
    'name',
    'initialValue',
    'optionsViewOpenDirection',
    'optionsMaxHeight'
  ];
  bool allowInitialValueChange = true;
  var unamedInput = const Uuid().v4();
  TextEditingValue? initialValue;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      sendInitialFormState();
    });
    super.initState();
  }

  @override
  void onWipeState() {
    allowInitialValueChange = true;
    super.onWipeState();
  }

  void sendInitialFormState() {
    reloadAttributes(node, attributes);
    FormFieldEvent(
      name: getAttribute('name') ?? "unamed-autocomplete-$unamedInput",
      data: getAttribute('initialValue'),
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    if (allowInitialValueChange) {
      allowInitialValueChange = false;
      var val = getAttribute('initialValue');
      if (val != null) {
        initialValue = TextEditingValue(text: val);
      }
    }
  }

  @override
  Widget render(BuildContext context) {
    var options = childrenNodesOf(node, 'Result').map((result) {
      var attributes = bindChildVariableAttributes(
          result, ['value'], widget.state.variables);
      return attributes['value'] ?? '';
    }).toList();

    return Autocomplete<String>(
        initialValue: initialValue,
        optionsBuilder: (field) {
          FormFieldEvent(
                  name: getAttribute('name') ??
                      'unamed-autocomplete-$unamedInput',
                  data: field.text,
                  type: FormFieldEventType.change)
              .dispatch(context);
          return options;
        },
        optionsViewOpenDirection:
            optionsViewOpenDirectionAttribute('optionsViewOpenDirection') ??
                OptionsViewOpenDirection.down,
        optionsMaxHeight: doubleAttribute('optionsMaxHeight') ?? 200.0,
        onSelected: (selected) {});
  }
}
