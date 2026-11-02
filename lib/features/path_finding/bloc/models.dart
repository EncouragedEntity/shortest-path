import '../domain/path_models.dart';

enum PathStatus { idle, loading, calculating, ready, sending, submitted }

class PathState {
  const PathState({
    this.status = PathStatus.idle,
    this.progress = 0,
    this.results = const [],
    this.urlError,
    this.errorMessage,
  });

  final PathStatus status;
  final double progress;
  final List<PathResult> results;
  final String? urlError;
  final String? errorMessage;

  bool get isBusy =>
      status == PathStatus.loading ||
      status == PathStatus.calculating ||
      status == PathStatus.sending;
}
