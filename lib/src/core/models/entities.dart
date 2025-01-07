import 'package:fl_nodes/src/core/utils/serialization.dart';
import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

/// Entities are split in two categories: Prototypes and Instances.
///
/// Prototypes are the blueprint for the instances. They define the structure
/// of the instances, like the name, description, color, ports, etc.
/// Instances are the actual objects that are created based on the prototypes
/// and hold the data and state of the application.

/// A group is a collection of nodes that are visually grouped together.
final class Group {
  final String name;
  final String description;
  final Color color;
  final Rect area;

  Group({
    required this.name,
    this.description = '',
    this.color = Colors.grey,
    required this.area,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': colorToRGBAString(color),
      'area': [area.left, area.top, area.width, area.height],
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['name'],
      description: json['description'],
      color: colorFromRGBAString(json['color']),
      area: Rect.fromLTWH(
        json['area'][0],
        json['area'][1],
        json['area'][2],
        json['area'][3],
      ),
    );
  }
}

/// A link is a connection between two ports.
final class Link {
  final String id;
  final Tuple4<String, String, String, String> fromTo;

  Link({
    required this.id,
    required this.fromTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': fromTo.item1,
      'to': fromTo.item2,
      'fromPort': fromTo.item3,
      'toPort': fromTo.item4,
    };
  }

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: const Uuid().v4(),
      fromTo: Tuple4(
        json['from'],
        json['to'],
        json['fromPort'],
        json['toPort'],
      ),
    );
  }
}

/// A port prototype is the blueprint for a port instance.
///
/// It defines the name, data type, direction, and if it allows multiple links.
final class PortPrototype {
  final String name;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;

  PortPrototype({
    required this.name,
    this.dataType = dynamic,
    this.isInput = true,
    this.allowMultipleLinks = true,
  });
}

/// A port is a connection point on a node.
///
/// In addition to the prototype, it holds the data, links, and offset.
final class Port {
  final String id;
  final String name;
  final dynamic data;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;
  List<Link> links = [];
  Offset offset;
  final GlobalKey key = GlobalKey();

  Port({
    required this.id,
    required this.name,
    required this.data,
    required this.dataType,
    required this.isInput,
    required this.allowMultipleLinks,
    this.offset = Offset.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dataType': dataType.toString(),
      'isInput': isInput,
      'allowMultipleLinks': allowMultipleLinks,
      'links': links.map((link) => link.id).toList(),
    };
  }

  factory Port.fromJson(Map<String, dynamic> json, PortPrototype prototype) {
    final port = Port(
      id: const Uuid().v4(),
      name: json['name'],
      data: null,
      dataType: prototype.dataType,
      isInput: prototype.isInput,
      allowMultipleLinks: prototype.allowMultipleLinks,
    );

    if (json['links'] != null) {
      port.links = List<Link>.from(
        json['links'].map((linkId) => Link.fromJson(linkId)),
      );
    }

    return port;
  }
}

/// A field prototype is the blueprint for a field instance.
///
/// It is used to store variables for use in the onExecute function of a node.
/// If explicitly allowed, the user can change the value of the field.
class FieldPrototype {
  final String name;
  final Type dataType;
  final bool isEditable;

  FieldPrototype({
    required this.name,
    required this.dataType,
    this.isEditable = false,
  });
}

/// A field is a variable that can be used in the onExecute function of a node.
///
/// In addition to the prototype, it holds the data.
class Field {
  final String id;
  final String name;
  final bool isEditable;
  final dynamic data;
  final Type dataType;
  final GlobalKey key = GlobalKey();

  Field({
    required this.id,
    required this.name,
    required this.isEditable,
    required this.data,
    required this.dataType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isEditable': isEditable,
      'data': data,
      'dataType': dataType.toString(),
    };
  }

