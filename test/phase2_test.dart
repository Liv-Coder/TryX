import 'dart:async';
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('RetryPolicy', () {
    group('Basic RetryPolicy', () {
      test('should create policy with correct parameters', () {
        const policy = RetryPolicy(maxAttempts: 3, delay: Duration(seconds: 1));

        expect(policy.maxAttempts, equals(3));
        expect(policy.delay, equals(const Duration(seconds: 1)));
        expect(policy.backoffMultiplier, equals(1.0));
        expect(policy.jitter, isFalse);
      });

      test('should calculate fixed delay correctly', () {
        const policy = RetryPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 500),
        );

        expect(policy.getDelay(1), equals(const Duration(milliseconds: 500)));
        expect(policy.getDelay(2), equals(const Duration(milliseconds: 500)));
        expect(policy.getDelay(3), equals(const Duration(milliseconds: 500)));
      });

      test('should determine retry eligibility correctly', () {
        const policy = RetryPolicy(maxAttempts: 3);

        expect(policy.shouldRetry(1), isTrue); // Can retry after first attempt
        expect(policy.shouldRetry(2), isTrue); // Can retry after second attempt
        expect(
          policy.shouldRetry(3),
          isFalse,
        ); // No more retries after third attempt
      });

      test('should calculate retries remaining correctly', () {
        const policy = RetryPolicy(maxAttempts: 4);

        expect(policy.retriesRemaining(1), equals(3));
        expect(policy.retriesRemaining(2), equals(2));
        expect(policy.retriesRemaining(3), equals(1));
        expect(policy.retriesRemaining(4), equals(0));
      });
    });

    group('Exponential Backoff', () {
      test('should create exponential backoff policy', () {
        const policy = RetryPolicy.exponentialBackoff(
          maxAttempts: 4,
          initialDelay: Duration(milliseconds: 100),
        );

        expect(policy.maxAttempts, equals(4));
        expect(policy.delay, equals(const Duration(milliseconds: 100)));
        expect(policy.backoffMultiplier, equals(2.0));
        expect(policy.jitter, isTrue);
      });

      test('should calculate exponential delays correctly', () {
        const policy = RetryPolicy.exponentialBackoff(
          maxAttempts: 4,
          initialDelay: Duration(milliseconds: 100),
          jitter: false, // Disable jitter for predictable testing
        );

        expect(policy.getDelay(1), equals(const Duration(milliseconds: 100)));
        expect(policy.getDelay(2), equals(const Duration(milliseconds: 200)));
        expect(policy.getDelay(3), equals(const Duration(milliseconds: 400)));
      });

      test('should respect maximum delay', () {
        const policy = RetryPolicy.exponentialBackoff(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 100),
          maxDelay: Duration(milliseconds: 300),
          jitter: false,
        );

        expect(policy.getDelay(1), equals(const Duration(milliseconds: 100)));
        expect(policy.getDelay(2), equals(const Duration(milliseconds: 200)));
        expect(
          policy.getDelay(3),
          equals(const Duration(milliseconds: 300)),
        ); // Capped
        expect(
          policy.getDelay(4),
          equals(const Duration(milliseconds: 300)),
        ); // Capped
      });
    });

    group('Predefined Policies', () {
      test('should provide correct predefined policies', () {
        expect(RetryPolicies.none.maxAttempts, equals(1));
        expect(RetryPolicies.once.maxAttempts, equals(2));
        expect(RetryPolicies.standard.maxAttempts, equals(3));
        expect(RetryPolicies.aggressive.maxAttempts, equals(5));
        expect(RetryPolicies.conservative.maxAttempts, equals(3));
        expect(RetryPolicies.network.maxAttempts, equals(4));
      });
    });

    group('Equality and toString', () {
      test('should support equality', () {
        const policy1 = RetryPolicy(
          maxAttempts: 3,
          delay: Duration(seconds: 1),
        );
        const policy2 = RetryPolicy(
          maxAttempts: 3,
          delay: Duration(seconds: 1),
        );
        const policy3 = RetryPolicy(
          maxAttempts: 2,
          delay: Duration(seconds: 1),
        );

        expect(policy1, equals(policy2));
        expect(policy1, isNot(equals(policy3)));
      });

      test('should have meaningful toString', () {
        const policy = RetryPolicy(maxAttempts: 3, delay: Duration(seconds: 1));
        final str = policy.toString();

        expect(str, contains('RetryPolicy'));
        expect(str, contains('maxAttempts: 3'));
        expect(str, contains('delay: 0:00:01.000000'));
      });
    });
  });

  group('Safe Class', () {
    group('Basic Safe Execution', () {
      test('should execute successful function', () async {
        const safe = Safe();
        final result = await safe.call<int, Exception>(() => 42);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42));
      });

      test('should catch and return exceptions', () async {
        const safe = Safe();
        final result = await safe.call<int, Exception>(
          () => throw Exception('test error'),
        );

        expect(result.isFailure, isTrue);
        expect(result.getOrNull(), isNull);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) {
            expect(e, isA<Exception>());
            expect(e.toString(), contains('test error'));
          },
        );
      });

      test('should handle async functions', () async {
        const safe = Safe();
        final result = await safe.call<String, Exception>(
          () => Future.value('async result'),
        );

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('async result'));
      });
    });

    group('Timeout Support', () {
      test('should apply timeout to operations', () async {
        const safe = Safe(timeout: Duration(milliseconds: 100));

        final result = await safe.call<String, Exception>(
          () => Future.delayed(
            const Duration(milliseconds: 200),
            () => 'too slow',
          ),
        );

        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, isA<TimeoutException>()),
        );
      });

      test('should not timeout fast operations', () async {
        const safe = Safe(timeout: Duration(milliseconds: 200));

        final result = await safe.call<String, Exception>(
          () => Future.delayed(
            const Duration(milliseconds: 50),
            () => 'fast enough',
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('fast enough'));
      });
    });

    group('Retry Logic', () {
      test('should retry failed operations', () async {
        var attempts = 0;
        const safe = Safe(retryPolicy: RetryPolicy(maxAttempts: 3));

        final result = await safe.call<int, Exception>(() {
          attempts++;
          if (attempts < 3) {
            throw Exception('attempt $attempts failed');
          }
          return attempts;
        });

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(3));
        expect(attempts, equals(3));
      });

      test('should fail after max attempts', () async {
        var attempts = 0;
        const safe = Safe(retryPolicy: RetryPolicy(maxAttempts: 2));

        final result = await safe.call<int, Exception>(() {
          attempts++;
          throw Exception('always fails');
        });

        expect(result.isFailure, isTrue);
        expect(attempts, equals(2));
      });
    });

    group('Error Mapping', () {
      test('should map errors using errorMapper', () async {
        final safe = Safe(
          errorMapper: (error) => 'Mapped: ${error.toString()}',
        );

        final result = await safe.call<int, String>(
          () => throw Exception('original error'),
        );

        expect(result.isFailure, isTrue);
        expect(result.getOrNull(), isNull);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) {
            expect(e, isA<String>());
            expect(e, startsWith('Mapped:'));
            expect(e, contains('original error'));
          },
        );
      });
    });

    group('Logging and Callbacks', () {
      test('should call logger on errors', () async {
        final loggedErrors = <Object>[];
        final loggedAttempts = <int>[];

        final safe = Safe(
          retryPolicy: const RetryPolicy(maxAttempts: 2),
          logger: (error, attempt) {
            loggedErrors.add(error);
            loggedAttempts.add(attempt);
          },
        );

        await safe.call<int, Exception>(() => throw Exception('test'));

        expect(loggedErrors, hasLength(2));
        expect(loggedAttempts, equals([1, 2]));
      });

      test('should call onRetry callback', () async {
        final retryCallbacks = <int>[];
        var attempts = 0;

        final safe = Safe(
          retryPolicy: const RetryPolicy(maxAttempts: 3, delay: Duration.zero),
          onRetry: (error, attempt, delay) {
            retryCallbacks.add(attempt);
          },
        );

        await safe.call<int, Exception>(() {
          attempts++;
          if (attempts < 3) {
            throw Exception('retry me');
          }
          return attempts;
        });

        expect(retryCallbacks, equals([1, 2])); // Called before retry attempts
      });
    });

    group('Factory Constructors', () {
      test('should create network-optimized Safe', () {
        const safe = Safe.network();

        expect(safe.timeout, equals(const Duration(seconds: 30)));
        expect(safe.retryPolicy, equals(RetryPolicies.network));
      });

      test('should create database-optimized Safe', () {
        const safe = Safe.database();

        expect(safe.timeout, equals(const Duration(seconds: 10)));
        expect(safe.retryPolicy, equals(RetryPolicies.conservative));
      });

      test('should create critical-optimized Safe', () {
        const safe = Safe.critical();

        expect(safe.timeout, equals(const Duration(seconds: 60)));
        expect(safe.retryPolicy, equals(RetryPolicies.aggressive));
      });
    });

    group('Convenience Methods', () {
      test('should provide execute method for SafeResult', () async {
        const safe = Safe();
        final result = await safe.execute(() => 42);

        expect(result, isA<SafeResult<int>>());
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42));
      });

      test('should provide static executeWith method', () async {
        final result = await Safe.executeWith<int, Exception>(
          () => 42,
          timeout: const Duration(seconds: 1),
        );

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(42));
      });
    });

    group('copyWith', () {
      test('should create modified copy', () {
        const original = Safe(timeout: Duration(seconds: 5));
        final modified = original.copyWith(retryPolicy: RetryPolicies.standard);

        expect(modified.timeout, equals(const Duration(seconds: 5)));
        expect(modified.retryPolicy, equals(RetryPolicies.standard));
        expect(original.retryPolicy, equals(RetryPolicies.none));
      });
    });
  });

  group('Utility Functions', () {
    group('combineResults', () {
      test('should combine successful results', () {
        final results = [
          const Result<int, String>.success(1),
          const Result<int, String>.success(2),
          const Result<int, String>.success(3),
        ];

        final combined = combineResults(results);

        expect(combined.isSuccess, isTrue);
        expect(combined.getOrNull(), equals([1, 2, 3]));
      });

      test('should return first failure', () {
        final results = [
          const Result<int, String>.success(1),
          const Result<int, String>.failure('error1'),
          const Result<int, String>.success(3),
          const Result<int, String>.failure('error2'),
        ];

        final combined = combineResults(results);

        expect(combined.isFailure, isTrue);
        combined.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, equals('error1')),
        );
      });

      test('should handle empty list', () {
        final results = <Result<int, String>>[];
        final combined = combineResults(results);

        expect(combined.isSuccess, isTrue);
        expect(combined.getOrNull(), isEmpty);
      });
    });

    group('combineResults2', () {
      test('should combine two successful results', () {
        const result1 = Result<int, String>.success(5);
        const result2 = Result<int, String>.success(3);

        final combined = combineResults2(result1, result2, (a, b) => a + b);

        expect(combined.isSuccess, isTrue);
        expect(combined.getOrNull(), equals(8));
      });

      test('should return failure if first fails', () {
        const result1 = Result<int, String>.failure('error');
        const result2 = Result<int, String>.success(3);

        final combined = combineResults2(result1, result2, (a, b) => a + b);

        expect(combined.isFailure, isTrue);
        combined.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, equals('error')),
        );
      });
    });

    group('fromNullable', () {
      test('should convert non-null value to success', () {
        final result = fromNullable('hello', () => 'was null');

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('hello'));
      });

      test('should convert null to failure', () {
        final result = fromNullable<String, String>(null, () => 'was null');

        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, equals('was null')),
        );
      });
    });

    group('fromBool', () {
      test('should convert true to success', () {
        final result = fromBool(
          () => 'success value',
          () => 'error value',
          condition: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals('success value'));
      });

      test('should convert false to failure', () {
        final result = fromBool(
          () => 'success value',
          () => 'error value',
          condition: false,
        );

        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, equals('error value')),
        );
      });
    });

    group('partitionResults', () {
      test('should partition mixed results', () {
        final results = [
          const Result<int, String>.success(1),
          const Result<int, String>.failure('error1'),
          const Result<int, String>.success(3),
          const Result<int, String>.failure('error2'),
        ];

        final partition = partitionResults(results);
        final successes = partition.successes;
        final failures = partition.failures;

        expect(successes, equals([1, 3]));
        expect(failures, equals(['error1', 'error2']));
      });

      test('should handle all successes', () {
        final results = [
          const Result<int, String>.success(1),
          const Result<int, String>.success(2),
        ];

        final partition = partitionResults(results);
        final successes = partition.successes;
        final failures = partition.failures;

        expect(successes, equals([1, 2]));
        expect(failures, isEmpty);
      });
    });

    group('traverse', () {
      test('should traverse successful operations', () {
        final strings = ['1', '2', '3'];
        final result = traverse(strings, (s) => safe(() => int.parse(s)));

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals([1, 2, 3]));
      });

      test('should fail on first parse error', () {
        final strings = ['1', 'invalid', '3'];
        final result = traverse(strings, (s) => safe(() => int.parse(s)));

        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Expected failure'),
          failure: (e) => expect(e, isA<FormatException>()),
        );
      });
    });
  });
}
