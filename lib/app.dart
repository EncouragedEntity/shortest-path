import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/path_finding/bloc/cubit.dart';
import 'features/path_finding/domain/path_operations.dart';
import 'features/path_finding/presentation/home_screen.dart';

class WebsparkApp extends StatelessWidget {
  const WebsparkApp({required this.operations, super.key});

  final PathOperations operations;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2196F3);

    final colors = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
    ).copyWith(primary: blue, onPrimary: Colors.black);

    return BlocProvider(
      create: (_) => PathCubit(operations),
      child: MaterialApp(
        title: 'Webspark Test Task',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colors,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: blue,
            foregroundColor: Colors.black,
            centerTitle: false,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            errorMaxLines: 3,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
