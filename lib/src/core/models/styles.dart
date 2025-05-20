import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/models/entities.dart';

class FlGridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final double lineWidth;
  final Color lineColor;
  final Color intersectionColor;
  final double intersectionRadius;
  final bool showGrid;

  const FlGridStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineWidth = 1.0,
    this.lineColor = const Color.fromARGB(64, 100, 100, 100),
    this.intersectionColor = const Color.fromARGB(128, 150, 150, 150),
    this.intersectionRadius = 2,
    this.showGrid = true,
  });

  FlGridStyle copyWith({
    double? gridSpacingX,
    double? gridSpacingY,
    double? lineWidth,
    Color? lineColor,
    Color? intersectionColor,
    double? intersectionRadius,
    bool? showGrid,
  }) {
    return FlGridStyle(
      gridSpacingX: gridSpacingX ?? this.gridSpacingX,
      gridSpacingY: gridSpacingY ?? this.gridSpacingY,
      lineWidth: lineWidth ?? this.lineWidth,
      lineColor: lineColor ?? this.lineColor,
      intersectionColor: intersectionColor ?? this.intersectionColor,
      intersectionRadius: intersectionRadius ?? this.intersectionRadius,
      showGrid: showGrid ?? this.showGrid,
    );
  }
}

enum FlLinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

enum FlLinkDrawMode {
  solid,
  dashed,
  dotted,
}

class FlLinkStyle {
  final Color? color;
  final bool useGradient;
  final LinearGradient? gradient;
  final double lineWidth;
  final FlLinkDrawMode drawMode;
  final FlLinkCurveType curveType;

  const FlLinkStyle({
    this.color,
    this.useGradient = false,
    this.gradient,
    required this.lineWidth,
    required this.drawMode,
    required this.curveType,
  }) : assert(
          useGradient == false || gradient != null,
          'Gradient must be provided if useGradient is true',
        );

  FlLinkStyle copyWith({
    LinearGradient? gradient,
    double? lineWidth,
    FlLinkDrawMode? drawMode,
    FlLinkCurveType? curveType,
  }) {
    return FlLinkStyle(
      gradient: gradient ?? this.gradient,
      lineWidth: lineWidth ?? this.lineWidth,
      drawMode: drawMode ?? this.drawMode,
      curveType: curveType ?? this.curveType,
    );
  }
}

typedef FlLinkStyleBuilder = FlLinkStyle Function(LinkState style);

FlLinkStyle defaultLinkStyle(LinkState state) {
  return const FlLinkStyle(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.blue],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    lineWidth: 2.0,
    drawMode: FlLinkDrawMode.solid,
    curveType: FlLinkCurveType.bezier,
  );
}

enum FlPortShape {
  circle,
  triangle,
}

class FlPortStyle {
  final FlPortShape shape;
  final Color color;
  final double radius;
  final FlLinkStyleBuilder linkStyleBuilder;

  const FlPortStyle({
    this.shape = FlPortShape.circle,
    this.color = Colors.blue,
    this.radius = 4,
    this.linkStyleBuilder = defaultLinkStyle,
  });

  FlPortStyle copyWith({
    FlPortShape? shape,
    Color? color,
    FlLinkStyleBuilder? linkStyleBuilder,
    double? radius,
  }) {
    return FlPortStyle(
      shape: shape ?? this.shape,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      linkStyleBuilder: linkStyleBuilder ?? this.linkStyleBuilder,
    );
  }
}

class FlFieldStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;

  const FlFieldStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF424242),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  FlFieldStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
  }) {
    return FlFieldStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
    );
  }
}

class FlNodeHeaderStyle {
  final EdgeInsets padding;
  final BoxDecoration decoration;
  final TextStyle textStyle;
  final IconData? icon;

  const FlNodeHeaderStyle({
    required this.padding,
    required this.decoration,
    required this.textStyle,
    required this.icon,
  });

  FlNodeHeaderStyle copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    TextStyle? textStyle,
    IconData? icon,
  }) {
    return FlNodeHeaderStyle(
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      icon: icon ?? this.icon,
    );
  }
}

typedef FlNodeHeaderStyleBuilder = FlNodeHeaderStyle Function(NodeState style);

FlNodeHeaderStyle defaultNodeHeaderStyle(NodeState state) {
  return FlNodeHeaderStyle(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(7),
        topRight: Radius.circular(7),
      ),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    icon: state.isCollapsed ? Icons.expand_more : Icons.expand_less,
  );
}

class FlNodeStyle {
  final BoxDecoration decoration;

  const FlNodeStyle({
    required this.decoration,
  });

  FlNodeStyle copyWith({
    BoxDecoration? decoration,
  }) {
    return FlNodeStyle(
      decoration: decoration ?? this.decoration,
    );
  }
}

typedef FlNodeStyleBuilder = FlNodeStyle Function(NodeState style);

FlNodeStyle defaultNodeStyle(NodeState state) {
  return FlNodeStyle(
    decoration: state.isSelected
        ? const BoxDecoration(
            color: Color(0xC7616161),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          )
        : const BoxDecoration(
            color: Color(0xC8424242),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
  );
}

class FlNodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlGridStyle gridStyle;

  const FlNodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.black12,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.gridStyle = const FlGridStyle(),
  });

  FlNodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlGridStyle? gridStyle,
  }) {
    return FlNodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
    );
  }
}
