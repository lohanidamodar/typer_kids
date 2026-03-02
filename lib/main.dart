import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/profile_provider.dart';
import 'providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure imperative API calls (push, pushReplacement) update the browser URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Initialize providers before app starts
  final profileProvider = ProfileProvider();
  await profileProvider.init();

  final progressProvider = ProgressProvider();
  // Load SharedPreferences instance, then load data for the active profile
  await progressProvider.init(profileId: profileProvider.activeProfileId ?? '');

  runApp(
    TyperKidsApp(
      profileProvider: profileProvider,
      progressProvider: progressProvider,
    ),
  );
}

class TyperKidsApp extends StatelessWidget {
  final ProfileProvider profileProvider;
  final ProgressProvider progressProvider;

  const TyperKidsApp({
    super.key,
    required this.profileProvider,
    required this.progressProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider.value(value: progressProvider),
      ],
      child: MaterialApp.router(
        title: 'Typer Kids',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: AppRouter.router(profileProvider),
      ),
    );
  }
}
