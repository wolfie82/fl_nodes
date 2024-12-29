import 'package:fl_nodes/src/core/models/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gap/gap.dart';

import 'package:fl_nodes/src/core/controllers/node_editor_events.dart';

import '../core/controllers/node_editor.dart';

class FlHierarchyWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final HierarchyStyle style;

  const FlHierarchyWidget({
    required this.controller,
    required this.style,
    super.key,
  });

  @override
  State<FlHierarchyWidget> createState() => _FlHierarchyWidgetState();
}

class _FlHierarchyWidgetState extends State<FlHierarchyWidget> {
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
            event is CollapseNodeEvent ||
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
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.style.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: widget.style.borderRadius,
      ),
      child: Column(
        children: [
          Text(
            'Hierarchy',
            style: TextStyle(
              color: widget.style.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.controller.nodesAsList.length,
            itemBuilder: (context, index) {
              final node = widget.controller.nodesAsList[index];
              return Container(
                decoration: BoxDecoration(
                  color: node.state.isSelected
                      ? widget.style.selectedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    '${node.offset} - ${node.name}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.style.textColor,
                    ),
                  ),
                  onTap: () {
                    final focusedNodes = [
                      node.id,
                      if (HardwareKeyboard.instance.isControlPressed)
                        ...widget.controller.selectedNodeIds,
                    ];

                    widget.controller.focusNodesById(focusedNodes);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
