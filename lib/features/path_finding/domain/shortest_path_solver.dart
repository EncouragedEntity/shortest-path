import 'path_models.dart';

class ShortestPathSolver {
  const ShortestPathSolver();

  static const _directions = [
    (0, -1),
    (1, 0),
    (0, 1),
    (-1, 0),
    (1, -1),
    (1, 1),
    (-1, 1),
    (-1, -1),
  ];

  PathResult solve(PathTask task) {
    final size = task.field.length;
    final start = task.start.y * size + task.start.x;
    final end = task.end.y * size + task.end.x;
    final previous = List<int>.filled(size * size, -1);
    previous[start] = start;
    final queue = <int>[start];

    for (var head = 0; head < queue.length && previous[end] == -1; head++) {
      final current = queue[head];
      for (final (dx, dy) in _directions) {
        final x = current % size + dx;
        final y = current ~/ size + dy;
        if (x < 0 ||
            y < 0 ||
            x >= size ||
            y >= size ||
            task.field[y][x] == 'X') {
          continue;
        }

        final next = y * size + x;
        if (previous[next] != -1) continue;
        previous[next] = current;
        queue.add(next);
      }
    }

    if (previous[end] == -1) return PathResult(task: task, steps: const []);

    final steps = <GridPoint>[];
    for (var point = end; ; point = previous[point]) {
      steps.add(GridPoint(point % size, point ~/ size));
      if (point == start) break;
    }

    return PathResult(task: task, steps: steps.reversed.toList());
  }
}
