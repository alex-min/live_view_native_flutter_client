import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

Map<String, dynamic> _mergeDiff(
  Map<String, dynamic> base,
  Map<String, dynamic> overlay,
) {
  var result = Map<String, dynamic>.from(base);
  for (var entry in overlay.entries) {
    var existing = result[entry.key];
    var value = entry.value;
    if (existing is Map && value is Map) {
      result[entry.key] = _mergeDiff(
        Map<String, dynamic>.from(existing),
        Map<String, dynamic>.from(value),
      );
    } else {
      result[entry.key] = value;
    }
  }
  return result;
}

class LiveDynamicComponent extends LiveStateWidget<LiveDynamicComponent> {
  const LiveDynamicComponent({super.key, required super.state});

  @override
  State<LiveDynamicComponent> createState() => _LiveDynamicComponentState();
}

class _LiveDynamicComponentState extends StateWidget<LiveDynamicComponent> {
  Map<String, dynamic> lastLiveDiff = {};

  List<Widget>? child;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    lastLiveDiff = _mergeDiff(lastLiveDiff, diff);
    listenInnerTextKeys();
    if (extraKeysListened.isNotEmpty) {
      if (lastLiveDiff.containsKey(extraKeysListened[0]) &&
          lastLiveDiff[extraKeysListened[0]] == '') {
        child = null;
      }
    }
  }

  @override
  void onWipeState() {
    child = null;
    super.onWipeState();
  }

  @override
  Widget render(BuildContext context) {
    List<Widget> children = [];
    for (ElementKey elementKey in extraKeysListened) {
      var result = _handleElementKey(elementKey);
      if (result != null) {
        children.add(result);
      }
    }

    if (children.isNotEmpty) {
      child = children;
    }

    return body(child ?? _initialContent() ?? [LiveText(state: widget.state)]);
  }

  /// Renders the initial content of a section or comprehension (a map value
  /// with statics) before any diff targets it.
  List<Widget>? _initialContent() {
    for (var elementKey in extraKeysListened) {
      var value = widget.state.variables[elementKey.key];
      if (value is Map && (value.containsKey('s') || value.containsKey('d'))) {
        return _parseContent(elementKey, Map<String, dynamic>.from(value));
      }
    }
    return null;
  }

  List<Widget> _parseContent(
    ElementKey elementKey,
    Map<String, dynamic> content,
  ) {
    var newState = List<String>.from(widget.state.nestedState);
    newState.add(elementKey.key);

    // Comprehension: render each row with its own variables. Parsing the
    // whole map at once is not possible: row-level slots don't exist at the
    // comprehension level and produce invalid markup.
    if (content['d'] is List) {
      List<Widget> rows = [];
      for (var i = 0; i < (content['d'] as List).length; i++) {
        var rowVariables = content[i.toString()];
        if (rowVariables is! Map) {
          continue;
        }
        rows.addAll(
          widget.state.parser.parseHtml(
            List<String>.from(content['s'] ?? []),
            Map<String, dynamic>.from(rowVariables),
            [...newState, i.toString()],
          ).$1,
        );
      }
      return rows;
    }

    return widget.state.parser
        .parseHtml(List<String>.from(content['s'] ?? []), content, newState)
        .$1;
  }

  Widget? _handleElementKey(ElementKey elementKey) {
    var diffEntry = lastLiveDiff[elementKey.key];

    if (diffEntry is String && diffEntry.trim() == '') {
      return const SizedBox.shrink();
    }

    if (diffEntry is Map) {
      return _handleMapDiffEntry(diffEntry, elementKey);
    }
    return null;
  }

  Widget? _handleMapDiffEntry(Map diffEntry, ElementKey elementKey) {
    if (!diffEntry.containsKey('s') && !diffEntry.containsKey('d')) {
      // only updating child props
      return null;
    }

    // Comprehension diffs only carry the new 'd' list; keep the initial
    // statics and dynamics as a base so the whole section can be re-rendered.
    var base = widget.state.variables[elementKey.key];
    var content = <String, dynamic>{
      if (base is Map) ...Map<String, dynamic>.from(base),
      ...Map<String, dynamic>.from(diffEntry),
    };

    return body(_parseContent(elementKey, content));
  }
}
