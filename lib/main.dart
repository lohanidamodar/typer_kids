import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure imperative API calls (push, pushReplacement) update the browser URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

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
      child: MaterialApp.router(
        title: 'Typer Kids',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
