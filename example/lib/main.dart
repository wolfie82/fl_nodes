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
        inputs: [
          Port(id: 'a', name: 'A', data: 0, color: Colors.red),
          Port(id: 'b', name: 'B', data: 0, color: Colors.green),
        ],
        outputs: [
          Port(id: 'result', name: 'Result', data: 0, color: Colors.blue),
        ],
        fields: [
          Field(id: 'a', name: 'A', data: 0, color: Colors.red),
          Field(id: 'b', name: 'B', data: 0, color: Colors.green),
        ],
        onExecute: (inputIds) {
          final a = int.parse(inputIds[0]);
          final b = int.parse(inputIds[1]);
          return [(a + b).toString()];
        },
        color: Colors.blue,
      ),
    );

    _nodeEditorController.addNode('add');
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
        child: FlNodeEditorWidget(
          controller: _nodeEditorController,
          expandToParent: true,
          style: const NodeEditorStyle(
            gridPainterStyle: GridStyle(
              lineType: LineType.solid,
              lineWidth: 1,
              intersectionType: IntersectionType.circle,
              intersectionRadius: 2,
            ),
          ),
          content: (offset, zoom) {
            return [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          _nodeEditorController.setOffset(Offset.zero),
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
                      onPressed: () => _nodeEditorController.setZoom(zoom * 2),
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
                      onPressed: () => _nodeEditorController.setZoom(zoom / 2),
                      icon: const Icon(
                        Icons.zoom_out,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      ),
    );
  }
}
