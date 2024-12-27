import 'package:fl_nodes/src/core/models/node.dart';
import 'package:flutter/widgets.dart';

/// Retrieves the global offset of a widget identified by a [GlobalKey].
Offset? getOffsetFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.localToGlobal(Offset.zero);
  }
  return null;
}

/// Retrieves the size of a widget identified by a [GlobalKey].
Size? getSizeFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.size;
  }
  return null;
}

/// Retrieves the bounds of a Node widget.
Rect? getBoundsFromGlobalKey(Node node) {
  final size = getSizeFromGlobalKey(node.key);
  if (size != null) {
    return Rect.fromLTWH(
      node.offset.dx,
      node.offset.dy,
      size.width,
      size.height,
    );
  }
  return null;
}

/// Converts a screen position to a world (canvas) position.
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
