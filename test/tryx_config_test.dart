import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('TryxConfig', () {
    setUp(TryxConfig.reset);

    tearDown(TryxConfig.reset);

    group('Basic Configuration', () {
      test('should have default values after reset', () {
        TryxConfig.reset();
        final config = TryxConfig.instance;

        expect(config.defaultRetryPolicy, isNull);
        expect(config.enableGlobalLogging, isFalse);
        expect(config.logLevel, equals(LogLevel.error));
        expect(config.globalErrorMapper, isNull);
        expect(config.globalTimeout, isNull);
        expect(config.includeStackTraces, isTrue);
        expect(config.customLogger, isNull);
        expect(config.globalErrorHandler, isNull);
        expect(config.enablePerformanceMonitoring, isFalse);
        expect(
          config.slowOperationThreshold,
          equals(const Duration(seconds: 1)),
        );
      });

      test('should configure default retry policy', () {
        const policy = RetryPolicies.network;
        TryxConfig.configure(defaultRetryPolicy: policy);

        expect(TryxConfig.instance.defaultRetryPolicy, equals(policy));
      });

      test('should configure global logging', () {
        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          includeStackTraces: false,
        );

        final config = TryxConfig.instance;
        expect(config.enableGlobalLogging, isTrue);
        expect(config.logLevel, equals(LogLevel.debug));
        expect(config.includeStackTraces, isFalse);
      });

      test('should configure global error mapper', () {
        String errorMapper(Object error) => 'Mapped: $error';
        TryxConfig.configure(globalErrorMapper: errorMapper);

        expect(TryxConfig.instance.globalErrorMapper, equals(errorMapper));
      });

      test('should configure global timeout', () {
        const timeout = Duration(seconds: 30);
        TryxConfig.configure(globalTimeout: timeout);

        expect(TryxConfig.instance.globalTimeout, equals(timeout));
      });

      test('should configure performance monitoring', () {
        const threshold = Duration(milliseconds: 500);
        TryxConfig.configure(
          enablePerformanceMonitoring: true,
          slowOperationThreshold: threshold,
        );

        final config = TryxConfig.instance;
        expect(config.enablePerformanceMonitoring, isTrue);
        expect(config.slowOperationThreshold, equals(threshold));
      });

      test('should configure custom logger', () {
        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          // Custom logging implementation
        }

        TryxConfig.configure(customLogger: customLogger);
        expect(TryxConfig.instance.customLogger, equals(customLogger));
      });

      test('should configure global error handler', () {
        void errorHandler(Object error, StackTrace stackTrace) {
          // Custom error handling
        }

        TryxConfig.configure(globalErrorHandler: errorHandler);
        expect(TryxConfig.instance.globalErrorHandler, equals(errorHandler));
      });
    });

    group('Logging System', () {
      test('should not log when global logging is disabled', () {
        TryxConfig.configure(enableGlobalLogging: false);

        // This should not throw or cause issues
        TryxConfig.log('Test message', LogLevel.error);

        // No way to verify it didn't log without capturing output,
        // but at least we verify it doesn't crash
        expect(TryxConfig.instance.enableGlobalLogging, isFalse);
      });

      test('should respect log level filtering', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add('${level.name}: $message');
        }

        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.warning,
          customLogger: customLogger,
        );

        // These should be logged (warning and above)
        TryxConfig.log('Warning message', LogLevel.warning);
        TryxConfig.log('Error message', LogLevel.error);

        // These should be filtered out (below warning)
        TryxConfig.log('Debug message', LogLevel.debug);
        TryxConfig.log('Info message', LogLevel.info);

        expect(loggedMessages, hasLength(2));
        expect(loggedMessages[0], equals('warning: Warning message'));
        expect(loggedMessages[1], equals('error: Error message'));
      });

      test('should include error and stack trace in logs when configured', () {
        String? lastMessage;
        Object? lastError;
        StackTrace? lastStackTrace;

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          lastMessage = message;
          lastError = error;
          lastStackTrace = stackTrace;
        }

        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          includeStackTraces: true,
          customLogger: customLogger,
        );

        final testError = Exception('Test error');
        final testStackTrace = StackTrace.current;

        TryxConfig.log(
          'Test message',
          LogLevel.error,
          testError,
          testStackTrace,
        );

        expect(lastMessage, equals('Test message'));
        expect(lastError, equals(testError));
        expect(lastStackTrace, equals(testStackTrace));
      });

      test('should exclude stack trace when configured', () {
        StackTrace? lastStackTrace;

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          lastStackTrace = stackTrace;
        }

        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          includeStackTraces: false,
          customLogger: customLogger,
        );

        TryxConfig.log(
          'Test message',
          LogLevel.error,
          Exception('Test'),
          StackTrace.current,
        );

        expect(lastStackTrace, isNull);
      });
    });

    group('Error Handling', () {
      test('should call global error handler when configured', () {
        Object? handledError;
        StackTrace? handledStackTrace;

        void errorHandler(Object error, StackTrace stackTrace) {
          handledError = error;
          handledStackTrace = stackTrace;
        }

        TryxConfig.configure(globalErrorHandler: errorHandler);

        final testError = Exception('Test error');
        final testStackTrace = StackTrace.current;

        TryxConfig.handleGlobalError(testError, testStackTrace);

        expect(handledError, equals(testError));
        expect(handledStackTrace, equals(testStackTrace));
      });

      test('should fall back to logging when error handler throws', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add(message);
        }

        void faultyErrorHandler(Object error, StackTrace stackTrace) {
          throw Exception('Handler error');
        }

        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          customLogger: customLogger,
          globalErrorHandler: faultyErrorHandler,
        );

        TryxConfig.handleGlobalError(
          Exception('Original error'),
          StackTrace.current,
        );

        expect(loggedMessages, hasLength(1));
        expect(loggedMessages[0], contains('Global error handler failed'));
      });

      test('should log unhandled errors when no handler configured', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add(message);
        }

        TryxConfig.configure(
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          customLogger: customLogger,
        );

        TryxConfig.handleGlobalError(
          Exception('Test error'),
          StackTrace.current,
        );

        expect(loggedMessages, hasLength(1));
        expect(loggedMessages[0], equals('Unhandled error'));
      });
    });

    group('Performance Monitoring', () {
      test('should not record performance when monitoring is disabled', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add(message);
        }

        TryxConfig.configure(
          enablePerformanceMonitoring: false,
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          customLogger: customLogger,
        );

        TryxConfig.recordPerformance('test-op', const Duration(seconds: 2));

        expect(loggedMessages, isEmpty);
      });

      test('should log slow operations when monitoring is enabled', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add(message);
        }

        TryxConfig.configure(
          enablePerformanceMonitoring: true,
          slowOperationThreshold: const Duration(seconds: 1),
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          customLogger: customLogger,
        );

        // This should be logged (above threshold)
        TryxConfig.recordPerformance('slow-op', const Duration(seconds: 2));

        // This should not be logged (below threshold)
        TryxConfig.recordPerformance(
          'fast-op',
          const Duration(milliseconds: 500),
        );

        expect(loggedMessages, hasLength(1));
        expect(loggedMessages[0], contains('Slow operation detected: slow-op'));
        expect(loggedMessages[0], contains('2000ms'));
        expect(loggedMessages[0], contains('success'));
      });

      test('should include success/failure status in performance logs', () {
        final loggedMessages = <String>[];

        void customLogger(
          String message,
          LogLevel level,
          Object? error,
          StackTrace? stackTrace,
        ) {
          loggedMessages.add(message);
        }

        TryxConfig.configure(
          enablePerformanceMonitoring: true,
          slowOperationThreshold: const Duration(milliseconds: 500),
          enableGlobalLogging: true,
          logLevel: LogLevel.debug,
          customLogger: customLogger,
        );

        TryxConfig.recordPerformance('success-op', const Duration(seconds: 1));
        TryxConfig.recordPerformance(
          'failure-op',
          const Duration(seconds: 1),
          false,
        );

        expect(loggedMessages, hasLength(2));
        expect(loggedMessages[0], contains('success'));
        expect(loggedMessages[1], contains('failure'));
      });
    });

    group('copyWith', () {
      test('should create copy with modified values', () {
        TryxConfig.configure(
          defaultRetryPolicy: RetryPolicies.standard,
          enableGlobalLogging: true,
          logLevel: LogLevel.info,
        );

        final copy = TryxConfig.instance.copyWith(
          enableGlobalLogging: false,
          logLevel: LogLevel.debug,
        );

        // Original should be unchanged
        expect(TryxConfig.instance.enableGlobalLogging, isTrue);
        expect(TryxConfig.instance.logLevel, equals(LogLevel.info));

        // Copy should have modified values
        expect(copy.enableGlobalLogging, isFalse);
        expect(copy.logLevel, equals(LogLevel.debug));
        expect(
          copy.defaultRetryPolicy,
          equals(RetryPolicies.standard),
        ); // Unchanged
      });

      test('should preserve unmodified values in copy', () {
        const timeout = Duration(seconds: 30);
        TryxConfig.configure(
          globalTimeout: timeout,
          enablePerformanceMonitoring: true,
        );

        final copy = TryxConfig.instance.copyWith(enableGlobalLogging: true);

        expect(copy.globalTimeout, equals(timeout));
        expect(copy.enablePerformanceMonitoring, isTrue);
        expect(copy.enableGlobalLogging, isTrue);
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        TryxConfig.configure(
          defaultRetryPolicy: RetryPolicies.network,
          enableGlobalLogging: true,
          logLevel: LogLevel.warning,
          globalTimeout: const Duration(seconds: 30),
        );

        final configString = TryxConfig.instance.toString();

        expect(configString, contains('TryxConfig('));
        expect(configString, contains('enableGlobalLogging: true'));
        expect(configString, contains('logLevel: LogLevel.warning'));
        expect(configString, contains('globalTimeout: 0:00:30.000000'));
      });
    });
  });

  group('LogLevel', () {
    test('should have correct names', () {
      expect(LogLevel.debug.name, equals('debug'));
      expect(LogLevel.info.name, equals('info'));
      expect(LogLevel.warning.name, equals('warning'));
      expect(LogLevel.error.name, equals('error'));
    });

    test('should have correct priorities', () {
      expect(LogLevel.debug.priority, equals(0));
      expect(LogLevel.info.priority, equals(1));
      expect(LogLevel.warning.priority, equals(2));
      expect(LogLevel.error.priority, equals(3));
    });

    test('should be ordered by priority', () {
      final levels = [
        LogLevel.error,
        LogLevel.debug,
        LogLevel.warning,
        LogLevel.info,
      ];
      levels.sort((a, b) => a.priority.compareTo(b.priority));

      expect(
        levels,
        equals([
          LogLevel.debug,
          LogLevel.info,
          LogLevel.warning,
          LogLevel.error,
        ]),
      );
    });
  });

  group('TryxConfigPresets', () {
    setUp(TryxConfig.reset);

    tearDown(TryxConfig.reset);

    test('development preset should configure for development', () {
      TryxConfigPresets.development();

      final config = TryxConfig.instance;
      expect(config.defaultRetryPolicy, equals(RetryPolicies.standard));
      expect(config.enableGlobalLogging, isTrue);
      expect(config.logLevel, equals(LogLevel.debug));
      expect(config.includeStackTraces, isTrue);
      expect(config.enablePerformanceMonitoring, isTrue);
      expect(
        config.slowOperationThreshold,
        equals(const Duration(milliseconds: 500)),
      );
    });

    test('production preset should configure for production', () {
      TryxConfigPresets.production();

      final config = TryxConfig.instance;
      expect(config.defaultRetryPolicy, equals(RetryPolicies.network));
      expect(config.enableGlobalLogging, isTrue);
      expect(config.logLevel, equals(LogLevel.error));
      expect(config.includeStackTraces, isFalse);
      expect(config.enablePerformanceMonitoring, isFalse);
      expect(config.globalTimeout, equals(const Duration(seconds: 30)));
    });

    test('testing preset should configure for testing', () {
      TryxConfigPresets.testing();

      final config = TryxConfig.instance;
      expect(config.defaultRetryPolicy, equals(RetryPolicies.none));
      expect(config.enableGlobalLogging, isFalse);
      expect(config.logLevel, equals(LogLevel.error));
      expect(config.includeStackTraces, isFalse);
      expect(config.enablePerformanceMonitoring, isFalse);
      expect(config.globalTimeout, equals(const Duration(seconds: 5)));
    });

    test('networkOptimized preset should configure for network operations', () {
      TryxConfigPresets.networkOptimized();

      final config = TryxConfig.instance;
      expect(config.defaultRetryPolicy, equals(RetryPolicies.aggressive));
      expect(config.enableGlobalLogging, isTrue);
      expect(config.logLevel, equals(LogLevel.warning));
      expect(config.includeStackTraces, isTrue);
      expect(config.enablePerformanceMonitoring, isTrue);
      expect(config.globalTimeout, equals(const Duration(seconds: 60)));
      expect(config.slowOperationThreshold, equals(const Duration(seconds: 2)));
    });

    test(
      'databaseOptimized preset should configure for database operations',
      () {
        TryxConfigPresets.databaseOptimized();

        final config = TryxConfig.instance;
        expect(config.defaultRetryPolicy, isNotNull);
        expect(config.defaultRetryPolicy!.maxAttempts, equals(3));
        expect(config.enableGlobalLogging, isTrue);
        expect(config.logLevel, equals(LogLevel.info));
        expect(config.includeStackTraces, isTrue);
        expect(config.enablePerformanceMonitoring, isTrue);
        expect(config.globalTimeout, equals(const Duration(seconds: 30)));
        expect(
          config.slowOperationThreshold,
          equals(const Duration(milliseconds: 1000)),
        );
      },
    );
  });

  group('Integration Tests', () {
    setUp(TryxConfig.reset);

    tearDown(TryxConfig.reset);

    test('should work with multiple configuration changes', () {
      // Initial configuration
      TryxConfigPresets.development();
      expect(TryxConfig.instance.logLevel, equals(LogLevel.debug));

      // Override specific settings
      TryxConfig.configure(
        logLevel: LogLevel.warning,
        globalTimeout: const Duration(seconds: 15),
      );

      final config = TryxConfig.instance;
      expect(config.logLevel, equals(LogLevel.warning));
      expect(config.globalTimeout, equals(const Duration(seconds: 15)));
      // Other development settings should remain
      expect(config.enableGlobalLogging, isTrue);
      expect(config.enablePerformanceMonitoring, isTrue);
    });

    test('should handle complex logging scenario', () {
      final loggedMessages = <Map<String, dynamic>>[];

      void customLogger(
        String message,
        LogLevel level,
        Object? error,
        StackTrace? stackTrace,
      ) {
        loggedMessages.add({
          'message': message,
          'level': level,
          'error': error,
          'stackTrace': stackTrace,
        });
      }

      TryxConfig.configure(
        enableGlobalLogging: true,
        logLevel: LogLevel.info,
        includeStackTraces: true,
        customLogger: customLogger,
        enablePerformanceMonitoring: true,
        slowOperationThreshold: const Duration(milliseconds: 100),
      );

      // Log various messages
      TryxConfig.log('Debug message', LogLevel.debug); // Should be filtered
      TryxConfig.log('Info message', LogLevel.info);
      TryxConfig.log('Warning message', LogLevel.warning);
      TryxConfig.log('Error message', LogLevel.error, Exception('Test error'));

      // Record performance
      TryxConfig.recordPerformance(
        'slow-op',
        const Duration(milliseconds: 200),
      );

      expect(loggedMessages, hasLength(4)); // 3 logs + 1 performance
      expect(loggedMessages[0]['message'], equals('Info message'));
      expect(loggedMessages[1]['message'], equals('Warning message'));
      expect(loggedMessages[2]['message'], equals('Error message'));
      expect(loggedMessages[2]['error'], isA<Exception>());
      expect(loggedMessages[3]['message'], contains('Slow operation detected'));
    });
  });
}
