import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Assume MyHomePage is accessible or we will update imports later
import 'app.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage(title: 'Flutter Demo Page (Router)');
      },
    ),
  ],
);
