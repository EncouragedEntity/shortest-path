import 'package:flutter/material.dart';

import '../domain/path_models.dart';

class PathGrid extends StatefulWidget {
  const PathGrid({required this.result, super.key});

  static const cellSize = 64.0;
  final PathResult result;

  @override
  State<PathGrid> createState() => _PathGridState();
}

class _PathGridState extends State<PathGrid> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  late Set<GridPoint> _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.result.steps.toSet();
  }

  @override
  void didUpdateWidget(PathGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _steps = widget.result.steps.toSet();
    }
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.result.task;
    final size = task.field.length;

    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: size * PathGrid.cellSize,
          child: Scrollbar(
            controller: _vertical,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _vertical,
              itemExtent: PathGrid.cellSize,
              itemCount: size,
              itemBuilder: (context, y) {
                return Row(
                  children: [
                    for (var x = 0; x < size; x++)
                      _buildCell(task, GridPoint(x, y)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(PathTask task, GridPoint point) {
    final color = switch (point) {
      _ when point == task.start => const Color(0xFF64FFDA),
      _ when point == task.end => const Color(0xFF009688),
      _ when task.field[point.y][point.x] == 'X' => Colors.black,
      _ when _steps.contains(point) => const Color(0xFF4CAF50),
      _ => Colors.white,
    };

    return Container(
      width: PathGrid.cellSize,
      height: PathGrid.cellSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Text(
        '$point',
        style: TextStyle(
          color: color == Colors.black ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }
}
