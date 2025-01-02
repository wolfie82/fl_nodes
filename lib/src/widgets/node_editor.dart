import 'dart:async';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';

import 'package:fl_nodes/src/core/utils/platform.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';
import 'package:fl_nodes/src/widgets/node_editor_render.dart';
import 'package:tuple/tuple.dart';

import '../core/controllers/node_editor_events.dart';
import '../core/utils/constants.dart';

class FlOverlayData {
  final Widget child;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  FlOverlayData({
    required this.child,
    this.top,
    this.left,
    this.bottom,
    this.right,
  });
}

class FlNodeEditor extends StatefulWidget {
  final FlNodeEditorController controller;
  final NodeEditorStyle style;
  final bool expandToParent;
  final Size? fixedSize;
  final List<FlOverlayData> Function() overaly;

  const FlNodeEditor({
    super.key,
    required this.controller,
    this.style = const NodeEditorStyle(
      gridStyle: GridStyle(),
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
  bool _isLinking = false;

  // Interaction kinematics
  Offset _lastPositionDelta = Offset.zero;
  Offset _kineticEnergy = Offset.zero;
  Timer? _kineticTimer;
  Offset _selectionStart = Offset.zero;
  Tuple2<String, String>? _tempLink;

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
      if (event.isHandled || !mounted) return;

      if (event is ViewportOffsetEvent) {
        _setOffset(event.offset, animate: event.animate);
      } else if (event is ViewportZoomEvent) {
        _setZoom(event.zoom, animate: event.animate);
      } else if (event is DragSelectionEvent) {
        setState(() {
          _suppressEvents();
        });
      } else if (event is AddNodeEvent ||
          event is RemoveNodeEvent ||
          event is AddLinkEvent ||
          event is RemoveLinkEvent ||
          event is LinkDrawEvent) {
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

  void _onDragCancel() => _onDragEnd();

  void _onDragEnd() {
    setState(() {
      _isDragging = false;
      _kineticEnergy = _lastPositionDelta;
    });
  }

  void _onSelectStart(Offset position) {
    setState(() {
      _isSelecting = true;
      _selectionStart = screenToWorld(
        position,
        getSizeFromGlobalKey(kNodeEditorWidgetKey)!,
        _offset,
        _zoom,
      );
    });
  }

  void _onSelectUpdate(Offset position) {
    setState(() {
      widget.controller.setSelectionArea(
        Rect.fromPoints(
          _selectionStart,
          screenToWorld(
            position,
            getSizeFromGlobalKey(kNodeEditorWidgetKey)!,
            _offset,
            _zoom,
          ),
        ),
      );
    });
  }

  void _onSelectCancel() {
    setState(() {
      _isSelecting = false;
      _selectionStart = Offset.zero;
      widget.controller.setSelectionArea(Rect.zero);
    });
  }

  void _onSelectEnd() {
    setState(() {
      if (widget.controller.selectionArea.size > const Size(10, 10)) {
        widget.controller.selectNodesByArea(
          holdSelection: HardwareKeyboard.instance.isControlPressed,
        );
      } else {
        widget.controller.setSelectionArea(Rect.zero);
      }

      _isSelecting = false;
      _selectionStart = Offset.zero;
    });
  }

  void _suppressEvents() {
    if (_isDragging) {
      _onDragCancel();
    } else if (_isSelecting) {
      _onSelectCancel();
    }
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
    final Offset offsetFactor =
        delta * widget.controller.behavior.panSensitivity / _zoom;

    final Offset targetOffset = _offset + offsetFactor;

    _setOffset(targetOffset, animate: false);
  }

  void _setZoomFromRawInput(double amount) {
    const double baseSpeed =
        0.05; // Base zoom speed and damping factor (magic number)
    const double scaleFactor =
        1.5; // Controls how zoom speed scales with zoom level (magic number)

    final double sensitivity = widget.controller.behavior.zoomSensitivity;

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

    final beginOffset = _offset;

    final Offset endOffset = Offset(
      targetOffset.dx.clamp(
        -widget.controller.behavior.maxPanX,
        widget.controller.behavior.maxPanX,
      ),
      targetOffset.dy.clamp(
        -widget.controller.behavior.maxPanY,
        widget.controller.behavior.maxPanY,
      ),
    );

    if (animate) {
      _offsetAnimationController.reset();

      final distance = (_offset - endOffset).distance;
      final durationFactor = (distance / 1000).clamp(0.5, 3.0);
      _offsetAnimationController.duration = Duration(
        milliseconds: (1000 * durationFactor).toInt(),
      );

      _offsetAnimation = Tween<Offset>(
        begin: beginOffset,
        end: endOffset,
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
        _offset = endOffset;
        widget.controller.offset = _offset;
      });
    }
  }

  void _setZoom(double targetZoom, {bool animate = true}) {
    if (_zoom == targetZoom) return;

    final beginZoom = _zoom;

    final endZoom = targetZoom.clamp(
      widget.controller.behavior.minZoom,
      widget.controller.behavior.maxZoom,
    );

    if (animate) {
      _zoomAnimationController.reset();

      _zoomAnimationController.duration = const Duration(milliseconds: 200);

      _zoomAnimation = Tween<double>(
        begin: beginZoom,
        end: endZoom,
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
        _zoom = endZoom;
        widget.controller.zoom = _zoom;
      });
    }
  }

  Tuple2<String, String>? _isNearPort(Offset worldPosition) {
    for (final node in widget.controller.nodes.values) {
      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;

        if ((worldPosition - absolutePortPosition).distance < 12) {
          return Tuple2(node.id, port.id);
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<ContextMenuEntry> contextMenuEntries(Offset position) => [
          const MenuHeader(text: "Context Menu"),
          MenuItem(
            label: 'Center View',
            value: "Center View",
            icon: Icons.center_focus_strong,
            onSelected: () => widget.controller.setViewportOffset(
              Offset.zero,
              absolute: true,
            ),
          ),
          if (_zoom != 1.0)
            MenuItem(
              label: 'Reset Zoom',
              value: "Reset Zoom",
              icon: _zoom < 1.0 ? Icons.zoom_in_map : Icons.zoom_out_map,
              onSelected: () => widget.controller.setViewportZoom(1.0),
            ),
          const MenuDivider(),
          MenuItem.submenu(
            label: 'Create',
            icon: Icons.add,
            items: widget.controller.nodePrototypes.entries
                .map(
                  (entry) => MenuItem(
                    label: entry.value().name,
                    value: entry.key,
                    icon: Icons.widgets,
                    onSelected: () => widget.controller.addNode(
                      entry.key,
                      offset: screenToWorld(
                        position,
                        getSizeFromGlobalKey(kNodeEditorWidgetKey)!,
                        _offset,
                        _zoom,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          MenuItem(
            label: 'Paste',
            value: "Paste",
            icon: Icons.paste,
            onSelected: () {},
          ),
          const MenuDivider(),
          MenuItem(
            label: 'Undo',
            value: "Undo",
            icon: Icons.undo,
            onSelected: () {},
          ),
          MenuItem(
            label: 'Redo',
            value: 'Redo',
            icon: Icons.redo,
            onSelected: () {},
          ),
        ];

    Widget controlsWrapper(Widget child) {
      return isMobile()
          ? GestureDetector(
              onDoubleTap: () => widget.controller.clearSelection(),
              onLongPressDown: (details) {
                createAndShowContextMenu(
                  context,
                  contextMenuEntries(details.localPosition),
                  details.globalPosition,
                );
              },
              onScaleStart: (details) => _onDragStart(),
              onScaleUpdate: (details) {
                if (widget.controller.behavior.zoomSensitivity > 0 &&
                    details.scale.abs() > 0.01) {
                  _setZoomFromRawInput(details.scale);
                }

                if (widget.controller.behavior.panSensitivity > 0 &&
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
                onDoubleClick: () => widget.controller.clearSelection(),
                onPointerPressed: (event) {
                  if (event.buttons == kPrimaryMouseButton) {
                    final worldPosition = screenToWorld(
                      event.localPosition,
                      getSizeFromGlobalKey(kNodeEditorWidgetKey)!,
                      _offset,
                      _zoom,
                    );

                    final locator = _isNearPort(worldPosition);

                    if (locator != null) {
                      if (_isLinking && _tempLink != null) {
                        widget.controller.addLink(
                          _tempLink!.item1,
                          _tempLink!.item2,
                          locator.item1,
                          locator.item2,
                        );

                        _isLinking = false;
                        _tempLink = null;
                      } else {
                        _tempLink = Tuple2(locator.item1, locator.item2);
                        _isLinking = true;
                      }
                    } else {
                      _onSelectStart(event.localPosition);
                    }
                  } else if (event.buttons == kSecondaryMouseButton &&
                      !isContextMenuVisible) {
                    createAndShowContextMenu(
                      context,
                      contextMenuEntries(event.localPosition),
                      event.position,
                    );
                  } else if (event.buttons == kMiddleMouseButton) {
                    _onDragStart();
                  }
                },
                onPointerMoved: (event) {
                  if (_isDragging &&
                      widget.controller.behavior.panSensitivity > 0) {
                    _onDragUpdate(event.localDelta);
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
                  if (widget.controller.behavior.zoomSensitivity > 0 &&
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
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              child: RepaintBoundary(
                child: NodeEditorRenderWidget(
                  key: kNodeEditorWidgetKey,
                  controller: widget.controller,
                  style: widget.style,
                ),
              ),
            ),
            ...widget.overaly().map(
                  (overlayData) => Positioned(
                    top: overlayData.top,
                    left: overlayData.left,
                    bottom: overlayData.bottom,
                    right: overlayData.right,
                    child: RepaintBoundary(
                      child: overlayData.child,
                    ),
                  ),
                ),
            if (kDebugMode)
              _DebugInfoWidget(
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

class _DebugInfoWidget extends StatelessWidget {
  final Offset offset;
  final double zoom;

  const _DebugInfoWidget({required this.offset, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${offset.dx.toStringAsFixed(2)}, Y: ${offset.dy.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          Text(
            'Zoom: ${zoom.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
