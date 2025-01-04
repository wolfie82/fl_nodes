import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:gap/gap.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';

import '../core/controllers/node_editor_events.dart';
import '../core/models/node.dart';
import '../core/utils/constants.dart';
import '../core/utils/platform.dart';
import '../core/utils/renderbox.dart';

class NodeWidget extends StatefulWidget {
  final Node node;
  final FlNodeEditorController controller;
  const NodeWidget({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  Timer? _edgeTimer;

  double get zoom => widget.controller.zoom;
  Offset get nodeOffset => widget.node.offset;

  @override
  void initState() {
    super.initState();

    _handleControllerEvents();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event.isHandled || !mounted) return;

      if (event is SelectionEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {
            widget.node.state.isSelected = true;
          });
        } else {
          setState(() {
            widget.node.state.isSelected = false;
          });
        }
      } else if (event is DragSelectionEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {
            widget.node.offset += event.delta / widget.controller.zoom;
          });
        }
      } else if (event is CollapseNodeEvent) {
        if (event.id == widget.node.id) {
          setState(() {});
        }
      } else if (event is ExpandNodeEvent) {
        if (event.id == widget.node.id) {
          setState(() {});
        }
      }
    });
  }

  void _startEdgeTimer(Offset position) {
    const edgeThreshold = 50.0; // Distance from edge to start moving
    final moveAmount = 5.0 / widget.controller.zoom; // Amount to move per frame

    final editorBounds = getEditorBoundsInScreen(kNodeEditorWidgetKey);
    if (editorBounds == null) return;

    _edgeTimer?.cancel();

    _edgeTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) async {
      double dx = 0;
      double dy = 0;
      final rect = editorBounds;

      if (position.dx < rect.left + edgeThreshold) {
        dx = -moveAmount;
      } else if (position.dx > rect.right - edgeThreshold) {
        dx = moveAmount;
      }
      if (position.dy < rect.top + edgeThreshold) {
        dy = -moveAmount;
      } else if (position.dy > rect.bottom - edgeThreshold) {
        dy = moveAmount;
      }

      if (dx != 0 || dy != 0) {
        widget.controller.dragSelection(Offset(dx, dy));
        widget.controller.setViewportOffset(
          Offset(-dx / zoom, -dy / zoom),
          animate: false,
        );
      }
    });
  }

  void _resetEdgeTimer() {
    _edgeTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    List<ContextMenuEntry> contextMenuEntries() {
      return [
        const MenuHeader(text: 'Node Menu'),
        MenuItem(
          label: widget.node.state.isCollapsed ? 'Expand' : 'Collapse',
          icon: widget.node.state.isCollapsed
              ? Icons.arrow_drop_down
              : Icons.arrow_right,
          onSelected: () {
            if (widget.node.state.isCollapsed) {
              widget.controller.expandNode(widget.node.id);
            } else {
              widget.controller.collapseNode(widget.node.id);
            }
          },
        ),
        const MenuDivider(),
        MenuItem(
          label: 'Delete',
          icon: Icons.delete,
          onSelected: () {
            widget.controller.removeNode(widget.node.id);
          },
        ),
        MenuItem(
          label: 'Cut',
          icon: Icons.content_cut,
          onSelected: () {},
        ),
        MenuItem(
          label: 'Copy',
          icon: Icons.copy,
          onSelected: () {},
        ),
      ];
    }

    Widget controlsWrapper(Widget child) {
      return isMobile()
          ? child
          : ImprovedListener(
              onPointerPressed: (event) {
                if (event.buttons == kSecondaryMouseButton &&
                    !isContextMenuVisible) {
                  createAndShowContextMenu(
                    context,
                    contextMenuEntries(),
                    event.position,
                  );
                } else if (event.buttons == kPrimaryMouseButton) {
                  widget.controller.selectNodesById(
                    [widget.node.id],
                    holdSelection: widget.node.state.isSelected
                        ? true
                        : HardwareKeyboard.instance.isControlPressed,
                  );
                }
              },
              onPointerMoved: (event) {
                _startEdgeTimer(event.position);

                if (event.buttons == kPrimaryMouseButton) {
                  widget.controller.dragSelection(event.delta);
                }
              },
              onPointerReleased: (event) {
                _resetEdgeTimer();
              },
              child: child,
            );
    }

    return controlsWrapper(
      IntrinsicWidth(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: widget.node.key,
              constraints: const BoxConstraints(minWidth: 100),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                boxShadow: [
                  BoxShadow(
                    color: widget.node.state.isSelected
                        ? widget.node.color.withAlpha(128)
                        : Colors.black.withAlpha(64),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: widget.node.color,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.node.color,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(7),
                        topRight: const Radius.circular(7),
                        bottomLeft: widget.node.state.isCollapsed
                            ? const Radius.circular(7)
                            : Radius.zero,
                        bottomRight: widget.node.state.isCollapsed
                            ? const Radius.circular(7)
                            : Radius.zero,
                      ),
                    ),
                    child: Text(
                      widget.node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Visibility(
                    visible: !widget.node.state.isCollapsed,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...widget.node.ports.entries.map(
                            (entry) => _buildPortRow(
                              entry.value,
                              isInput: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...widget.node.ports.entries.map(
              (entry) => _buildPortIndicator(entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortRow(Port port, {required bool isInput}) {
    return Visibility(
      visible: !widget.node.state.isCollapsed,
      child: Row(
        mainAxisAlignment:
            isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        key: port.key,
        children: [
          Gap(isInput ? 4 : 0),
          Text(
            port.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const Gap(4),
          Text(
            port.dataType.toString(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          Gap(isInput ? 0 : 4),
        ],
      ),
    );
  }

  Widget _buildPortIndicator(Port port) {
    return Visibility(
      visible: !widget.node.state.isCollapsed,
      child: Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final portKey = port.key;
            final RenderBox? portBox =
                portKey.currentContext?.findRenderObject() as RenderBox?;

            if (portBox == null) return const SizedBox();

            final nodeBox = widget.node.key.currentContext?.findRenderObject()
                as RenderBox?;
            if (nodeBox == null) return const SizedBox();

            final portOffset = portBox.localToGlobal(Offset.zero);
            final nodeOffset = nodeBox.localToGlobal(Offset.zero);
            final relativeOffset = portOffset - nodeOffset;

            port.offset = Offset(
              port.isInput ? 0 : constraints.maxWidth,
              relativeOffset.dy + portBox.size.height / 2,
            );

            return CustomPaint(
              painter: _PortDotPainter(
                position: Offset(
                  port.isInput ? 0 : constraints.maxWidth,
                  relativeOffset.dy + portBox.size.height / 2,
                ),
                color: port.isInput ? Colors.purple[200]! : Colors.green[300]!,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortDotPainter extends CustomPainter {
  final Offset position;
  final Color color;
  static const double portSize = 4;
  static const double hitBoxSize = 16;

  _PortDotPainter({
    required this.position,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, portSize, paint);

    if (kDebugMode) {
      _paintDebugHitBox(canvas);
    }
  }

  void _paintDebugHitBox(Canvas canvas) {
    final hitBoxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final hitBoxRect = Rect.fromCenter(
      center: position,
      width: hitBoxSize,
      height: hitBoxSize,
    );

    canvas.drawRect(hitBoxRect, hitBoxPaint);
  }

  @override
  bool shouldRepaint(covariant _PortDotPainter oldDelegate) {
    return position != oldDelegate.position || color != oldDelegate.color;
  }
}
