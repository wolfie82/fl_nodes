import 'package:flutter/material.dart';

class Port {
  final String id;
  final String name;
  final dynamic data;
  Color color;

  Port({
    required this.id,
    required this.name,
    required this.data,
    required this.color,
  });
}

class Field {
  final String id;
  final String name;
  final dynamic data;
  Color color;

  Field({
    required this.id,
    required this.name,
    required this.data,
    required this.color,
  });
}

class NodePrototype {
  final String name;
  final List<Port> inputs;
  final List<Port> outputs;
  final List<Field> fields;
  final List<String> Function(List<String> inputIds) onExecute;
  final Color color;

  NodePrototype({
    required this.name,
    required this.inputs,
    required this.outputs,
    required this.onExecute,
    required this.fields,
    required this.color,
  });
}

class Node {
  final NodePrototype prototype;
  final String id;
  Offset offset;

  Node({
    required this.prototype,
    required this.id,
    required this.offset,
  });
}
