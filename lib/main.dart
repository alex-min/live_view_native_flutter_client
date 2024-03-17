import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

void main() => runApp(const MyApp());

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
    view = LiveView();

    if (kIsWeb) {
      view.connectToDocs();
    } else {
      await view.connect(Platform.isAndroid
          ?
          // android emulator
          'http://10.0.2.2:4000'
          // computer
          : 'http://localhost:4000/');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return view.rootView;
  }
}
