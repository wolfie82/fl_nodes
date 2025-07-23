import 'dart:async'; // Import 'dart:async' for StreamSubscription
import 'package:fl_nodes/src/core/models/events.dart';
import 'package:flutter/material.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/core.dart';

class DebugInfoWidget extends StatefulWidget {
  final FlNodeEditorController controller;

  const DebugInfoWidget({
    super.key,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() => _DebugInfoWidgetState();
}

class _DebugInfoWidgetState extends State<DebugInfoWidget> {
  // 1. ADD THIS VARIABLE TO HOLD THE SUBSCRIPTION
  StreamSubscription? _eventSubscription;

  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;
  int get selectionCount => widget.controller.selectedNodeIds.length;

  @override
  void initState() {
    super.initState();

    // 2. STORE THE SUBSCRIPTION WHEN YOU START LISTENING
    _eventSubscription = widget.controller.eventBus.events.listen((event) {
      if (event is ViewportOffsetEvent ||
          event is ViewportZoomEvent ||
          event is NodeSelectionEvent) {
        // As a good practice, check if the widget is still mounted
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  // 3. ADD THIS ENTIRE DISPOSE METHOD TO CANCEL THE SUBSCRIPTION
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${viewportOffset.dx.toStringAsFixed(2)}, Y: ${viewportOffset.dy.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          Text(
            'Zoom: ${viewportZoom.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
          Text(
            'Selection count: $selectionCount',
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}