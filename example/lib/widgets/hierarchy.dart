import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fl_nodes/fl_nodes.dart';

class HierarchyWidget extends StatefulWidget {
  final FlNodeEditorController controller;

  const HierarchyWidget({
    required this.controller,
    super.key,
  });

  @override
  State<HierarchyWidget> createState() => _HierarchyWidgetState();
}

class _HierarchyWidgetState extends State<HierarchyWidget> {
  @override
  void initState() {
    super.initState();

    _handleControllerEvents();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen(
      (event) {
        if (event is SelectionEvent ||
            event is DragSelectionEvent ||
            event is NodeRenderModeEvent ||
            event is AddNodeEvent ||
            event is RemoveNodeEvent) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      color: const Color(0xFF212121),
      padding: const EdgeInsets.all(8),
      child: Column(
        spacing: 8,
        children: [
          const Text(
            'Hierarchy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.controller.nodesAsList.length,
              itemBuilder: (context, index) {
                final node = widget.controller.nodesAsList[index];
                return Container(
                  decoration: node.state.isSelected
                      ? BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: ListTile(
                    title: Text(
                      '${node.offset} - ${node.prototype.displayName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.controller.selectNodesById(
                        {node.id},
                        holdSelection:
                            HardwareKeyboard.instance.isControlPressed,
                      );

                      widget.controller.focusNodesById(
                        widget.controller.selectedNodeIds.toSet(),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
