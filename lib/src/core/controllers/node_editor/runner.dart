import 'dart:async';

import 'package:fl_nodes/src/core/models/events.dart';
import 'package:fl_nodes/src/core/utils/snackbar.dart';

import '../../models/entities.dart';

import 'core.dart';

class FlNodeEditorRunner {
  final FlNodeEditorController controller;
  Map<String, NodeInstance> _nodes = {};
  Map<String, Set<String>> _dataDeps = {};

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
      _buildDepsMap();
    }
  }

  /// Identifies independent subgraphs in the graph.
  void _copyNodes() {
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
  }

  /// Builds the data dependency map.
  void _buildDepsMap() {
    _dataDeps = {};

    _copyNodes();

    final Set<String> visited = {};

    for (final node in _nodes.values) {
      if (!node.ports.values
          .every((port) => port.prototype.portType == PortType.output)) {
        continue;
      }

      _findDeps(node.id, visited);
    }
  }

  /// Returns the unique IDs of nodes connected to a given node's input or output ports.
  Set<String> _getConnectedNodeIds(NodeInstance node, PortType portType) {
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

  void _findDeps(String nodeId, Set<String> visited) {
    if (visited.contains(nodeId)) return;

    visited.add(nodeId);

    _dataDeps[nodeId] = _getConnectedNodeIds(
      _nodes[nodeId]!,
      PortType.input,
    );

    final connectedNodeIds = _getConnectedNodeIds(
      _nodes[nodeId]!,
      PortType.output,
    );

    for (final connectedNodeId in connectedNodeIds) {
      _findDeps(connectedNodeId, visited);
    }
  }

  /// Executes the entire graph asynchronously
  Future<void> executeGraph() async {
    final Set<String> executed = {};

    for (final node in _nodes.values) {
      if (!node.ports.values
          .every((port) => port.prototype.portType == PortType.output)) {
        continue;
      }

      await _executeNode(node, executed);
    }
  }

  /// Executes a node asynchronously
  Future<void> _executeNode(NodeInstance node, Set<String> executed) async {
    if (executed.contains(node.id)) return;

    executed.add(node.id);

    for (final dep in _dataDeps[node.id]!) {
      await _executeNode(_nodes[dep]!, executed);
    }

    late final Map<String, dynamic> forwardedData;

    try {
      forwardedData = await node.prototype.onExecute(
        node.ports.map((portId, port) => MapEntry(portId, port.data)),
        node.fields.map((fieldId, field) => MapEntry(fieldId, field.data)),
      );
    } catch (e) {
      controller.focusNodesById({node.id});
      showNodeEditorSnackbar(
        'Error executing node: ${node.prototype.displayName}: $e',
        SnackbarType.error,
      );
      return;
    }

    for (final entry in forwardedData.entries) {
      final port = node.ports[entry.key]!;

      port.data = entry.value;

      final Set<NodeInstance> connectedNodes = {};

      for (final link in port.links) {
        final connectedNode = _nodes[link.fromTo.item3]!;
        final connectedPort = connectedNode.ports[link.fromTo.item4]!;

        connectedPort.data = entry.value;

        connectedNodes.add(connectedNode);
      }

      for (final node in connectedNodes) {
        await _executeNode(node, executed);
      }
    }
  }
}
