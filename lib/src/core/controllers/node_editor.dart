import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:fl_nodes/src/core/utils/platform.dart';
import 'package:fl_nodes/src/core/utils/spatial_hash_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';

import '../models/node.dart';

import 'node_editor_events.dart';

/// A class that acts as an event bus for the Node Editor.
///
/// This class is responsible for handling and dispatching events
/// related to the node editor. It allows different parts of the
/// application to communicate with each other by sending and
/// receiving events.
///
/// Events can object instances should extend the [NodeEditorEvent] class.
class _NodeEditorEventBus {
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

enum NodeEditorLogSeverity {
  info,
  warning,
  error,
}

class NodeEditorLog {
  final String message;
  final DateTime timestamp;
  final NodeEditorLogSeverity severity;

  NodeEditorLog({
    required this.message,
    required this.timestamp,
    required this.severity,
  });
}

/// A class that acts as a logger for the Node Editor. It serves
/// internal purposes but can still be accessed by the developer
/// to check the logs for debugging or giving feedback to the user.
class _NodeEditorLogger {
  final List<NodeEditorLog> _logs = [];

  void log(String message, NodeEditorLogSeverity severity) {
    final log = NodeEditorLog(
      message: message,
      timestamp: DateTime.now(),
      severity: severity,
    );

    _logs.add(log);
  }

  void clearLogs() {
    _logs.clear();
  }
}

/// A class that defines the behavior of a node editor.
///
/// This class is responsible for handling the interactions and
/// behaviors associated with a node editor, such as node selection,
/// movement, and other editor-specific functionalities.
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

/// A controller class for the Node Editor.
///
/// This class is responsible for managing the state of the node editor,
/// including the nodes, links, and the viewport. It also provides methods
/// for adding, removing, and manipulating nodes and links.
///
/// The controller also provides an event bus for the node editor, allowing
/// different parts of the application to communicate with each other by
/// sending and receiving events.
class FlNodeEditorController {
  // Streams
  final eventBus = _NodeEditorEventBus();
  final logger = _NodeEditorLogger();

  // Behavior
  final NodeEditorBehavior behavior;

  FlNodeEditorController({
    this.behavior = const NodeEditorBehavior(),
  }) {
    if (kDebugMode) {
      logger.log(
        'FlNodes is running in debug mode. This may affect performance.',
        NodeEditorLogSeverity.warning,
      );
    }

    if (isMobile()) {
      logger.log(
        'FlNodes is view only on mobile devices. Editing is only available on desktop.',
        NodeEditorLogSeverity.info,
      );
    }
  }

  void dispose() {
    eventBus.dispose();
  }

  // Viewport
  Offset offset = Offset.zero;
  double zoom = 1.0;

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

  // This is used for rendering purposes only. For computation, use the links list in the Port class.
  final Map<String, Link> _renderLinks = {};
  Tuple2<Offset, Offset>? _renderTempLink;

  List<Link> get renderLinksAsList => _renderLinks.values.toList();
  Tuple2<Offset, Offset>? get renderTempLink => _renderTempLink;

  void drawTempLink(Offset from, Offset to) {
    _renderTempLink = Tuple2(from, to);
    eventBus.emit(DrawTempLinkEvent(from, to));
  }

  void clearTempLink() {
    _renderTempLink = null;
    eventBus.emit(DrawTempLinkEvent(Offset.zero, Offset.zero));
  }

  // Nodes and links
  final Map<String, NodePrototype Function()> _nodePrototypes = {};
  final SpatialHashGrid _spatialHashGrid = SpatialHashGrid();
  final Map<String, Node> _nodes = {};

  List<NodePrototype> get nodePrototypesAsList =>
      _nodePrototypes.values.map((e) => e()).toList();
  Map<String, NodePrototype Function()> get nodePrototypes => _nodePrototypes;

