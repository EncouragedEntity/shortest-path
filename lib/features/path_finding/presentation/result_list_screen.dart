import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit.dart';
import 'preview_screen.dart';

class ResultListScreen extends StatelessWidget {
  const ResultListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = context.select((PathCubit cubit) => cubit.state.results);

    return Scaffold(
      appBar: AppBar(title: const Text('Result list screen')),
      body: SafeArea(
        child: results.isEmpty
            ? const Center(child: Text('No results'))
            : ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      result.formattedPath,
                      textAlign: TextAlign.center,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PreviewScreen(result: result),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
