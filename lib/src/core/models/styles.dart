import 'package:flutter/material.dart';

class GridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final double lineWidth;
  final Color lineColor;
  final Color intersectionColor;
  final double intersectionRadius;
  final bool showGrid = true;

  const GridStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineWidth = 1.0,
    this.lineColor = Colors.transparent,
    this.intersectionColor = const Color(0xFF333333),
    this.intersectionRadius = 1,
  });

  GridStyle copyWith({
    double? gridSpacingX,
    double? gridSpacingY,
    double? lineWidth,
    Color? lineColor,
    Color? intersectionColor,
    double? intersectionRadius,
  }) {
    return GridStyle(
      gridSpacingX: gridSpacingX ?? this.gridSpacingX,
      gridSpacingY: gridSpacingY ?? this.gridSpacingY,
      lineWidth: lineWidth ?? this.lineWidth,
      lineColor: lineColor ?? this.lineColor,
      intersectionColor: intersectionColor ?? this.intersectionColor,
      intersectionRadius: intersectionRadius ?? this.intersectionRadius,
    );
  }
}

enum LinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

enum LinkStyle {
  solid,
  dashed,
  dotted,
}

class NodeEditorStyle {
  final Color backgroundColor;
  final DecorationImage? backgroundImage;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double contentPadding;
  final LinkCurveType linkCurveType;
  final LinkStyle linkStyle;
  final GridStyle gridStyle;

  const NodeEditorStyle({
    this.backgroundColor = Colors.transparent,
    this.backgroundImage,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.borderRadius = BorderRadius.zero,
    this.contentPadding = 8.0,
    this.linkCurveType = LinkCurveType.bezier,
    this.linkStyle = LinkStyle.solid,
    required this.gridStyle,
  });

  NodeEditorStyle copyWith({
    Color? backgroundColor,
    DecorationImage? backgroundImage,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? contentPadding,
    GridStyle? gridStyle,
  }) {
    return NodeEditorStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      gridStyle: gridStyle ?? this.gridStyle,
    );
  }
}

class SearchStyle {
  final Color backgroundColor;
  final Color textColor;
  final Icon searchIcon;
  final Icon previousResultIcon;
  final Icon nextResultIcon;
  final BorderRadius borderRadius;

  const SearchStyle({
    this.backgroundColor = const Color(0xFF212121),
    this.textColor = Colors.white,
    this.searchIcon = const Icon(Icons.search),
    this.previousResultIcon = const Icon(Icons.arrow_upward),
    this.nextResultIcon = const Icon(Icons.arrow_downward),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  SearchStyle copyWith({
    Color? backgroundColor,
    Color? textColor,
    Icon? searchIcon,
    Icon? previousResultIcon,
    Icon? nextResultIcon,
    BorderRadius? borderRadius,
  }) {
    return SearchStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      searchIcon: searchIcon ?? this.searchIcon,
      previousResultIcon: previousResultIcon ?? this.previousResultIcon,
      nextResultIcon: nextResultIcon ?? this.nextResultIcon,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}

class HierarchyStyle {
  final Color backgroundColor;
  final Color selectedColor;
  final Color textColor;
  final BorderRadius borderRadius;

  const HierarchyStyle({
    this.backgroundColor = const Color.fromARGB(255, 33, 33, 33),
    this.selectedColor = Colors.grey,
    this.textColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  HierarchyStyle copyWith({
    Color? backgroundColor,
    Color? selectedColor,
    Color? textColor,
    BorderRadius? borderRadius,
  }) {
    return HierarchyStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedColor: selectedColor ?? this.selectedColor,
      textColor: textColor ?? this.textColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}
