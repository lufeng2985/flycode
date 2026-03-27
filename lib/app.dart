import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_lifecycle_provider.dart';
import 'providers/global_event_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'theme/theme_mode_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final GoRouter _router = appRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initialState = WidgetsBinding.instance.lifecycleState;
    if (initialState != null) {
      ref.read(appLifecycleStateProvider.notifier).setState(initialState);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleStateProvider.notifier).setState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(globalEventListenerProvider);
    ref.watch(appLifecycleStateProvider);
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
