import 'package:flutter/material.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';

bool isContextMenuVisible = false;

Future createAndShowContextMenu(
  BuildContext context,
  List<ContextMenuEntry> entries,
  Offset position,
) {
  if (isContextMenuVisible) return Future.value();

  isContextMenuVisible = true;

  final menu = ContextMenu(
    entries: entries,
    position: position,
    padding: const EdgeInsets.all(8.0),
  );

  return showContextMenu(context, contextMenu: menu).then((value) {
    isContextMenuVisible = false;
  });
}
