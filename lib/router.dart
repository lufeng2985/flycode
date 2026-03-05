import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/project_list_page.dart';
import 'pages/settings_page.dart';
import 'pages/server_config_page.dart';
import 'pages/model_config_page.dart';
import 'widgets/scaffold_with_nav_bar.dart';
import 'models/server_config.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const MyHomePage(title: '首页'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings/server',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final config = state.extra as ServerConfig?;
        return ServerConfigPage(initialConfig: config);
      },
    ),
    GoRoute(
      path: '/settings/model',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ModelConfigPage(),
    ),
    GoRoute(
      path: '/projects',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProjectListPage(),
    ),
  ],
);
