import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/screens/home_screen.dart';
import '../features/basic_usage/screens/basic_usage_screen.dart';
import '../features/advanced_features/screens/advanced_features_screen.dart';
import '../features/stream_processing/screens/stream_processing_screen.dart';
import '../features/error_recovery/screens/error_recovery_screen.dart';
import '../features/performance/screens/performance_screen.dart';
import '../features/migration/screens/migration_screen.dart';
import '../features/playground/screens/playground_screen.dart';

/// Application router configuration using GoRouter
class AppRouter {
  AppRouter._();

  /// The main router configuration
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Basic Usage Demo
      GoRoute(
        path: '/basic-usage',
        name: 'basic-usage',
        builder: (context, state) => const BasicUsageScreen(),
      ),

      // Advanced Features Demo
      GoRoute(
        path: '/advanced-features',
        name: 'advanced-features',
        builder: (context, state) => const AdvancedFeaturesScreen(),
      ),

      // Stream Processing Demo
      GoRoute(
        path: '/stream-processing',
        name: 'stream-processing',
        builder: (context, state) => const StreamProcessingScreen(),
      ),

      // Error Recovery Demo
      GoRoute(
        path: '/error-recovery',
        name: 'error-recovery',
        builder: (context, state) => const ErrorRecoveryScreen(),
      ),

      // Performance Demo
      GoRoute(
        path: '/performance',
        name: 'performance',
        builder: (context, state) => const PerformanceScreen(),
      ),

      // Migration Demo
      GoRoute(
        path: '/migration',
        name: 'migration',
        builder: (context, state) => const MigrationScreen(),
      ),

      // Interactive Playground
      GoRoute(
        path: '/playground',
        name: 'playground',
        builder: (context, state) => const PlaygroundScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Navigation helper methods
extension AppRouterExtension on BuildContext {
  /// Navigate to home screen
  void goHome() => go('/');

  /// Navigate to basic usage demo
  void goToBasicUsage() => go('/basic-usage');

  /// Navigate to advanced features demo
  void goToAdvancedFeatures() => go('/advanced-features');

  /// Navigate to stream processing demo
  void goToStreamProcessing() => go('/stream-processing');

  /// Navigate to error recovery demo
  void goToErrorRecovery() => go('/error-recovery');

  /// Navigate to performance demo
  void goToPerformance() => go('/performance');

  /// Navigate to migration demo
  void goToMigration() => go('/migration');

  /// Navigate to interactive playground
  void goToPlayground() => go('/playground');
}

/// Route information for navigation menu
class RouteInfo {
  final String path;
  final String name;
  final String title;
  final String description;
  final IconData icon;
  final Color? color;

  const RouteInfo({
    required this.path,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
  });
}

/// Available routes for navigation
class AppRoutes {
  AppRoutes._();

  static const List<RouteInfo> demoRoutes = [
    RouteInfo(
      path: '/basic-usage',
      name: 'basic-usage',
      title: 'Basic Usage',
      description: 'Learn the fundamentals of Tryx error handling',
      icon: Icons.play_circle_outline,
      color: Colors.blue,
    ),
    RouteInfo(
      path: '/advanced-features',
      name: 'advanced-features',
      title: 'Advanced Features',
      description: 'Explore retry policies, timeouts, and error mapping',
      icon: Icons.settings,
      color: Colors.purple,
    ),
    RouteInfo(
      path: '/stream-processing',
      name: 'stream-processing',
      title: 'Stream Processing',
      description: 'Handle errors in reactive streams safely',
      icon: Icons.stream,
      color: Colors.teal,
    ),
    RouteInfo(
      path: '/error-recovery',
      name: 'error-recovery',
      title: 'Error Recovery',
      description: 'Circuit breakers, fallbacks, and recovery patterns',
      icon: Icons.healing,
      color: Colors.green,
    ),
    RouteInfo(
      path: '/performance',
      name: 'performance',
      title: 'Performance',
      description: 'Monitor and optimize error handling performance',
      icon: Icons.speed,
      color: Colors.orange,
    ),
    RouteInfo(
      path: '/migration',
      name: 'migration',
      title: 'Migration Guide',
      description: 'Migrate from try-catch to Tryx patterns',
      icon: Icons.transform,
      color: Colors.indigo,
    ),
    RouteInfo(
      path: '/playground',
      name: 'playground',
      title: 'Interactive Playground',
      description: 'Experiment with Tryx features in real-time',
      icon: Icons.code,
      color: Colors.red,
    ),
  ];
}
