/// Tracks which `onMount` execs already fired, so an exec attribute fires
/// exactly once per element insertion and never again on rebuilds.
///
/// The widget tree of this client is fully re-created when server diffs
/// arrive, so element lifecycle alone (initState/dispose) cannot distinguish
/// "element kept and updated" from "element removed and re-added". This
/// tracker instead derives insertions from the diffs themselves, which are
/// the authoritative source:
///
/// - a diff entry carrying new statics (`s`) at a path means the content at
///   that path was replaced: the generation of the path (and its descendants)
///   is bumped and only mount execs whose payload appears in those statics
///   may fire;
/// - leaf-only diffs don't bump anything, so re-mounted copies of kept
///   content hit an already-fired fingerprint and stay silent;
/// - [reset] is called on every full render (page change), so re-visiting a
///   page fires its mount execs again.
class MountExecTracker {
  final Map<String, int> _generations = {};
  final Map<int, String> _generationStatics = {};
  final Set<String> _fired = {};
  int _counter = 0;

  void reset() {
    _generations.clear();
    _generationStatics.clear();
    _fired.clear();
    _counter = 0;
  }

  /// Records a server diff: bumps the generation of every path whose content
  /// was replaced by the diff.
  void recordDiff(Map<String, dynamic> diff) => _walk(diff, '');

  void _walk(Map<String, dynamic> diff, String path) {
    diff.forEach((key, value) {
      if (key == 'e' || value is! Map) {
        return;
      }
      final childPath = path.isEmpty ? key : '$path.$key';
      final statics = value['s'];
      if (statics is List) {
        final generation = ++_counter;
        _generations[childPath] = generation;
        _generationStatics[generation] = statics.join();
      }
      _walk(Map<String, dynamic>.from(value), childPath);
    });
  }

  /// Highest generation recorded for [path] or any of its ancestors.
  int _effectiveGeneration(String path) {
    var best = 0;
    var current = path;
    while (true) {
      final generation = _generations[current];
      if (generation != null && generation > best) {
        best = generation;
      }
      final dot = current.lastIndexOf('.');
      if (dot == -1) {
        break;
      }
      current = current.substring(0, dot);
    }
    return best;
  }

  /// Whether a mount exec for [attribute] (resolved to [resolvedValue]) on
  /// the element at [nestedState] / [childIndex] may fire now. Returns true
  /// at most once per fingerprint.
  bool shouldFire({
    required List<String> nestedState,
    required int childIndex,
    required String attribute,
    required String resolvedValue,
  }) {
    final path = nestedState.join('.');
    final generation = _effectiveGeneration(path);
    final fingerprint =
        '$path#$generation:$childIndex:$attribute:$resolvedValue';

    if (_fired.contains(fingerprint)) {
      return false;
    }

    final statics = _generationStatics[generation];
    final introducedByDiff = statics != null;
    final allowed =
        !introducedByDiff ||
        (statics.contains(attribute) &&
            (statics.contains(resolvedValue) || statics.contains('{{')));

    if (allowed) {
      _fired.add(fingerprint);
    }
    return allowed;
  }
}
