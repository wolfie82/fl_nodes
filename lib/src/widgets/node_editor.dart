import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/core/utils/platform.dart';
import 'package:fl_nodes/src/utils/grid_painter.dart';

import 'grid.dart';

class NodeEditorBehavior {
  final double zoomSensitivity;
  final double minZoom;
  final double maxZoom;
  final double panSensitivity;
  final double maxPanX;
  final double maxPanY;
  final bool enableKineticScrolling;

  const NodeEditorBehavior({
    this.zoomSensitivity = 0.1,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
    this.panSensitivity = 1.0,
    this.maxPanX = 10000.0,
    this.maxPanY = 10000.0,
    this.enableKineticScrolling = true,
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
  final NodeEditorController controller;
  final NodeEditorBehavior behavior;
  final NodeEditorStyle style;
  final bool expandToParent;
  final Size? fixedSize;
  final List<Widget> Function(Offset, double) content;

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
    with TickerProviderStateMixin {
  // Core state
  Offset _gridOffset = Offset.zero;
  double _zoom = 1.0;

  // Interaction state
  bool _isDragging = true;

  // Interaction kinematics
  Offset _lastFocalDelta = Offset.zero;
  Offset _kineticEnergy = Offset.zero;
  Timer? _kineticTimer;

  // Animation controllers and animations
  late AnimationController _offsetAnimationController;
  late AnimationController _zoomAnimationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _handleControllerEvents();
    _offsetAnimationController = AnimationController(vsync: this);
    _zoomAnimationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _offsetAnimationController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event is OffsetEvent) {
        _setOffset(event.offset, animate: event.animate);
      } else if (event is ZoomEvent) {
        _setZoom(event.zoom, animate: event.animate);
      }
    });
  }

  void _onDragStart() {
    _offsetAnimationController.stop();
    _startKineticTimer();
  }

  void _onDragUpdate(Offset delta) {
    _lastFocalDelta = delta;
    _resetKineticTimer();
    _setOffsetFromRawInput(delta);
  }

  void _onDragEnd() => _kineticEnergy = _lastFocalDelta;

  void _startKineticTimer() {
    const duration = Duration(milliseconds: 16); // ~60 FPS
    const decayFactor = 0.9; // Exponential decay factor (magic number)
    const minEnergyThreshold = 0.1; // Stop motion threshold (magic number)

    _kineticTimer?.cancel();

    _kineticTimer = Timer.periodic(duration, (timer) {
      if (_lastFocalDelta == Offset.zero) {
        timer.cancel();
        return;
      }

      final Offset adjustedKineticEnergy = _kineticEnergy / _zoom;

      _setOffset(_gridOffset + adjustedKineticEnergy, animate: false);

      _kineticEnergy *= decayFactor;

      if (_kineticEnergy.distance < minEnergyThreshold) {
        timer.cancel();
        _kineticEnergy = Offset.zero;
      }
    });
  }

  void _resetKineticTimer() {
    _kineticTimer?.cancel();
    _startKineticTimer();
  }

  void _setOffsetFromRawInput(Offset delta) {
    final Offset offsetFactor = delta * widget.behavior.panSensitivity / _zoom;

    final Offset targetOffset = _gridOffset + offsetFactor;

    _setOffset(targetOffset, animate: false);
  }

  void _setZoomFromRawInput(double amount) {
    const double baseSpeed =
        0.05; // Base zoom speed and damping factor (magic number)
    const double scaleFactor =
        1.5; // Controls how zoom speed scales with zoom level (magic number)

    final double sensitivity = widget.behavior.zoomSensitivity;

    final double dynamicZoomFactor =
        baseSpeed * (1 + scaleFactor * _zoom) * sensitivity;

    final double zoomFactor =
        (amount * dynamicZoomFactor).abs().clamp(0.1, 10.0);

    final double targetZoom =
        (amount < 0 ? _zoom * (1 + zoomFactor) : _zoom / (1 + zoomFactor));

    _setZoom(targetZoom, animate: true);
  }

  void _setOffset(Offset targetOffset, {bool animate = true}) {
    if (_gridOffset == targetOffset) return;

    final Offset clampedOffset = Offset(
      targetOffset.dx.clamp(
        -widget.behavior.maxPanX,
        widget.behavior.maxPanX,
      ),
      targetOffset.dy.clamp(
        -widget.behavior.maxPanY,
        widget.behavior.maxPanY,
      ),
    );

    if (animate) {
      _offsetAnimationController.reset();

      final distance = (_gridOffset - clampedOffset).distance;

      final durationFactor = (distance / 1000).clamp(0.5, 3.0);
      _offsetAnimationController.duration = Duration(
        milliseconds: (1000 * durationFactor).toInt(),
      );

      _offsetAnimation = Tween<Offset>(
        begin: _gridOffset,
        end: clampedOffset,
      ).animate(
        CurvedAnimation(
          parent: _offsetAnimationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          setState(() {
            _gridOffset = _offsetAnimation.value;
          });
        });

      _offsetAnimationController.forward();
    } else {
      setState(() {
        _gridOffset = clampedOffset;
      });
    }
  }

  void _setZoom(double targetZoom, {bool animate = true}) {
    final initialScale = _zoom;

    final clampedZoom = targetZoom.clamp(
      widget.behavior.minZoom,
      widget.behavior.maxZoom,
    );

    if (animate) {
      _zoomAnimationController.reset();
      _zoomAnimationController.duration = const Duration(milliseconds: 200);

      _zoomAnimation = Tween<double>(
        begin: initialScale,
        end: clampedZoom,
      ).animate(
        CurvedAnimation(
          parent: _zoomAnimationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          setState(() {
            _zoom = _zoomAnimation.value;
          });
        });

      _zoomAnimationController.forward();
    } else {
      setState(() {
        _zoom = clampedZoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget editorContent = Stack(
      children: [
        GridWidget(
          offset: _gridOffset,
          scale: _zoom,
          style: widget.style.gridPainterStyle,
        ),
        ...widget.content(_gridOffset, _zoom),
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
                onDoubleTap: () => _setOffset(Offset.zero, animate: false),
                onScaleStart: (details) => _onDragStart(),
                onScaleUpdate: (details) {
                  setState(() {
                    _isDragging = true;
                  });

                  if (widget.behavior.zoomSensitivity > 0) {
                    _setZoomFromRawInput(details.scale);
                  }

                  if (widget.behavior.panSensitivity > 0) {
                    _setOffsetFromRawInput(details.focalPointDelta);
                  }
                },
                onScaleEnd: (details) => _onDragEnd(),
                child: editorContent,
              )
            : Listener(
                onPointerDown: (event) => setState(() {
                  _isDragging = true;
                  _onDragStart();
                }),
                onPointerMove: (event) {
                  if (widget.behavior.panSensitivity > 0 && _isDragging) {
                    _setOffsetFromRawInput(event.delta);
                    _onDragUpdate(event.delta);
                  }
                },
                onPointerSignal: (event) {
                  if (widget.behavior.zoomSensitivity > 0 &&
                      event is PointerScrollEvent) {
                    _setZoomFromRawInput(event.scrollDelta.dy);
                  }
                },
                onPointerUp: (event) => setState(() {
                  _isDragging = false;
                  _onDragEnd();
                }),
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
