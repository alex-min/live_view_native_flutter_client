import 'package:flutter/material.dart';

class LiveConnectionNotifier extends ChangeNotifier {
  void reconnect() => notifyListeners();
}
