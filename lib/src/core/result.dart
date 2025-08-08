import 'package:meta/meta.dart';

/// Core Result type that encapsulates success/failure outcomes.
///
/// [Result] is a sealed class that represents the outcome of an operation
/// that can either succeed with a value of type [T] or fail with an error
/// of type [E]. This provides a type-safe way to handle errors without
/// using exceptions.
///
/// Example:
/// ```dart
/// Result<int, String> parseNumber(String input) {
///   final number = int.tryParse(input);
///   return number != null
///     ? Result.success(number)
///     : Result.failure('Invalid number: $input');
/// }
/// ```
@immutable
sealed class Result<T, E extends Object> {
  /// Creates a Result instance.
  const Result();

  /// Creates a successful result containing the given [value].
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.success(42);
  /// print(result.isSuccess); // true
  /// print(result.value); // 42
  /// ```
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failure result containing the given [error].
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.failure('Something went wrong');
  /// print(result.isFailure); // true
  /// print(result.error); // 'Something went wrong'
  /// ```
  const factory Result.failure(E error) = Failure<T, E>;

  /// Returns `true` if this is a [Success] result.
  bool get isSuccess => switch (this) {
    Success() => true,
    Failure() => false,
  };

  /// Returns `true` if this is a [Failure] result.
  bool get isFailure => !isSuccess;

  /// Gets the success value or `null` if this is a failure.
  ///
  /// Example:
  /// ```dart
  /// final success = Result<int, String>.success(42);
  /// final failure = Result<int, String>.failure('error');
  ///
  /// print(success.value); // 42
  /// print(failure.value); // null
  /// ```
  T? get value => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  /// Gets the error or `null` if this is a success.
  ///
  /// Example:
  /// ```dart
  /// final success = Result<int, String>.success(42);
  /// final failure = Result<int, String>.failure('error');
  ///
  /// print(success.error); // null
  /// print(failure.error); // 'error'
  /// ```
  E? get error => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Result<T, E> &&
        switch ((this, other)) {
          (Success(value: final a), Success(value: final b)) => a == b,
          (Failure(error: final a), Failure(error: final b)) => a == b,
          _ => false,
        };
  }

  @override
  int get hashCode => switch (this) {
    Success(value: final v) => Object.hash('Success', v),
    Failure(error: final e) => Object.hash('Failure', e),
  };

  @override
  String toString() => switch (this) {
    Success(value: final v) => 'Success($v)',
    Failure(error: final e) => 'Failure($e)',
  };
}

/// Success state implementation of [Result].
///
/// Represents a successful operation outcome containing a value of type [T].
/// This class is immutable and provides access to the success value.
@immutable
final class Success<T, E extends Object> extends Result<T, E> {
  /// Creates a Success result with the given [value].
  const Success(this._value);

  final T _value;

  /// The success value.
  ///
  /// This getter provides direct access to the success value without
  /// null checking, since Success is guaranteed to contain a value.
  @override
  T get value => _value;

  /// Always returns `null` since Success results don't have errors.
  @override
  E? get error => null;

  /// Always returns `true` for Success results.
  @override
  bool get isSuccess => true;

  /// Always returns `false` for Success results.
  @override
  bool get isFailure => false;
}

/// Failure state implementation of [Result].
///
/// Represents a failed operation outcome containing an error of type [E].
/// This class is immutable and provides access to the error information.
@immutable
final class Failure<T, E extends Object> extends Result<T, E> {
  /// Creates a Failure result with the given [error].
  const Failure(this._error);

  final E _error;

  /// The error that caused the failure.
  ///
  /// This getter provides direct access to the error without null checking,
  /// since Failure is guaranteed to contain an error.
  @override
  E get error => _error;

  /// Always returns `null` since Failure results don't have values.
  @override
  T? get value => null;

  /// Always returns `false` for Failure results.
  @override
  bool get isSuccess => false;

  /// Always returns `true` for Failure results.
  @override
  bool get isFailure => true;
}

/// Type alias for common usage with [Exception] as the error type.
///
/// This provides a convenient shorthand for the most common use case
/// where errors are represented as [Exception] instances.
///
/// Example:
/// ```dart
/// SafeResult<String> readFile(String path) {
///   try {
///     final content = File(path).readAsStringSync();
///     return Result.success(content);
///   } catch (e) {
///     return Result.failure(e is Exception ? e : Exception(e.toString()));
///   }
/// }
/// ```
typedef SafeResult<T> = Result<T, Exception>;
