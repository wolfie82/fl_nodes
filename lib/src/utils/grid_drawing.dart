import 'package:flutter/material.dart';

import '../core/models/styles.dart';

void drawGrid(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  if (style.lineType != LineType.none) {
    _drawGridLines(style, canvas, viewport, startX, startY);
  }

  if (style.intersectionType != IntersectionType.none) {
    _drawIntersections(style, canvas, viewport, startX, startY);
  }
}

void _drawGridLines(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  final linePaint = Paint()
    ..color = style.lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = style.lineWidth;

  if (style.lineType == LineType.solid) {
    _drawVerticalLines(style, canvas, viewport, startX, linePaint);
    _drawHorizontalLines(style, canvas, viewport, startY, linePaint);
  } else {
    throw Exception('Invalid line type');
  }
}

void _drawVerticalLines(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  Paint linePaint,
) {
  for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
    canvas.drawLine(
      Offset(x, viewport.top),
      Offset(x, viewport.bottom),
      linePaint,
    );
  }
}

void _drawHorizontalLines(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startY,
  Paint linePaint,
) {
  for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
    canvas.drawLine(
      Offset(viewport.left, y),
      Offset(viewport.right, y),
      linePaint,
    );
  }
}

void _drawIntersections(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  final intersectionPaint = Paint()
    ..color = style.intersectionColor
    ..style = PaintingStyle.fill;

  switch (style.intersectionType) {
    case IntersectionType.rectangle:
      _drawRectangles(
        style,
        canvas,
        viewport,
        startX,
        startY,
        intersectionPaint,
      );
      break;
    case IntersectionType.circle:
      _drawCircles(
        style,
        canvas,
        viewport,
        startX,
        startY,
        intersectionPaint,
      );
      break;
    default:
      throw Exception('Invalid intersection type');
  }
}

void _drawRectangles(
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
  Paint paint,
) {
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
  GridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
  Paint paint,
) {
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
