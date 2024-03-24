import 'package:flutter/material.dart';

class ParsingErrorView extends StatefulWidget {
  final String xml;
  final String url;
  const ParsingErrorView({super.key, required this.xml, required this.url});

  @override
  State<ParsingErrorView> createState() => _ParsingErrorViewState();
}

class _ParsingErrorViewState extends State<ParsingErrorView> {
  @override
  Widget build(BuildContext context) {
    List<Widget> doc = [
      Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Unable to parse the Flutter live view data',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text('XML output returned on URL ${widget.url} is shown below',
                style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            Text(
                'If the output below looks like HTML, please returned proper flutter live view data instead',
                style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          ]))
    ];
    doc.addAll([
      Container(
          padding: const EdgeInsets.all(20),
          child: Text(
              widget.xml == ''
                  ? '(empty data, nothing was returned)'
                  : widget.xml,
              style: const TextStyle(color: Colors.black, fontSize: 15))),
    ]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(children: doc),
    );
  }
}
