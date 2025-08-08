# Tryx Library - API Design Document

## 🎯 Overview

Tryx is a minimalistic and expressive Dart library for handling errors without traditional try-catch blocks. It provides a clean, functional, and beginner-friendly alternative using a declarative API similar to Result, Either, or safeCall patterns from Kotlin, Swift, or Rust.

## 🏗️ Core Architecture

### 1. Result<T, E> - Core Type

The foundation of the library is a generic `Result<T, E>` type that encapsulates success and failure states:

```dart
/// Core Result type that encapsulates success/failure outcomes
sealed class Result<T, E extends Object> {
  const Result();

  /// Creates a successful result
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failure result
  const factory Result.failure(E error) = Failure<T, E>;

  /// Returns true if this is a success
  bool get isSuccess;

  /// Returns true if this is a failure
  bool get isFailure;

  /// Gets the success value or null
  T? get value;

  /// Gets the error or null
  E? get error;
}

/// Success state implementation
final class Success<T, E extends Object> extends Result<T, E> {
  const Success(this._value);

  final T _value;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T get value => _value;

  @override
  E? get error => null;
}

/// Failure state implementation
final class Failure<T, E extends Object> extends Result<T, E> {
  const Failure(this._error);

  final E _error;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get value => null;

  @override
  E get error => _error;
}

/// Type alias for common usage with Exception
typedef SafeResult<T> = Result<T, Exception>;
```

### 2. Primary API - safe() Function

The main entry point for safe execution:

```dart
/// Safely executes a synchronous function
SafeResult<T> safe<T>(T Function() fn) {
  try {
    return Result.success(fn());
  } catch (e) {
    return Result.failure(e is Exception ? e : Exception(e.toString()));
  }
}

/// Safely executes an asynchronous function
Future<SafeResult<T>> safeAsync<T>(Future<T> Function() fn) async {
  try {
    final result = await fn();
    return Result.success(result);
  } catch (e) {
    return Result.failure(e is Exception ? e : Exception(e.toString()));
  }
}

/// Generic safe execution that handles both sync and async
Future<Result<T, E>> safeWith<T, E extends Object>(
  FutureOr<T> Function() fn, {
  E Function(Object error)? errorMapper,
}) async {
  try {
    final result = await fn();
    return Result.success(result);
  } catch (e) {
    final mappedError = errorMapper?.call(e) ?? e as E;
    return Result.failure(mappedError);
  }
}
```

### 3. Method Chaining API

Rich functional programming methods for Result:

```dart
extension ResultExtensions<T, E extends Object> on Result<T, E> {
  /// Maps the success value to a new type
  Result<U, E> map<U>(U Function(T value) mapper) {
    return switch (this) {
      Success(value: final v) => Result.success(mapper(v)),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Flat maps the success value to a new Result
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) mapper) {
    return switch (this) {
      Success(value: final v) => mapper(v),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Maps the error to a new type
  Result<T, F> mapError<F extends Object>(F Function(E error) mapper) {
    return switch (this) {
      Success(value: final v) => Result.success(v),
      Failure(error: final e) => Result.failure(mapper(e)),
    };
  }

  /// Pattern matching with when
  U when<U>({
    required U Function(T value) success,
    required U Function(E error) failure,
  }) {
    return switch (this) {
      Success(value: final v) => success(v),
      Failure(error: final e) => failure(e),
    };
  }

  /// Fold operation (alias for when)
  U fold<U>(
    U Function(E error) onFailure,
    U Function(T value) onSuccess,
  ) {
    return when(success: onSuccess, failure: onFailure);
  }

  /// Execute side effect on success
  Result<T, E> onSuccess(void Function(T value) action) {
    if (this case Success(value: final v)) {
      action(v);
    }
    return this;
  }

  /// Execute side effect on failure
  Result<T, E> onFailure(void Function(E error) action) {
    if (this case Failure(error: final e)) {
      action(e);
    }
    return this;
  }

  /// Get value or provide default
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(value: final v) => v,
      Failure() => defaultValue(),
    };
  }

  /// Get value or null
  T? getOrNull() {
    return switch (this) {
      Success(value: final v) => v,
      Failure() => null,
    };
  }

  /// Recover from failure
  Result<T, E> recover(T Function(E error) recovery) {
    return switch (this) {
      Success() => this,
      Failure(error: final e) => Result.success(recovery(e)),
    };
  }

  /// Recover from failure with another Result
  Result<T, E> recoverWith(Result<T, E> Function(E error) recovery) {
    return switch (this) {
      Success() => this,
      Failure(error: final e) => recovery(e),
    };
  }
}
```

