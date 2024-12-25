import 'package:flutter/widgets.dart';

Offset? getOffsetFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.localToGlobal(Offset.zero);
  }
  return null;
}

Size? getSizeFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.size;
  }
  return null;
}

Offset screenToWorld(
  Offset screenPosition,
  Size size,
  Offset offset,
  double zoom,
) {
  final center = Offset(size.width / 2, size.height / 2);
  final translated = screenPosition - center;
  return translated / zoom - offset;
}
