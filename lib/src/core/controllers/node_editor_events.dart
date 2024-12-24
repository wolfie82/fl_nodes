import 'package:flutter/material.dart';

class NodeEditorEvent {}

class ViewportOffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  ViewportOffsetEvent(this.offset, {this.animate = true});
}

class ViewportZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  ViewportZoomEvent(
    this.zoom, {
    this.animate = true,
  });
}

class DragNodeEvent extends NodeEditorEvent {
  final String id;

  DragNodeEvent(this.id);
}

class SelectNodeEvent extends NodeEditorEvent {
  final List<String> ids;

  SelectNodeEvent(this.ids);
}

class CollapseNodeEvent extends NodeEditorEvent {
  final String id;

  CollapseNodeEvent(this.id);
}
