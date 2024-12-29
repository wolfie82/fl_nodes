import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

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
        inputs: [
          PortPrototype(
            name: 'A',
            data: 0,
          ),
          PortPrototype(
            name: 'B',
            data: 0,
          ),
        ],
        outputs: [
          PortPrototype(
            name: 'Result',
            data: 0,
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
        outputs: [
          PortPrototype(
            name: 'Value',
            data: 0,
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
        inputs: [
          PortPrototype(
            name: 'Value',
            data: 0,
          ),
        ],
        onExecute: (inputIds, outputIds) {},
      ),
    );

    _nodeEditorController.addNode('add', offset: const Offset(0, 0));
    _nodeEditorController.addNode('input', offset: const Offset(-200, -100));
    _nodeEditorController.addNode('input', offset: const Offset(-200, 100));
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
      appBar: AppBar(
        title: const Text(
          'Node Editor Example',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FlSearchWidget(
                              controller: _nodeEditorController,
                              style: const SearchStyle(),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    _nodeEditorController.setViewportOffset(
                                  Offset.zero,
                                  absolute: true,
                                ),
                                icon: const Icon(
                                  Icons.center_focus_strong,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Gap(8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    _nodeEditorController.setViewportZoom(
                                  _nodeEditorController.zoom * 2,
                                ),
                                icon: const Icon(
                                  Icons.zoom_in,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Gap(8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    _nodeEditorController.setViewportZoom(
                                  _nodeEditorController.zoom / 2,
                                ),
                                icon: const Icon(
                                  Icons.zoom_out,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
