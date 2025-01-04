import 'package:flutter/material.dart';

/// Events are used to communicate between the [FlNodeEditorController] and the Widgets composing the Node Editor.
/// Events can (where applicable) carry data to be used by the Widgets to update their state.

/// Event base class for the [FlNodeEditorController] events bus.
class NodeEditorEvent {
  final bool isHandled;

  NodeEditorEvent({this.isHandled = false});
}

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

class SelectionAreaEvent extends NodeEditorEvent {
  final Rect area;

  SelectionAreaEvent(this.area);
}

class DragSelectionEvent extends NodeEditorEvent {
  final Set<String> ids;
  final Offset delta;

  DragSelectionEvent(this.ids, this.delta);
}

class SelectionEvent extends NodeEditorEvent {
  final Set<String> ids;

  SelectionEvent(this.ids);
}

class AddNodeEvent extends NodeEditorEvent {
  final String id;

  AddNodeEvent(this.id);
}

class RemoveNodeEvent extends NodeEditorEvent {
  final String id;

  RemoveNodeEvent(this.id);
}

class AddLinkEvent extends NodeEditorEvent {
  final String id;

  AddLinkEvent(this.id);
}

class DrawTempLinkEvent extends NodeEditorEvent {
  final Offset from;
  final Offset to;

  DrawTempLinkEvent(this.from, this.to);
}

class RemoveLinksEvent extends NodeEditorEvent {
  final String id;

  RemoveLinksEvent(this.id);
}

class CollapseNodeEvent extends NodeEditorEvent {
  final String id;

  CollapseNodeEvent(this.id);
}

class ExpandNodeEvent extends NodeEditorEvent {
  final String id;

  ExpandNodeEvent(this.id);
}
