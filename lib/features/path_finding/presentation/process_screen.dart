import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit.dart';
import '../bloc/models.dart';
import 'result_list_screen.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleState(context.read<PathCubit>().state);
    });
  }

  void _handleState(PathState state) {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    if (state.status == PathStatus.submitted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ResultListScreen()),
      );
    } else if (state.status == PathStatus.idle && state.errorMessage != null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop &&
            context.read<PathCubit>().state.status != PathStatus.submitted) {
          context.read<PathCubit>().cancel();
        }
      },
      child: BlocConsumer<PathCubit, PathState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) => _handleState(state),
        builder: (context, state) {
          final loading = state.status == PathStatus.loading;
          final sending = state.status == PathStatus.sending;
          final finished =
              state.status == PathStatus.ready ||
              sending ||
              state.status == PathStatus.submitted;
          final percentage = (state.progress * 100).round();

          return Scaffold(
            appBar: AppBar(title: const Text('Process screen')),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: (constraints.maxWidth - 48).clamp(
                                0,
                                double.infinity,
                              ),
                              minHeight: (constraints.maxHeight - 48).clamp(
                                0,
                                double.infinity,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loading
                                      ? 'Loading tasks...'
                                      : finished
                                      ? 'All calculations have finished. You can send your results to the server.'
                                      : 'Calculating the shortest paths...',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 20),
                                if (!loading) ...[
                                  Text(
                                    '$percentage%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                SizedBox.square(
                                  dimension: 96,
                                  child: CircularProgressIndicator(
                                    value: loading ? null : state.progress,
                                  ),
                                ),
                                if (state.errorMessage != null) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    state.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (finished)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: state.status == PathStatus.ready
                            ? context.read<PathCubit>().sendResults
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (sending) ...[
                              const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Flexible(
                              child: Text(
                                'Send results to server',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
