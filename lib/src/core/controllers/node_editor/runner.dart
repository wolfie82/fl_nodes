import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/models/events.dart';

import '../../models/entities.dart';
import '../../models/exception.dart';
import '../../utils/snackbar.dart';

import 'core.dart';

/// A subgraph is a collection of linearly dependent nodes.
///
/// It is used to execute nodes in the correct order in the runner component of the controller.
///
/// NOTE: Subgraphs and nodes are stored both in a [List] and a [Set] to allow for conservative ordering and fast ID based lookups.
class Subgraph {
  final String id;
  final Set<String> nodeIds = {};
  final List<NodeInstance> nodes = [];
  final Set<String> childrenIds = {};
  final List<Subgraph> children = [];
  final Set<String> parentIds = {}; // Currently not used
  final List<Subgraph> parents = []; // Currently not used

  Subgraph() : id = const Uuid().v4();

  void addNode(NodeInstance node) {
    nodeIds.add(node.id);
    nodes.add(node);
  }

  void addSubgraph(Subgraph newSubgraph) {
    newSubgraph.parentIds.add(newSubgraph.id);
    newSubgraph.parents.add(newSubgraph);
    childrenIds.add(newSubgraph.id);
    children.add(newSubgraph);
  }
}

class FlNodeEditorRunner {
  final FlNodeEditorController controller;
  Map<String, NodeInstance> _nodes = {};
  List<Subgraph> _topSubgraphs = [];
  Set<String> _executedSubgraphs = {};

  FlNodeEditorRunner(this.controller) {
    controller.eventBus.events.listen(_handleRunnerEvents);
  }

  /// Handles events from the controller and updates the graph accordingly.
  void _handleRunnerEvents(NodeEditorEvent event) {
    if (event is AddNodeEvent ||
        event is RemoveNodeEvent ||
        event is AddLinkEvent ||
        event is RemoveLinkEvent ||
        (event is NodeFieldEvent && event.eventType == FieldEventType.submit)) {
      _identifySubgraphs();
    }
  }

  /// Identifies independent subgraphs in the graph.
  void _identifySubgraphs() {
    _topSubgraphs = [];

    // This isolates and avoids async access issues
    _nodes = controller.nodes.map((id, node) {
      final deepCopiedPorts = node.ports.map((portId, port) {
        final deepCopiedLinks = port.links.map((link) {
          return link.copyWith();
        }).toSet();

        return MapEntry(
          portId,
          port.copyWith(links: deepCopiedLinks),
        );
      });

      final deepCopiedFields = node.fields.map((fieldId, field) {
        return MapEntry(
          fieldId,
          field.copyWith(),
        );
      });

      return MapEntry(
        id,
        node.copyWith(
          ports: deepCopiedPorts,
          fields: deepCopiedFields,
        ),
      );
    });

    // Detect top-level subgraphs
    for (final node in _nodes.values) {
      final hasOnlyInputPorts = node.ports.values.every(
        (port) => port.prototype.portType == PortType.input,
      );

      if (hasOnlyInputPorts) {
        final Set<String> visitedNodes = {};
        final Subgraph subgraph = Subgraph();
        _topSubgraphs.add(subgraph);

        _collectSubgraphFromLinks(
          node,
          subgraph,
          visitedNodes,
        );
      }
    }

    if (kDebugMode) _debugColorNodes();
  }

  /// Returns the unique IDs of nodes connected to a given node's input or output ports.
  Set<String> connectedNodeIds(NodeInstance node, PortType portType) {
    final connectedNodeIds = <String>{};

    final ports = node.ports.values.where(
      (port) => port.prototype.portType == portType,
    );

    for (final port in ports) {
      for (final link in port.links) {
        final connectedNode = _nodes[portType == PortType.input
            ? link.fromTo.item1
            : link.fromTo.item3]!;
        connectedNodeIds.add(connectedNode.id);
      }
    }

    return connectedNodeIds;
  }

