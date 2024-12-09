import 'package:flutter/material.dart';
import '../utils/dotted_grid_painter.dart';

class DottedGridWidget extends StatelessWidget {
  final double dotSpacing;
  final double dotRadius;
  final Color dotColor;
  final Offset offset;
  final double scale;

  const DottedGridWidget({
    super.key,
    this.dotSpacing = 20.0,
    this.dotRadius = 1.5,
    this.dotColor = Colors.grey,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedGridPainter(
        dotSpacing: dotSpacing,
        dotRadius: dotRadius,
        dotColor: dotColor,
        offset: offset,
        scale: scale,
      ),
      child: const SizedBox.expand(),
    );
  }
}
