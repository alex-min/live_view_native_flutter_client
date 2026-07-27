import 'package:flutter/material.dart';
import 'package:http_query_string/http_query_string.dart' as qs;
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

enum FormFieldEventType { initField, change, submit }

class FormFieldEvent extends Notification {
  final String name;
  final dynamic data;
  final FormFieldEventType type;

  const FormFieldEvent({
    required this.name,
    required this.data,
    required this.type,
  });

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
  bool _dependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dependenciesReady = true;
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'phx-change',
      'phx-submit',
      'method',
      'action',
      'phx-trigger-action',
    ]);
    _maybeTriggerAction();
  }

  @override
  void onWipeState() {
    formValues = {};
    super.onWipeState();
  }

  void _maybeTriggerAction() {
    // Offstage forms from previous routes share the same StateNotifier and can
    // receive diffs that target the current page. They must never auto-submit.
    if (!widget.state.isOnTheCurrentPage) {
      return;
    }
    // The URL check above is not enough: two routes can share the same URL
    // (e.g. navigating register -> log_in -> register). Only the currently
    // visible route should auto-submit its form.
    if (_dependenciesReady && mounted) {
      var route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return;
      }
    }
    var triggerAction = getAttribute('phx-trigger-action') ?? 'false';
    var action = getAttribute('action') ?? '';
    var last = widget.state.liveView.getFormTriggerAction(
      widget.state.urlPath,
      action,
    );
    if (triggerAction == last) {
      return;
    }
    widget.state.liveView.setFormTriggerAction(
      widget.state.urlPath,
      action,
      triggerAction,
    );
    if (triggerAction == 'false') {
      return;
    }
    widget.state.liveView.postForm(formValues, url: action);
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

    liveView.sendEvent(
      ExecLiveEvent(
        type: 'form',
        name: getAttribute(eventKind)!,
        value: qs.Encoder().convert(nonNullValues),
      ),
    );
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
            if (getAttribute('phx-submit') != null) {
              sendFormEvent('phx-submit', target: event.name);
            } else if (getAttribute('method')?.toUpperCase() == 'POST') {
              widget.state.liveView.postForm(
                formValues,
                url: getAttribute('action'),
              );
            }
          }
          return true;
        },
        child: singleChild(),
      ),
    );
  }
}
