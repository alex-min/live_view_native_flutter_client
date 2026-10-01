import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;
import 'package:html_unescape/html_unescape.dart';

class CompilationErrorView extends StatefulWidget {
  final String html;
  const CompilationErrorView({super.key, required this.html});

  @override
  State<CompilationErrorView> createState() => _CompilationErrorViewState();
}

class _CompilationErrorViewState extends State<CompilationErrorView> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    dom.Document document = htmlparser.parse(widget.html);
    var error = HtmlUnescape().convert(
      document
          .getElementsByClassName('code-block')
          .map((e) => e.innerHtml)
          .join("\n"),
    );
    List<Widget> doc = [
      Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compilation Error',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Console output is shown below',
              style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ];
    doc.addAll([
      Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          error == '' ? document.outerHtml : error,
          style: TextStyle(color: colors.onSurface, fontSize: 15),
        ),
      ),
    ]);
    return Scaffold(
      backgroundColor: colors.surface,
      body: ListView(children: doc),
    );
  }
}
