import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/path_operations.dart';
import 'models.dart';

class PathCubit extends Cubit<PathState> {
  PathCubit(this._operations) : super(const PathState());

  final PathOperations _operations;
  Uri? _url;
  int _run = 0;

  void reset() => emit(const PathState());

  bool start(String input) {
    if (isClosed || state.isBusy) return false;

    final value = input.trim();
    final url = Uri.tryParse(value);

    if (url == null ||
        (url.scheme != 'http' && url.scheme != 'https') ||
        url.host.isEmpty ||
        RegExp(r'\s').hasMatch(value)) {
      emit(
        const PathState(
          urlError: 'Enter a valid HTTP or HTTPS URL with a host.',
        ),
      );
      return false;
    }

    _url = url;
    final run = ++_run;

    emit(const PathState(status: PathStatus.loading));
    unawaited(_loadAndCalculate(url, run));

    return true;
  }

  void clearUrlError() {
    if (!isClosed && state.status == PathStatus.idle) reset();
  }

  Future<void> _loadAndCalculate(Uri url, int run) async {
    var failureMessage = 'Could not load tasks. Please try again.';
    try {
      final tasks = await _operations.loadTasks(url);
      if (!_isCurrent(run)) return;

      if (tasks.isEmpty) {
        emit(const PathState(status: PathStatus.submitted, progress: 1));
        return;
      }

      failureMessage = 'Could not calculate paths. Please try again.';
      emit(const PathState(status: PathStatus.calculating));
      final results = await _operations.calculatePaths(tasks, (progress) {
        if (_isCurrent(run) &&
            state.status == PathStatus.calculating &&
            progress.isFinite) {
          emit(
            PathState(
              status: PathStatus.calculating,
              progress: progress.clamp(0, 1).toDouble(),
            ),
          );
        }
      });
      if (!_isCurrent(run)) return;

      emit(
        PathState(
          status: PathStatus.ready,
          progress: 1,
          results: List.unmodifiable(results),
        ),
      );
    } catch (error) {
      if (_isCurrent(run)) {
        emit(
          PathState(
            errorMessage: error is PathOperationException
                ? error.message
                : failureMessage,
          ),
        );
      }
    }
  }

  Future<void> sendResults() async {
    if (isClosed || state.status != PathStatus.ready) return;

    final url = _url;
    if (url == null) return;

    final run = _run;
    final results = state.results;
    emit(PathState(status: PathStatus.sending, progress: 1, results: results));
    try {
      await _operations.sendResults(url, results);
      if (!_isCurrent(run)) return;

      emit(
        PathState(status: PathStatus.submitted, progress: 1, results: results),
      );
    } catch (error) {
      if (_isCurrent(run)) {
        emit(
          PathState(
            status: PathStatus.ready,
            progress: 1,
            results: results,
            errorMessage: error is PathOperationException
                ? error.message
                : 'Could not send results. Please try again.',
          ),
        );
      }
    }
  }

  void cancel() {
    if (isClosed) return;

    _run++;
    if (state.status != PathStatus.idle) reset();
  }

  bool _isCurrent(int run) => !isClosed && run == _run;
}
