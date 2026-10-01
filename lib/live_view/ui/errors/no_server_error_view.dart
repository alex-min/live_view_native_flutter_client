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
    final colors = Theme.of(context).colorScheme;
    debugPrint(widget.error.toString());
    List<Widget> doc = [
      Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Unable to connect to the Live View Server",
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(widget.error.summary.toString()),
            Text(
              'Stacktrace is shown below',
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
          widget.error.stack.toString(),
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
