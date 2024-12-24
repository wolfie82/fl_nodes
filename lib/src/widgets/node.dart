import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';

import '../core/models/node.dart';
import '../core/utils/platform.dart';

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
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    Widget controlsWrapper(Widget child) {
      return isMobile()
          ? GestureDetector(
              onPanUpdate: (details) {
                widget.controller.dragNode(widget.node.id, details.delta);
              },
              onTap: () => widget.controller.selectNodesById([widget.node.id]),
              child: child,
            )
          : ImprovedListener(
              onPointerMoved: (event) {
                if (event.buttons == kPrimaryMouseButton) {
                  widget.controller.dragNode(widget.node.id, event.delta);
                }
              },
              onPointerPressed: (event) =>
                  widget.controller.selectNodesById([widget.node.id]),
              child: child,
            );
    }

    return controlsWrapper(
      IntrinsicWidth(
        child: Stack(
          children: [
            Container(
              key: widget.node.key,
              constraints: const BoxConstraints(minWidth: 100),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                boxShadow: [
                  BoxShadow(
                    color: widget.node.state.isSelected
                        ? Colors.blue.withAlpha(128)
                        : Colors.black.withAlpha(64),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isCollapsed = !_isCollapsed;
                              });
                            },
                            child: Icon(
                              _isCollapsed
                                  ? Icons.arrow_right
                                  : Icons.arrow_drop_down,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            widget.node.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _isCollapsed,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Input Ports
                            ...widget.node.inputs.asMap().entries.map(
                                  (entry) => _buildPortRow(
                                    entry.value,
                                    isInput: true,
                                  ),
                                ),
                            const SizedBox(height: 8),
                            // Output Ports
                            ...widget.node.outputs.asMap().entries.map(
                                  (entry) => _buildPortRow(
                                    entry.value,
                                    isInput: false,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...widget.node.inputs.asMap().entries.map(
                  (entry) => _buildPortIndicator(entry.value, isInput: true),
                ),
            ...widget.node.outputs.asMap().entries.map(
                  (entry) => _buildPortIndicator(entry.value, isInput: false),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortRow(Port port, {required bool isInput}) {
    return Visibility(
      visible: _isCollapsed,
      child: Row(
        mainAxisAlignment:
            isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min, // Prevents stretching
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
          Gap(isInput ? 0 : 4),
        ],
      ),
    );
  }

  Widget _buildPortIndicator(Port port, {required bool isInput}) {
    return Visibility(
      visible: _isCollapsed,
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

            final portPosition = portBox.localToGlobal(Offset.zero);
            final nodePosition = nodeBox.localToGlobal(Offset.zero);
            final relativePosition = portPosition - nodePosition;

            return CustomPaint(
              painter: _PortDotPainter(
                position: Offset(
                  isInput ? 0 : constraints.maxWidth,
                  relativePosition.dy + portBox.size.height / 2,
                ),
                color: isInput ? Colors.purple[200]! : Colors.green[300]!,
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
  }

  @override
  bool? hitTest(Offset position) {
    final dx = (position.dx - this.position.dx).abs();
    final dy = (position.dy - this.position.dy).abs();
    return dx <= portSize && dy <= portSize;
  }

  @override
  bool shouldRepaint(covariant _PortDotPainter oldDelegate) {
    return position != oldDelegate.position || color != oldDelegate.color;
  }
}
