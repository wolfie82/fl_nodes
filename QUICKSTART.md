# **Quickstart**

Welcome to **FlNodes**! 🎉

This guide will walk you through the basics of installing and using **FlNodes**,
a fully customizable node-based editor for Flutter.

---

## 🌌 Design Choices

### 💡 Core Idea

Before diving in, let's clarify what you should and shouldn't expect from
**FlNodes**. This package is heavily inspired by Blender and Unreal Engine 5 and
was originally developed as part of
[OpenLocalUI](https://github.com/WilliamKarolDiCioccio/open_local_ui) to
facilitate the creation of node-based workflows and automation scripts with the
convenience of a graphical user interface. This core purpose significantly
influenced the design of **FlNodes**.

While the package was initially tailored for this specific task, its codebase
quickly proved to be highly extensible and modular. As a result, **FlNodes** is
now open to more general-purpose applications in creating node-based UIs of any
kind. For further discussions on this expansion, refer to issues #18 and #19.

### 🤯 Minimal Impact

A key goal of **FlNodes** is to minimize its impact on the integrating codebase.
This principle is evident in how project storage is handled: project data is
seamlessly converted to JSON, allowing for easy manipulation and storage. This
approach ensures smooth interoperability with other systems while maintaining a
lightweight footprint.

### 🧑‍🌬️ Nodes Execution

**FlNodes** offers an exceptionally flexible—some might even say all-powerful
🧙‍♂️—graph execution system. Developers using this package have complete control
over defining nodes, customizing them to suit their needs. Our examples showcase
only a fraction of what’s possible. Loops, branches, sequences, and other
advanced logic structures can all be implemented seamlessly within the
framework.

In **FlNodes**, core entities such as nodes, ports, and fields are represented
in two distinct forms: as **`Prototypes`** (which define their structure and
behavior in your code) and as **`Instances`** (which hold the data used for
rendering and inference). This separation allows for a clear distinction between
the abstract logic and the dynamic, real-time data that powers the system.

By separating data from control flow, **FlNodes** ensures both a clean and
intuitive visual representation and a more robust, flexible backend, enabling
developers to create sophisticated graph-based systems with ease.

In **FlNodes**, loops should be represented directly within the graph structure
to avoid hidden flow control. This does not imply that loops can be embedded
within the node’s internal logic; rather, it means that nodes designed to
execute multiple times should visually reflect this behavior in alignment with
the established visible flow paradigm. By representing these looping structures
explicitly within the graph, we maintain transparency and clarity in the flow of
execution, ensuring the graph remains easy to understand and debug.

All entities have both a `idName` for identification purposes (I like using
camel case) and a `displayName` that is rendered and will, in the future allow
for easier localization of the package.

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

For web platforms we strongly recommend to disallow most default browser
interactions:

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
      document.addEventListener("gesturestart", function (e) {
        e.preventDefault();
      });
      document.addEventListener("gesturechange", function (e) {
        e.preventDefault();
      });
      document.addEventListener("gestureend", function (e) {
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
        if (
          e.key === "F12" || (e.ctrlKey && e.shiftKey && e.key === "I")
        ) {
          e.preventDefault(); // Prevent DevTools opening
        }
      });
    </script>
  </body>
</html>
```

### **Core Components**

1️⃣ **`FlNodeEditorWidget`** – The UI component that renders the node editor.\
2️⃣ **`FlNodeEditorController`** – Manages node data, interactions, and project
state.

### **Setting Up a Node Editor**

In this example of how to integrate **FlNodes** into your Flutter app we show a
simple setup of the **`FlNodeEditorController`** that allows to load and save
project on disk with custom nodes and data types:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:file_picker/file_picker.dart';

import 'package:fl_nodes/fl_nodes.dart';

void main() {
  // Ensures Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the Node Editor Example app
  runApp(const NodeEditorExampleApp());
}

class NodeEditorExampleApp extends StatelessWidget {
  const NodeEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Editor Example',
      theme: ThemeData.dark(), // Use a dark theme for the app
      home: const NodeEditorExampleScreen(),
      debugShowCheckedModeBanner: kDebugMode, // Show debug banner only in debug mode
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
  late final FlNodeEditorController _nodeEditorController; // Controller for managing the node editor

  @override
  void initState() {
    super.initState();

    // Initialize the node editor controller with project management functionality
    _nodeEditorController = FlNodeEditorController(
      projectSaver: (jsonData) async {
        if (kIsWeb) return false; // Skip file saving on web (not supported by file_picker)

        // Open a save file dialog to allow the user to save the project as JSON
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Project',
          fileName: 'node_project.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        // If a file path is selected, write the project data to the file
        if (outputPath != null) {
          final File file = File(outputPath);
          await file.writeAsString(jsonEncode(jsonData));

          return true;
        } else {
          return false; // Return false if saving was canceled
        }
      },
      projectLoader: (isSaved) async {
        // If there are unsaved changes, confirm whether the user wants to proceed
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

          if (proceed != true) return null; // Cancel loading if user chooses not to proceed
        }

        // Open file picker to select a JSON project file
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result == null) return null; // Return null if no file was selected

        late final String fileContent;

        // Handle file reading differently for web vs other platforms
        if (kIsWeb) {
          final byteData = result.files.single.bytes!;
          fileContent = utf8.decode(byteData.buffer.asUint8List());
        } else {
          final File file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        }

        return jsonDecode(fileContent); // Return the parsed JSON data
      },
      projectCreator: (isSaved) async {
        // If the project is not saved, ask the user whether to proceed
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

        return proceed == true; // Return true if the user chooses to proceed
      },
    );

    // Register data handlers and custom node definitions for the editor
    registerDataHandlers(_nodeEditorController);
    registerNodes(context, _nodeEditorController);
  }

  @override
  void dispose() {
    _nodeEditorController.dispose(); // Dispose of the controller to free resources
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
            // Sidebar widget to show node hierarchy, collapsible for convenience
            HierarchyWidget(
              controller: _nodeEditorController,
              isCollapsed: isHierarchyCollapsed,
            ),
            Expanded(
              child: FlNodeEditorWidget(
                controller: _nodeEditorController, // Attach the controller to the editor
                expandToParent: true, // Ensure the editor fills its parent
                style: const FlNodeEditorStyle(), // Use default styles
                
                // Overlay widgets for additional UI elements
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
                                _nodeEditorController.runner.executeGraph(), // Execute the node graph
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

NOTE: This is a purposefully advanced example to showcase all possibilities.

```dart
// Define a custom style for the output data port
final FlPortStyle outputDataPortStyle = FlPortStyle(
  color: Colors.orange, // Set port color to orange
  shape: FlPortShape.circle, // Use a circular port shape
  linkStyleBuilder: (state) => const FlLinkStyle(
    gradient: LinearGradient(
      colors: [Colors.orange, Colors.purple], // Gradient color for links
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    lineWidth: 3.0, // Set the link width
    drawMode: FlLinkDrawMode.solid, // Use solid line style
    curveType: FlLinkCurveType.bezier, // Use a smooth bezier curve
  ),
);

...

// Register a new node prototype in the node editor
controller.registerNodePrototype(
  NodePrototype(
    idName: 'forEachLoop', // Unique identifier for this node type
    displayName: 'For Each Loop', // User-friendly name
    description: 'Executes a loop for a specified number of iterations.', // Description for UI

    // Define node style (partially overriding the default)
    styleBuilder: (state) => FlNodeStyle(
      decoration: defaultNodeStyle(state).decoration, // Keep default decoration
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.teal, // Set header background color to teal
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            // Adjust bottom radius based on collapse state
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
    ),

    // Define the input and output ports for this node
    ports: [
      ControlInputPortPrototype(
        idName: 'exec', // Control input to trigger execution
        displayName: 'Exec',
        style: controlInputPortStyle,
      ),
      DataInputPortPrototype(
        idName: 'list', // Data input port for the list to iterate over
        displayName: 'List',
        dataType: dynamic, // Accepts any type
        style: inputDataPortStyle,
      ),
      ControlOutputPortPrototype(
        idName: 'loopBody', // Control output for the loop body execution
        displayName: 'Loop Body',
        style: controlOutputPortStyle,
      ),
      ControlOutputPortPrototype(
        idName: 'completed', // Control output for when the loop finishes
        displayName: 'Completed',
        style: controlOutputPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'listElem', // Data output for the current list element
        displayName: 'List Element',
        dataType: dynamic,
        style: outputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'listIdx', // Data output for the current index in the list
        displayName: 'List Index',
        dataType: int,
        style: outputDataPortStyle,
      ),
    ],

    // Define execution behavior of the node
    onExecute: (ports, fields, state, f, p) async {
      // Retrieve the list from the input port
      final List<dynamic> list = ports['list']! as List<dynamic>;

      late int i;

      // Check if this node has a stored iteration state, otherwise initialize it
      if (!state.containsKey('iteration')) {
        i = state['iteration'] = 0;
      } else {
        i = state['iteration'] as int;
      }

      // If there are still elements to iterate over
      if (i < list.length) {
        // Send the current element and index to the output ports
        p({('listElem', list[i]), ('listIdx', i)});

        // Increment iteration counter and store it in node state
        state['iteration'] = ++i;

        // Trigger the loop body control output
        await f({'loopBody'});
      } else {
        // If iteration is complete, trigger the "completed" output
        unawaited(f({('completed')}));
      }
    },
  ),
);

```

This is the data handler registration process for an hypothetical `Operator`
custom enumerator type:

```dart
controller.project.registerDataHandler<Operator>(
  // Converts an Operator enum instance to a JSON-compatible string 
  // by extracting the last part of its toString() value (i.e., the enum name).
  toJson: (data) => data.toString().split('.').last,

  // Converts a JSON string back into an Operator enum instance by 
  // finding the matching enum value based on its name.
  fromJson: (json) => Operator.values.firstWhere(
    (e) => e.toString().split('.').last == json,
  ),
);

```

---

## 🎨 Extensive Styling Options

Version **0.2.0** introduced **state-responsive styling**, allowing entities to
dynamically change appearance based on their state (e.g., selected, collapsed).
This enables a more interactive and customizable UI.

### 🟦 FlGridStyle (Grid Appearance)

Controls how the grid looks in the node editor:

- **gridSpacingX**: Horizontal spacing between grid lines.
- **gridSpacingY**: Vertical spacing between grid lines.
- **lineWidth**: Thickness of grid lines.
- **lineColor**: Color of grid lines.
- **intersectionColor**: Color of grid intersection points.
- **intersectionRadius**: Size of the intersection points.
- **showGrid**: Whether the grid is visible.

---

### 🔗 FlLinkCurveType (Link Curve Style)

Defines how links between nodes are drawn:

- **straight**: Direct straight-line connections.
- **bezier**: Smooth, flowing Bezier curves.
- **ninetyDegree**: Right-angle (90°) connections.

---

### 🎚 FlLinkDrawMode (Link Visual Style)

Determines how links appear:

- **solid**: A continuous line.
- **dashed**: A segmented dashed line.
- **dotted**: A series of small dots.

---

### 🖌 FlLinkStyle (Link Appearance)

Defines how links are visually styled:

- **gradient**: The color gradient of the link.
- **lineWidth**: Thickness of the link.
- **drawMode**: Drawing style (solid, dashed, dotted).
- **curveType**: Curve style (straight, Bezier, 90-degree).

---

### 🔵 FlPortStyle (Port Appearance)

Controls how ports look:

- **shape**: The shape of the port (`circle` or `triangle`).
- **color**: Defines port colors based on type and direction (e.g.,
  input/output).
- **linkStyleBuilder**: Function to dynamically generate link styles based on
  state.

---

### 📦 FlFieldStyle (Field Appearance)

Defines the appearance of fields inside nodes:

- **decoration**: Background styling.
- **padding**: Internal spacing inside the field.

---

### 🏗 FlNodeStyle (Node Appearance)

Controls the styling of nodes:

- **decoration**: Default node appearance.
- **headerStyleBuilder**: Customizable header style for different node states.

---

### 📌 FlNodeHeaderStyle (Node Header Styling)

Defines how the header of a node looks:

- **padding**: Internal spacing inside the header.
- **decoration**: Background style.
- **textStyle**: Font style for the header text.
- **icon**: Icon indicating collapse/expand state.

---

### 🖥 FlNodeEditorStyle (Editor Appearance)

Defines overall styling of the node editor:

- **decoration**: Background appearance.
- **padding**: Internal spacing within the editor.
- **gridStyle**: Grid appearance settings.

---

🚀 Happy coding with **FlNodes**! 🚀
