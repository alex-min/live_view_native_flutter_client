import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class FormEvents {
  final void Function() onSave;
  FormEvents({required this.onSave});
}

class LiveForm extends LiveStateWidget<LiveForm> {
  const LiveForm({super.key, required super.state});

  @override
  State<LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends StateWidget<LiveForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(['phx-change', 'phx-submit']);
  }

  void onFormEvent(String eventKind, {sendOnChange = true}) {
    if (_formKey.currentState == null && getAttribute(eventKind) == null) {
      return;
    }
    List<String> inputChanged = [];
    var previousInput = Map<String, dynamic>.from(_formKey.currentState!.value);
    _formKey.currentState?.saveAndValidate();
    var nextInput = Map<String, dynamic>.from(_formKey.currentState!.value);

    for (var item in nextInput.entries) {
      if (!previousInput.containsKey(item.key)) {
        if (!inputChanged.contains(item.key)) {
          inputChanged.add(item.key);
        }
      } else if (previousInput[item.key] != item.value) {
        if (!inputChanged.contains(item.key)) {
          inputChanged.add(item.key);
        }
      }
    }

    if (inputChanged.isNotEmpty || !sendOnChange) {
      Map<String, dynamic> ret =
          Map<String, dynamic>.from(_formKey.currentState!.value);
      if (inputChanged.isNotEmpty) {
        ret['_target'] = inputChanged.last;
      }
      liveView.sendEvent(LiveEvent(
          type: 'form',
          name: getAttribute(eventKind)!,
          value: Uri(host: 'localhost', queryParameters: ret).query));
    }
  }

  @override
  Widget render(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      onChanged: () => onFormEvent('phx-change'),
      child: singleChild(
          state: widget.state.copyWith(formEvents: FormEvents(onSave: () {
        onFormEvent('phx-submit', sendOnChange: false);
      }))),
    );
  }
}
