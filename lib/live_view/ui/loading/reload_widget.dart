import 'package:flutter/material.dart';

class ReloadWidget extends StatefulWidget {
  const ReloadWidget({super.key});

  @override
  State<ReloadWidget> createState() => _ReloadWidgetState();
}

class _ReloadWidgetState extends State<ReloadWidget>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..drive(CurveTween(curve: Curves.easeIn));
    Tween<double>(begin: 0, end: 1).animate(controller);
    controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return FractionallySizedBox(
              widthFactor: controller.value,
              child: Container(
                  height: 5,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment(0.8, 1),
                          colors: [
                        Colors.green,
                        Colors.red,
                        Colors.blue,
                        Colors.purple
                      ]))));
        });
  }
}
