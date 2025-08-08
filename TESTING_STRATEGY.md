# Tryx Library - Testing Strategy

## 🧪 Testing Philosophy

The Tryx library follows a comprehensive testing approach that ensures reliability, performance, and maintainability. Our testing strategy covers unit tests, integration tests, performance benchmarks, and real-world scenario validation.

## 📋 Test Categories

### 1. Unit Tests

Test individual components in isolation with comprehensive coverage.

### 2. Integration Tests

Test component interactions and end-to-end workflows.

### 3. Performance Tests

Benchmark against try-catch and measure overhead.

### 4. Example Tests

Validate all documentation examples work correctly.

### 5. Property-Based Tests

Use fuzzing to test edge cases and invariants.

## 🏗️ Test Structure

```
test/
├── unit/
│   ├── core/
│   │   ├── result_test.dart
│   │   ├── success_test.dart
│   │   └── failure_test.dart
│   ├── functions/
│   │   ├── safe_test.dart
│   │   ├── safe_async_test.dart
│   │   └── safe_with_test.dart
│   ├── extensions/
│   │   ├── result_extensions_test.dart
│   │   ├── future_extensions_test.dart
│   │   └── stream_extensions_test.dart
│   ├── advanced/
│   │   ├── safe_class_test.dart
│   │   ├── retry_policy_test.dart
│   │   └── global_config_test.dart
│   └── utils/
│       ├── combinators_test.dart
│       └── converters_test.dart
├── integration/
│   ├── real_world_scenarios_test.dart
│   ├── flutter_integration_test.dart
│   └── stream_processing_test.dart
├── performance/
│   ├── benchmark_test.dart
│   ├── memory_usage_test.dart
│   └── async_performance_test.dart
├── examples/
│   ├── readme_examples_test.dart
│   ├── design_examples_test.dart
│   └── usage_examples_test.dart
├── property/
│   ├── result_properties_test.dart
│   └── safe_properties_test.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_services.dart
    └── test_data.dart
```

## 🔧 Test Implementation Examples

### Unit Tests - Core Result Type

```dart
// test/unit/core/result_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('Result<T, E>', () {
    group('Success', () {
      test('should create success result', () {
        final result = Result<int, String>.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.value, equals(42));
        expect(result.error, isNull);
      });

      test('should maintain type safety', () {
        final result = Result<String, Exception>.success('hello');

        expect(result, isA<Success<String, Exception>>());
        expect(result.value, isA<String>());
      });

      test('should support equality', () {
        final result1 = Result<int, String>.success(42);
        final result2 = Result<int, String>.success(42);
        final result3 = Result<int, String>.success(43);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });
    });

    group('Failure', () {
      test('should create failure result', () {
        final error = Exception('test error');
        final result = Result<int, Exception>.failure(error);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.value, isNull);
        expect(result.error, equals(error));
      });

      test('should maintain error type', () {
        final result = Result<int, String>.failure('error message');

        expect(result, isA<Failure<int, String>>());
        expect(result.error, isA<String>());
      });
    });

    group('Pattern Matching', () {
      test('should support switch expressions', () {
        final successResult = Result<int, String>.success(42);
        final failureResult = Result<int, String>.failure('error');

        final successValue = switch (successResult) {
          Success(value: final v) => 'success: $v',
          Failure(error: final e) => 'failure: $e',
        };

        final failureValue = switch (failureResult) {
          Success(value: final v) => 'success: $v',
          Failure(error: final e) => 'failure: $e',
        };

        expect(successValue, equals('success: 42'));
        expect(failureValue, equals('failure: error'));
      });
    });
  });
}
```

### Unit Tests - Safe Functions

```dart
// test/unit/functions/safe_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('safe()', () {
    test('should wrap successful function', () {
      final result = safe(() => 42);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });

    test('should catch exceptions', () {
      final result = safe(() => throw Exception('test error'));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
      expect(result.error.toString(), contains('test error'));
    });

    test('should handle different return types', () {
      final stringResult = safe(() => 'hello');
      final intResult = safe(() => 42);
      final listResult = safe(() => [1, 2, 3]);

      expect(stringResult.value, isA<String>());
      expect(intResult.value, isA<int>());
      expect(listResult.value, isA<List<int>>());
    });

    test('should convert non-Exception errors', () {
      final result = safe(() => throw 'string error');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
    });
  });

  group('safeAsync()', () {
    test('should wrap successful async function', () async {
      final result = await safeAsync(() async => 42);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });

    test('should catch async exceptions', () async {
      final result = await safeAsync(() async => throw Exception('async error'));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
    });

    test('should handle Future.delayed', () async {
      final result = await safeAsync(() => Future.delayed(
        Duration(milliseconds: 10),
        () => 'delayed result',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('delayed result'));
    });
  });

  group('safeWith()', () {
    test('should use custom error mapper', () async {
      final result = await safeWith<int, String>(
        () => throw Exception('original error'),
        errorMapper: (e) => 'mapped: ${e.toString()}',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, startsWith('mapped:'));
    });

    test('should handle sync functions', () async {
      final result = await safeWith<int, String>(
        () => 42,
        errorMapper: (e) => 'error',
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });
  });
}
```

