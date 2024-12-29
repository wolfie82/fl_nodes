import 'package:flutter/material.dart';

import '../models/node.dart';

import 'renderbox.dart';

class _RTreeNode {
  final Rect bounds;
  final List<Node> nodes = [];
  final List<_RTreeNode> children = [];

  _RTreeNode(this.bounds);

  bool get isLeaf => children.isEmpty;
  bool get isBranch => children.isNotEmpty && nodes.isEmpty;

  @override
  String toString() {
    return 'RTreeNode(nodes: $nodes, bounds: $bounds)';
  }
}

/// A simple R-Tree implementation for spatial indexing.
class RTree {
  final _RTreeNode _root;

  RTree(Rect bounds) : _root = _RTreeNode(bounds) {
    _initializeTree(_root, 2056);
  }

  /// Builds the R-Tree by subdividing the space into ~1024x1024 chunks.
  /// Each node may recursively create child nodes if its width or height
  /// exceeds the threshold. Partial blocks are allowed.
  void _initializeTree(_RTreeNode node, double blockSize) {
    final w = node.bounds.width;
    final h = node.bounds.height;
    if (w <= blockSize && h <= blockSize) return;

    final xCount = (w / blockSize).ceil();
    final yCount = (h / blockSize).ceil();
    final childW = w / xCount;
    final childH = h / yCount;

    for (int i = 0; i < xCount; i++) {
      for (int j = 0; j < yCount; j++) {
        final childBounds = Rect.fromLTWH(
          node.bounds.left + i * childW,
          node.bounds.top + j * childH,
          childW,
          childH,
        );
        final child = _RTreeNode(childBounds);
        node.children.add(child);
        _initializeTree(child, blockSize);
      }
    }
  }

  /// Insert the given node and insert it.
  void insert(Node node) {
    final nodeBounds = getNodeBoundsInWorld(node);
    if (nodeBounds == null) return;
    _insertNode(_root, node, nodeBounds);
  }

  void _insertNode(_RTreeNode currentNode, Node node, Rect nodeBounds) {
    if (currentNode.isLeaf) {
      currentNode.nodes.add(node);
    } else {
      for (final child in currentNode.children) {
        if (child.bounds.overlaps(nodeBounds)) {
          _insertNode(child, node, nodeBounds);
        }
      }
    }
  }

  /// Remove the given node from the tree.
  void remove(Node node) {
    final nodeBounds = getNodeBoundsInWorld(node);
    if (nodeBounds == null) return;
    _removeNode(_root, node, nodeBounds);
  }

  void _removeNode(_RTreeNode currentNode, Node node, Rect nodeBounds) {
    if (currentNode.isLeaf) {
      currentNode.nodes.remove(node);
    } else {
      for (final child in currentNode.children) {
        if (child.bounds.overlaps(nodeBounds)) {
          _removeNode(child, node, nodeBounds);
        }
      }
    }
  }

  List<String> query(Rect range) {
    final result = <String>[];
    _query(_root, range, result);
    return result;
  }

  void _query(_RTreeNode currentNode, Rect range, List<String> result) {
    if (currentNode.isLeaf) {
      for (final node in currentNode.nodes) {
        final nodeBounds = getNodeBoundsInWorld(node);
        if (nodeBounds != null && range.overlaps(nodeBounds)) {
          result.add(node.id);
        }
      }
    } else {
      for (final child in currentNode.children) {
        if (child.bounds.overlaps(range)) {
          _query(child, range, result);
        }
      }
    }
  }

  @override
  String toString() {
    final sb = StringBuffer();

    void appendNodeInfo(_RTreeNode node, int level) {
      sb.writeln('${'  ' * level}Bounds: ${node.bounds}');
      if (node.isLeaf) {
        for (var n in node.nodes) {
          sb.writeln('${'  ' * (level + 1)}Leaf node: ${n.id}');
        }
      } else {
        sb.writeln('${'  ' * level}Branch:');
        for (var child in node.children) {
          appendNodeInfo(child, level + 1);
        }
      }
    }

    appendNodeInfo(_root, 0);
    return sb.toString();
  }
}
