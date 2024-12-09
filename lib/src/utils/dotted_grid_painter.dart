import 'package:flutter/material.dart';

class DottedGridPainter extends CustomPainter {
  final double dotSpacing;
  final double dotRadius;
  final Color dotColor;
  final Offset offset;
  final double scale;

  DottedGridPainter({
    this.dotSpacing = 20.0,
    this.dotRadius = 1.5,
    this.dotColor = Colors.grey,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final dotSpacing = this.dotSpacing * scale;
    final dotRadius = this.dotRadius * scale;

    final visibleRect = Rect.fromLTWH(
      -offset.dx,
      -offset.dy,
      size.width,
      size.height,
    );

    final startX = (visibleRect.left / dotSpacing).floor() * dotSpacing;
    final startY = (visibleRect.top / dotSpacing).floor() * dotSpacing;

    for (double x = startX; x <= visibleRect.right; x += dotSpacing) {
      for (double y = startY; y <= visibleRect.bottom; y += dotSpacing) {
        canvas.drawCircle(
          Offset(x + offset.dx, y + offset.dy),
          dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedGridPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.dotSpacing != dotSpacing ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotColor != dotColor;
  }
}
