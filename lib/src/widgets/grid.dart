import 'package:flutter/material.dart';

import '../utils/grid_painter.dart';

class GridWidget extends StatelessWidget {
  final GridPainterStyle style;
  final Offset offset;
  final double scale;

  const GridWidget({
    super.key,
    required this.style,
    required this.offset,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        style: style,
        offset: offset,
        scale: scale,
      ),
      child: const SizedBox.expand(),
    );
  }
}
