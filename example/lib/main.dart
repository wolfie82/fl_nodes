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
            dataType: double,
          ),
          PortPrototype(
            name: 'B',
            dataType: double,
          ),
          PortPrototype(
            name: 'Result',
            dataType: double,
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
            dataType: double,
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
            dataType: double,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );

    _nodeEditorController.registerNodePrototype(
      'round',
      () => NodePrototype(
        name: 'Round',
        color: Colors.blue,
        ports: [
          PortPrototype(
            name: 'Value',
            dataType: double,
          ),
          PortPrototype(
            name: 'Rounded',
            dataType: int,
            isInput: false,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );
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
                      top: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.play_arrow,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
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
