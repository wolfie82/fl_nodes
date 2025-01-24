import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/fl_nodes.dart';

import '../../models/events.dart';
import '../../utils/snackbar.dart';

class FlNodeEditorProject {
  final FlNodeEditorController controller;

  bool _isSaved = true;
  bool get isSaved => _isSaved;

  Offset get viewportOffset => controller.viewportOffset;
  double get viewportZoom => controller.viewportZoom;

  final Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver;
  final Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader;
  final Future<bool> Function(bool isSaved)? projectCreator;

  FlNodeEditorProject(
    this.controller, {
    required this.projectSaver,
    required this.projectLoader,
    required this.projectCreator,
  }) {
    controller.eventBus.events.listen(_handleProjectEvents);
  }

  void clear() {
    controller.history.clear();

    _isSaved = true;
  }

  void _handleProjectEvents(NodeEditorEvent event) {
    if (event.isUndoable) _isSaved = false;

    if (event is SaveProjectEvent) {
      _isSaved = true;
    } else if (event is LoadProjectEvent) {
      _isSaved = true;
      controller.history.clear();
    } else if (event is NewProjectEvent) {
      controller.clear();
    }
  }

  Map<String, dynamic> _toJson() {
    final nodesJson =
        controller.nodes.values.map((node) => node.toJson()).toList();

    return {
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  void _fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return;

    final viewportJson = json['viewport'] as Map<String, dynamic>;

    controller.setViewportOffset(
      Offset(
        viewportJson['offset'][0] as double,
        viewportJson['offset'][1] as double,
      ),
      absolute: true,
    );

    controller.setViewportZoom(viewportJson['zoom'] as double);

    final nodesJson = json['nodes'] as List<dynamic>;

    final node = nodesJson.map((node) {
      return NodeInstance.fromJson(
        node,
        prototypes: controller.nodePrototypes,
        onRendered: controller.onRenderedCallback,
      );
    }).toSet();

    for (final node in node) {
      controller.addNodeFromExisting(node, isHandled: true);
    }
  }

  void saveProject() async {
    final jsonData = _toJson();
    if (jsonData.isEmpty) return;

    final hasSaved = await projectSaver?.call(jsonData);
    if (hasSaved == false) return;

    _isSaved = true;

    controller.eventBus.emit(SaveProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'Project saved successfully.',
      SnackbarType.success,
    );
  }

  void loadProject() async {
    final jsonData = await projectLoader?.call(isSaved);

    if (jsonData == null) {
      showNodeEditorSnackbar(
        'Failed to load project. Invalid project data.',
        SnackbarType.error,
      );
      return;
    }

    controller.clear();

    _fromJson(jsonData);

    controller.eventBus.emit(LoadProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'Project loaded successfully.',
      SnackbarType.success,
    );
  }

  void newProject() async {
    final shouldProceed = await projectCreator?.call(isSaved);

    if (shouldProceed == false) return;

    controller.eventBus.emit(NewProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'New project created successfully.',
      SnackbarType.success,
    );
  }
}
