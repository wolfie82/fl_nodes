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
    if (_shouldSkipPainting(size)) return;

    _prepareCanvas(canvas, size);

    final viewport = _calculateViewport(canvas, size);
    final startX = _calculateStart(viewport.left, style.gridSpacingX);
    final startY = _calculateStart(viewport.top, style.gridSpacingY);

    if (style.lineType != LineType.none) {
      _drawGridLines(canvas, viewport, startX, startY);
    }

    if (style.intersectionType != IntersectionType.none) {
      _drawIntersections(canvas, viewport, startX, startY);
    }
  }

  bool _shouldSkipPainting(Size size) {
    return size.isEmpty ||
        (style.lineType == LineType.none &&
            style.intersectionType == IntersectionType.none);
  }

  void _prepareCanvas(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(offset.dx, offset.dy);
  }

  Rect _calculateViewport(Canvas canvas, Size size) {
    final viewport = Rect.fromLTWH(
      -size.width / scale / 2 - offset.dx,
      -size.height / scale / 2 - offset.dy,
      size.width / scale,
      size.height / scale,
    );

    canvas.clipRect(viewport);

    return viewport;
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

  void _drawGridLines(
      Canvas canvas, Rect viewport, double startX, double startY) {
    final linePaint = Paint()
      ..color = style.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth;

    if (style.lineType == LineType.solid) {
      _drawVerticalLines(canvas, viewport, startX, linePaint);
      _drawHorizontalLines(canvas, viewport, startY, linePaint);
    } else {
      throw Exception('Invalid line type');
    }
  }

  void _drawVerticalLines(
      Canvas canvas, Rect viewport, double startX, Paint linePaint) {
    for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
      canvas.drawLine(
        Offset(x, viewport.top),
        Offset(x, viewport.bottom),
        linePaint,
      );
    }
  }

  void _drawHorizontalLines(
      Canvas canvas, Rect viewport, double startY, Paint linePaint) {
    for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
      canvas.drawLine(
        Offset(viewport.left, y),
        Offset(viewport.right, y),
        linePaint,
      );
    }
  }

  void _drawIntersections(
      Canvas canvas, Rect viewport, double startX, double startY) {
    final intersectionPaint = Paint()
      ..color = style.intersectionColor
      ..style = PaintingStyle.fill;

    switch (style.intersectionType) {
      case IntersectionType.rectangle:
        _drawRectangles(canvas, viewport, startX, startY, intersectionPaint);
        break;
      case IntersectionType.circle:
        _drawCircles(canvas, viewport, startX, startY, intersectionPaint);
        break;
      default:
        throw Exception('Invalid intersection type');
    }
  }

  void _drawRectangles(
      Canvas canvas, Rect viewport, double startX, double startY, Paint paint) {
    final intersectionSize = style.intersectionSize!;

    for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
      for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
        canvas.drawRect(
          Rect.fromLTWH(
            x - intersectionSize.width / 2,
            y - intersectionSize.height / 2,
            intersectionSize.width,
            intersectionSize.height,
          ),
          paint,
        );
      }
    }
  }

  void _drawCircles(
      Canvas canvas, Rect viewport, double startX, double startY, Paint paint) {
    final intersectionRadius = style.intersectionRadius!;

    for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
      for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
        canvas.drawCircle(
          Offset(x, y),
          intersectionRadius,
          paint,
        );
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
