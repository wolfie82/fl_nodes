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
    required this.inputs,
    required this.outputs,
    required this.onExecute,
  });
}

class Node {
  final String id;
  final String name;
  final List<Port> inputs;
  final List<Port> outputs;
  Offset offset;
  final GlobalKey key = GlobalKey();

  Node({
    required this.id,
    required this.name,
    required this.inputs,
    required this.outputs,
    required this.offset,
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
    offset: offset ?? Offset.zero,
  );
}
