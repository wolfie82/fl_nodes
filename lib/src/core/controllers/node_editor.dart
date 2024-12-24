import 'dart:async';

import 'package:flutter/material.dart';

import '../models/node.dart';

import 'node_editor_events.dart';

class NodeEditorEventBus {
  final _streamController = StreamController<NodeEditorEvent>.broadcast();

  Stream<NodeEditorEvent> get events => _streamController.stream;

  void emit(NodeEditorEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}

class FlNodeEditorController {
  // Event bus
  final eventBus = NodeEditorEventBus();

  // Node data
  Offset offset = Offset.zero;
  double zoom = 1.0;
  final Map<String, NodePrototype Function()> _nodePrototypes = {};
  final Map<String, Node> _nodes = {};
  List<String> _selectedNodeIds = [];
  Rect _selectionArea = Rect.zero;

  FlNodeEditorController();

  void dispose() {
    eventBus.dispose();
  }

  // Controllet to UI communication

  void registerNodePrototype(String type, NodePrototype Function() node) {
    _nodePrototypes[type] = node;
  }

  void unregisterNodePrototype(String type) {
    _nodePrototypes.remove(type);
  }

  void addNode(String type, {Offset? offset}) {
    final node = createNode(
      _nodePrototypes[type]!(),
      offset: offset,
    );

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );
  }

  void removeNode(String id) {
    _nodes.remove(id);
  }

  void setViewportOffset(Offset coords, {bool animate = true}) {
    offset = coords;
    eventBus.emit(ViewportOffsetEvent(offset));
  }

  void setViewportZoom(double amount, {bool animate = true}) {
    zoom = amount;
    eventBus.emit(ViewportZoomEvent(zoom));
  }

  void setNodeOffset(String id, Offset offset) {
    final node = _nodes[id];
    node?.offset = offset;
  }

  void dragNode(String id, Offset offset) {
    final node = _nodes[id];
    node?.offset += offset;
    eventBus.emit(DragNodeEvent(id));
  }

  void collapseNode(String id) {
    final node = _nodes[id];
    node?.state.isCollapsed = !node.state.isCollapsed;
    eventBus.emit(CollapseNodeEvent(id));
  }

  void selectNodesById(List<String> ids) {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = false;
    }

    _selectedNodeIds = ids;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = true;
    }

    eventBus.emit(SelectNodeEvent(ids));
  }

  void selectNodesByArea(Rect area) {
    _selectionArea = area;
  }

  // Getters

  Map<String, NodePrototype Function()> get nodePrototypes => _nodePrototypes;
  List<Node> get nodesAsList => _nodes.values.toList();
  List<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;
}