### 4. Async Extensions

Extensions for working with Future<Result>:

```dart
extension FutureResultExtensions<T, E extends Object> on Future<Result<T, E>> {
  /// Async map
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T value) mapper) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => Result.success(await mapper(v)),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Async flat map
  Future<Result<U, E>> flatMapAsync<U>(
    Future<Result<U, E>> Function(T value) mapper,
  ) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => await mapper(v),
      Failure(error: final e) => Result.failure(e),
    };
  }

  /// Async when
  Future<U> whenAsync<U>({
    required Future<U> Function(T value) success,
    required Future<U> Function(E error) failure,
  }) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => await success(v),
      Failure(error: final e) => await failure(e),
    };
  }
}
```

### 5. Stream Integration

Extensions for working with streams:

```dart
extension StreamResultExtensions<T, E extends Object> on Stream<T> {
  /// Convert stream to stream of results
  Stream<Result<T, E>> safeStream({
    E Function(Object error)? errorMapper,
  }) {
    return map((value) => Result<T, E>.success(value))
        .handleError((error) {
      final mappedError = errorMapper?.call(error) ?? error as E;
      return Result<T, E>.failure(mappedError);
    });
  }
}

extension ResultStreamExtensions<T, E extends Object> on Stream<Result<T, E>> {
  /// Filter only successful results
  Stream<T> successes() {
    return where((result) => result.isSuccess)
        .map((result) => result.value!);
  }

  /// Filter only failed results
  Stream<E> failures() {
    return where((result) => result.isFailure)
        .map((result) => result.error!);
  }

  /// Map successful values
  Stream<Result<U, E>> mapSuccesses<U>(U Function(T value) mapper) {
    return map((result) => result.map(mapper));
  }
}
```

### 6. Safe Class for Advanced Usage

```dart
/// Advanced configuration class for safe execution
class Safe {
  const Safe({
    this.errorMapper,
    this.logger,
    this.timeout,
    this.retryPolicy,
  });

  final Object Function(Object error)? errorMapper;
  final void Function(Object error)? logger;
  final Duration? timeout;
  final RetryPolicy? retryPolicy;

  /// Execute with configuration
  Future<Result<T, E>> call<T, E extends Object>(
    FutureOr<T> Function() fn,
  ) async {
    var attempts = 0;
    final maxAttempts = retryPolicy?.maxAttempts ?? 1;

    while (attempts < maxAttempts) {
      try {
        final Future<T> future = Future.value(fn());
        final result = timeout != null
            ? await future.timeout(timeout!)
            : await future;
        return Result.success(result);
      } catch (e) {
        attempts++;
        logger?.call(e);

        if (attempts >= maxAttempts) {
          final mappedError = errorMapper?.call(e) ?? e;
          return Result.failure(mappedError as E);
        }

        if (retryPolicy?.delay != null) {
          await Future.delayed(retryPolicy!.delay!);
        }
      }
    }

    // This should never be reached, but for type safety
    return Result.failure(Exception('Unexpected error') as E);
  }

  /// Static convenience methods
  static Future<SafeResult<T>> execute<T>(
    FutureOr<T> Function() fn, {
    Duration? timeout,
    RetryPolicy? retryPolicy,
  }) {
    return Safe(timeout: timeout, retryPolicy: retryPolicy).call(fn);
  }
}

/// Retry policy configuration
class RetryPolicy {
  const RetryPolicy({
    required this.maxAttempts,
    this.delay,
    this.backoffMultiplier = 1.0,
  });

  final int maxAttempts;
  final Duration? delay;
  final double backoffMultiplier;
}
```

