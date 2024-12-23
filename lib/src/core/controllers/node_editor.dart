import 'dart:async';

import 'package:flutter/material.dart';

import '../models/node.dart';

class NodeEditorEvent {}

class OffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  OffsetEvent(this.offset, {this.animate = true});
}

class ZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  ZoomEvent(this.zoom, {this.animate = true});
}

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
  final Map<String, NodePrototype Function()> _nodePrototypes = {};
  final List<Node> _nodes = [];

  FlNodeEditorController();

  void registerNodePrototype(String type, NodePrototype Function() node) {
    _nodePrototypes[type] = node;
  }

  void unregisterNodePrototype(String type) {
    _nodePrototypes.remove(type);
  }

  void addNode(String type, {Offset? offset}) {
    _nodes.add(
      createNode(
        _nodePrototypes[type]!(),
        offset: offset,
      ),
    );
  }

  void removeNode(String id) {
    _nodes.removeWhere((node) => node.id == id);
  }

  void setOffset(Offset offset, {bool animate = true}) {
    eventBus.emit(OffsetEvent(offset));
  }

  void setZoom(double zoom, {bool animate = true}) {
    eventBus.emit(ZoomEvent(zoom));
  }

  List<Node> get nodes => _nodes;
  Map<String, NodePrototype Function()> get nodePrototypes => _nodePrototypes;
}
