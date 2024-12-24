import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

class PortPrototype {
  final String name;
  final dynamic data;

  PortPrototype({
    required this.name,
    required this.data,
  });
}

class Port {
  final String id;
  final String name;
  final GlobalKey key = GlobalKey();

  Port({
    required this.id,
    required this.name,
  });
}

class NodePrototype {
  final String name;
  final List<PortPrototype> inputs;
  final List<PortPrototype> outputs;
  final void Function(List<String> inputIds, List<String> outputIds) onExecute;

  NodePrototype({
    required this.name,
    this.inputs = const [],
    this.outputs = const [],
    required this.onExecute,
  });
}

class NodeState {
  bool isSelected;
  bool isCollapsed;

  NodeState({
    this.isSelected = false,
    this.isCollapsed = false,
  });
}

class Node {
  final String id;
  final String name;
  final List<Port> inputs;
  final List<Port> outputs;
  final Function(List<String> inputIds, List<String> outputIds) onExecute;
  Offset offset;
  final NodeState state = NodeState();
  final GlobalKey key = GlobalKey();

  Node({
    required this.id,
    required this.name,
    this.inputs = const [],
    this.outputs = const [],
    required this.onExecute,
    this.offset = Offset.zero,
  });
}

Port createPort(PortPrototype prototype) {
  return Port(
    id: const Uuid().v4(),
    name: prototype.name,
  );
}

Node createNode(NodePrototype prototype, {Offset? offset}) {
  return Node(
    id: const Uuid().v4(),
    name: prototype.name,
    inputs: prototype.inputs.map(createPort).toList(),
    outputs: prototype.outputs.map(createPort).toList(),
    onExecute: prototype.onExecute,
    offset: offset ?? Offset.zero,
  );
}
