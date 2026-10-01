import 'package:flutter/material.dart';

class Error404 extends StatefulWidget {
  final String url;
  const Error404({super.key, required this.url});

  @override
  State<Error404> createState() => _Error404State();
}

class _Error404State extends State<Error404> {
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
              '404 Page not found',
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
        child: Text(
          "Flutter was unable to GET '${widget.url}', please add an HTML view at this endpoint so that the live view can get the metadada.",
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
