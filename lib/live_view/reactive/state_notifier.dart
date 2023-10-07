import 'package:flutter/material.dart';

class StateNotifier extends ChangeNotifier {
  late Map<String, dynamic> _diff;
  StateNotifier() {
    _diff = {};
  }

  void setDiff(Map<String, dynamic> diff) {
    _diff = Map.from(diff);
    notifyListeners();
  }

  void emptyData() {
    _diff = {};
  }

  Map<String, dynamic> getDiff() => _diff;

  Map<String, dynamic> getNestedDiff(List<int> nestedState) {
    var fullDiff = _diff;
    var currentDiff = fullDiff;
    for (var state in nestedState) {
      if (currentDiff.containsKey(state.toString())) {
        if (currentDiff[state.toString()] == '') {
          currentDiff = {};
        } else {
          currentDiff =
              Map<String, dynamic>.from(currentDiff[state.toString()]);
        }
      }
    }
    return currentDiff;
  }
}
