import 'dart:math';

import 'package:flutter/material.dart';

num maxIn(List<num> numbers) {
  return numbers.reduce((a, b) => max(a, b));
}

List<Rect> kMeansClustering(List<Offset> points, int k) {
  final random = Random();
  final groups = List.generate(k, (index) => <Offset>[]);
  final centers =
      List.generate(k, (index) => points[random.nextInt(points.length)]);

  for (int i = 0; i < 100; i++) {
    for (final point in points) {
      final distances =
          centers.map((center) => (point - center).distance).toList();
      final minDistance = distances.reduce((a, b) => min(a, b));
      final minIndex = distances.indexOf(minDistance);
      groups[minIndex].add(point);
    }

    for (int j = 0; j < k; j++) {
      if (groups[j].isEmpty) {
        centers[j] = points[random.nextInt(points.length)];
      } else {
        centers[j] = Offset(
          groups[j].map((point) => point.dx).reduce((a, b) => a + b) /
              groups[j].length,
          groups[j].map((point) => point.dy).reduce((a, b) => a + b) /
              groups[j].length,
        );
      }
    }
  }

  return groups.map((group) {
    final xs = group.map((point) => point.dx).toList();
    final ys = group.map((point) => point.dy).toList();
    final left = xs.reduce((a, b) => min(a, b));
    final top = ys.reduce((a, b) => min(a, b));
    final right = xs.reduce((a, b) => max(a, b));
    final bottom = ys.reduce((a, b) => max(a, b));
    return Rect.fromLTRB(left, top, right, bottom);
  }).toList();
}