### 7. Utility Functions

```dart
/// Combine multiple results
Result<List<T>, E> combineResults<T, E extends Object>(
  List<Result<T, E>> results,
) {
  final values = <T>[];
  for (final result in results) {
    switch (result) {
      case Success(value: final v):
        values.add(v);
      case Failure(error: final e):
        return Result.failure(e);
    }
  }
  return Result.success(values);
}

/// Convert nullable to Result
Result<T, E> fromNullable<T, E extends Object>(
  T? value,
  E Function() errorProvider,
) {
  return value != null
      ? Result.success(value)
      : Result.failure(errorProvider());
}

/// Convert boolean to Result
Result<T, E> fromBool<T, E extends Object>(
  bool condition,
  T Function() valueProvider,
  E Function() errorProvider,
) {
  return condition
      ? Result.success(valueProvider())
      : Result.failure(errorProvider());
}
```

## 📦 Package Structure

```
lib/
├── tryx.dart                 # Main export file
├── src/
│   ├── core/
│   │   ├── result.dart       # Core Result type
│   │   └── safe.dart         # Safe class and functions
│   ├── extensions/
│   │   ├── result_extensions.dart
│   │   ├── future_extensions.dart
│   │   └── stream_extensions.dart
│   ├── utils/
│   │   ├── combinators.dart  # Utility functions
│   │   └── converters.dart   # Conversion utilities
│   └── config/
│       ├── retry_policy.dart
│       └── global_config.dart
```

## 🚀 Usage Examples

### Basic Usage

```dart
// Synchronous
final result = safe(() => int.parse('42'));
result.when(
  success: (value) => print('Parsed: $value'),
  failure: (error) => print('Error: $error'),
);

// Asynchronous
final asyncResult = await safeAsync(() => fetchUserData());
asyncResult
  .map((user) => user.name)
  .onSuccess((name) => print('User: $name'))
  .onFailure((error) => logError(error));
```

### Advanced Usage

```dart
// Custom error types
sealed class ApiError extends Exception {
  const ApiError();
  factory ApiError.network() = NetworkError;
  factory ApiError.auth() = AuthError;
}

final result = await safeWith<User, ApiError>(
  () => apiClient.getUser(),
  errorMapper: (e) => e is SocketException
      ? ApiError.network()
      : ApiError.auth(),
);

// With configuration
final configuredResult = await Safe(
  timeout: Duration(seconds: 5),
  retryPolicy: RetryPolicy(maxAttempts: 3, delay: Duration(seconds: 1)),
).call(() => unreliableApiCall());
```

### Stream Usage

```dart
final stream = Stream.fromIterable([1, 2, 3, 4, 5]);
final safeStream = stream
    .safeStream<int, Exception>()
    .mapSuccesses((x) => x * 2)
    .successes();

await for (final value in safeStream) {
  print('Safe value: $value');
}
```

## 🎨 Design Principles

1. **Beginner-Friendly**: Simple `safe()` function for 95% of use cases
2. **Type-Safe**: Leverages Dart's type system and sealed classes
3. **Functional**: Supports method chaining and functional composition
4. **Flexible**: Generic error types with sensible defaults
5. **Performance**: Zero-cost abstractions where possible
6. **Interoperable**: Works seamlessly with existing Dart/Flutter code

## 🔄 Migration Strategy

### From try-catch

```dart
// Before
try {
  final user = await fetchUser();
  print('User: ${user.name}');
} catch (e) {
  print('Error: $e');
}

// After
final result = await safeAsync(() => fetchUser());
result.when(
  success: (user) => print('User: ${user.name}'),
  failure: (error) => print('Error: $error'),
);
```

This design provides a comprehensive, beginner-friendly, yet powerful error handling solution for Dart applications.