  /// Recursively collects nodes in a subgraph from input links.
  void _collectSubgraphFromLinks(
    NodeInstance currentNode,
    Subgraph currentSubgraph,
    Set<String> visitedNodes,
  ) {
    // Check if the node has already been visited
    if (visitedNodes.contains(currentNode.id)) return;

    visitedNodes.add(currentNode.id);

    final lastNode = currentSubgraph.nodes.lastOrNull;

    final currentInputNodeIds = connectedNodeIds(
      currentNode,
      PortType.input,
    );
    final currentOutputNodeIds = connectedNodeIds(
      currentNode,
      PortType.output,
    );

    if (lastNode == null) {
      currentSubgraph.addNode(currentNode);

      for (final inputNodeId in currentInputNodeIds) {
        _collectSubgraphFromLinks(
          _nodes[inputNodeId]!,
          currentSubgraph,
          visitedNodes,
        );
      }
    } else {
      final lastInputNodeIds = connectedNodeIds(
        lastNode,
        PortType.input,
      );

      if (lastInputNodeIds.length > 1 || currentOutputNodeIds.length > 1) {
        final newSubgraph = Subgraph();
        newSubgraph.addNode(currentNode);
        currentSubgraph.addSubgraph(newSubgraph);

        for (final inputNodeId in currentInputNodeIds) {
          _collectSubgraphFromLinks(
            _nodes[inputNodeId]!,
            newSubgraph,
            visitedNodes,
          );
        }
      } else {
        currentSubgraph.addNode(currentNode);

        for (final inputNodeId in currentInputNodeIds) {
          _collectSubgraphFromLinks(
            _nodes[inputNodeId]!,
            currentSubgraph,
            visitedNodes,
          );
        }
      }
    }
  }

  /// Executes the entire graph asynchronously
  Future<void> executeGraph() async {
    if (_nodes.isEmpty) return;

    final futures = <Future<void>>[];

    for (final subgraph in _topSubgraphs) {
      futures.add(_executeSubgraph(subgraph));
    }

    // Await all subgraph executions to complete
    await Future.wait(futures);
  }

  /// Executes a single subgraph asynchronously
  Future<void> _executeSubgraph(Subgraph subgraph) async {
    if (_executedSubgraphs.contains(subgraph.id)) return;

    _executedSubgraphs.add(subgraph.id);

    for (final child in subgraph.children) {
      await _executeSubgraph(child);
    }

    for (final node in subgraph.nodes.reversed) {
      await _executeNode(node);
    }

    _executedSubgraphs = {};
  }

  /// Executes a single node
  Future<void> _executeNode(NodeInstance node) async {
    try {
      await Future.microtask(() async {
        await node.onExecute(
          node.ports.map(
            (key, value) => MapEntry(value.prototype.name, value),
          ),
          node.fields.map(
            (key, value) => MapEntry(value.prototype.name, value),
          ),
        );

        for (final port in node.ports.values) {
          if (port.prototype.portType == PortType.output) {
            for (final link in port.links) {
              _nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!.data =
                  port.data;
            }
          }
        }
      });
    } on RunnerException catch (e) {
      controller.focusNodesById({node.id});
      showNodeEditorSnackbar(
        'Error executing node ${node.id}: $e',
        SnackbarType.error,
      );
    } catch (e) {
      if (kDebugMode) {
        controller.focusNodesById({node.id});
        showNodeEditorSnackbar(
          'Error executing node ${node.id}: $e',
          SnackbarType.error,
        );
        debugPrint('Error executing node ${node.id}: $e');
      }
      rethrow;
    }
  }

  void _debugColorNodes() {
    Color generateRandomColor() {
      return Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );
    }

    // Assign a unique color to each subgraph recursively
    void assignColorsToSubgraphs(Subgraph subgraph) {
      final randomColor = generateRandomColor();

      for (final node in subgraph.nodes) {
        controller.nodes[node.id]?.debugColor = randomColor;
      }

      for (final child in subgraph.children) {
        assignColorsToSubgraphs(child);
      }
    }

    for (final subgraph in _topSubgraphs) {
      assignColorsToSubgraphs(subgraph);
    }
  }
}
