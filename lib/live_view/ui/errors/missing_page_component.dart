import 'package:flutter/material.dart';

class MissingPageComponent extends StatefulWidget {
  final String url;
  final String html;
  const MissingPageComponent({
    super.key,
    required this.url,
    required this.html,
  });

  @override
  State<MissingPageComponent> createState() => _MissingPageComponentState();
}

class _MissingPageComponentState extends State<MissingPageComponent> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    List<Widget> doc = [
      Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Unable to find any <viewBody> component on url ${widget.url}",
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    ];
    doc.addAll([
      Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your page needs to contain a <viewBody> component directly inside the <flutter> component representing the view",
              style: TextStyle(color: colors.onSurface, fontSize: 15),
            ),
            Text(
              'Current invalid view returned:',
              style: TextStyle(color: colors.onSurface, fontSize: 15),
            ),
            Text(widget.html),
          ],
        ),
      ),
    ]);
    debugPrint("Unable to find any <viewBody> component on url ${widget.url}");
    debugPrint(widget.html);
    return Scaffold(
      backgroundColor: colors.surface,
      body: ListView(children: doc),
    );
  }
}
