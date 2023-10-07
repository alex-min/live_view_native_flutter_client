import 'package:xml/xml.dart';

extension NonEmptyChildren on XmlNode {
  List<XmlNode> get nonEmptyChildren {
    return children.where((c) {
      return !c.isEmpty;
    }).toList();
  }

  bool get isEmpty => nodeType == XmlNodeType.TEXT && text.trim() == '';
}

extension JoinMethod on List<String> {
  String joinWith(String Function(int index) separator) {
    var index = -1;
    Iterator<String> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    var first = iterator.current.toString();
    if (!iterator.moveNext()) return first;
    var buffer = StringBuffer(first);
    if (separator(index++).isEmpty) {
      do {
        buffer.write(iterator.current.toString());
      } while (iterator.moveNext());
    } else {
      do {
        buffer
          ..write(separator(index++))
          ..write(iterator.current.toString());
      } while (iterator.moveNext());
    }
    return buffer.toString();
  }
}

extension Matches on String {
  bool matches(String regex) => RegExp(regex).firstMatch(this) != null;
}
