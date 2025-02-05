import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

/// A `SpatialHashGrid` is a utility class that provides a spatial hashing system.
/// It organizes and queries rectangular objects (`Rect`) within a 2D grid,
/// allowing for efficient spatial lookups.
///
/// The grid divides the 2D space into cells of fixed size (`cellSize`). Each
/// cell maintains references to objects (referred to as "nodes") that overlap
/// with that cell.
class SpatialHashGrid {
  /// The fixed size of each grid cell.
  final double cellSize;

  /// The main grid structure that maps grid cell indices to a set of nodes.
  /// Each node is represented as a tuple containing an identifier (`String`)
  /// and its bounding rectangle (`Rect`).
  final Map<Tuple2<int, int>, Set<Tuple2<String, Rect>>> grid = {};

  /// Maps each node's identifier (`String`) to the set of grid cells it occupies.
  final Map<String, Set<Tuple2<int, int>>> nodeToCells = {};

  /// Constructs a `SpatialHashGrid` using a predefined cell size defined in `constants.dart`.
  SpatialHashGrid() : cellSize = kSpatialHashingCellSize;

  /// Calculates the grid cell index (`Tuple2<int, int>`) for a given point in 2D space.
  Tuple2<int, int> _getGridIndex(Offset point) {
    return Tuple2(
      (point.dx / cellSize).floor(),
      (point.dy / cellSize).floor(),
    );
  }

  /// Determines all grid cells that a given rectangle (`Rect`) overlaps.
  ///
  /// Returns a set of cell indices (`Tuple2<int, int>`).
  Set<Tuple2<int, int>> _getCoveredCells(Rect rect) {
    final Tuple2<int, int> topLeft = _getGridIndex(rect.topLeft);
    final Tuple2<int, int> bottomRight = _getGridIndex(rect.bottomRight);

    final Set<Tuple2<int, int>> cells = {};

    for (int x = topLeft.item1; x <= bottomRight.item1; x++) {
      for (int y = topLeft.item2; y <= bottomRight.item2; y++) {
        cells.add(Tuple2(x, y));
      }
    }

    return cells;
  }

  /// Inserts a new node into the spatial hash grid.
  ///
  /// A node is represented by a tuple (`Tuple2<String, Rect>`), where:
  /// - `node.item1` is the unique identifier of the node.
  /// - `node.item2` is the bounding rectangle of the node.
  void insert(Tuple2<String, Rect> node) {
    final Set<Tuple2<int, int>> cells = _getCoveredCells(node.item2);

    for (final Tuple2<int, int> cell in cells) {
      if (!grid.containsKey(cell)) {
        grid[cell] = {};
      }

      grid[cell]!.add(node);
    }

    nodeToCells[node.item1] = cells;
  }

  /// Removes a node from the spatial hash grid by its identifier (`nodeId`).
  void remove(String nodeId) {
    if (nodeToCells.containsKey(nodeId)) {
      for (final Tuple2<int, int> cell in nodeToCells[nodeId]!) {
        if (grid.containsKey(cell)) {
          grid[cell]!.removeWhere((node) => node.item1 == nodeId);
        }
      }

      nodeToCells.remove(nodeId);
    }
  }

  /// Clears all data from the spatial hash grid.
  void clear() {
    grid.clear();
    nodeToCells.clear();
  }

  /// Queries the spatial hash grid for all node identifiers (`String`)
  /// whose rectangles overlap with a given bounding rectangle (`bounds`).
  ///
  /// Returns a set of node identifiers that are within or overlap the bounds.
  Set<String> queryNodeIdsInArea(Rect bounds) {
    final Set<String> nodeIds = {};

    final Set<Tuple2<int, int>> cells = _getCoveredCells(bounds);

    for (final Tuple2<int, int> cell in cells) {
      if (grid.containsKey(cell)) {
        for (final Tuple2<String, Rect> node in grid[cell]!) {
          if (bounds.overlaps(node.item2)) {
            nodeIds.add(node.item1);
          }
        }
      }
    }

    return nodeIds;
  }

  /// Computes the total number of node references stored in the grid.
  ///
  /// Useful for debugging or performance analysis.
  int get numRefs => grid.values.fold(0, (acc, nodes) => acc + nodes.length);
}
