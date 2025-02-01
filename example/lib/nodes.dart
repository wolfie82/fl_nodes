import 'dart:math';

import 'package:flutter/material.dart';

import 'package:fl_nodes/fl_nodes.dart';

enum Operator { add, subtract, multiply, divide }

void registerNodes(BuildContext context, FlNodeEditorController controller) {
  controller.registerNodePrototype(
    NodePrototype(
      name: 'Operator',
      description: 'Applies a chosen operation to two numbers.',
      color: Colors.yellow,
      allowRecursion: false,
      ports: [
        InputPortPrototype(name: 'A', dataType: double),
        InputPortPrototype(name: 'B', dataType: double),
        OutputPortPrototype(name: 'Result', dataType: double),
      ],
      fields: [
        FieldPrototype(
          name: 'Operation',
          dataType: Operator,
          defaultData: Operator.add,
          visualizerBuilder: (data) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              data.toString().split('.').last,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              SegmentedButton<Operator>(
            segments: const [
              ButtonSegment(value: Operator.add, label: Text('Add')),
              ButtonSegment(value: Operator.subtract, label: Text('Subtract')),
              ButtonSegment(value: Operator.multiply, label: Text('Multiply')),
              ButtonSegment(value: Operator.divide, label: Text('Divide')),
            ],
            selected: {data as Operator},
            onSelectionChanged: (newSelection) {
              setData(newSelection.first, eventType: FieldEventType.submit);
              removeOverlay();
            },
            direction: Axis.horizontal,
          ),
        ),
      ],
      onExecute: (ports, fields) async {
        final a = ports['A']?.data as double;
        final b = ports['B']?.data as double;
        final op = fields['Operation']?.data as Operator;
        switch (op) {
          case Operator.add:
            ports['Result']!.data = a + b;
            break;
          case Operator.subtract:
            ports['Result']!.data = a - b;
            break;
          case Operator.multiply:
            ports['Result']!.data = a * b;
            break;
          case Operator.divide:
            ports['Result']!.data = b == 0 ? 0 : a / b;
            break;
        }
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      name: 'Random',
      description: 'Outputs a random number between 0 and 1.',
      color: Colors.purple,
      allowRecursion: false,
      ports: [
        OutputPortPrototype(name: 'Value', dataType: double),
      ],
      onExecute: (ports, fields) async {
        ports['Value']!.data = Random().nextDouble();
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      name: 'Value',
      description: 'Holds a constant double value.',
      color: Colors.orange,
      allowRecursion: false,
      ports: [
        OutputPortPrototype(name: 'Value', dataType: double),
      ],
      fields: [
        FieldPrototype(
          name: 'Value',
          dataType: double,
          visualizerBuilder: (data) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              data.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: TextFormField(
              initialValue: data.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setData(
                  double.tryParse(value) ?? 0.0,
                  eventType: FieldEventType.change,
                );
              },
              onFieldSubmitted: (value) {
                setData(
                  double.tryParse(value) ?? 0.0,
                  eventType: FieldEventType.submit,
                );
                removeOverlay();
              },
            ),
          ),
        ),
      ],
      onExecute: (ports, fields) async {
        ports['Value']!.data = fields['Value']!.data as double;
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      name: 'Output',
      description: 'Outputs a value.',
      color: Colors.red,
      allowRecursion: false,
      ports: [
        InputPortPrototype(
          name: 'Value',
          dataType: double,
        ),
      ],
      onExecute: (ports, fields) async {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Output'),
              content: Text('Output: ${ports['Value']!.data}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      name: 'Round',
      description: 'Rounds a number to a specified number of decimals.',
      color: Colors.blue,
      allowRecursion: false,
      ports: [
        InputPortPrototype(name: 'Value', dataType: double),
        OutputPortPrototype(name: 'Rounded', dataType: int),
      ],
      fields: [
        FieldPrototype(
          name: 'Decimals',
          dataType: int,
          defaultData: 2,
          visualizerBuilder: (data) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              data.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: TextFormField(
              initialValue: data.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setData(
                  int.tryParse(value) ?? 0,
                  eventType: FieldEventType.change,
                );
              },
              onFieldSubmitted: (value) {
                setData(
                  int.tryParse(value) ?? 0,
                  eventType: FieldEventType.submit,
                );
                removeOverlay();
              },
            ),
          ),
        ),
      ],
      onExecute: (ports, fields) async {
        final double value = ports['Value']!.data as double;
        final int decimals = fields['Decimals']!.data as int;

        ports['Rounded']!.data = double.parse(value.toStringAsFixed(decimals));
      },
    ),
  );
}
