import 'package:flutter/material.dart';

import '../models/node.dart';

class NodeEditorController extends ChangeNotifier {
  final Map<String, Node Function()> _nodeTypes = {};
  final List<Node> _nodes = [];

  NodeEditorController();

  void registerNodeType(String type, Node Function() node) {
    _nodeTypes[type] = node;
  }

  void unregisterNodeType(String type) {
    _nodeTypes.remove(type);
  }

  Node createNode(String type) {
    final node = _nodeTypes[type]!();
    _nodes.add(node);
    return node;
  }

  void deleteNode(Node node) {
    _nodes.remove(node);
  }

  void clear() {
    _nodes.clear();
  }

  List<Node> get nodes => _nodes;
  Map<String, Node Function()> get nodeTypes => _nodeTypes;
}
