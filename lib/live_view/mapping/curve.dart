import 'package:flutter/widgets.dart';

Curve? getCurve(String? prop) {
  if (prop == null) {
    return null;
  }
  switch (prop) {
    case 'bounceIn':
      return Curves.bounceIn;
    case 'bounceInOut':
      return Curves.bounceInOut;
    case 'bounceOut':
      return Curves.bounceOut;
    case 'decelerate':
      return Curves.decelerate;
    case 'ease':
      return Curves.ease;
    case 'easeIn':
      return Curves.easeIn;
    case 'easeInBack':
      return Curves.easeInBack;
    case 'easeInCirc':
      return Curves.easeInCirc;
    case 'easeInCubic':
      return Curves.easeInCubic;
    case 'easeInExpo':
      return Curves.easeInExpo;
    case 'easeInOut':
      return Curves.easeInOut;
    case 'easeInOutBack':
      return Curves.easeInOutBack;
    case 'easeInOutCirc':
      return Curves.easeInOutCirc;
    case 'easeInOutCubic':
      return Curves.easeInOutCubic;
    case 'easeInOutCubicEmphasized':
      return Curves.easeInOutCubicEmphasized;
    case 'easeInOutExpo':
      return Curves.easeInOutExpo;
    case 'easeInOutQuad':
      return Curves.easeInOutQuad;
    case 'easeInOutQuart':
      return Curves.easeInOutQuart;
    case 'easeInOutQuint':
      return Curves.easeInOutQuint;
    case 'easeInOutSine':
      return Curves.easeInOutSine;
    case 'easeInToLinear':
      return Curves.easeInToLinear;
    case 'easeOut':
      return Curves.easeOut;
    case 'easeOutBack':
      return Curves.easeOutBack;
    case 'easeOutQuad':
      return Curves.easeOutQuad;
    case 'easeOutCirc':
      return Curves.easeOutCirc;
    case 'easeOutCubic':
      return Curves.easeOutCubic;
    case 'easeOutQuart':
      return Curves.easeOutQuart;
    case 'easeOutQuint':
      return Curves.easeOutQuint;
    case 'easeOutSine':
      return Curves.easeOutSine;
    case 'elasticIn':
      return Curves.elasticIn;
    case 'elasticOut':
      return Curves.elasticOut;
    case 'elasticInOut':
      return Curves.elasticInOut;
    case 'fastEaseInToSlowEaseOut':
      return Curves.fastEaseInToSlowEaseOut;
    case 'fastLinearToSlowEaseIn':
      return Curves.fastLinearToSlowEaseIn;
    case 'linear':
      return Curves.linear;
    case 'linearToEaseOut':
      return Curves.linearToEaseOut;
    case 'slowMiddle':
      return Curves.slowMiddle;
    default:
      return null;
  }
}
