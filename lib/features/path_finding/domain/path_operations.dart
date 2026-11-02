import 'path_models.dart';

abstract interface class PathOperations {
  Future<List<PathTask>> loadTasks(Uri url);

  Future<List<PathResult>> calculatePaths(
    List<PathTask> tasks,
    void Function(double progress) onProgress,
  );

  Future<void> sendResults(Uri url, List<PathResult> results);
}

class PathOperationException implements Exception {
  const PathOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