### Unit Tests - Extensions

```dart
// test/unit/extensions/result_extensions_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('ResultExtensions', () {
    group('map', () {
      test('should transform success value', () {
        final result = Result<int, String>.success(42);
        final mapped = result.map((x) => x.toString());

        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, equals('42'));
      });

      test('should preserve failure', () {
        final result = Result<int, String>.failure('error');
        final mapped = result.map((x) => x.toString());

        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals('error'));
      });
    });

    group('flatMap', () {
      test('should chain successful operations', () {
        final result = Result<int, String>.success(42);
        final chained = result.flatMap((x) => Result.success(x.toString()));

        expect(chained.isSuccess, isTrue);
        expect(chained.value, equals('42'));
      });

      test('should short-circuit on failure', () {
        final result = Result<int, String>.failure('error');
        final chained = result.flatMap((x) => Result.success(x.toString()));

        expect(chained.isFailure, isTrue);
        expect(chained.error, equals('error'));
      });

      test('should propagate inner failure', () {
        final result = Result<int, String>.success(42);
        final chained = result.flatMap((x) => Result<String, String>.failure('inner error'));

        expect(chained.isFailure, isTrue);
        expect(chained.error, equals('inner error'));
      });
    });

    group('when', () {
      test('should call success callback', () {
        final result = Result<int, String>.success(42);
        var called = false;

        final output = result.when(
          success: (value) {
            called = true;
            return 'success: $value';
          },
          failure: (error) => 'failure: $error',
        );

        expect(called, isTrue);
        expect(output, equals('success: 42'));
      });

      test('should call failure callback', () {
        final result = Result<int, String>.failure('error');
        var called = false;

        final output = result.when(
          success: (value) => 'success: $value',
          failure: (error) {
            called = true;
            return 'failure: $error';
          },
        );

        expect(called, isTrue);
        expect(output, equals('failure: error'));
      });
    });

    group('getOrElse', () {
      test('should return value on success', () {
        final result = Result<int, String>.success(42);
        final value = result.getOrElse(() => 0);

        expect(value, equals(42));
      });

      test('should return default on failure', () {
        final result = Result<int, String>.failure('error');
        final value = result.getOrElse(() => 0);

        expect(value, equals(0));
      });
    });

    group('recover', () {
      test('should not affect success', () {
        final result = Result<int, String>.success(42);
        final recovered = result.recover((error) => 0);

        expect(recovered.isSuccess, isTrue);
        expect(recovered.value, equals(42));
      });

      test('should recover from failure', () {
        final result = Result<int, String>.failure('error');
        final recovered = result.recover((error) => 0);

        expect(recovered.isSuccess, isTrue);
        expect(recovered.value, equals(0));
      });
    });
  });
}
```

### Integration Tests

```dart
// test/integration/real_world_scenarios_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

// Mock services for testing
class MockApiClient {
  Future<User> getUser(String id) async {
    if (id == 'error') throw Exception('User not found');
    return User(id: id, name: 'Test User', email: 'test@example.com');
  }

  Future<UserProfile> getUserProfile(String userId) async {
    if (userId == 'error') throw Exception('Profile not found');
    return UserProfile(userId: userId, bio: 'Test bio');
  }
}

class UserService {
  UserService(this.apiClient);
  final MockApiClient apiClient;

  Future<Result<User, Exception>> getUser(String id) async {
    return await safeAsync(() => apiClient.getUser(id));
  }

  Future<Result<UserWithProfile, Exception>> getUserWithProfile(String id) async {
    final userResult = await getUser(id);
    return await userResult.flatMapAsync((user) async {
      final profileResult = await safeAsync(() => apiClient.getUserProfile(user.id));
      return profileResult.map((profile) => UserWithProfile(user, profile));
    });
  }
}

void main() {
  group('Real World Scenarios', () {
    late UserService userService;

    setUp(() {
      userService = UserService(MockApiClient());
    });

    test('should handle successful user fetch', () async {
      final result = await userService.getUser('123');

      expect(result.isSuccess, isTrue);
      expect(result.value?.name, equals('Test User'));
    });

    test('should handle user fetch error', () async {
      final result = await userService.getUser('error');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
    });

    test('should chain user and profile operations', () async {
      final result = await userService.getUserWithProfile('123');

      expect(result.isSuccess, isTrue);
      expect(result.value?.user.name, equals('Test User'));
      expect(result.value?.profile.bio, equals('Test bio'));
    });

    test('should handle chained operation failure', () async {
      final result = await userService.getUserWithProfile('error');

      expect(result.isFailure, isTrue);
    });
  });
}
```

### Performance Tests

