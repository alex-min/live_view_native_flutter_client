import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';

Map<String, dynamic> expandVariables(Map<String, dynamic> diff,
    {Map<String, dynamic> templates = const {}}) {
  var ret = Map<String, dynamic>.from(diff);
  var nextTemplate = Map<String, dynamic>.from(templates);

  if (ret.containsKey('p') && ret['p'] is Map) {
    nextTemplate.addAll(ret['p']);
  }
  if (ret.containsKey('d') && ret['d'] is List && !ret.containsKey('0')) {
    var count = 0;
    for (List<dynamic> forList in ret['d']) {
      var localVar = {
        for (var localVar in forList.indexed) '${localVar.$1}': localVar.$2
      };
      ret[count.toString()] = localVar;
      count++;
    }
    return expandVariables(ret, templates: nextTemplate);
  }
  if (ret.containsKey('s') && ret['s'] is int) {
    ret['s'] = nextTemplate[ret['s'].toString()];
  }
  return ret.map((k, v) {
    if (v is Map) {
      return MapEntry(
          k,
          expandVariables(
            Map<String, dynamic>.from(v),
            templates: nextTemplate,
          ));
    }
    return MapEntry(k, v);
  });
}

List<Widget> renderDynamicComponent(NodeState state) {
  List<Widget> comps = [];

  for (var elementKey in extractDynamicKeys(state.node.toString())) {
    var currentVariables = state.variables[elementKey.key];
    if (currentVariables is! Map || !currentVariables.containsKey('d')) {
      continue;
    }

    for (var i = 0; i < currentVariables['d'].length; i++) {
      var newState = List<int>.from(state.nestedState);
      newState.add(int.parse(elementKey.key));
      newState.add(i);

      comps.addAll(
        state.parser
            .parseHtml(
              List<String>.from(currentVariables['s']),
              currentVariables[i.toString()],
              newState,
              elementKey,
            )
            .$1,
      );
    }
  }

  return (comps.isNotEmpty) ? comps : [LiveDynamicComponent(state: state)];
}
