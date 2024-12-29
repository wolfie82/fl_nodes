import 'dart:ui' as ui;

import 'package:fl_nodes/src/utils/grid_drawing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/widgets/node.dart';

class NodeParentData extends ContainerBoxParentData<RenderBox> {
  Offset nodeOffset = Offset.zero;
}

class NodeEditorRenderWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final NodeEditorBehavior behavior;
  final NodeEditorStyle style;

  NodeEditorRenderWidget({
    super.key,
    required this.controller,
    required this.style,
  })  : behavior = controller.behavior,
        super(
          children: controller.nodesAsList
              .map(
                (node) => NodeWidget(
                  node: node,
                  controller: controller,
                ),
              )
              .toList(),
        );

  @override
  NodeEditorRenderBox createRenderObject(BuildContext context) {
    return NodeEditorRenderBox(
      style: style,
      behavior: behavior,
      offset: controller.offset,
      zoom: controller.zoom,
      selectionArea: controller.selectionArea,
      nodePositions: controller.nodesAsList.map((n) => n.offset).toList(),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject
      ..offset = controller.offset
      ..zoom = controller.zoom
      ..selectionArea = controller.selectionArea
      ..updateNodePositions(
        controller.nodesAsList.map((n) => n.offset).toList(),
      );
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {
  NodeEditorRenderBox({
    required NodeEditorStyle style,
    required NodeEditorBehavior behavior,
    required Offset offset,
    required double zoom,
    required Rect selectionArea,
    required List<Offset> nodePositions,
  })  : _style = style,
        _behavior = behavior,
        _offset = offset,
        _zoom = zoom,
        _selectionArea = selectionArea {
    _updateNodePositions(nodePositions);
  }

  NodeEditorBehavior _behavior;
  NodeEditorBehavior get behavior => _behavior;
  set behavior(NodeEditorBehavior value) {
    if (_behavior == value) return;
    _behavior = value;
    markNeedsPaint();
  }

  NodeEditorStyle _style;
  NodeEditorStyle get style => _style;
  set style(NodeEditorStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  double _zoom;
  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;
    _zoom = value;
    markNeedsPaint();
    markNeedsLayout();
  }

  Rect _selectionArea;
  Rect get selectionArea => _selectionArea;
  set selectionArea(Rect value) {
    if (_selectionArea == value) return;
    _selectionArea = value;
    markNeedsPaint();
  }

  void updateNodePositions(List<Offset> newPositions) {
    if (_areNodePositionsEqual(newPositions)) return;
    _updateNodePositions(newPositions);
    markNeedsLayout();
  }

  void _updateNodePositions(List<Offset> positions) {
    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < positions.length) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;
      childParentData.nodeOffset = positions[index];
      child = childParentData.nextSibling;
      index++;
    }
  }

  bool _areNodePositionsEqual(List<Offset> newPositions) {
    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < newPositions.length) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;
      if (childParentData.nodeOffset != newPositions[index]) {
        return false;
      }
      child = childParentData.nextSibling;
      index++;
    }

    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeParentData) {
      child.parentData = NodeParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

      childParentData.offset = childParentData.nodeOffset;

      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) async {
    final Canvas canvas = context.canvas;

    canvas.save();

    final (viewport, startX, startY) = _prepareCanvas(canvas, size);

    if (style.gridStyle.showGrid) {
      drawGrid(style.gridStyle, canvas, viewport, startX, startY);
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      if (!Rect.fromLTWH(
        childParentData.nodeOffset.dx,
        childParentData.nodeOffset.dy,
        child.size.width,
        child.size.height,
      ).overlaps(viewport)) {
        child = childParentData.nextSibling;
        continue;
      }

      final Offset nodeOffset = childParentData.nodeOffset;
      context.paintChild(child, nodeOffset);

      child = childParentData.nextSibling;
    }

    if (!selectionArea.isEmpty) {
      paintSelectionArea(canvas, viewport);
    }

    if (kDebugMode) {
      paintDebugViewport(canvas, viewport);
      paintDebugOffset(canvas, size);
    }

    context.canvas.restore();
  }

  (Rect, double, double) _prepareCanvas(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(offset.dx, offset.dy);

    final viewport = _calculateViewport(canvas, size);
    final startX = _calculateStart(viewport.left, style.gridStyle.gridSpacingX);
    final startY = _calculateStart(viewport.top, style.gridStyle.gridSpacingY);

    canvas.clipRect(
      viewport,
      clipOp: ui.ClipOp.intersect,
      doAntiAlias: false,
    );

    return (viewport, startX, startY);
  }

  Rect _calculateViewport(Canvas canvas, Size size) {
    final viewport = Rect.fromLTWH(
      -size.width / 2 / zoom - _offset.dx,
      -size.height / 2 / zoom - _offset.dy,
      size.width / zoom,
      size.height / zoom,
    );

    return viewport;
  }

  @visibleForTesting
  void paintDebugViewport(Canvas canvas, Rect viewport) {
    final Paint debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    // Draw the viewport rect
    canvas.drawRect(viewport, debugPaint);
  }

  void paintSelectionArea(Canvas canvas, Rect viewport) {
    final Paint selectionPaint = Paint()
      ..color = Colors.blue.withAlpha(50)
      ..style = PaintingStyle.fill;

    canvas.drawRect(selectionArea, selectionPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRect(selectionArea, borderPaint);
  }

  @visibleForTesting
  void paintDebugOffset(Canvas canvas, Size size) {
    final Paint debugPaint = Paint()
      ..color = Colors.green.withAlpha(200)
      ..style = PaintingStyle.fill;

    // Draw the offset point
    canvas.drawCircle(Offset.zero, 5, debugPaint);
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final transformedPosition =
        (position - Offset(size.width / 2, size.height / 2))
                .scale(1 / zoom, 1 / zoom) -
            _offset;

    RenderBox? child = lastChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.nodeOffset,
        position: transformedPosition,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }

      child = childParentData.previousSibling;
    }

    return false;
  }
}
