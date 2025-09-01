import 'dart:async';

import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('Integration Tests', () {
    test('should handle complex error scenario end-to-end', () async {
      // Test the fixed type safety in result extensions
      final result = safe(() => '42')
          .flatMap((str) => safe(() => int.parse(str)))
          .map((number) => number * 2)
          .recover((error) => 0);

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(84));
    });

    test('should handle Safe class with retry properly', () async {
      var attemptCount = 0;
      final safe = Safe(
        retryPolicy: const RetryPolicy(maxAttempts: 3),
        logger: (error, attempt) {
          // Logger should be called for each failure
          expect(attempt, lessThanOrEqualTo(3));
        },
      );

      final result = await safe.execute<int>(() {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('Not ready yet');
        }
        return 42;
      });

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(42));
      expect(attemptCount, equals(3));
    });

    test('should handle safeWith with proper error mapping', () async {
      final result = await safeWith<int, String>(
        () => throw Exception('original error'),
        errorMapper: (error) => 'Mapped: ${error.toString()}',
      );

      expect(result.isFailure, isTrue);
      final errorMessage = result.when(
        success: (_) => null,
        failure: (e) => e,
      );
      expect(errorMessage, contains('Mapped: Exception: original error'));
    });

    test('should handle stream processing safely', () async {
      final numbers = Stream.fromIterable(['1', '2', 'invalid', '4']);
      
      final results = await numbers
          .safeMap<int, String>(
            int.parse,
            errorMapper: (error) => 'Parse error: $error',
          )
          .toList();

      expect(results.length, equals(4));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[2].isFailure, isTrue);
      expect(
        results[2].when(success: (_) => null, failure: (e) => e),
        contains('Parse error'),
      );
    });

    test('should work with TryxConfig global settings', () {
      // Reset to ensure clean state
      TryxConfig.reset();
      
      var loggedMessages = <String>[];
      
      TryxConfig.configure(
        enableGlobalLogging: true,
        logLevel: LogLevel.error,
        customLogger: (message, level, error, stackTrace) {
          loggedMessages.add('$level: $message');
        },
      );

      // Trigger an error that should be logged
      TryxConfig.log('Test error message', LogLevel.error);
      
      expect(loggedMessages.length, equals(1));
      expect(loggedMessages.first, contains('error: Test error message'));
      
      // Reset after test
      TryxConfig.reset();
    });

    test('should demonstrate improved error types', () async {
      // This tests the improved error handling in safeWith
      final result = await safeWith<int, ArgumentError>(
        () => int.parse('invalid'),
        errorMapper: (error) => ArgumentError('Failed to parse: $error'),
      );

      expect(result.isFailure, isTrue);
      final error = result.when(
        success: (_) => null,
        failure: (e) => e,
      );
      expect(error, isA<ArgumentError>());
      expect(error.toString(), contains('Failed to parse'));
    });
  });
}