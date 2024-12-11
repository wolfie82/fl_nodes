import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/core/utils/platform.dart';
import 'package:fl_nodes/src/utils/grid_painter.dart';

import 'grid.dart';

class NodeEditorBehavior {
  final double zoomSensitivity;
  final double panSensitivity;
  final double minZoom;
  final double maxZoom;

  const NodeEditorBehavior({
    this.zoomSensitivity = 0.1,
    this.panSensitivity = 1.0,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
  });
}

class NodeEditorStyle {
  final Color backgroundColor;
  final DecorationImage? backgroundImage;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double contentPadding;
  final GridPainterStyle gridPainterStyle;

  const NodeEditorStyle({
    this.backgroundColor = Colors.transparent,
    this.backgroundImage,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.borderRadius = BorderRadius.zero,
    this.contentPadding = 8.0,
    required this.gridPainterStyle,
  });
}

class NodeEditorWidget extends StatefulWidget {
  final NodeEditorController? controller;
  final NodeEditorBehavior behavior;
  final NodeEditorStyle style;
  final bool expandToParent;
  final Size? fixedSize;
  final List<Widget> content;

  const NodeEditorWidget({
    super.key,
    required this.controller,
    this.behavior = const NodeEditorBehavior(),
    this.style = const NodeEditorStyle(
      gridPainterStyle: GridPainterStyle(),
    ),
    this.expandToParent = true,
    this.fixedSize,
    required this.content,
  });

  @override
  State<NodeEditorWidget> createState() => _NodeEditorWidgetState();
}

class _NodeEditorWidgetState extends State<NodeEditorWidget>
    with SingleTickerProviderStateMixin {
  Offset _gridOffset = Offset.zero;
  double _zoom = 1.0;
  bool _isDragging = true;
  late AnimationController _animationController;
  late Animation<Offset> _centerGridAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _panView(Offset delta) {
    final Offset panFactors = delta * widget.behavior.panSensitivity / _zoom;

    setState(() {
      _gridOffset += panFactors / _zoom;

      const maxOffset = 10000.0;

      _gridOffset = Offset(
        _gridOffset.dx.clamp(-maxOffset, maxOffset),
        _gridOffset.dy.clamp(-maxOffset, maxOffset),
      );
    });
  }

  void _centerView({bool animate = true}) {
    if (animate) {
      _animationController.reset();

      final distance = (_gridOffset - Offset.zero).distance;

      final durationFactor = (distance / 1000).clamp(0.5, 3.0);
      _animationController.duration = Duration(
        milliseconds: (1000 * durationFactor).toInt(),
      );

      _centerGridAnimation = Tween<Offset>(
        begin: _gridOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          setState(() {
            _gridOffset = _centerGridAnimation.value;
          });
        });

      _animationController.forward();
    } else {
      setState(() {
        _gridOffset = Offset.zero;
      });
    }
  }

  void _zoomView(double amount, {bool animate = true}) {
    // The 0.1 factor is a magic number that works well for most cases for the values emitted by the PointerScrollEvent. Same applies to the clamp values.
    final double zoomFactor =
        (amount * 0.1 * widget.behavior.zoomSensitivity / _zoom)
            .abs()
            .clamp(0.1, 10.0);

    final initialScale = _zoom;
    // Negative amount means zoom in, positive means zoom out. Counter-intuitive, but that's how it is addressed in the PointerScrollEvent.
    final targetScale =
        (amount < 0 ? _zoom * (1 + zoomFactor) : _zoom / (1 + zoomFactor))
            .clamp(widget.behavior.minZoom, widget.behavior.maxZoom);

    if (animate) {
      _animationController.reset();
      _animationController.duration = const Duration(milliseconds: 200);

      _zoomAnimation = Tween<double>(
        begin: initialScale,
        end: targetScale,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          setState(() {
            _zoom = _zoomAnimation.value;
          });
        });

      _animationController.forward();
    } else {
      setState(() {
        _zoom = targetScale;
      });
    }

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Widget editorContent = ClipRect(
      child: Stack(
        children: [
          GridWidget(
            offset: _gridOffset,
            scale: _zoom,
            style: widget.style.gridPainterStyle,
          ),
          ...widget.content,
          if (kDebugMode)
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'X: ${_gridOffset.dx.toStringAsFixed(2)}, Y: ${_gridOffset.dy.toStringAsFixed(2)}',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Zoom: ${_zoom.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final Widget editor = Container(
      decoration: BoxDecoration(
        image: widget.style.backgroundImage,
        color: widget.style.backgroundColor,
        border: Border.all(
          color: widget.style.borderColor,
          width: widget.style.borderWidth,
        ),
        borderRadius: widget.style.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isMobile()
            ? GestureDetector(
                onDoubleTap: () => _centerView(animate: false),
                onScaleUpdate: (details) {
                  setState(() {
                    if (widget.behavior.zoomSensitivity > 0) {
                      _zoomView(
                        details.scale,
                        animate: false,
                      );
                    }

                    if (widget.behavior.panSensitivity > 0) {
                      _panView(details.focalPointDelta);
                    }
                  });
                },
                child: editorContent,
              )
            : Listener(
                onPointerDown: (event) => setState(() {
                  _isDragging = true;
                }),
                onPointerUp: (event) => setState(() {
                  _isDragging = false;
                }),
                onPointerMove: widget.behavior.panSensitivity > 0
                    ? (event) => {
                          if (_isDragging) _panView(event.delta),
                        }
                    : null,
                onPointerSignal: widget.behavior.zoomSensitivity > 0
                    ? (event) {
                        if (event is PointerScrollEvent) {
                          _zoomView(event.scrollDelta.dy);
                        }
                      }
                    : null,
                child: editorContent,
              ),
      ),
    );

    if (widget.expandToParent) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: editor,
          );
        },
      );
    } else {
      return SizedBox(
        width: widget.fixedSize?.width ?? 100,
        height: widget.fixedSize?.height ?? 100,
        child: editor,
      );
    }
  }
}
