import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'models/chat_route_args.dart';
import 'pages/app_entry_page.dart';
import 'pages/file_content_page.dart';
import 'pages/home_page.dart';
import 'pages/project_list_page.dart';
import 'pages/session_context_page.dart';
import 'pages/session_diff_page.dart';
import 'pages/settings_page.dart';
import 'pages/theme_mode_page.dart';
import 'pages/server_config_page.dart';
import 'pages/model_config_page.dart';
import 'pages/sub_session_page.dart';
import 'models/server_config.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const AppEntryPage()),
    GoRoute(
      path: '/chat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as ChatRouteArgs?;
        return MyHomePage(title: '会话', args: args);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/settings/theme',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ThemeModePage(),
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
    GoRoute(
      path: '/diff',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionID = state.extra as String;
        return SessionDiffPage(sessionID: sessionID);
      },
    ),
    GoRoute(
      path: '/file',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final filePath = state.extra as String;
        return FileContentPage(filePath: filePath);
      },
    ),
    GoRoute(
      path: '/sub-session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionID = state.extra as String;
        return SubSessionPage(sessionID: sessionID);
      },
    ),
    GoRoute(
      path: '/session-context',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionID = state.extra as String;
        return SessionContextPage(sessionID: sessionID);
      },
    ),
  ],
);
