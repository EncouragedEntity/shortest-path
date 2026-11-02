import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../domain/path_models.dart';
import '../domain/path_operations.dart';
import '../domain/shortest_path_solver.dart';

class ApiPathOperations implements PathOperations {
  const ApiPathOperations();

  static const _timeout = Duration(seconds: 30);

  @override
  Future<List<PathTask>> loadTasks(Uri url) async {
    final data = await _request(url);
    final Set<PathTask> tasks = {};

    for (final item in data) {
      final task = _parseTask(item);

      tasks.add(task);
    }

    return List.unmodifiable(tasks);
  }

  @override
  Future<List<PathResult>> calculatePaths(
    List<PathTask> tasks,
    void Function(double progress) onProgress,
  ) async {
    onProgress(0);
    final results = <PathResult>[];
    for (final task in tasks) {
      results.add(await _solveTask(task));
      onProgress(results.length / tasks.length);
    }
    if (tasks.isEmpty) onProgress(1);
    return List.unmodifiable(results);
  }

  @override
  Future<void> sendResults(Uri url, List<PathResult> results) async {
    if (results.isEmpty) return;

    final body = [
      for (final result in results)
        {
          'id': result.task.id,
          'result': {
            'steps': result.steps.isEmpty
                ? null
                : [
                    for (final point in result.steps)
                      {'x': point.x, 'y': point.y},
                  ],
            'path': result.steps.isEmpty
                ? null
                : result.steps
                      .map((point) => '(${point.x},${point.y})')
                      .join('->'),
          },
        },
    ];
    final data = await _request(url, body: body);
    final expected = results.map((result) => result.task.id).toSet();
    final confirmed = <String>{};
    final rejected = <String>[];
    for (final item in data) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          item['correct'] is! bool ||
          !expected.contains(item['id']) ||
          !confirmed.add(item['id'] as String)) {
        throw const PathOperationException(
          'The server returned an invalid result confirmation.',
        );
      }
      if (item['correct'] == false) rejected.add(item['id'] as String);
    }
    if (confirmed.length != expected.length) {
      throw const PathOperationException(
        'The server did not confirm every result. Please try again.',
      );
    }
    if (rejected.isNotEmpty) {
      throw PathOperationException(
        'The server rejected results for: ${rejected.join(', ')}.',
      );
    }
  }

  Future<List<dynamic>> _request(
    Uri url, {
    List<Map<String, Object?>>? body,
  }) async {
    final client = http.Client();

    try {
      final headers = {
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };

      final response =
          await (body == null
                  ? client.get(url, headers: headers)
                  : client.post(url, headers: headers, body: jsonEncode(body)))
              .timeout(_timeout);

      final successful =
          response.statusCode >= 200 && response.statusCode < 300;

      Object? decoded;

      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (!successful) throw _httpError(response, null);
        throw const PathOperationException('The server returned invalid JSON.');
      }

      final document = decoded is Map<String, dynamic> ? decoded : null;
      if (!successful) throw _httpError(response, document);
      if (document == null || document['error'] is! bool) {
        throw const PathOperationException(
          'The server returned an invalid response.',
        );
      }
      if (document['error'] == true) {
        throw PathOperationException(_message(document, 'The request failed.'));
      }

      final data = document['data'];
      if (data is! List) {
        throw const PathOperationException(
          'The server returned an invalid data list.',
        );
      }
      return data;
    } on TimeoutException {
      throw const PathOperationException(
        'The request timed out after 30 seconds. Please try again.',
      );
    } on http.ClientException {
      throw const PathOperationException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } finally {
      client.close();
    }
  }

  PathOperationException _httpError(
    http.Response response,
    Map<String, dynamic>? document,
  ) {
    final message = _message(document, 'The request failed');
    final retryAfter = response.headers['retry-after'];
    final retry = response.statusCode == 429 && retryAfter != null
        ? ' Retry after: $retryAfter.'
        : '';
    final data = document?['data'];
    final rejected = data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .where((item) => item['correct'] == false)
              .map((item) => item['id'])
              .whereType<String>()
              .toList()
        : <String>[];
    final details = rejected.isEmpty
        ? ''
        : ' Rejected task IDs: ${rejected.join(', ')}.';
    return PathOperationException(
      '$message (HTTP ${response.statusCode}).$retry$details',
    );
  }

  String _message(Map<String, dynamic>? document, String fallback) {
    final message = document?['message'];
    return message is String && message.trim().isNotEmpty ? message : fallback;
  }

  PathTask _parseTask(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const PathOperationException(
        'The server returned an invalid task.',
      );
    }

    final id = value['id'];
    final field = value['field'];
    if (id is! String ||
        id.trim().isEmpty ||
        field is! List ||
        field.length < 2 ||
        field.length > 99 ||
        field.any((row) => row is! String)) {
      throw const PathOperationException(
        'The server returned an invalid task.',
      );
    }
    final rows = field.cast<String>();
    if (rows.any(
      (row) => row.length != rows.length || !RegExp(r'^[.X]+$').hasMatch(row),
    )) {
      throw PathOperationException('Task $id contains an invalid grid.');
    }
    final start = _parsePoint(value['start'], rows.length, id);
    final end = _parsePoint(value['end'], rows.length, id);
    if (rows[start.y][start.x] == 'X' || rows[end.y][end.x] == 'X') {
      throw PathOperationException('Task $id has a blocked start or end cell.');
    }
    return PathTask(id: id, field: rows, start: start, end: end);
  }

  GridPoint _parsePoint(Object? value, int size, String id) {
    if (value is Map<String, dynamic>) {
      final x = value['x'];
      final y = value['y'];
      if (x is int && y is int && x >= 0 && y >= 0 && x < size && y < size) {
        return GridPoint(x, y);
      }
    }
    throw PathOperationException('Task $id contains invalid coordinates.');
  }
}

Future<PathResult> _solveTask(PathTask task) {
  return Isolate.run(() => const ShortestPathSolver().solve(task));
}