  factory Field.fromJson(Map<String, dynamic> json, FieldPrototype prototype) {
    return Field(
      id: const Uuid().v4(),
      name: json['name'],
      isEditable: prototype.isEditable,
      data: json['data'],
      dataType: prototype.dataType,
    );
  }
}

/// A node prototype is the blueprint for a node instance.
///
/// It defines the name, description, color, ports, fields, and onExecute function.
final class NodePrototype {
  final String name;
  final String description;
  final Color color;
  final List<PortPrototype> ports;
  final List<FieldPrototype> fields;
  final void Function(List<String> inputIds, List<String> outputIds) onExecute;

  NodePrototype({
    required this.name,
    this.description = '',
    this.color = Colors.grey,
    this.ports = const [],
    this.fields = const [],
    required this.onExecute,
  });
}

/// The state of a node widget.
final class NodeState {
  bool isSelected;
  bool isCollapsed;

  NodeState({
    this.isSelected = false,
    this.isCollapsed = false,
  });
}

/// A node is a component in the node editor.
///
/// It holds the instances of the ports and fields, the offset, the data and the state.
final class Node {
  final String id;
  final String name;
  final String description;
  final Color color;
  final Map<String, Port> ports;
  final Map<String, Field> fields;
  final Function(List<String> inputIds, List<String> outputIds) onExecute;
  final void Function(Node node) onRendered;
  Offset offset;
  final NodeState state = NodeState();
  final GlobalKey key = GlobalKey();

  Node({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.ports,
    required this.fields,
    required this.onExecute,
    required this.onRendered,
    this.offset = Offset.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'ports': ports.map((portId, port) => MapEntry(portId, port.toJson())),
      'fields':
          fields.map((fieldId, field) => MapEntry(fieldId, field.toJson())),
      'offset': [offset.dx, offset.dy],
    };
  }

  factory Node.fromJson(
    Map<String, dynamic> json,
    NodePrototype prototype, {
    required void Function(Node node) onRendered,
  }) {
    return Node(
      id: const Uuid().v4(),
      name: json['name'],
      description: prototype.description,
      color: prototype.color,
      ports: json['ports'].map((portId, portJson) {
        final portPrototype = prototype.ports.firstWhere(
          (port) => port.name == portJson['name'],
        );
        return MapEntry(portId, Port.fromJson(portJson, portPrototype));
      }),
      fields: json['fields'].map((fieldId, fieldJson) {
        final fieldPrototype = prototype.fields.firstWhere(
          (field) => field.name == fieldJson['name'],
        );
        return MapEntry(fieldId, Field.fromJson(fieldJson, fieldPrototype));
      }),
      onExecute: prototype.onExecute,
      onRendered: onRendered,
      offset: Offset(json['offset'][0], json['offset'][1]),
    );
  }
}

Port createPort(PortPrototype prototype) {
  return Port(
    id: const Uuid().v4(),
    name: prototype.name,
    data: null,
    dataType: prototype.dataType,
    isInput: prototype.isInput,
    allowMultipleLinks: prototype.allowMultipleLinks,
  );
}

Field createField(FieldPrototype prototype) {
  return Field(
    id: const Uuid().v4(),
    name: prototype.name,
    isEditable: prototype.isEditable,
    data: null,
    dataType: prototype.dataType,
  );
}

Node createNode(
  NodePrototype prototype, {
  Offset? offset,
  required void Function(Node node) onRendered,
}) {
  return Node(
    id: const Uuid().v4(),
    name: prototype.name,
    description: prototype.description,
    color: prototype.color,
    ports: prototype.ports.asMap().map((_, portPrototype) {
      final port = createPort(portPrototype);
      return MapEntry(port.id, port);
    }),
    fields: prototype.fields.asMap().map((_, fieldPrototype) {
      final field = createField(fieldPrototype);
      return MapEntry(field.id, field);
    }),
    onExecute: prototype.onExecute,
    onRendered: onRendered,
    offset: offset ?? Offset.zero,
  );
}
