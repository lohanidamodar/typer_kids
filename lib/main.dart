import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/progress_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize progress provider before app starts
  final progressProvider = ProgressProvider();
  await progressProvider.init();

  runApp(TyperKidsApp(progressProvider: progressProvider));
}

class TyperKidsApp extends StatelessWidget {
  final ProgressProvider progressProvider;

  const TyperKidsApp({super.key, required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: progressProvider,
      child: MaterialApp(
        title: 'Typer Kids',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
