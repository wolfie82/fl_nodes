import 'dart:math';

import 'package:flutter/material.dart';

import 'package:benchmark_harness/benchmark_harness.dart';

// Dummy constant if not already defined in constants.dart.
const double kSpatialHashingCellSize = 50.0;

// Assuming SpatialHashGrid is defined as in your snippet.
class SpatialHashGrid {
  final double cellSize;
  final Map<({int x, int y}), Set<({String id, Rect rect})>> grid = {};
  final Map<String, Set<({int x, int y})>> nodeToCells = {};

  SpatialHashGrid() : cellSize = kSpatialHashingCellSize;

  ({int x, int y}) _getGridIndex(Offset point) {
    return (
      x: (point.dx / cellSize).floor(),
      y: (point.dy / cellSize).floor(),
    );
  }

  Set<({int x, int y})> _getCoveredCells(Rect rect) {
    final ({int x, int y}) topLeft = _getGridIndex(rect.topLeft);
    final ({int x, int y}) bottomRight = _getGridIndex(rect.bottomRight);

    final Set<({int x, int y})> cells = {};

    for (int x = topLeft.x; x <= bottomRight.x; x++) {
      for (int y = topLeft.y; y <= bottomRight.y; y++) {
        cells.add((x: x, y: y));
      }
    }
    return cells;
  }

  void insert(({String id, Rect rect}) node) {
    final Set<({int x, int y})> cells = _getCoveredCells(node.rect);
    for (final ({int x, int y}) cell in cells) {
      grid.putIfAbsent(cell, () => {});
      grid[cell]!.add(node);
    }
    nodeToCells[node.id] = cells;
  }

  void remove(String nodeId) {
    if (nodeToCells.containsKey(nodeId)) {
      for (final ({int x, int y}) cell in nodeToCells[nodeId]!) {
        grid[cell]?.removeWhere((node) => node.id == nodeId);
      }
      nodeToCells.remove(nodeId);
    }
  }

  void update(({String id, Rect rect}) node) {
    if (!nodeToCells.containsKey(node.id)) {
      insert(node);
      return;
    }
    final currentRect =
        grid[nodeToCells[node.id]!.first]!.firstWhere((n) => n.id == node.id);
    // Check if the node's rect has actually changed.
    if (currentRect.rect.topLeft == node.rect.topLeft &&
        currentRect.rect.bottomLeft == node.rect.bottomLeft) {
      return;
    }
    remove(node.id);
    insert(node);
  }

  void clear() {
    grid.clear();
    nodeToCells.clear();
  }

  Set<String> queryNodeIdsInArea(Rect bounds) {
    final Set<String> nodeIds = {};
    final Set<({int x, int y})> cells = _getCoveredCells(bounds);
    for (final ({int x, int y}) cell in cells) {
      if (grid.containsKey(cell)) {
        for (final ({String id, Rect rect}) node in grid[cell]!) {
          if (bounds.overlaps(node.rect)) {
            nodeIds.add(node.id);
          }
        }
      }
    }
    return nodeIds;
  }

  int get numRefs => grid.values.fold(0, (acc, nodes) => acc + nodes.length);
}

/// Generates a large list of nodes with random positions and sizes.
List<({String id, Rect rect})> generateNodes(int count, {int seed = 1234}) {
  final random = Random(seed);
  final List<({String id, Rect rect})> nodes = [];
  for (int i = 0; i < count; i++) {
    final double x = random.nextDouble() * 1000;
    final double y = random.nextDouble() * 1000;
    final double width = random.nextDouble() * 50 + 10;
    final double height = random.nextDouble() * 50 + 10;
    nodes.add((id: 'node_$i', rect: Rect.fromLTWH(x, y, width, height)));
  }
  return nodes;
}

/// Benchmark for inserting nodes.
class InsertBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  InsertBenchmark(this.count) : super("InsertBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
  }

  @override
  void run() {
    for (var node in nodes) {
      grid.insert(node);
    }
  }
}

/// Benchmark for removing nodes.
class RemoveBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  RemoveBenchmark(this.count) : super("RemoveBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    for (var node in nodes) {
      grid.remove(node.id);
    }
  }
}

/// Benchmark for updating nodes by direct removal and reinsertion.
class DirectUpdateBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  DirectUpdateBenchmark(this.count) : super("DirectUpdateBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    final random = Random(1234);
    for (int i = 0; i < nodes.length; i++) {
      final bool shouldInflate = random.nextBool();
      final node = nodes[i];
      Rect newRect;
      if (shouldInflate) {
        // Inflate by a factor between 1.0 and 1.5.
        final double factor = 1.0 + random.nextDouble() * 0.5;
        newRect = node.rect.inflate(factor);
      } else {
        newRect = node.rect;
      }
      // Directly remove and reinsert.
      grid.remove(node.id);
      final updatedNode = (id: node.id, rect: newRect);
      grid.insert(updatedNode);
      nodes[i] = updatedNode;
    }
  }
}

/// Benchmark for updating nodes using the grid's update method.
class UpdateMethodBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  UpdateMethodBenchmark(this.count) : super("UpdateMethodBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    final random = Random(1234);
    for (int i = 0; i < nodes.length; i++) {
      final bool shouldInflate = random.nextBool();
      final node = nodes[i];
      Rect newRect;
      if (shouldInflate) {
        final double factor = 1.0 + random.nextDouble() * 0.5;
        newRect = node.rect.inflate(factor);
      } else {
        newRect = node.rect;
      }
      final updatedNode = (id: node.id, rect: newRect);
      grid.update(updatedNode);
      nodes[i] = updatedNode;
    }
  }
}

void main() {
  const int nodeCount = 10000;

  // Report each benchmark.
  InsertBenchmark(nodeCount).report();
  RemoveBenchmark(nodeCount).report();
  DirectUpdateBenchmark(nodeCount).report();
  UpdateMethodBenchmark(nodeCount).report();
}
