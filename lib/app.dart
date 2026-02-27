import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

class MyApp extends StatelessWidget {
  // Define the routes configuration
  final GoRouter _router = appRouter; // Use the exported router

  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fetch Data Example',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
