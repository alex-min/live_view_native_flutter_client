import 'package:flutter/material.dart';

class MissingPageComponent extends StatefulWidget {
  final String url;
  final String html;
  const MissingPageComponent(
      {super.key, required this.url, required this.html});

  @override
  State<MissingPageComponent> createState() => _MissingPageComponentState();
}

class _MissingPageComponentState extends State<MissingPageComponent> {
  @override
  Widget build(BuildContext context) {
    List<Widget> doc = [
      Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Unable to find any <viewBody> component on url ${widget.url}",
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ]))
    ];
    doc.addAll([
      Container(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
              "Your page needs to contain a <viewBody> component directly inside the <flutter> component representing the view",
              style: TextStyle(color: Colors.black, fontSize: 15)),
          const Text('Current invalid view returned:',
              style: TextStyle(color: Colors.black, fontSize: 15)),
          Text(widget.html)
        ]),
      )
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(children: doc),
    );
  }
}
