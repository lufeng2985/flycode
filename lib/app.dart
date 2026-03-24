import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'theme/theme_mode_provider.dart';

class MyApp extends ConsumerWidget {
  // Define the routes configuration
  final GoRouter _router = appRouter; // Use the exported router

  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fetch Data Example',
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode.toThemeMode(),
      debugShowCheckedModeBanner: false,
    );
  }
}