  List<Node> get nodesAsList {
    final nodesList = _nodes.values.toList();

    // We sort the nodes list so that selected nodes are rendered on top of others.
    nodesList.sort((a, b) {
      if (_selectedNodeIds.contains(a.id) && !_selectedNodeIds.contains(b.id)) {
        return 1;
      } else if (!_selectedNodeIds.contains(a.id) &&
          _selectedNodeIds.contains(b.id)) {
        return -1;
      } else {
        return 0;
      }
    });

    return nodesList;
  }

  Map<String, Node> get nodes => _nodes;
  SpatialHashGrid get spatialHashGrid => _spatialHashGrid;

  void registerNodePrototype(String type, NodePrototype Function() node) {
    _nodePrototypes[type] = node;
  }

  void unregisterNodePrototype(String type) {
    _nodePrototypes.remove(type);
  }

  Node addNode(String type, {Offset? offset}) {
    final node = createNode(
      _nodePrototypes[type]!(),
      offset: offset,
      onRendered: (node) {
        _spatialHashGrid.remove(node.id);
        _spatialHashGrid.insert(Tuple2(node.id, getNodeBoundsInWorld(node)!));
      },
    );

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );

    // The node is added to the spatial hash grid directly in the widget as it needs to be rendered first.

    eventBus.emit(AddNodeEvent(node.id));

    return node;
  }

  void removeNodes(Set<String> ids) {
    for (final id in ids) {
      for (final port in _nodes[id]!.ports.values) {
        removeLinks(id, port.id);
      }

      _spatialHashGrid.remove(id);
      _nodes.remove(id);
    }

    eventBus.emit(RemoveNodesEvent(ids));
  }

  Link? addLink(
    String fromNodeId,
    String fromPortId,
    String toNodeId,
    String toPortId,
  ) {
    final fromPort = _nodes[fromNodeId]!.ports[fromPortId]!;
    final toPort = _nodes[toNodeId]!.ports[toPortId]!;

    if (fromPort.isInput == toPort.isInput) return null;

    if (fromPort.links.isNotEmpty && !fromPort.allowMultipleLinks) return null;
    if (toPort.links.isNotEmpty && !toPort.allowMultipleLinks) return null;

    for (final link in toPort.links) {
      if (link.fromTo.item1 == fromNodeId && link.fromTo.item2 == fromPortId) {
        return null;
      }
    }

    final link = Link(
      id: const Uuid().v4(),
      fromTo: Tuple4(fromNodeId, fromPortId, toNodeId, toPortId),
    );

    fromPort.links.add(link);
    _nodes[toNodeId]!.ports[toPortId]!.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(AddLinkEvent(link.id));

    return link;
  }

  void removeLinks(String nodeId, String portId) {
    final port = _nodes[nodeId]!.ports[portId]!;

    final linksToRemove = List<Link>.from(port.links);

    for (final link in linksToRemove) {
      final fromPort = _nodes[link.fromTo.item1]!.ports[link.fromTo.item2]!;
      final toPort = _nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!;

      fromPort.links.remove(link);
      toPort.links.remove(link);

      _renderLinks.remove(link.id);
    }

    eventBus.emit(RemoveLinksEvent('$nodeId-$portId'));
  }

  void setNodeOffset(String id, Offset offset) {
    final node = _nodes[id];
    node?.offset = offset;
  }

  void collapseSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = true;
    }

    eventBus.emit(CollapseNodeEvent(_selectedNodeIds));
  }

  void expandSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = false;
    }

    eventBus.emit(CollapseNodeEvent(_selectedNodeIds));
  }

  // Selection
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;

  void dragSelection(Offset delta) {
    eventBus.emit(DragSelectionEvent(_selectedNodeIds.toSet(), delta));
  }

  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(area));
  }

  void selectNodesById(Set<String> ids, {bool holdSelection = false}) async {
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
    final containedNodes = _spatialHashGrid.queryNodeIdsInArea(_selectionArea);
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

  void focusNodesById(Set<String> ids) {
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
}
