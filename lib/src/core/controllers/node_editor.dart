import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';

import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';

import '../models/node.dart';

import 'node_editor_events.dart';

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
    this.maxPanX = 100000.0,
    this.maxPanY = 100000.0,
    this.enableKineticScrolling = true,
  });
}

class NodeEditorEventBus {
  final _streamController = StreamController<NodeEditorEvent>.broadcast();
  final Queue<NodeEditorEvent> _eventHistory = Queue();

  void emit(NodeEditorEvent event) {
    _streamController.add(event);

    if (_eventHistory.length >= kMaxEventHistory) {
      _eventHistory.removeFirst();
    }

    _eventHistory.add(event);
  }

  void dispose() {
    _streamController.close();
  }

  Stream<NodeEditorEvent> get events => _streamController.stream;
  NodeEditorEvent get lastEvent => _eventHistory.last;
}

class FlNodeEditorController {
  // Event bus
  final eventBus = NodeEditorEventBus();

  // Node data
  Offset offset = Offset.zero;
  double zoom = 1.0;
  final Map<String, NodePrototype Function()> _nodePrototypes = {};
  final Map<String, Node> _nodes = {};
  final Map<String, Link> _links = {};
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  // Behavior
  final NodeEditorBehavior behavior;

  FlNodeEditorController({
    this.behavior = const NodeEditorBehavior(),
  });

  void dispose() {
    eventBus.dispose();
  }

  void registerNodePrototype(String type, NodePrototype Function() node) {
    _nodePrototypes[type] = node;
  }

  void unregisterNodePrototype(String type) {
    _nodePrototypes.remove(type);
  }

  String addNode(String type, {Offset? offset}) {
    final node = createNode(
      _nodePrototypes[type]!(),
      offset: offset,
    );

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );

    eventBus.emit(AddNodeEvent(node.id));

    return node.id;
  }

  void removeNode(String id) {
    _nodes.remove(id);
    eventBus.emit(RemoveNodeEvent(id));
  }

  String addLink(
    String fromNode,
    String fromPort,
    String toNode,
    String toPort,
  ) {
    final link = Link(
      id: 'from-$fromNode-$fromPort-to-$toNode-$toPort',
      fromTo: Tuple4(fromNode, fromPort, toNode, toPort),
    );

    _links.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(AddLinkEvent(link.id));

    return link.id;
  }

  void removeLink(String id) {
    _links.remove(id);
    eventBus.emit(RemoveLinkEvent(id));
  }

  void setViewportOffset(
    Offset coords, {
    bool animate = true,
    bool absolute = false,
  }) {
    if (absolute) {
      offset = coords;
    } else {
      offset += coords;
    }

    eventBus.emit(ViewportOffsetEvent(offset, animate: animate));
  }

  void setViewportZoom(double amount, {bool animate = true}) {
    zoom = amount;
    eventBus.emit(ViewportZoomEvent(zoom));
  }

  void setNodeOffset(String id, Offset offset) {
    final node = _nodes[id];
    node?.offset = offset;
  }

  void dragSelection(Offset delta) {
    eventBus.emit(DragSelectionEvent(_selectedNodeIds.toSet(), delta));
  }

  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(area));
  }

  void collapseNode(String id) {
    final node = _nodes[id];
    node?.state.isCollapsed = true;
    eventBus.emit(CollapseNodeEvent(id));
  }

  void expandNode(String id) {
    final node = _nodes[id];
    node?.state.isCollapsed = false;
    eventBus.emit(ExpandNodeEvent(id));
  }

  void selectNodesById(List<String> ids, {bool holdSelection = false}) async {
    if (!holdSelection) {
      for (final id in _selectedNodeIds) {
        final node = _nodes[id];
        node?.state.isSelected = false;
      }

      _selectedNodeIds.clear();
    }

    _selectedNodeIds.addAll(ids);

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = true;
    }

    eventBus.emit(SelectionEvent(_selectedNodeIds.toSet()));
  }

  void selectNodesByArea({bool holdSelection = false}) async {
    final containedNodes = <String>[];

    for (final node in _nodes.values) {
      final nodeBounds = getNodeBoundsInWorld(node);
      if (nodeBounds == null) continue;

      if (_selectionArea.overlaps(nodeBounds)) {
        containedNodes.add(node.id);
      }
    }

    selectNodesById(containedNodes, holdSelection: holdSelection);

    _selectionArea = Rect.zero;
  }

  void clearSelection() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = false;
    }

    _selectedNodeIds.clear();
    eventBus.emit(SelectionEvent(_selectedNodeIds.toSet()));
  }

  void focusNodesById(List<String> ids) {
    Rect encompassingRect = Rect.zero;

    for (final id in ids) {
      final nodeBounds = getNodeBoundsInWorld(_nodes[id]!);
      if (nodeBounds == null) continue;

      if (encompassingRect.isEmpty) {
        encompassingRect = nodeBounds;
      } else {
        encompassingRect = encompassingRect.expandToInclude(nodeBounds);
      }
    }

    selectNodesById(ids, holdSelection: false);

    final nodeEditorSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;
    final paddedEncompassingRect = encompassingRect.inflate(50.0);
    final fitZoom = min(
      nodeEditorSize.width / paddedEncompassingRect.width,
      nodeEditorSize.height / paddedEncompassingRect.height,
    );

    setViewportZoom(fitZoom, animate: true);
    setViewportOffset(
      -encompassingRect.center,
      animate: true,
      absolute: true,
    );
  }

  Future<List<String>> searchNodesByName(String name) async {
    final results = <String>[];

    for (final node in _nodes.values) {
      if (node.name.toLowerCase().contains(name.toLowerCase())) {
        results.add(node.id);
      }
    }

    return results;
  }

  // Getters

  List<NodePrototype> get nodePrototypesAsList =>
      _nodePrototypes.values.map((e) => e()).toList();
  Map<String, NodePrototype Function()> get nodePrototypes => _nodePrototypes;
  List<Node> get nodesAsList => _nodes.values.toList();
  Map<String, Link> get links => _links;
  List<Link> get linksAsList => _links.values.toList();
  Map<String, Node> get nodes => _nodes;
  List<String> get selectedNodeIds => _selectedNodeIds.toList();
  Rect get selectionArea => _selectionArea;
}
