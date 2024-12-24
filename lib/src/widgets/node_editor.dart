import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:fl_nodes/src/utils/grid.dart';
import 'package:fl_nodes/src/widgets/node.dart';

class NodeParentData extends ContainerBoxParentData<RenderBox> {
  Offset nodeOffset = Offset.zero;
}

class NodeEditorWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final GridStyle style;

  NodeEditorWidget({
    super.key,
    required this.controller,
    required this.style,
  }) : super(
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
      offset: controller.offset,
      zoom: controller.zoom,
      selctionArea: controller.selectionArea,
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
    required GridStyle style,
    required Offset offset,
    required double zoom,
    required Rect selctionArea,
    required List<Offset> nodePositions,
  })  : _style = style,
        _offset = offset,
        _zoom = zoom,
        _selectionArea = selctionArea {
    _updateNodePositions(nodePositions);
  }

  Rect _selectionArea;
  Rect get selectionArea => _selectionArea;
  set selectionArea(Rect value) {
    if (_selectionArea == value) return;
    _selectionArea = value;
    markNeedsPaint();
  }

  GridStyle _style;
  GridStyle get style => _style;
  set style(GridStyle value) {
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
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    canvas.save();
    _prepareCanvas(context.canvas, size);

    final viewport = _calculateViewport(context.canvas, size);
    final startX = _calculateStart(viewport.left, style.gridSpacingX);
    final startY = _calculateStart(viewport.top, style.gridSpacingY);

    paintGrid(style, canvas, viewport, startX, startY);

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      final Offset nodeOffset = childParentData.nodeOffset;
      context.paintChild(child, nodeOffset);

      child = childParentData.nextSibling;
    }

    if (!selectionArea.isEmpty) {
      final transformedSelectionArea = Rect.fromLTWH(
        screenToCanvas(selectionArea.topLeft, size, offset, zoom).dx,
        screenToCanvas(selectionArea.topLeft, size, offset, zoom).dy,
        selectionArea.width / zoom,
        selectionArea.height / zoom,
      );

      final Paint selectionPaint = Paint()
        ..color = Colors.blue.withAlpha(50)
        ..style = PaintingStyle.fill;

      canvas.drawRect(transformedSelectionArea, selectionPaint);

      final Paint borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawRect(transformedSelectionArea, borderPaint);
    }

    if (kDebugMode) {
      paintDebugViewport(canvas, viewport);
      paintDebugOffset(canvas, size);
    }

    context.canvas.restore();
  }

  void _prepareCanvas(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(_zoom);
    canvas.translate(_offset.dx, _offset.dy);
  }

  Rect _calculateViewport(Canvas canvas, Size size) {
    final viewport = Rect.fromLTWH(
      -size.width / 2 / _zoom - _offset.dx,
      -size.height / 2 / _zoom - _offset.dy,
      size.width / _zoom,
      size.height / _zoom,
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

  @visibleForTesting
  void paintDebugOffset(Canvas canvas, Size size) {
    final Paint debugPaint = Paint()
      ..color = Colors.green.withAlpha(200)
      ..style = PaintingStyle.fill;

    // Draw the offset point
    canvas.drawCircle(Offset.zero, 5, debugPaint);
  }

  Offset screenToCanvas(
    Offset screenPosition,
    Size size,
    Offset offset,
    double zoom,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final translated = screenPosition - center;
    return translated / zoom - offset;
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
                .scale(1 / _zoom, 1 / _zoom) -
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
