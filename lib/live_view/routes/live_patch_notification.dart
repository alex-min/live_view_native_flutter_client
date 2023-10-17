import 'package:flutter/material.dart';

class LivePatchNotification extends Notification {
  final Map<String, dynamic> data;

  const LivePatchNotification({required this.data});
}
