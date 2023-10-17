import 'package:flutter/material.dart';

class InternalView extends StatelessWidget {
  final Widget child;
  const InternalView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
