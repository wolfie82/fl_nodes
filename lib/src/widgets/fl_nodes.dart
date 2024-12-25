import 'dart:async';

import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/core/models/styles.dart';
import 'package:fl_nodes/src/core/utils/platform.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';
import 'package:fl_nodes/src/widgets/node_editor.dart';

import '../core/controllers/node_editor_events.dart';
import '../core/utils/keys.dart';

class FlNodeEditor extends StatefulWidget {
  final FlNodeEditorController controller;
  final NodeEditorBehavior behavior;
  final NodeEditorStyle style;
  final bool expandToParent;
  final Size? fixedSize;
  final List<Widget> Function() overaly;

  const FlNodeEditor({
    super.key,
    required this.controller,
    this.behavior = const NodeEditorBehavior(),
    this.style = const NodeEditorStyle(
      gridPainterStyle: GridStyle(),
    ),
    this.expandToParent = true,
    this.fixedSize,
    required this.overaly,
  });

  @override
  State<FlNodeEditor> createState() => _FlNodeEditorWidgetState();
}

class _FlNodeEditorWidgetState extends State<FlNodeEditor>
    with TickerProviderStateMixin {
  // Core state
  Offset _offset = Offset.zero;
  double _zoom = 1.0;

  // Interaction state
  bool _isDragging = false;
  bool _isSelecting = false;

  // Interaction kinematics
  Offset _lastPositionDelta = Offset.zero;
  Offset _kineticEnergy = Offset.zero;
  Timer? _kineticTimer;
  Offset _selectionStart = Offset.zero;

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

    // Ensure that the editor is updated after the first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _offsetAnimationController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event is ViewportOffsetEvent) {
        _setOffset(event.offset, animate: event.animate);
      } else if (event is ViewportZoomEvent) {
        _setZoom(event.zoom, animate: event.animate);
      } else if (event is DragNodeEvent) {
        _onNodeDrag();
      } else {
        setState(() {});
      }
    });
  }

  void _onDragStart() {
    _isDragging = true;
    _offsetAnimationController.stop();
    _startKineticTimer();
  }

  void _onDragUpdate(Offset delta) {
    setState(() {
      _lastPositionDelta = delta;
      _resetKineticTimer();
      _setOffsetFromRawInput(delta);
    });
  }

  void _onDragEnd() {
    setState(() {
      _isDragging = false;
      _kineticEnergy = _lastPositionDelta;
      _kineticTimer?.cancel();
    });
  }

  void _onSelectStart(Offset position) {
    setState(() {
      _isSelecting = true;
      _selectionStart = position;
    });
  }

  void _onSelectUpdate(Offset position) {
    setState(() {
      final screenSpaceSelectionArea = Rect.fromPoints(
        _selectionStart,
        position,
      );

      final nodeEditorWidgetSize = getSizeFromGlobalKey(nodeEditorWidgetKey);

      if (nodeEditorWidgetSize == null) return;

      final worldSpaceSelectionArea = Rect.fromLTWH(
        screenToWorld(
          screenSpaceSelectionArea.topLeft,
          nodeEditorWidgetSize,
          _offset,
          _zoom,
        ).dx,
        screenToWorld(
          screenSpaceSelectionArea.topLeft,
          nodeEditorWidgetSize,
          _offset,
          _zoom,
        ).dy,
        screenSpaceSelectionArea.width / _zoom,
        screenSpaceSelectionArea.height / _zoom,
      );

      widget.controller.setSelectionArea(worldSpaceSelectionArea);
    });
  }

  void _onSelectEnd() {
    setState(() {
      _isSelecting = false;
      widget.controller.selectNodesByArea();
    });
  }

  void _onNodeDrag() {
    setState(() {
      if (_isDragging) {
        _onDragEnd();
      } else if (_isSelecting) {
        _onSelectEnd();
      }
    });
  }

  void _startKineticTimer() {
    const duration = Duration(milliseconds: 16); // ~60 FPS
    const decayFactor = 0.9; // Exponential decay factor (magic number)
    const minEnergyThreshold = 0.1; // Stop motion threshold (magic number)

    _kineticTimer?.cancel();

    _kineticTimer = Timer.periodic(duration, (timer) {
      if (_lastPositionDelta == Offset.zero) {
        timer.cancel();
        return;
      }

      final Offset adjustedKineticEnergy = _kineticEnergy / _zoom;

      _setOffset(_offset + adjustedKineticEnergy, animate: false);

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

    final Offset targetOffset = _offset + offsetFactor;

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
    if (_offset == targetOffset) return;

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

      final distance = (_offset - clampedOffset).distance;

      final durationFactor = (distance / 1000).clamp(0.5, 3.0);
      _offsetAnimationController.duration = Duration(
        milliseconds: (1000 * durationFactor).toInt(),
      );

      _offsetAnimation = Tween<Offset>(
        begin: _offset,
        end: clampedOffset,
      ).animate(
        CurvedAnimation(
          parent: _offsetAnimationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          setState(() {
            _offset = _offsetAnimation.value;
            widget.controller.offset = _offset;
          });
        });

      _offsetAnimationController.forward();
    } else {
      setState(() {
        _offset = clampedOffset;
        widget.controller.offset = _offset;
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
            widget.controller.zoom = _zoom;
          });
        });

      _zoomAnimationController.forward();
    } else {
      setState(() {
        _zoom = clampedZoom;
        widget.controller.zoom = _zoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget controlsWrapper(Widget child) {
      return isMobile()
          ? GestureDetector(
              onDoubleTap: () => widget.controller.selectNodesById([]),
              onScaleStart: (details) => _onDragStart(),
              onScaleUpdate: (details) {
                if (widget.behavior.zoomSensitivity > 0 &&
                    details.scale.abs() > 0.01) {
                  _setZoomFromRawInput(details.scale);
                }

                if (widget.behavior.panSensitivity > 0 &&
                    details.focalPointDelta > const Offset(10, 10)) {
                  _setOffsetFromRawInput(details.focalPointDelta);
                }
              },
              onScaleEnd: (details) => _onDragEnd(),
              child: child,
            )
          : MouseRegion(
              cursor: _isDragging
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.basic,
              child: ImprovedListener(
                onDoubleClick: () => widget.controller.selectNodesById([]),
                onPointerPressed: (event) {
                  if (event.buttons == kMiddleMouseButton) {
                    _onDragStart();
                  } else if (event.buttons == kPrimaryMouseButton) {
                    _onSelectStart(event.localPosition);
                  }
                },
                onPointerMoved: (event) {
                  if (_isDragging && widget.behavior.panSensitivity > 0) {
                    _onDragUpdate(event.delta);
                  } else if (_isSelecting) {
                    _onSelectUpdate(event.localPosition);
                  }
                },
                onPointerReleased: (event) {
                  if (_isDragging) {
                    _onDragEnd();
                  } else if (_isSelecting) {
                    _onSelectEnd();
                  }
                },
                onPointerSignalReceived: (event) {
                  if (widget.behavior.zoomSensitivity > 0 &&
                      event is PointerScrollEvent) {
                    _setZoomFromRawInput(event.scrollDelta.dy);
                  }
                },
                child: child,
              ),
            );
    }

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
      child: controlsWrapper(
        Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              child: RepaintBoundary(
                child: NodeEditorWidget(
                  key: nodeEditorWidgetKey,
                  controller: widget.controller,
                  style: widget.style.gridPainterStyle,
                ),
              ),
            ),
            ...widget.overaly().map(
                  (overlay) => RepaintBoundary(child: overlay),
                ),
            if (kDebugMode)
              DebugInfoWidget(
                offset: widget.controller.offset,
                zoom: widget.controller.zoom,
              ),
          ],
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

class DebugInfoWidget extends StatelessWidget {
  final Offset offset;
  final double zoom;

  const DebugInfoWidget({super.key, required this.offset, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${offset.dx.toStringAsFixed(2)}, Y: ${offset.dy.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
          Text(
            'Zoom: ${zoom.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
