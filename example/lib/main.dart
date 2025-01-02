import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fl_nodes/fl_nodes.dart';

void main() {
  runApp(const NodeEditorExampleApp());
}

class NodeEditorExampleApp extends StatelessWidget {
  const NodeEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Editor Example',
      theme: ThemeData.dark(),
      home: const NodeEditorExampleScreen(),
      debugShowCheckedModeBanner: kDebugMode,
    );
  }
}

class NodeEditorExampleScreen extends StatefulWidget {
  const NodeEditorExampleScreen({super.key});

  @override
  State<NodeEditorExampleScreen> createState() =>
      NodeEditorExampleScreenState();
}

class NodeEditorExampleScreenState extends State<NodeEditorExampleScreen> {
  final FlNodeEditorController _nodeEditorController = FlNodeEditorController();

  @override
  void initState() {
    super.initState();

    _nodeEditorController.registerNodePrototype(
      'add',
      () => NodePrototype(
        name: 'Add',
        color: Colors.amber,
        ports: [
          PortPrototype(
            name: 'A',
            data: 0,
          ),
          PortPrototype(
            name: 'B',
            data: 0,
          ),
          PortPrototype(
            name: 'Result',
            data: 0,
            isInput: false,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );

    _nodeEditorController.registerNodePrototype(
      'input',
      () => NodePrototype(
        name: 'Input',
        color: Colors.red,
        ports: [
          PortPrototype(
            name: 'Value',
            data: 0,
            isInput: false,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );

    _nodeEditorController.registerNodePrototype(
      'output',
      () => NodePrototype(
        name: 'Output',
        color: Colors.green,
        ports: [
          PortPrototype(
            name: 'Value',
            data: 0,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );

    _nodeEditorController.addNode('input', offset: const Offset(-200, -100));
    _nodeEditorController.addNode('input', offset: const Offset(-200, 100));
    _nodeEditorController.addNode('add', offset: const Offset(0, 0));
    _nodeEditorController.addNode('output', offset: const Offset(200, 0));
  }

  @override
  void dispose() {
    _nodeEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FlHierarchyWidget(
              controller: _nodeEditorController,
              style: const HierarchyStyle(),
            ),
            Expanded(
              child: FlNodeEditor(
                controller: _nodeEditorController,
                expandToParent: true,
                style: const NodeEditorStyle(
                  gridStyle: GridStyle(
                    lineType: LineType.solid,
                    lineWidth: 1,
                    intersectionType: IntersectionType.circle,
                    intersectionRadius: 2,
                  ),
                ),
                overaly: () {
                  return [
                    FlOverlayData(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: FlSearchWidget(
                          controller: _nodeEditorController,
                          style: const SearchStyle(),
                        ),
                      ),
                    ),
                    FlOverlayData(
                      bottom: 0,
                      left: 0,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mouse Commands:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(' - Left Click: Select Node'),
                            Text(' - Right Click: Open Context Menu'),
                            Text(' - Scroll: Zoom In/Out'),
                            Text(' - Middle Click: Pan'),
                            SizedBox(height: 8),
                            Text(
                              'Keyboard Commands:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(' - Ctrl + C: Copy Node'),
                            Text(' - Ctrl + V: Paste Node'),
                            Text(' - Ctrl + X: Cut Node'),
                            Text(' - Delete: Remove Node'),
                            Text(' - Ctrl + Z: Undo'),
                            Text(' - Ctrl + Y: Redo'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
