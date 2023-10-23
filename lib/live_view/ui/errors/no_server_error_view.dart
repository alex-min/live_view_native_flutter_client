import 'package:flutter/material.dart';

class NoServerError extends StatefulWidget {
  final FlutterErrorDetails error;
  const NoServerError({super.key, required this.error});

  @override
  State<NoServerError> createState() => _NoServerErrorState();
}

class _NoServerErrorState extends State<NoServerError> {
  @override
  Widget build(BuildContext context) {
    debugPrint(widget.error.toString());
    List<Widget> doc = [
      Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              "Unable to connect to the Live View Server",
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(widget.error.summary.toString()),
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
