import 'dart:async';

import 'package:fl_nodes/src/core/utils/renderbox.dart';
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
  final Set<String> _selectedNodeIds = {};
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
      hasBuilt: (self) => (),
    );

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );
  }

  void removeNode(String id) {
    _nodes.remove(id);
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
    node?.state.isCollapsed = !node.state.isCollapsed;
    eventBus.emit(CollapseNodeEvent(id));
  }

  void selectNodesById(List<String> ids, {bool holdSelection = false}) {
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

  void selectNodesByArea({bool holdSelection = false}) {
    if (!holdSelection) {
      for (final id in _selectedNodeIds) {
        final node = _nodes[id];
        node?.state.isSelected = false;
      }

      _selectedNodeIds.clear();
    }

    for (final node in _nodes.values) {
      final nodeBounds = getBoundsFromGlobalKey(node);

      if (nodeBounds != null && _selectionArea.overlaps(nodeBounds)) {
        node.state.isSelected = true;
        _selectedNodeIds.add(node.id);
      }
    }

    _selectionArea = Rect.zero;
  }

  // Getters

  Map<String, NodePrototype Function()> get nodePrototypes => _nodePrototypes;
  List<Node> get nodesAsList => _nodes.values.toList();
  List<String> get selectedNodeIds => _selectedNodeIds.toList();
  Rect get selectionArea => _selectionArea;
}
