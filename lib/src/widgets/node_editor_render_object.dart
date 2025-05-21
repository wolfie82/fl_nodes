import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'package:fl_nodes/src/widgets/node.dart';

import '../core/controllers/node_editor/core.dart';
import '../core/models/entities.dart';
import '../core/models/styles.dart';

import 'builders.dart';

class NodeDiffCheckData {
  String id;
  Offset offset;
  NodeState state;

  NodeDiffCheckData({
    required this.id,
    required this.offset,
    required this.state,
  });
}

class LinkDrawData {
  final Offset outPortOffset;
  final Offset inPortOffset;
  final FlLinkStyle linkStyle;

  LinkDrawData({
    required this.outPortOffset,
    required this.inPortOffset,
    required this.linkStyle,
  });
}

class PortDrawData {
  final bool isSelected;
  final Offset offset;
  final FlPortStyle style;

  PortDrawData({
    required this.isSelected,
    required this.offset,
    required this.style,
  });
}

/// This extends the [ContainerBoxParentData] class from the Flutter framework
/// for the data to be passed down to children for layout and painting.
class _ParentData extends ContainerBoxParentData<RenderBox> {
  String id = '';
  Offset nodeOffset = Offset.zero;
  NodeState state = NodeState();

  // // // This is used to prevent unnecessary layout and painting of children
  // // bool hasBeenLaidOut = false;

  // This is used to avoid unnecessary recomputations of the renderbox rect
  Rect rect = Rect.zero;
}

class NodeEditorRenderObjectWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final FlNodeEditorStyle style;
  final FragmentShader gridShader;
  final FlNodeHeaderBuilder? headerBuilder;
  final FlNodeFieldBuilder? fieldBuilder;
  final FlNodePortBuilder? portBuilder;
  final FlNodeContextMenuBuilder? contextMenuBuilder;
  final FlNodeBuilder? nodeBuilder;

  NodeEditorRenderObjectWidget({
    super.key,
    required this.controller,
    required this.style,
    required this.gridShader,
    this.headerBuilder,
    this.fieldBuilder,
    this.portBuilder,
    this.contextMenuBuilder,
    this.nodeBuilder,
  }) : super(
          children: controller.nodesAsList
              .map(
                (node) => NodeWidget(
                  controller: controller,
                  node: node,
                  headerBuilder: headerBuilder,
                  fieldBuilder: fieldBuilder,
                  portBuilder: portBuilder,
                  contextMenuBuilder: contextMenuBuilder,
                  nodeBuilder: nodeBuilder,
                ),
              )
              .toList(),
        );

  @override
  NodeEditorRenderBox createRenderObject(BuildContext context) {
    return NodeEditorRenderBox(
      controller: controller,
      style: style,
      gridShader: gridShader,
      offset: controller.viewportOffset,
      zoom: controller.viewportZoom,
      lodLevel: controller.lodLevel,
      tmpLinkDrawData: _getTmpLinkDrawData(),
      selectionArea: controller.selectionArea,
      nodesData: _getNodeDrawData(),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject
      ..style = style
      ..offset = controller.viewportOffset
      ..zoom = controller.viewportZoom
      ..lodLevel = controller.lodLevel
      ..tmpLinkDrawData = _getTmpLinkDrawData()
      ..selectionArea = controller.selectionArea
      ..updateNodes(_getNodeDrawData());
  }

  List<NodeDiffCheckData> _getNodeDrawData() {
    return controller.nodesAsList
        .map(
          (node) => NodeDiffCheckData(
            id: node.id,
            offset: node.offset,
            state: node.state,
          ),
        )
        .toList();
  }

  LinkDrawData? _getTmpLinkDrawData() {
    if (controller.tempLink == null) return null;

    final link = controller.tempLink!;

    return LinkDrawData(
      outPortOffset: link.from,
      inPortOffset: link.to,
      linkStyle: link.style,
    );
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  NodeEditorRenderBox({
    required FlNodeEditorController controller,
    required FlNodeEditorStyle style,
    required FragmentShader gridShader,
    required Offset offset,
    required double zoom,
    required int lodLevel,
    required LinkDrawData? tmpLinkDrawData,
    required Rect selectionArea,
    required List<NodeDiffCheckData> nodesData,
  })  : _controller = controller,
        _style = style,
        _gridShader = gridShader,
        _offset = offset,
        _zoom = zoom,
        _lodLevel = lodLevel,
        _tmpLinkDrawData = tmpLinkDrawData,
        _selectionArea = selectionArea {
    _loadGridShader();
    updateNodes(nodesData);
  }

  final FlNodeEditorController _controller;
  final Map<String, RenderBox> _childrenById = {};

  // We keep track of the layout operation manually beacuse the hasSize getter
  // calls the size method which implementation causes assertions to be thrown.
  // See: https://api.flutter.dev/flutter/rendering/RenderBox/size.html
  final Map<String, RenderBox> _childrenNotLaidOut = {};

  FlNodeEditorStyle _style;
  FlNodeEditorStyle get style => _style;
  set style(FlNodeEditorStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  bool gridShaderStyleLoaded = false;
  FragmentShader _gridShader;
  FragmentShader get gridShader => _gridShader;
  set gridShader(FragmentShader value) {
    if (_gridShader == value) return;
    _gridShader = value;
    markNeedsPaint();
  }

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;
    _offset = value;
    _transformMatrixDirty = true;
    markNeedsPaint();
  }

  double _zoom;
  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;
    _zoom = value;
    _transformMatrixDirty = true;
    markNeedsPaint();
  }

  int _lodLevel;
  int get lodLevel => _lodLevel;
  set lodLevel(int value) {
    if (_lodLevel == value) return;
    _lodLevel = value;
    markNeedsPaint();
  }

  Matrix4? _transformMatrix;
  bool _transformMatrixDirty = true;

  LinkDrawData? _tmpLinkDrawData;
  LinkDrawData? get tmpLinkDrawData => _tmpLinkDrawData;
  set tmpLinkDrawData(LinkDrawData? value) {
    if (_tmpLinkDrawData == value) return;
    _tmpLinkDrawData = value;
    markNeedsPaint();
  }

  Rect _selectionArea;
  Rect get selectionArea => _selectionArea;
  set selectionArea(Rect value) {
    if (_selectionArea == value) return;
    _selectionArea = value;
    markNeedsPaint();
  }

  List<NodeDiffCheckData> _nodesDiffCheckData = [];
  List<NodeDiffCheckData> get nodesData => _nodesDiffCheckData;
  set nodesData(List<NodeDiffCheckData> value) {
    if (_nodesDiffCheckData == value) return;
    _nodesDiffCheckData = value;
    markNeedsLayout();
  }

  void _loadGridShader() {
    final gridStyle = style.gridStyle;

    gridShader.setFloat(0, gridStyle.gridSpacingX);
    gridShader.setFloat(1, gridStyle.gridSpacingY);

    final lineColor = gridStyle.lineColor;

    gridShader.setFloat(4, gridStyle.lineWidth);
    gridShader.setFloat(5, lineColor.r * lineColor.a);
    gridShader.setFloat(6, lineColor.g * lineColor.a);
    gridShader.setFloat(7, lineColor.b * lineColor.a);
    gridShader.setFloat(8, lineColor.a);

    final intersectionColor = gridStyle.intersectionColor;

    gridShader.setFloat(9, gridStyle.intersectionRadius);
    gridShader.setFloat(10, intersectionColor.r * intersectionColor.a);
    gridShader.setFloat(11, intersectionColor.g * intersectionColor.a);
    gridShader.setFloat(12, intersectionColor.b * intersectionColor.a);
    gridShader.setFloat(13, intersectionColor.a);
  }

  Set<String> visibleNodes = {};

  void updateNodes(List<NodeDiffCheckData> nodesData) {
    if (!_controller.nodesDataDirty) {
      markNeedsPaint();
      return;
    }

    _nodesDiffCheckData = nodesData;

    _childrenById.clear();

    RenderBox? child = firstChild;
    int index = 0;
    bool needsLayout = false;

    final nodesAsList = _controller.nodesAsList;

    while (child != null && index < nodesData.length) {
      final childParentData = child.parentData! as _ParentData;
      final nodeData = nodesData[index];

      if (childParentData.id != nodesAsList[index].id ||
          childParentData.offset != nodeData.offset ||
          childParentData.state.isCollapsed != nodeData.state.isCollapsed) {
        childParentData.id = nodesAsList[index].id;
        childParentData.offset = nodeData.offset;
        childParentData.state = nodeData.state;
        childParentData.rect = Rect.zero;

        _childrenNotLaidOut[childParentData.id] = child;

        needsLayout = true;
      }

      _childrenById[childParentData.id] = child;

      child = childParentData.nextSibling;
      index++;
    }

    if (needsLayout) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeDiffCheckData) {
      child.parentData = _ParentData();
    }
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    setupParentData(child);
    super.insert(child, after: after);

    final index = indexOf(child);
    final parentData = child.parentData as _ParentData;

    if (index >= 0 && index < _nodesDiffCheckData.length) {
      parentData.id = _nodesDiffCheckData[index].id;
      parentData.offset = _nodesDiffCheckData[index].offset;
      parentData.state = _nodesDiffCheckData[index].state;

      _childrenById[parentData.id] = child;
      _childrenNotLaidOut[parentData.id] = child;
    }
  }

  int indexOf(RenderBox child) {
    int index = 0;
    RenderBox? current = firstChild;

    while (current != null) {
      if (current == child) return index;
      current = childAfter(current);
      index++;
    }

    return -1;
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    // If the child has not been laid out yet, we need to layout it.
    // Otherwise, we only need to layout it if it's within the viewport.

    final Set<String> nodesToLayout = Set<String>.from(
      _childrenNotLaidOut.keys,
    ).union(visibleNodes);

    for (final nodeId in nodesToLayout) {
      final child = _childrenById[nodeId];

      if (child == null) continue;

      final childParentData = child.parentData as _ParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

      final renderBoxRect = Rect.fromLTWH(
        childParentData.offset.dx,
        childParentData.offset.dy,
        child.size.width,
        child.size.height,
      );

      childParentData.rect = renderBoxRect;

      _controller.spatialHashGrid.update((id: nodeId, rect: renderBoxRect));
    }

    _childrenNotLaidOut.clear();

    // Here we should be updating the visibleNodes set with the nodes that are within the viewport.
    // This action is delayed until the paint method to ensure all layout operations are done.
  }

  Rect _calculateViewport() {
    return Rect.fromLTWH(
      -size.width / 2 / zoom - _offset.dx,
      -size.height / 2 / zoom - _offset.dy,
      size.width / zoom,
      size.height / zoom,
    );
  }

  /// We need to manually mark the transform matrix when the viewport resizes
  Size _lastViewportSize = Size.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_lastViewportSize != size) {
      _lastViewportSize = size;
      _transformMatrixDirty = true;
    }

    final (viewport, startX, startY) = _prepareCanvas(context.canvas, size);

    // Performing the visibility update here ensures all layout operations are done.

    visibleNodes = _controller.spatialHashGrid.queryArea(
      // Inflate the viewport to include nodes that are close to the edges
      _calculateViewport().inflate(300),
    );

    _paintGrid(context.canvas, viewport, startX, startY);

    _paintLinks(context.canvas, viewport);

    _paintChildren(context);

    _paintTemporaryLink(context.canvas);

    _paintSelectionArea(context.canvas, viewport);

    if (kDebugMode) {
      paintDebugViewport(context.canvas, viewport);
      paintDebugOffset(context.canvas, size);
    }

    _controller.nodesDataDirty = false;
    _controller.linksDataDirty = false;
    _transformMatrixDirty = false;
  }

  Matrix4 _getTransformMatrix() {
    if (_transformMatrix != null && !_transformMatrixDirty) {
      return _transformMatrix!;
    }

    _transformMatrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(zoom, zoom, 1.0)
      ..translate(offset.dx, offset.dy);

    return _transformMatrix!;
  }

  (Rect, double, double) _prepareCanvas(Canvas canvas, Size size) {
    canvas.transform(_getTransformMatrix().storage);

    final viewport = _calculateViewport();
    final startX = _calculateStart(viewport.left, style.gridStyle.gridSpacingX);
    final startY = _calculateStart(viewport.top, style.gridStyle.gridSpacingY);

    canvas.clipRect(
      viewport,
      clipOp: ui.ClipOp.intersect,
      doAntiAlias: false,
    );

    return (viewport, startX, startY);
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

  ////////////////////////////////////////////////////////////////////
  /// Painting methods
  ////////////////////////////////////////////////////////////////////

  void _paintGrid(Canvas canvas, Rect viewport, double startX, double startY) {
    if (!style.gridStyle.showGrid) return;

    gridShader.setFloat(2, startX);
    gridShader.setFloat(3, startY);
    gridShader.setFloat(14, viewport.left);
    gridShader.setFloat(15, viewport.top);
    gridShader.setFloat(16, viewport.right);
    gridShader.setFloat(17, viewport.bottom);

    canvas.drawRect(viewport, Paint()..shader = gridShader);
  }

  bool _portsPositionsDirty = true;

  final Map<FlLinkStyle, (Path, Paint)> batchByLinkStyle = {};

  void _paintLinks(Canvas canvas, Rect viewport) {
    // Here we collect data also for ports and children to avoid multiple loops

    if (_controller.linksDataDirty ||
        _controller.nodesDataDirty ||
        _transformMatrixDirty ||
        _portsPositionsDirty) {
      final Set<LinkDrawData> linkDrawData = {};

      for (final value in batchByLinkStyle.values) {
        value.$1.reset();
      }

      for (final link in _controller.linksById.values) {
        final outNode = _controller.nodes[link.fromTo.from]!;
        final inNode = _controller.nodes[link.fromTo.fromPort]!;
        final outPort = outNode.ports[link.fromTo.to]!;
        final inPort = inNode.ports[link.fromTo.toPort]!;

        // NOTE: The port offset is relative to the node
        linkDrawData.add(
          LinkDrawData(
            outPortOffset: outNode.offset + outPort.offset,
            inPortOffset: inNode.offset + inPort.offset,
            linkStyle: outPort.prototype.style.linkStyleBuilder(link.state),
          ),
        );
      }

      // We don't draw the temporary link here because it should be on top of the nodes

      for (final drawData in linkDrawData) {
        if (drawData.linkStyle.useGradient) {
          switch (drawData.linkStyle.curveType) {
            case FlLinkCurveType.straight:
              _paintStraightLink(
                canvas,
                drawData,
              );
              break;
            case FlLinkCurveType.bezier:
              _paintBezierLink(
                canvas,
                drawData,
              );
              break;
            case FlLinkCurveType.ninetyDegree:
              _paintNinetyDegreesLink(
                canvas,
                drawData,
              );
              break;
          }
        } else {
          final style = drawData.linkStyle;
          batchByLinkStyle.putIfAbsent(style, () {
            return (
              Path(),
              Paint()
                ..color = style.color!
                ..style = PaintingStyle.stroke
                ..strokeWidth = style.lineWidth
            );
          });

          final (path, paint) = batchByLinkStyle[style]!;

          switch (style.curveType) {
            case FlLinkCurveType.straight:
              _batchPaintStraightLink(path, paint, drawData);
              break;
            case FlLinkCurveType.bezier:
              _batchPaintBezierLink(path, paint, drawData);
              break;
            case FlLinkCurveType.ninetyDegree:
              _batchPaintNinetyDegreesLink(path, paint, drawData);
              break;
          }
        }
      }
    }

    for (final entry in batchByLinkStyle.entries) {
      final (path, paint) = entry.value;
      canvas.drawPath(path, paint);
    }
  }

  final List<RenderBox> selectedChildren = [];
  final Path selectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchSelectedPortByStyle = {};

  final List<RenderBox> unselectedChildren = [];
  final Path unselectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchUnselectedPortByStyle = {};

  void _paintChildren(PaintingContext context) {
    if (_controller.nodesDataDirty ||
        _controller.linksDataDirty ||
        _transformMatrixDirty ||
        _portsPositionsDirty) {
      // Clear the old frame data

      for (final value in batchSelectedPortByStyle.values) {
        value.$1.reset();
      }

      for (final value in batchUnselectedPortByStyle.values) {
        value.$1.reset();
      }

      selectedChildren.clear();
      selectedShadowPath.reset();

      unselectedChildren.clear();
      unselectedShadowPath.reset();

      // Acquire new frame data

      final Set<PortDrawData> portDrawData = {};

      for (final nodeId in visibleNodes) {
        final child = _childrenById[nodeId];

        final childParentData = child!.parentData as _ParentData;

        if (childParentData.state.isSelected) {
          selectedChildren.add(child);

          selectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              const Radius.circular(4),
            ),
          );

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portDrawData.add(
              PortDrawData(
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.prototype.style,
              ),
            );
          }
        } else {
          unselectedChildren.add(child);

          unselectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              const Radius.circular(4),
            ),
          );

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portDrawData.add(
              PortDrawData(
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.prototype.style,
              ),
            );
          }
        }
      }

      for (final drawData in portDrawData) {
        final style = drawData.style;

        final batchPortByStyle = drawData.isSelected
            ? batchSelectedPortByStyle
            : batchUnselectedPortByStyle;

        batchPortByStyle.putIfAbsent(style, () {
          return (
            Path(),
            Paint()
              ..color = style.color
              ..style = PaintingStyle.fill,
          );
        });

        final (path, paint) = batchPortByStyle[style]!;

        switch (style.shape) {
          case FlPortShape.circle:
            _batchPaintCirclePort(path, paint, drawData);
            break;
          case FlPortShape.triangle:
            _batchPaintTrianglePort(path, paint, drawData);
            break;
        }
      }

      if (!_portsPositionsDirty) {
        _portsPositionsDirty = true;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          markNeedsPaint();
        });
      } else {
        _portsPositionsDirty = false;
      }
    }

    // First we paint the unselected nodes, so they appear below the selected ones.

    if (lodLevel == 4) {
      context.canvas.drawShadow(
        unselectedShadowPath,
        const ui.Color(0xC8000000),
        4,
        true,
      );
    }

    for (final unselectedChild in unselectedChildren) {
      final childParentData = unselectedChild.parentData! as _ParentData;
      context.paintChild(unselectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final entry in batchUnselectedPortByStyle.entries) {
        final (path, paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }

    // Then we paint the selected nodes, so they appear above the unselected ones.

    if (lodLevel == 4) {
      context.canvas.drawShadow(
        selectedShadowPath,
        const ui.Color(0xC8000000),
        4,
        true,
      );
    }

    for (final selectedChild in selectedChildren) {
      final childParentData = selectedChild.parentData! as _ParentData;
      context.paintChild(selectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final entry in batchSelectedPortByStyle.entries) {
        final (path, paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }
  }

  void _paintTemporaryLink(Canvas canvas) {
    if (_tmpLinkDrawData == null) return;

    switch (_tmpLinkDrawData!.linkStyle.curveType) {
      case FlLinkCurveType.straight:
        _paintStraightLink(canvas, _tmpLinkDrawData!);
        break;
      case FlLinkCurveType.bezier:
        _paintBezierLink(canvas, _tmpLinkDrawData!);
        break;
      case FlLinkCurveType.ninetyDegree:
        _paintNinetyDegreesLink(canvas, _tmpLinkDrawData!);
        break;
    }
  }

  void _paintBezierLink(Canvas canvas, LinkDrawData drawData) {
    final path = Path()
      ..moveTo(
        drawData.outPortOffset.dx,
        drawData.outPortOffset.dy,
      );

    const double defaultOffset = 400.0;

    //  How far the bezier follows the horizontal direction before curving based on the distance between ports
    final dx = (drawData.inPortOffset.dx - drawData.outPortOffset.dx).abs();
    final controlOffset = dx < defaultOffset * 2 ? dx / 2 : defaultOffset;

    // First control point: a few pixels to the right of the output port.
    final cp1 = Offset(
      drawData.outPortOffset.dx + controlOffset,
      drawData.outPortOffset.dy,
    );

    // Second control point: a few pixels to the left of the input port.
    final cp2 = Offset(
      drawData.inPortOffset.dx - controlOffset,
      drawData.inPortOffset.dy,
    );

    path.cubicTo(
      cp1.dx,
      cp1.dy,
      cp2.dx,
      cp2.dy,
      drawData.inPortOffset.dx,
      drawData.inPortOffset.dy,
    );

    final Paint paint = Paint();

    if (drawData.linkStyle.useGradient) {
      final shader = drawData.linkStyle.gradient!.createShader(
        Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
      );

      paint
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    } else {
      paint
        ..color = drawData.linkStyle.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    }

    canvas.drawPath(path, paint);
  }

  void _batchPaintBezierLink(
    Path path,
    Paint paint,
    LinkDrawData drawData,
  ) {
    path.moveTo(drawData.outPortOffset.dx, drawData.outPortOffset.dy);

    const double defaultOffset = 400.0;

    //  How far the bezier follows the horizontal direction before curving based on the distance between ports
    final dx = (drawData.inPortOffset.dx - drawData.outPortOffset.dx).abs();
    final controlOffset = dx < defaultOffset * 2 ? dx / 2 : defaultOffset;

    // First control point: a few pixels to the right of the output port.
    final cp1 = Offset(
      drawData.outPortOffset.dx + controlOffset,
      drawData.outPortOffset.dy,
    );

    // Second control point: a few pixels to the left of the input port.
    final cp2 = Offset(
      drawData.inPortOffset.dx - controlOffset,
      drawData.inPortOffset.dy,
    );

    path.cubicTo(
      cp1.dx,
      cp1.dy,
      cp2.dx,
      cp2.dy,
      drawData.inPortOffset.dx,
      drawData.inPortOffset.dy,
    );
  }

  void _paintStraightLink(
    Canvas canvas,
    LinkDrawData drawData,
  ) {
    final Paint paint = Paint();

    if (drawData.linkStyle.useGradient) {
      final shader = drawData.linkStyle.gradient!.createShader(
        Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
      );

      paint
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    } else {
      paint
        ..color = drawData.linkStyle.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    }

    canvas.drawLine(
      drawData.outPortOffset,
      drawData.inPortOffset,
      paint,
    );
  }

  void _batchPaintStraightLink(Path path, Paint paint, LinkDrawData drawData) {
    path
      ..moveTo(drawData.outPortOffset.dx, drawData.outPortOffset.dy)
      ..lineTo(drawData.inPortOffset.dx, drawData.inPortOffset.dy);
  }

  void _paintNinetyDegreesLink(
    Canvas canvas,
    LinkDrawData drawData,
  ) {
    final midX = (drawData.outPortOffset.dx + drawData.inPortOffset.dx) / 2;

    final path = Path()
      ..moveTo(drawData.outPortOffset.dx, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.inPortOffset.dy)
      ..lineTo(drawData.inPortOffset.dx, drawData.inPortOffset.dy);

    final Paint paint = Paint();

    if (drawData.linkStyle.useGradient) {
      final shader = drawData.linkStyle.gradient!.createShader(
        Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
      );

      paint
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    } else {
      paint
        ..color = drawData.linkStyle.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawData.linkStyle.lineWidth;
    }

    canvas.drawPath(path, paint);
  }

  void _batchPaintNinetyDegreesLink(
    Path path,
    Paint paint,
    LinkDrawData drawData,
  ) {
    final midX = (drawData.outPortOffset.dx + drawData.inPortOffset.dx) / 2;

    path
      ..moveTo(drawData.outPortOffset.dx, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.inPortOffset.dy)
      ..lineTo(drawData.inPortOffset.dx, drawData.inPortOffset.dy);
  }

  void _batchPaintCirclePort(
    Path path,
    Paint paint,
    PortDrawData drawData,
  ) {
    path.addOval(
      Rect.fromCircle(
        center: drawData.offset,
        radius: drawData.style.radius,
      ),
    );
  }

  void _batchPaintTrianglePort(
    Path path,
    Paint paint,
    PortDrawData drawData,
  ) {
    final trianglePath = Path()
      ..moveTo(
        drawData.offset.dx - drawData.style.radius,
        drawData.offset.dy - drawData.style.radius,
      ) // Top-left
      ..lineTo(
        drawData.offset.dx + drawData.style.radius,
        drawData.offset.dy,
      ) // Middle-right (apex)
      ..lineTo(
        drawData.offset.dx - drawData.style.radius,
        drawData.offset.dy + drawData.style.radius,
      ) // Bottom-left
      ..close();

    path.addPath(trianglePath, Offset.zero);
  }

  void _paintSelectionArea(Canvas canvas, Rect viewport) {
    if (selectionArea.isEmpty) return;

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

  ///////////////////////////////////////////////////////////////////
  /// Debug methods
  ///////////////////////////////////////////////////////////////////

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

  //////////////////////////////////////////////////////////////////
  /// Hit testing methods
  //////////////////////////////////////////////////////////////////

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final Offset centeredPosition =
        position - Offset(size.width / 2, size.height / 2);
    final Offset scaledPosition = centeredPosition.scale(1 / zoom, 1 / zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    for (final nodeId in _controller.spatialHashGrid.queryCoords(
      transformedPosition,
    )) {
      final child = _childrenById[nodeId]!;
      final childParentData = child.parentData as _ParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: transformedPosition,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }
    }

    return false;
  }
}
