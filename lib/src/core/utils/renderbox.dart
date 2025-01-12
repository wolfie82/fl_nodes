import 'package:fl_nodes/src/core/models/entities.dart';
import 'package:flutter/widgets.dart';

/// Retrieves the global offset of a widget identified by a [GlobalKey].
Offset? getOffsetFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.localToGlobal(Offset.zero);
  }
  return null;
}

/// Retrieves the global offset of a widget relative to another widget.
Offset? getOffsetFromGlobalKeyRelativeTo(
  GlobalKey key,
  GlobalKey relativeTo,
) {
  final renderObject = key.currentContext?.findRenderObject();
  final relativeRenderObject = relativeTo.currentContext?.findRenderObject();
  if (renderObject is RenderBox && relativeRenderObject is RenderBox) {
    return renderObject.localToGlobal(
      Offset.zero,
      ancestor: relativeRenderObject,
    );
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
Rect? getNodeBoundsInWorld(NodeInstance node) {
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

Rect? getEditorBoundsInScreen(GlobalKey key) {
  final size = getSizeFromGlobalKey(key);
  final offset = getOffsetFromGlobalKey(key);
  if (size != null && offset != null) {
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
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

/// Converts a world (canvas) position to a screen position.
Offset worldToScreen(
  Offset worldPosition,
  Size size,
  Offset offset,
  double zoom,
) {
  final center = Offset(size.width / 2, size.height / 2);
  final translated = (worldPosition + offset) * zoom;
  return translated + center;
}
