import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:example/data_handlers.dart';
import 'package:example/nodes.dart';
import 'package:file_picker/file_picker.dart';

import 'package:fl_nodes/fl_nodes.dart';

import './widgets/hierarchy.dart';
import './widgets/search.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }

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
  late final FlNodeEditorController _nodeEditorController;

  @override
  void initState() {
    super.initState();

    _nodeEditorController = FlNodeEditorController(
      projectSaver: (jsonData) async {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Project',
          fileName: 'node_project.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath != null) {
          final File file = File(outputPath);
          await file.writeAsString(jsonEncode(jsonData));

          return true;
        } else {
          return false;
        }
      },
      projectLoader: (isSaved) async {
        if (!isSaved) {
          final bool? proceed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Do you want to proceed without saving?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Proceed'),
                  ),
                ],
              );
            },
          );

          if (proceed != true) return null;
        }

        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result == null) return null;

        late final String fileContent;

        if (kIsWeb) {
          final byteData = result.files.single.bytes!;
          fileContent = utf8.decode(byteData.buffer.asUint8List());
        } else {
          final File file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        }

        final Map<String, dynamic> jsonData = jsonDecode(fileContent);
        return jsonData;
      },
      projectCreator: (isSaved) async {
        if (kIsWeb) return false;

        if (isSaved) return true;

        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have unsaved changes. Do you want to proceed without saving?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );

        return proceed == true;
      },
    );

    registerDataHandlers(_nodeEditorController);

    registerNodes(context, _nodeEditorController);
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
            HierarchyWidget(controller: _nodeEditorController),
            Expanded(
              child: FlNodeEditorWidget(
                controller: _nodeEditorController,
                expandToParent: true,
                style: const FlNodeEditorStyle(
                  gridStyle: FlGridStyle(
                    lineWidth: 1,
                    intersectionRadius: 2,
                  ),
                ),
                overlay: () {
                  return [
                    FlOverlayData(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SearchWidget(controller: _nodeEditorController),
                      ),
                    ),
                    FlOverlayData(
                      top: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _nodeEditorController.runner.executeGraph(),
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
                      child: const Opacity(
                        opacity: 0.5,
                        child: Padding(
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
                              Text(' - Ctrl + S: Save Project'),
                              Text(' - Ctrl + O: Open Project'),
                              Text(' - Ctrl + N: New Project'),
                              Text(' - Ctrl + C: Copy Node'),
                              Text(' - Ctrl + V: Paste Node'),
                              Text(' - Ctrl + X: Cut Node'),
                              Text(' - Delete | Backspace: Remove Node'),
                              Text(' - Ctrl + Z: Undo'),
                              Text(' - Ctrl + Y: Redo'),
                            ],
                          ),
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
