import 'package:flutter/material.dart';

import '../domain/path_models.dart';
import 'path_grid.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({required this.result, super.key});

  final PathResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview screen')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridHeight = (result.task.field.length * PathGrid.cellSize)
                .clamp(0, constraints.maxHeight * 0.75)
                .toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: gridHeight,
                  child: PathGrid(result: result),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      result.formattedPath,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
