import 'package:flutter/material.dart';

class FlutterErrorView extends StatefulWidget {
  final FlutterErrorDetails error;
  const FlutterErrorView({super.key, required this.error});

  @override
  State<FlutterErrorView> createState() => _FlutterErrorViewState();
}

class _FlutterErrorViewState extends State<FlutterErrorView> {
  @override
  Widget build(BuildContext context) {
    debugPrint(widget.error.toString());
    List<Widget> doc = [
      Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Flutter exception: ${widget.error.summary.toString()}",
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text('Stacktrace is shown below',
                style: TextStyle(fontSize: 15, color: Colors.grey[500]))
          ]))
    ];
    doc.addAll([
      Container(
          padding: const EdgeInsets.all(20),
          child: Text(widget.error.stack.toString(),
              style: const TextStyle(color: Colors.black, fontSize: 15)))
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(children: doc),
    );
  }
}
