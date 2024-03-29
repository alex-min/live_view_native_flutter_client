import 'package:liveview_flutter/when/when.dart';

/// Represents an action that can be executed in the view.
///
/// It can be an event or a command, like changing the current theme or switching pages.
class Exec {
  When conditions = When();
}

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

class ExecConfirmable extends Exec {
  /// This is responsible for show an alert before executing this action
  final DataConfirm? dataConfirm;
  ExecConfirmable({this.dataConfirm});
}

class ExecNoAction extends Exec {}
