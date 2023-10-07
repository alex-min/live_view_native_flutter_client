import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LiveView view;

  @override
  initState() {
    boot();
    super.initState();
  }

  boot() async {
    view = LiveView(onReload: () => setState(() {}));

    await view.connect(Platform.isAndroid
        ?
        // android emulator
        'http://10.0.0.2:4000'
        // computer
        : 'http://localhost:4000');
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: view.rootWidget,
    );
  }
}
