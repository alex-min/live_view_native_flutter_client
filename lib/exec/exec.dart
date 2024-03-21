import 'package:liveview_flutter/when/when.dart';

/// Represents an action that can be executed in the view.
///
/// It can be an event or a command, like changing the current theme or switching pages.
class Exec {
  When conditions = When();
}

class ExecNoAction extends Exec {}
