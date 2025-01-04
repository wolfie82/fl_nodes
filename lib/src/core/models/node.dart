import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

class Link {
  final String id;
  final Tuple4<String, String, String, String> fromTo;

  Link({
    required this.id,
    required this.fromTo,
  });
}

class PortPrototype {
  final String name;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;

  PortPrototype({
    required this.name,
    this.dataType = dynamic,
    this.isInput = true,
    this.allowMultipleLinks = true,
  });
}

class Port {
  final String id;
  final String name;
  final dynamic data;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;
  List<Link> links = [];
  Offset offset;
  final GlobalKey key = GlobalKey();

  Port({
    required this.id,
    required this.name,
    required this.data,
    required this.dataType,
    required this.isInput,
    required this.allowMultipleLinks,
    this.offset = Offset.zero,
  });
}

class NodePrototype {
  final String name;
  final Color color;
  final List<PortPrototype> ports;
  final void Function(List<String> inputIds, List<String> outputIds) onExecute;

  NodePrototype({
    required this.name,
    this.color = Colors.blue,
    this.ports = const [],
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
  final Color color;
  final Map<String, Port> ports;
  final Function(List<String> inputIds, List<String> outputIds) onExecute;
  Offset offset;
  final NodeState state = NodeState();
  final GlobalKey key = GlobalKey();

  Node({
    required this.id,
    required this.name,
    required this.color,
    required this.ports,
    required this.onExecute,
    this.offset = Offset.zero,
  });
}

Port createPort(PortPrototype prototype) {
  return Port(
    id: const Uuid().v4(),
    name: prototype.name,
    data: null,
    dataType: prototype.dataType,
    isInput: prototype.isInput,
    allowMultipleLinks: prototype.allowMultipleLinks,
  );
}

Node createNode(
  NodePrototype prototype, {
  Offset? offset,
}) {
  return Node(
    id: const Uuid().v4(),
    name: prototype.name,
    color: prototype.color,
    ports: prototype.ports.asMap().map((_, portPrototype) {
      final port = createPort(portPrototype);
      return MapEntry(port.id, port);
    }),
    onExecute: prototype.onExecute,
    offset: offset ?? Offset.zero,
  );
}
