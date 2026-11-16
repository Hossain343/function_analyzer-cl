import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'ui/watch_shell.dart';

void main() => runApp(const FunctionAnalyzerApp());

class FunctionAnalyzerApp extends StatelessWidget {
  const FunctionAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FunctionAnalyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(primary: AppColors.accent),
      ),
      home: const WatchShell(),
    );
  }
}
