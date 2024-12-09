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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NodeEditorExampleScreen(),
    );
  }
}

class NodeEditorExampleScreen extends StatelessWidget {
  const NodeEditorExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Editor Example'),
      ),
      body: const Center(
        child: NodeEditorWidget(
          expandToParent: false,
          fixedSize: Size(1280, 720),
        ),
      ),
    );
  }
}
