import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class DataConfirm {
  final String title;
  final String message;
  final String confirm;
  final String cancel;

  DataConfirm({
    required this.message,
    String? title,
    String? confirm,
    String? cancel,
  })  : title = title ?? 'Confirm?',
        confirm = confirm ?? 'Ok',
        cancel = cancel ?? 'Cancel';
}

abstract class ExecConfirmable extends Exec {
  /// This is responsible for show an alert before executing this action
  final DataConfirm? dataConfirm;

  ExecConfirmable({this.dataConfirm});

  @override
  void conditionalHandler(BuildContext context, StateWidget widget) {
    if (conditions.execute(context) == false) return;

    if (dataConfirm == null) return handler(context, widget);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dataConfirm!.title),
        content: Text(dataConfirm!.message),
        actions: [
          TextButton(
            child: Text(dataConfirm!.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(dataConfirm!.confirm),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) return handler(context, widget);
    });
  }
}
