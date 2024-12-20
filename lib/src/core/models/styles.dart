import 'package:flutter/material.dart';

enum LineType {
  solid,
  none,
}

enum IntersectionType {
  rectangle,
  circle,
  none,
}

class GridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final LineType lineType;
  final double lineWidth;
  final Color lineColor;
  final IntersectionType intersectionType;
  final Color intersectionColor;
  final double? intersectionRadius;
  final Size? intersectionSize;

  const GridStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineType = LineType.solid,
    this.lineWidth = 1.0,
    this.lineColor = Colors.white10,
    this.intersectionType = IntersectionType.circle,
    this.intersectionColor = Colors.white54,
    this.intersectionRadius = 1,
    this.intersectionSize = const Size(8.0, 8.0),
  });
}

class NodeEditorBehavior {
  final double zoomSensitivity;
  final double minZoom;
  final double maxZoom;
  final double panSensitivity;
  final double maxPanX;
  final double maxPanY;
  final bool enableKineticScrolling;

  const NodeEditorBehavior({
    this.zoomSensitivity = 0.1,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
    this.panSensitivity = 1.0,
    this.maxPanX = 10000.0,
    this.maxPanY = 10000.0,
    this.enableKineticScrolling = true,
  });
}

class NodeEditorStyle {
  final Color backgroundColor;
  final DecorationImage? backgroundImage;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double contentPadding;
  final GridStyle gridPainterStyle;

  const NodeEditorStyle({
    this.backgroundColor = Colors.transparent,
    this.backgroundImage,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.borderRadius = BorderRadius.zero,
    this.contentPadding = 8.0,
    required this.gridPainterStyle,
  });
}
