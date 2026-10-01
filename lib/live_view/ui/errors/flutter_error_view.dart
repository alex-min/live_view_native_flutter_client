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
              "Flutter exception: ${widget.error.summary.toString()}",
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
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
