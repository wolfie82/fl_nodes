import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/controllers/node_editor/history.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/project.dart';
import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/core/utils/spatial_hash_grid.dart';

import '../../models/entities.dart';
import '../../models/events.dart';

import 'clipboard.dart';
import 'config.dart';
import 'event_bus.dart';
import 'utils.dart';

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
  final NodeEditorConfig behavior;
  final eventBus = NodeEditorEventBus();

  late final FlNodeEditorClipboard clipboard;
  late final FlNodeEditorHistory history;
  late final FlNodeEditorProject project;

  FlNodeEditorController({
    this.behavior = const NodeEditorConfig(),
    Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver,
    Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader,
    Future<bool> Function(bool isSaved)? projectCreator,
  }) {
    clipboard = FlNodeEditorClipboard(this);
    history = FlNodeEditorHistory(this);
    project = FlNodeEditorProject(
      this,
      projectSaver: projectSaver,
      projectLoader: projectLoader,
      projectCreator: projectCreator,
    );
  }

  void dispose() {
    eventBus.close();
    history.clear();
    project.clear();

    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();
  }

  void clear() {
    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();
  }

  // Viewport
  Offset viewportOffset = Offset.zero;
  double viewportZoom = 1.0;

  void setViewportOffset(
    Offset coords, {
    bool animate = true,
    bool absolute = false,
    bool isHandled = false,
  }) {
    if (absolute) {
      viewportOffset = coords;
    } else {
      viewportOffset += coords;
    }

    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        viewportOffset,
        animate: animate,
        isHandled: isHandled,
      ),
    );
  }

  void setViewportZoom(
    double amount, {
    bool animate = true,
    bool isHandled = false,
  }) {
    viewportZoom = amount;

    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        viewportZoom,
        isHandled: isHandled,
      ),
    );
  }

  // Nodes, links and groups
  final Map<String, NodePrototype> _nodePrototypes = {};
  final SpatialHashGrid _spatialHashGrid = SpatialHashGrid();
  final Map<String, NodeInstance> _nodes = {};

  List<NodePrototype> get nodePrototypesAsList =>
      _nodePrototypes.values.map((e) => e).toList();
  Map<String, NodePrototype> get nodePrototypes => _nodePrototypes;

  List<NodeInstance> get nodesAsList {
    final nodesList = _nodes.values.toList();

    // We sort the nodes list so that selected nodes are rendered on top of others.
    nodesList.sort((a, b) {
      if (selectedNodeIds.contains(a.id) && !selectedNodeIds.contains(b.id)) {
        return 1;
      } else if (!selectedNodeIds.contains(a.id) &&
          selectedNodeIds.contains(b.id)) {
        return -1;
      } else {
        return 0;
      }
    });

    return nodesList;
  }

  Map<String, NodeInstance> get nodes => _nodes;
  SpatialHashGrid get spatialHashGrid => _spatialHashGrid;

  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void registerNodePrototype(NodePrototype name) {
    _nodePrototypes.putIfAbsent(
      name.name,
      () => name,
    );
  }

  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void unregisterNodePrototype(String name) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    } else {
      _nodePrototypes.remove(name);
    }
  }

  NodeInstance addNode(String name, {Offset? offset}) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    }

    final instance = createNode(
      _nodePrototypes[name]!,
      offset: offset,
      // Layout is needed to insert the node into the spatial hash grid.
      onRendered: onRenderedCallback,
    );

    _nodes.putIfAbsent(
      instance.id,
      () => instance,
    );

    eventBus.emit(
      AddNodeEvent(id: const Uuid().v4(), instance),
    );

    return instance;
  }

  void addNodeFromExisting(
    NodeInstance node, {
    bool isHandled = false,
    String? eventId,
  }) {
    if (_nodes.containsKey(node.id)) return;

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );

    eventBus.emit(
      AddNodeEvent(
        id: eventId ?? const Uuid().v4(),
        node,
        isHandled: isHandled,
      ),
    );

    for (final port in node.ports.values) {
      for (final link in port.links) {
        addLinkFromExisting(link, isHandled: isHandled);
      }
    }
  }

  void removeNode(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) async {
    if (!_nodes.containsKey(id)) return;

    final node = _nodes[id]!;

    for (final port in node.ports.values) {
      final linksToRemove = port.links.map((link) => link.id).toList();

      for (final linkId in linksToRemove) {
        removeLinkById(linkId, isHandled: true);
      }
    }

    _spatialHashGrid.remove(id);
    _nodes.remove(id);

    eventBus.emit(
      RemoveNodeEvent(
        id: eventId ?? const Uuid().v4(),
        node,
        isHandled: isHandled,
      ),
    );
  }

  Link? addLink(
    String node1Id,
    String port1Id,
    String node2Id,
    String port2Id, {
    String? eventId,
  }) {
    if (port1Id == port2Id) return null;

    final port1 = _nodes[node1Id]!.ports[port1Id]!;
    final port2 = _nodes[node2Id]!.ports[port2Id]!;

    if (port1.portType == port2.portType) return null;
    if (port1.links.length > 1 && !port1.allowMultipleLinks ||
        port2.links.length > 1 && !port2.allowMultipleLinks) {
      return null;
    }

    late PortInstance fromPort;
    late PortInstance toPort;

    // Determine the direction of the link based on the port types as we're building a directed graph.
    if (port1.portType == PortType.output) {
      fromPort = port1;
      toPort = port2;
    } else {
      fromPort = port2;
      toPort = port1;
    }

    for (final link in toPort.links) {
      if (link.fromTo.item1 == node1Id && link.fromTo.item2 == port1Id) {
        return null;
      }
    }

    final link = Link(
      id: const Uuid().v4(),
      fromTo: Tuple4(node1Id, port1Id, node2Id, port2Id),
    );

    fromPort.links.add(link);
    toPort.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(
      AddLinkEvent(id: eventId ?? const Uuid().v4(), link),
    );

    return link;
  }

  void addLinkFromExisting(
    Link link, {
    String? eventId,
    bool isHandled = false,
  }) {
    if (!_nodes.containsKey(link.fromTo.item1) ||
        !_nodes.containsKey(link.fromTo.item3)) {
      return;
    }

    final fromNode = _nodes[link.fromTo.item1]!;
    final toNode = _nodes[link.fromTo.item3]!;

    if (!fromNode.ports.containsKey(link.fromTo.item2) ||
        !toNode.ports.containsKey(link.fromTo.item4)) {
      return;
    }

    final fromPort = _nodes[link.fromTo.item1]!.ports[link.fromTo.item2]!;
    final toPort = _nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!;

    fromPort.links.add(link);
    toPort.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(
      AddLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  void removeLinkById(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) {
    if (!_renderLinks.containsKey(id)) return;

    final link = _renderLinks[id]!;

    // Remove the link from its associated ports
    final fromPort = _nodes[link.fromTo.item1]?.ports[link.fromTo.item2];
    final toPort = _nodes[link.fromTo.item3]?.ports[link.fromTo.item4];

    fromPort?.links.remove(link);
    toPort?.links.remove(link);

    _renderLinks.remove(id);

    eventBus.emit(
      RemoveLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  // This is used for rendering purposes only. For computation, use the links list in the Port class.
  final Map<String, Link> _renderLinks = {};
  Tuple2<Offset, Offset>? _renderTempLink;

  List<Link> get renderLinksAsList => _renderLinks.values.toList();
  Tuple2<Offset, Offset>? get renderTempLink => _renderTempLink;

  void drawTempLink(Offset from, Offset to) {
    _renderTempLink = Tuple2(from, to);
    eventBus.emit(DrawTempLinkEvent(id: const Uuid().v4(), from, to));
  }

  void clearTempLink() {
    _renderTempLink = null;
    eventBus.emit(
      DrawTempLinkEvent(id: const Uuid().v4(), Offset.zero, Offset.zero),
    );
  }

  void breakPortLinks(String nodeId, String portId, {bool isHandled = false}) {
    if (!_nodes.containsKey(nodeId)) return;
    if (!_nodes[nodeId]!.ports.containsKey(portId)) return;

    final port = _nodes[nodeId]!.ports[portId]!;

    // Collect all link IDs associated with the port
    final linksToRemove = port.links.map((link) => link.id).toList();

    for (final linkId in linksToRemove) {
      removeLinkById(linkId, isHandled: true);
    }
  }

  void setFieldData(
    String nodeId,
    String fieldId, {
    dynamic data,
    required FieldEventType eventType,
  }) {
    if (eventType == FieldEventType.change) return;

    final node = _nodes[nodeId]!;
    final field = node.fields[fieldId]!;
    field.data = data;

    eventBus.emit(
      NodeFieldEvent(
        id: const Uuid().v4(),
        nodeId,
        data,
        eventType,
      ),
    );
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

    eventBus.emit(CollapseNodeEvent(id: const Uuid().v4(), _selectedNodeIds));
  }

  void expandSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = false;
    }

    eventBus.emit(CollapseNodeEvent(id: const Uuid().v4(), _selectedNodeIds));
  }

  // Selection
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;

  void dragSelection(Offset delta, {String? eventId}) {
    if (_selectedNodeIds.isEmpty) return;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.offset += delta / viewportZoom;
    }

    eventBus.emit(
      DragSelectionEvent(
        id: eventId ?? const Uuid().v4(),
        _selectedNodeIds.toSet(),
        delta / viewportZoom,
      ),
    );
  }

  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(id: const Uuid().v4(), area));
  }

  void selectNodesById(
    Set<String> ids, {
    bool holdSelection = false,
    bool isHandled = false,
  }) async {
    if (ids.isEmpty) {
      clearSelection();
      return;
    }

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

    eventBus.emit(
      SelectionEvent(id: const Uuid().v4(), _selectedNodeIds.toSet()),
    );
  }

  void selectNodesByArea({bool holdSelection = false}) async {
    final containedNodes = _spatialHashGrid.queryNodeIdsInArea(_selectionArea);
    selectNodesById(containedNodes, holdSelection: holdSelection);
    _selectionArea = Rect.zero;
  }

  void clearSelection({bool isHandled = false}) {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = false;
    }

    _selectedNodeIds.clear();

    eventBus.emit(
      SelectionEvent(
        id: const Uuid().v4(),
        _selectedNodeIds.toSet(),
        isHandled: isHandled,
      ),
    );
  }

  void focusNodesById(Set<String> ids) {
    final encompassingRect = calculateEncompassingRect(
      ids,
      _nodes,
      margin: 256,
    );

    selectNodesById(ids, holdSelection: false);

    final nodeEditorSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;

    setViewportOffset(
      -encompassingRect.center,
      animate: true,
      absolute: true,
    );

    final fitZoom = min(
      nodeEditorSize.width / encompassingRect.width,
      nodeEditorSize.height / encompassingRect.height,
    );

    setViewportZoom(fitZoom, animate: true);
  }

  Future<List<String>> searchNodesByName(String name) async {
    final results = <String>[];

    final regex = RegExp(name, caseSensitive: false);

    for (final node in _nodes.values) {
      if (regex.hasMatch(node.name)) {
        results.add(node.id);
      }
    }

    return results;
  }

  /// Callback function that is called when a node is rendered.
  ///
  /// This function is used to update the spatial hash grid with the new bounds
  /// of the node after it has been rendered. This is necessary to keep the grid
  /// up to date with the latest positions of the nodes.
  void onRenderedCallback(NodeInstance node) {
    _spatialHashGrid.remove(node.id);
    _spatialHashGrid.insert(
      Tuple2(node.id, getNodeBoundsInWorld(node)!),
    );
  }
}
