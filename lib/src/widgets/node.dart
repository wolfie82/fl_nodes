import 'package:flutter/material.dart';

import '../core/models/node.dart';

class NodeWidget extends StatelessWidget {
  final Node node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: node.key,
      onPanUpdate: (details) {
        // Handle dragging logic (e.g., update the position of the node)
        node.offset += details.localPosition;
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                // Display input ports
                for (var input in node.inputs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: PortWidget(port: input),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                // Display output ports
                for (var output in node.outputs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: PortWidget(port: output),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PortWidget extends StatelessWidget {
  final Port port;
  final bool output;

  const PortWidget({super.key, required this.port, this.output = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.black.withOpacity(0.2),
        ),
      ),
      child: Text(
        port.name, // Display part of the port ID for uniqueness
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
}
