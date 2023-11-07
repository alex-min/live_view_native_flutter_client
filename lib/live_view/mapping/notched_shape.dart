import 'package:flutter/material.dart';

NotchedShape? getNotchedShape(String? prop) {
  // TODO: handle AutomaticNotchedReactable
  switch (prop) {
    case 'CircularNotchedRectangle':
      return const CircularNotchedRectangle();
    default:
      return null;
  }
}
