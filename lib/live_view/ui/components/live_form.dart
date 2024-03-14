import 'package:flutter/material.dart';
import 'package:http_query_string/http_query_string.dart' as qs;
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

enum FormFieldEventType { initField, change, submit }

class FormFieldEvent extends Notification {
  final String name;
  final dynamic data;
  final FormFieldEventType type;

  const FormFieldEvent(
      {required this.name, required this.data, required this.type});

  @override
  String toString() => "FormFieldEvent(type=$type,name=$name,data=$data)";
}

class FormError {
  final String message;
  Map<String, dynamic>? options;

  FormError({required this.message, required this.options});
}

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
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> formValues = {};

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['phx-change', 'phx-submit']);
  }

  @override
  void onWipeState() {
    formValues = {};
    super.onWipeState();
  }

  void sendFormEvent(String eventKind, {String? target}) {
    if (getAttribute(eventKind) == null) {
      return;
    }
    var nonNullValues = Map<String, dynamic>.from(formValues)
      ..removeWhere((_, value) => value == null);

    if (target != null) {
      nonNullValues['_target'] = target;
    }

    liveView.sendEvent(ExecLiveEvent(
        type: 'form',
        name: getAttribute(eventKind)!,
        value: qs.Encoder().convert(nonNullValues)));
  }

  @override
  Widget render(BuildContext context) {
    return Form(
        key: _formKey,
        child: NotificationListener<FormFieldEvent>(
          onNotification: (event) {
            if (event.type == FormFieldEventType.change ||
                event.type == FormFieldEventType.initField) {
              formValues[event.name] = event.data;
            }

            if (event.type == FormFieldEventType.change) {
              sendFormEvent('phx-change', target: event.name);
            } else if (event.type == FormFieldEventType.submit) {
              sendFormEvent('phx-submit', target: event.name);
            }
            return true;
          },
          child: singleChild(),
        ));
  }
}
