import 'package:flutter/material.dart';

String colorToRGBAString(Color color) {
  final r = color.r / 255.0;
  final g = color.g / 255.0;
  final b = color.b / 255.0;
  final a = color.a / 255.0;
  return '$r,$g,$b,$a';
}

Color colorFromRGBAString(String rgba) {
  final values =
      rgba.split(',').map((value) => double.parse(value.trim())).toList();

  return Color.fromARGB(
    (values[3] * 255).round(),
    (values[0] * 255).round(),
    (values[1] * 255).round(),
    (values[2] * 255).round(),
  );
}
