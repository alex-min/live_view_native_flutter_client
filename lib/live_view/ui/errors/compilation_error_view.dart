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
    dom.Document document = htmlparser.parse(widget.html);
    var error = HtmlUnescape().convert(document
        .getElementsByClassName('code-block')
        .map((e) => e.innerHtml)
        .join("\n"));
    List<Widget> doc = [
      Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Compilation Error',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text('Console output is shown below',
                style: TextStyle(fontSize: 15, color: Colors.grey[500]))
          ]))
    ];
    doc.addAll([
      Container(
          padding: const EdgeInsets.all(20),
          child: Text(error == '' ? document.outerHtml : error,
              style: const TextStyle(color: Colors.black, fontSize: 15)))
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(children: doc),
    );
  }
}
