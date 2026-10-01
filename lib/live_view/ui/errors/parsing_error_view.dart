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
    final colors = Theme.of(context).colorScheme;
    List<Widget> doc = [
      Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to parse the Flutter live view data',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'XML output returned on URL ${widget.url} is shown below',
              style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
            ),
            Text(
              'If the output below looks like HTML, please returned proper flutter live view data instead',
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
          widget.xml == '' ? '(empty data, nothing was returned)' : widget.xml,
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
