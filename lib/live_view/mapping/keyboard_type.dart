import 'package:flutter/material.dart';

TextInputType? getTextInputType(String? type) {
  switch (type) {
    case 'datetime':
      return TextInputType.datetime;
    case 'emailAddress':
      return TextInputType.emailAddress;
    case 'multiline':
      return TextInputType.multiline;
    case 'name':
      return TextInputType.name;
    case 'none':
      return TextInputType.none;
    case 'number':
      return TextInputType.number;
    case 'phone':
      return TextInputType.phone;
    case 'streetAddress':
      return TextInputType.streetAddress;
    case 'text':
      return TextInputType.text;
    case 'url':
      return TextInputType.url;
    case 'visiblePassword':
      return TextInputType.visiblePassword;
    default:
      return null;
  }
}
