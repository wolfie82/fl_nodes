import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:fl_nodes/src/core/models/styles.dart';
import 'package:fl_nodes/src/utils/grid.dart';

import '../core/models/node.dart';

class NodeViewParentData extends ContainerBoxParentData<RenderBox> {
  Offset nodeOffset = Offset.zero;
}

class NodeViewWidget extends MultiChildRenderObjectWidget {
  final GridStyle style;
  final Offset offset;
  final double zoom;
  final List<Node> nodes;

  NodeViewWidget({
    super.key,
    required this.style,
    required this.offset,
    required this.zoom,
    required this.nodes,
  }) : super(
          children: nodes
              .map(
                (node) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: node.prototype.color,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        node.prototype.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );

  @override
  RenderNodeView createRenderObject(BuildContext context) {
    return RenderNodeView(
      style: style,
      offset: offset,
      zoom: zoom,
      nodePositions: nodes.map((n) => n.offset).toList(),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderNodeView renderObject) {
    renderObject
      ..offset = offset
      ..zoom = zoom
      ..updateNodePositions(nodes.map((n) => n.offset).toList());
  }
}

class RenderNodeView extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeViewParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeViewParentData> {
  RenderNodeView({
    required GridStyle style,
    required Offset offset,
    required double zoom,
    required List<Offset> nodePositions,
  })  : _style = style,
        _offset = offset,
        _zoom = zoom {
    _updateNodePositions(nodePositions);
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
      final NodeViewParentData childParentData =
          child.parentData! as NodeViewParentData;
      childParentData.nodeOffset = positions[index];
      child = childParentData.nextSibling;
      index++;
    }
  }

  bool _areNodePositionsEqual(List<Offset> newPositions) {
    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < newPositions.length) {
      final NodeViewParentData childParentData =
          child.parentData! as NodeViewParentData;
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
    if (child.parentData is! NodeViewParentData) {
      child.parentData = NodeViewParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeViewParentData childParentData =
          child.parentData! as NodeViewParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

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
      final NodeViewParentData childParentData =
          child.parentData! as NodeViewParentData;

      final Offset nodeOffset = childParentData.nodeOffset;
      context.paintChild(child, nodeOffset);

      child = childParentData.nextSibling;
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
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke;

    // Draw the viewport rect
    canvas.drawRect(viewport, debugPaint);
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return true;
  }
}
