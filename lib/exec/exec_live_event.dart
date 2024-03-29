import 'package:liveview_flutter/exec/exec.dart';

class ExecLiveEvent extends ExecConfirmable {
  final String type;
  final String name;
  final dynamic value;

  ExecLiveEvent({
    required this.type,
    required this.name,
    required this.value,
    super.dataConfirm,
  });
}
