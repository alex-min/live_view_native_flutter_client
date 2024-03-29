import 'package:liveview_flutter/when/when.dart';

/// Represents an action that can be executed in the view.
///
/// It can be an event or a command, like changing the current theme or switching pages.
class Exec {
  When conditions = When();
}

class ExecConfirmable extends Exec {
  /// This is responsible for show an alert before executing this action
  final String? dataConfirm;
  ExecConfirmable({this.dataConfirm});
}

class ExecNoAction extends Exec {}
