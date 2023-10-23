import 'package:liveview_flutter/exec/exec.dart';

class ExecVisibilityAction extends Exec {
  String? to;
  int? timeInMilliseconds;

  ExecVisibilityAction({String? to, required this.timeInMilliseconds}) {
    this.to = to?.replaceAll('#', '');
  }

  @override
  String toString() =>
      'ExecVisibilityAction(to: $to, timeInMilliseconds: $timeInMilliseconds)';
}

class ExecShowAction extends ExecVisibilityAction {
  ExecShowAction({required super.to, required super.timeInMilliseconds});
}

class ExecHideAction extends ExecVisibilityAction {
  ExecHideAction({required super.to, required super.timeInMilliseconds});
}
