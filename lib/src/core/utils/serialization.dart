import 'package:flutter/material.dart';

String colorToRGBAString(Color color) {
  return '${color.r},${color.g},${color.b},${color.a}';
}

Color colorFromRGBAString(String rgba) {
  final values = rgba
      .substring(5, rgba.length - 1)
      .split(',')
      .map((value) => int.parse(value))
      .toList();
  return Color.fromARGB(values[3], values[0], values[1], values[2]);
}
