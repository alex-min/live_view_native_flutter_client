import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';

Map<String, dynamic> nestedDiff(
  Map<String, dynamic> diff,
  List<String> nestedState,
) {
  var fullDiff = diff;
  var currentDiff = fullDiff;
  for (var state in nestedState) {
    if (currentDiff.containsKey(state)) {
      if (currentDiff[state] is Map) {
        currentDiff = Map<String, dynamic>.from(currentDiff[state]);
      } else {
        // The subtree was replaced by a leaf value (or removed); return an
        // empty diff so the widget keeps its existing state instead of
        // crashing on a non-map diff (e.g. stale widgets from a previous
        // route still listening to the notifier).
        return {};
      }
    } else {
      // This subtree did not change; return an empty diff so the widget keeps
      // its existing state instead of receiving the parent diff.
      return {};
    }
  }
  return currentDiff;
}

class StateNotifier extends ChangeNotifier {
  late Map<String, dynamic> _diff;
  StateNotifier() {
    _diff = {};
  }

  void setDiff(Map<String, dynamic> diff) {
    _diff = expandVariables(diff);
    notifyListeners();
  }

  void emptyData() {
    _diff = {};
  }

  Map<String, dynamic> getDiff() => _diff;

  Map<String, dynamic> getNestedDiff(List<String> nestedState) =>
      nestedDiff(_diff, nestedState);
}
