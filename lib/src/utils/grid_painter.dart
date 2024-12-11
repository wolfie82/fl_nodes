import 'package:flutter/material.dart';

enum LineType {
  solid,
  none,
}

enum IntersectionType {
  rectangle,
  circle,
  none,
}

class GridPainterStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final LineType lineType;
  final double lineWidth;
  final Color lineColor;
  final IntersectionType intersectionType;
  final Color intersectionColor;
  final double? intersectionRadius;
  final Size? intersectionSize;

  const GridPainterStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineType = LineType.solid,
    this.lineWidth = 1.0,
    this.lineColor = Colors.white10,
    this.intersectionType = IntersectionType.circle,
    this.intersectionColor = Colors.white54,
    this.intersectionRadius = 1,
    this.intersectionSize = const Size(8.0, 8.0),
  });
}

class GridPainter extends CustomPainter {
  final GridPainterStyle style;
  final Offset offset;
  final double scale;

  GridPainter({
    required this.style,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        style.lineType == LineType.none &&
            style.intersectionType == IntersectionType.none) {
      return;
    }
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    // We're faking the viewport size to account for the scaling operation on the canvas.
    final viewport = Rect.fromLTWH(
      -size.width / scale / 2 - offset.dx,
      -size.height / scale / 2 - offset.dy,
      size.width / scale,
      size.height / scale,
    );

    final startX =
        (viewport.left / style.gridSpacingX).floor() * style.gridSpacingX;
    final startY =
        (viewport.top / style.gridSpacingY).floor() * style.gridSpacingY;

    if (style.lineType != LineType.none) {
      final linePaint = Paint()
        ..color = style.lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.lineWidth;

      switch (style.lineType) {
        case LineType.solid:
          for (double x = startX;
              x <= viewport.right;
              x += style.gridSpacingX) {
            canvas.drawLine(
              Offset(x + offset.dx, viewport.top + offset.dy),
              Offset(x + offset.dx, viewport.bottom + offset.dy),
              linePaint,
            );
          }

          for (double y = startY;
              y <= viewport.bottom;
              y += style.gridSpacingY) {
            canvas.drawLine(
              Offset(viewport.left + offset.dx, y + offset.dy),
              Offset(viewport.right + offset.dx, y + offset.dy),
              linePaint,
            );
          }

          break;
        default:
          throw Exception('Invalid line type');
      }
    }

    if (style.intersectionType != IntersectionType.none) {
      final intersectionPaint = Paint()
        ..color = style.intersectionColor
        ..style = PaintingStyle.fill;

      switch (style.intersectionType) {
        case IntersectionType.rectangle:
          final intersectionSize = style.intersectionSize!;

          for (double x = startX;
              x <= viewport.right;
              x += style.gridSpacingX) {
            for (double y = startY;
                y <= viewport.bottom;
                y += style.gridSpacingY) {
              canvas.drawRect(
                Rect.fromLTWH(
                  x + offset.dx - intersectionSize.width / 2,
                  y + offset.dy - intersectionSize.height / 2,
                  intersectionSize.width,
                  intersectionSize.height,
                ),
                intersectionPaint,
              );
            }
          }

          break;
        case IntersectionType.circle:
          final intersectionRadius = style.intersectionRadius!;

          for (double x = startX;
              x <= viewport.right;
              x += style.gridSpacingX) {
            for (double y = startY;
                y <= viewport.bottom;
                y += style.gridSpacingY) {
              canvas.drawCircle(
                Offset(x + offset.dx, y + offset.dy),
                intersectionRadius,
                intersectionPaint,
              );
            }
          }

          break;
        default:
          throw Exception('Invalid intersection type');
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.style != style;
  }
}
