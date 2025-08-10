import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';
import 'core/theme.dart';
import 'core/tryx_config.dart';

void main() {
  // Configure Tryx globally for the demo app
  configureTryxForDemo();

  runApp(
    const ProviderScope(
      child: TryxDemoApp(),
    ),
  );
}

class TryxDemoApp extends StatelessWidget {
  const TryxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tryx Demo - Error Handling Made Simple',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
