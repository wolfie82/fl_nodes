import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'dotted_grid.dart';

class NodeEditorWidget extends StatefulWidget {
  final bool expandToParent;
  final Size? fixedSize;

  const NodeEditorWidget({
    super.key,
    this.expandToParent = true,
    this.fixedSize,
  }) : assert(
          expandToParent || fixedSize != null,
          'If expandToParent is false, a fixedSize must be provided.',
        );

  @override
  State<NodeEditorWidget> createState() => _NodeEditorWidgetState();
}

class _NodeEditorWidgetState extends State<NodeEditorWidget>
    with SingleTickerProviderStateMixin {
  Offset _gridOffset = Offset.zero;
  double _zoom = 1.0;
  late AnimationController _animationController;
  late Animation<Offset> _centerGridAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _centerGrid() {
    _animationController.reset();

    final distance = (_gridOffset - Offset.zero).distance;

    final durationFactor = (distance / 1000).clamp(0.5, 3.0);
    _animationController.duration = Duration(
      milliseconds: (1000 * durationFactor).toInt(),
    );

    _centerGridAnimation = Tween<Offset>(
      begin: _gridOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _gridOffset = _centerGridAnimation.value;
        });
      });

    _animationController.forward();
  }

  void _zoomIn() {
    final initialScale = _zoom; // Save current scale
    final targetScale = _zoom * 1.5; // Define target scale

    _animationController.reset();
    _animationController.duration = const Duration(milliseconds: 200);

    _zoomAnimation = Tween<double>(
      begin: initialScale,
      end: targetScale,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _zoom = _zoomAnimation.value; // Update scale during animation
        });
      });

    _animationController.forward();
  }

  void _zoomOut() {
    final initialScale = _zoom; // Save current scale
    final targetScale = _zoom / 1.5; // Define target scale

    _animationController.reset();
    _animationController.duration = const Duration(milliseconds: 200);

    _zoomAnimation = Tween<double>(
      begin: initialScale,
      end: targetScale,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _zoom = _zoomAnimation.value; // Update scale during animation
        });
      });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Widget editor = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _gridOffset += details.delta / _zoom;

              const maxOffset = 10000.0;

              _gridOffset = Offset(
                _gridOffset.dx.clamp(-maxOffset, maxOffset),
                _gridOffset.dy.clamp(-maxOffset, maxOffset),
              );
            });
          },
          child: ClipRect(
            child: Stack(
              children: [
                DottedGridWidget(
                  offset: _gridOffset,
                  scale: _zoom,
                  dotColor: Colors.grey[300]!,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _centerGrid,
                        icon: const Icon(
                          Icons.center_focus_strong,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _zoomIn,
                        icon: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _zoomOut,
                        icon: const Icon(
                          Icons.zoom_out,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'X: ${_gridOffset.dx.toStringAsFixed(2)}, Y: ${_gridOffset.dy.toStringAsFixed(2)}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Zoom: ${_zoom.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.expandToParent) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: editor,
          );
        },
      );
    } else {
      return SizedBox(
        width: widget.fixedSize?.width ?? 100,
        height: widget.fixedSize?.height ?? 100,
        child: editor,
      );
    }
  }
}
