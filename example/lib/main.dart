import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/liveview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LiveView view = LiveView();

  @override
  initState() {
    Future.microtask(boot);
    super.initState();
  }

  void boot() async {
    if (kIsWeb) {
      view.connectToDocs();
      return;
    }

    await view.connect(
      Platform.isAndroid
          ?
          // android emulator
          'http://10.0.2.2:4000'
          // computer
          : 'http://localhost:4000/',
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return view.rootView;
  }
}
