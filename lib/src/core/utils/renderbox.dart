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