```dart
// test/performance/benchmark_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('Performance Benchmarks', () {
    const iterations = 100000;

    test('safe() vs try-catch overhead', () {
      final stopwatch = Stopwatch();

      // Benchmark try-catch
      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        try {
          final result = i * 2;
          // Use result to prevent optimization
          if (result < 0) print(result);
        } catch (e) {
          // Handle error
        }
      }
      stopwatch.stop();
      final tryCatchTime = stopwatch.elapsedMicroseconds;

      // Benchmark safe()
      stopwatch.reset();
      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        final result = safe(() => i * 2);
        // Use result to prevent optimization
        if (result.value != null && result.value! < 0) print(result.value);
      }
      stopwatch.stop();
      final safeTime = stopwatch.elapsedMicroseconds;

      final overhead = (safeTime / tryCatchTime);
      print('Try-catch time: ${tryCatchTime}μs');
      print('Safe time: ${safeTime}μs');
      print('Overhead: ${overhead.toStringAsFixed(2)}x');

      // Acceptable overhead should be less than 5x
      expect(overhead, lessThan(5.0));
    });

    test('method chaining performance', () {
      final stopwatch = Stopwatch();
      final result = Result<int, String>.success(42);

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        final chained = result
          .map((x) => x * 2)
          .map((x) => x + 1)
          .map((x) => x.toString())
          .map((x) => x.length);

        // Use result to prevent optimization
        if (chained.value != null && chained.value! < 0) print(chained.value);
      }
      stopwatch.stop();

      print('Method chaining time: ${stopwatch.elapsedMicroseconds}μs');

      // Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
```

### Property-Based Tests

```dart
// test/property/result_properties_test.dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('Result Properties', () {
    test('map preserves success/failure state', () {
      // Property: mapping a success always results in success
      // Property: mapping a failure always results in failure

      for (int i = 0; i < 1000; i++) {
        final successResult = Result<int, String>.success(i);
        final failureResult = Result<int, String>.failure('error $i');

        final mappedSuccess = successResult.map((x) => x.toString());
        final mappedFailure = failureResult.map((x) => x.toString());

        expect(mappedSuccess.isSuccess, isTrue);
        expect(mappedFailure.isFailure, isTrue);
      }
    });

    test('flatMap associativity', () {
      // Property: (m flatMap f) flatMap g == m flatMap (x => f(x) flatMap g)

      final m = Result<int, String>.success(42);
      final f = (int x) => Result<String, String>.success(x.toString());
      final g = (String x) => Result<int, String>.success(x.length);

      final left = m.flatMap(f).flatMap(g);
      final right = m.flatMap((x) => f(x).flatMap(g));

      expect(left.value, equals(right.value));
      expect(left.isSuccess, equals(right.isSuccess));
    });

    test('when exhaustiveness', () {
      // Property: when should handle all cases

      final results = [
        Result<int, String>.success(42),
        Result<int, String>.failure('error'),
      ];

      for (final result in results) {
        final output = result.when(
          success: (value) => 'success',
          failure: (error) => 'failure',
        );

        expect(output, isIn(['success', 'failure']));
      }
    });
  });
}
```

## 🎯 Test Coverage Goals

- **Unit Tests**: 100% line coverage
- **Branch Coverage**: 95% minimum
- **Integration Tests**: All major workflows
- **Performance Tests**: Overhead < 5x try-catch
- **Example Tests**: All documentation examples

## 🚀 Continuous Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Analyze code
        run: dart analyze

      - name: Format check
        run: dart format --output=none --set-exit-if-changed .

      - name: Run tests
        run: dart test --coverage=coverage

      - name: Generate coverage report
        run: dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

## 🔧 Test Utilities

```dart
// test/helpers/test_helpers.dart
import 'package:tryx/tryx.dart';

/// Creates a successful result for testing
Result<T, E> success<T, E extends Object>(T value) => Result.success(value);

/// Creates a failure result for testing
Result<T, E> failure<T, E extends Object>(E error) => Result.failure(error);

/// Asserts that a result is successful with expected value
void expectSuccess<T, E extends Object>(Result<T, E> result, T expectedValue) {
  expect(result.isSuccess, isTrue, reason: 'Expected success but got failure: ${result.error}');
  expect(result.value, equals(expectedValue));
}

/// Asserts that a result is a failure with expected error
void expectFailure<T, E extends Object>(Result<T, E> result, E expectedError) {
  expect(result.isFailure, isTrue, reason: 'Expected failure but got success: ${result.value}');
  expect(result.error, equals(expectedError));
}

/// Asserts that a result is a failure of specific type
void expectFailureType<T, E extends Object, F extends E>(Result<T, E> result) {
  expect(result.isFailure, isTrue, reason: 'Expected failure but got success: ${result.value}');
  expect(result.error, isA<F>());
}
```

This comprehensive testing strategy ensures the Tryx library is reliable, performant, and maintainable while providing excellent developer experience.
