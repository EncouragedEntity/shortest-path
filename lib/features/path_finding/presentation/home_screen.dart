import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit.dart';
import '../bloc/models.dart';
import 'constants.dart';
import 'process_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController(text: DEFAULT_LINK);

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _start() {
    final cubit = context.read<PathCubit>();
    if (!cubit.start(_urlController.text)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ProcessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen')),
      body: SafeArea(
        child: BlocBuilder<PathCubit, PathState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Set a valid API base URL in order to continue',
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'API URL',
                            prefixIcon: const Icon(Icons.link),
                            errorText: state.urlError,
                          ),
                          onChanged: (_) =>
                              context.read<PathCubit>().clearUrlError(),
                          onSubmitted: (_) => _start(),
                        ),
                        if (state.status == PathStatus.idle &&
                            state.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: state.isBusy ? null : _start,
                    child: const Text('Start'),
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
