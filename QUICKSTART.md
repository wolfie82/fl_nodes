# **Quickstart**

Welcome to **FlNodes**! 🎉

This guide will walk you through the basics of installing and using **FlNodes**, a fully customizable node-based editor for Flutter.

---

## 🌌 Design Choices

### 💡 Core Idea

Before diving in, let's clarify what you should and shouldn't expect from **FlNodes**. This package is heavily inspired by Blender and Unreal Engine 5 and was originally developed as part of [OpenLocalUI](https://github.com/WilliamKarolDiCioccio/open_local_ui) to facilitate the creation of node-based workflows and automation scripts with the convenience of a graphical user interface. This core purpose significantly influenced the design of **FlNodes**.

While the package was initially tailored for this specific task, its codebase quickly proved to be highly extensible and modular. As a result, **FlNodes** is now open to more general-purpose applications in creating node-based UIs of any kind. For further discussions on this expansion, refer to issues #18 and #19.

### 🤯 Minimal Impact

A key goal of **FlNodes** is to minimize its impact on the integrating codebase. This principle is evident in how project storage is handled: project data is seamlessly converted to JSON, allowing for easy manipulation and storage. This approach ensures smooth interoperability with other systems while maintaining a lightweight footprint.

### 🧑‍🌬️ Nodes Execution

**FlNodes** offers an exceptionally flexible—some might even say all-powerful 🧙‍♂️—graph execution system. Developers using this package have complete control over defining nodes, customizing them to suit their needs. Our examples showcase only a fraction of what’s possible. Loops, branches, sequences, and other advanced logic structures can all be implemented seamlessly within the framework.

In **FlNodes**, core entities such as nodes, ports, and fields are represented in two distinct forms: as **`Prototypes`** (which define their structure and behavior in your code) and as **`Instances`** (which hold the data used for rendering and inference). This separation allows for a clear distinction between the abstract logic and the dynamic, real-time data that powers the system.

By separating data from control flow, **FlNodes** ensures both a clean and intuitive visual representation and a more robust, flexible backend, enabling developers to create sophisticated graph-based systems with ease.

In **FlNodes**, loops should be represented directly within the graph structure to avoid hidden flow control. This does not imply that loops can be embedded within the node’s internal logic; rather, it means that nodes designed to execute multiple times should visually reflect this behavior in alignment with the established visible flow paradigm. By representing these looping structures explicitly within the graph, we maintain transparency and clarity in the flow of execution, ensuring the graph remains easy to understand and debug.

All entities have both a `idName` for identification purposes (I like using camel case) and a `displayName` that is rendered and will, in the future allow for easier localization of the package.

---

## 📦 **Installation**

To install **FlNodes**, add it to your `pubspec.yaml`:

```yaml
dependencies:
  fl_nodes: ^latest_version
```

Then, run:

```bash
flutter pub get
```

---

## 🛠️ **Basic Usage**

Start by importing the package:

```dart
import 'package:fl_nodes/fl_nodes.dart';
```

For advanced functionalities, use:

```dart
import 'package:fl_nodes/fl_nodes_ext.dart';
```

For web platforms we strongly recommend to disallow most default browser interactions:

```html
<!DOCTYPE html>
<html>

<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="example">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png" />

  <title>example</title>
  <link rel="manifest" href="manifest.json">

  <style>
    /* Disable touch gestures */
    html, body {
      touch-action: none;
      overscroll-behavior: none;
    }
  </style>
</head>

<body>
  <canvas></canvas>
  <script src="flutter_bootstrap.js" async></script>

  <script>
    // Prevent pinch-to-zoom
    document.addEventListener('gesturestart', function (e) {
      e.preventDefault();
    });
    document.addEventListener('gesturechange', function (e) {
      e.preventDefault();
    });
    document.addEventListener('gestureend', function (e) {
      e.preventDefault();
    });

    // Disable right-click
    document.addEventListener("contextmenu", function (e) {
      e.preventDefault();
    });

    // Block certain keyboard shortcuts
    document.addEventListener("keydown", function (e) {
      if (e.ctrlKey && (e.key === "r" || e.key === "R")) {
        e.preventDefault();
      }
      if (e.key === "F12" || (e.ctrlKey && e.shiftKey && e.key === "I")) {
        e.preventDefault(); // Prevent DevTools opening
      }
    });
  </script>
</body>

</html>
```

### **Core Components**

1️⃣ **`FlNodeEditorWidget`** – The UI component that renders the node editor.  
2️⃣ **`FlNodeEditorController`** – Manages node data, interactions, and project state.

### **Setting Up a Node Editor**

In this example of how to integrate **FlNodes** into your Flutter app we show a simple setup of the **`FlNodeEditorController`** that allows to load and save project on disk with custom nodes and data types:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:example/data_handlers.dart';
import 'package:example/nodes.dart';
import 'package:file_picker/file_picker.dart';

import 'package:fl_nodes/fl_nodes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        if (kIsWeb) return false;

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

        return jsonDecode(fileContent);
      },
      projectCreator: (isSaved) async {
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
            HierarchyWidget(
              controller: _nodeEditorController,
              isCollapsed: isHierarchyCollapsed,
            ),
            Expanded(
              child: FlNodeEditorWidget(
                controller: _nodeEditorController,
                expandToParent: true,
                style: const FlNodeEditorStyle(),
                overlay: () {
                  return [
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
```

This is the prototpye registration process for an hypotetical `For Each Loop`:

```dart
void registerNodes(BuildContext context, FlNodeEditorController controller) {
  controller.registerNodePrototype(
    NodePrototype(
      idName: 'forEachLoop',
      displayName: 'For Each Loop',
      description: 'Executes a loop for a specified number of iterations.',
      color: Colors.teal,
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: 'Exec',
        ),
        DataInputPortPrototype(
          idName: 'list',
          displayName: 'List',
          dataType: dynamic,
        ),
        ControlOutputPortPrototype(
          idName: 'loopBody',
          displayName: 'Loop Body',
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: 'Completed',
        ),
        DataOutputPortPrototype(
          idName: 'listElem',
          displayName: 'List Element',
          dataType: dynamic,
        ),
        DataOutputPortPrototype(
          idName: 'listIdx',
          displayName: 'List Index',
          dataType: int,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final List<dynamic> list = ports['list']! as List<dynamic>;

        late int i;

        if (!state.containsKey('iteration')) {
          i = state['iteration'] = 0;
        } else {
          i = state['iteration'] as int;
        }

        if (i < list.length) {
          p({('listElem', list[i]), ('listIdx', i)});
          state['iteration'] = ++i;
          await f({'loopBody'});
        } else {
          unawaited(f({('completed')}));
        }
      },
    ),
  );
}
```

This is the data handler registration process for an hypothetical `Operator` custom enumerator type:

```dart
void registerDataHandlers(FlNodeEditorController controller) {
  controller.project.registerDataHandler<Operator>(
    toJson: (data) => data.toString().split('.').last,
    fromJson: (json) => Operator.values.firstWhere(
      (e) => e.toString().split('.').last == json,
    ),
  );
}
```

---

## 🎨 Extensive Styling Options

### FlGridStyle

Defines the grid appearance in the node editor:

- **gridSpacingX**: Horizontal grid spacing.
- **gridSpacingY**: Vertical grid spacing.
- **lineWidth**: Width of the grid lines.
- **lineColor**: Color of the grid lines.
- **intersectionColor**: Color of the grid intersections.
- **intersectionRadius**: Radius of the grid intersection points.
- **showGrid**: Whether the grid is visible.

---

### FlLinkCurveType

Defines the curve style of links between nodes:

- **straight**: Straight lines.
- **bezier**: Smooth Bezier curves.
- **ninetyDegree**: Right-angle connections.

---

### FlLinkDrawMode

Defines the visual style of links:

- **solid**: Continuous line.
- **dashed**: Dashed line.
- **dotted**: Dotted line.

---

### FlLinkStyle

Defines the appearance of links:

- **lineWidth**: Thickness of the link.
- **drawMode**: Drawing style (solid, dashed, or dotted).
- **curveType**: Curve type of the link.

---

### FlPortStyle

Defines port colors based on type and direction:

- **color**: Mapping of port types to colors for input and output directions e.g.
  - **PortType.data**:
    - **input**: Soft Purple
    - **output**: Coral Pink
  - **PortType.control**:
    - **input**: Green
    - **output**: Blue

---

### FlFieldStyle

Defines the appearance of fields in a node:

- **decoration**: Background styling (default: dark blue-grey with rounded corners).
- **padding**: Internal padding of the field.

---

### FlNodeStyle

Defines the styling of nodes:

- **decoration**: Default node appearance.
- **selectedDecoration**: Appearance when a node is selected.
- **linkStyle**: Link appearance settings.
- **portStyle**: Port appearance settings.
- **fieldStyle**: Field appearance settings.

---

### FlNodeEditorStyle

Defines the overall editor appearance:

- **decoration**: Background styling.
- **padding**: Padding inside the editor.
- **gridStyle**: Grid appearance settings.
- **nodeStyle**: Node appearance settings.

---

🚀 Happy coding with **FlNodes**! 🚀
