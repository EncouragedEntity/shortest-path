class GridPoint {
  const GridPoint(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is GridPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x.$y)';
}

class PathTask {
  PathTask({
    required this.id,
    required List<String> field,
    required this.start,
    required this.end,
  }) : field = List.unmodifiable(field);

  final String id;
  final List<String> field;
  final GridPoint start;
  final GridPoint end;
}

class PathResult {
  PathResult({required this.task, required List<GridPoint> steps})
    : steps = List.unmodifiable(steps);

  final PathTask task;
  final List<GridPoint> steps;

  String get formattedPath =>
      steps.isEmpty ? 'No path found' : steps.join(' -> ');
}
