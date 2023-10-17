import 'package:flutter/material.dart';

class LiveConnectionNotifier extends ChangeNotifier {
  void wipeState() => notifyListeners();
}
