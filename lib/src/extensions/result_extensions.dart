import 'dart:async';

import 'package:tryx/src/core/result.dart';

/// Extensions that add functional programming methods to [Result].
///
/// These extensions provide a fluent API for transforming, chaining,
/// and handling [Result] instances in a functional programming style.
extension ResultExtensions<T, E extends Object> on Result<T, E> {
  /// Transforms the success value using the provided [mapper] function.
  ///
  /// If this is a [Success], applies [mapper] to the value and returns
  /// a new [Success] with the transformed value. If this is a [Failure],
  /// returns the failure unchanged.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.success(42);
  /// final mapped = result.map((x) => x.toString());
  /// print(mapped.value); // '42'
  ///
  /// final failure = Result<int, String>.failure('error');
  /// final mappedFailure = failure.map((x) => x.toString());
  /// print(mappedFailure.error); // 'error'
  /// ```
  Result<U, E> map<U>(U Function(T value) mapper) => switch (this) {
        Success() => Result.success(mapper((this as Success<T, E>).value)),
        Failure() => this as Result<U, E>,
      };

  /// Chains this result with another operation that returns a [Result].
  ///
  /// If this is a [Success], applies [mapper] to the value and returns
  /// the result. If this is a [Failure], returns the failure unchanged.
  /// This is useful for chaining operations that can fail.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> parseNumber(String input) {
  ///   final number = int.tryParse(input);
  ///   return number != null
  ///     ? Result.success(number)
  ///     : Result.failure('Invalid number');
  /// }
  ///
  /// final result = Result<String, String>.success('42');
  /// final chained = result.flatMap(parseNumber);
  /// print(chained.value); // 42
  /// ```
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) mapper) =>
      switch (this) {
        Success() => mapper((this as Success<T, E>).value),
        Failure() => this as Result<U, E>,
      };

  /// Transforms the error using the provided [mapper] function.
  ///
  /// If this is a [Failure], applies [mapper] to the error and returns
  /// a new [Failure] with the transformed error. If this is a [Success],
  /// returns the success unchanged.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.failure('network error');
  /// final mapped = result.mapError((error) => 'Failed: $error');
  /// print(mapped.error); // 'Failed: network error'
  /// ```
  Result<T, F> mapError<F extends Object>(F Function(E error) mapper) =>
      switch (this) {
        Success() => this as Result<T, F>,
        Failure() => Result.failure(mapper((this as Failure<T, E>).error)),
      };

  /// Pattern matching that handles both success and failure cases.
  ///
  /// This method provides exhaustive pattern matching by requiring
  /// handlers for both success and failure cases. It's useful when
  /// you need to transform the result into a different type.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.success(42);
  /// final message = result.when(
  ///   success: (value) => 'Got: $value',
  ///   failure: (error) => 'Error: $error',
  /// );
  /// print(message); // 'Got: 42'
  /// ```
  U when<U>({
    required U Function(T value) success,
    required U Function(E error) failure,
  }) =>
      switch (this) {
        Success() => success((this as Success<T, E>).value),
        Failure() => failure((this as Failure<T, E>).error),
      };

  /// Folds the result into a single value.
  ///
  /// This is an alias for [when] with the parameters in a different order,
  /// following functional programming conventions where the failure case
  /// is typically handled first.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.success(42);
  /// final message = result.fold(
  ///   (error) => 'Error: $error',
  ///   (value) => 'Success: $value',
  /// );
  /// print(message); // 'Success: 42'
  /// ```
  U fold<U>(U Function(E error) onFailure, U Function(T value) onSuccess) =>
      when(success: onSuccess, failure: onFailure);

  /// Executes a side effect if this is a [Success].
  ///
  /// The [action] is called with the success value, but the original
  /// result is returned unchanged. This is useful for logging, caching,
  /// or other side effects.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.success(42);
  /// final sameResult = result.onSuccess((value) => print('Got: $value'));
  /// // Prints: Got: 42
  /// print(sameResult == result); // true
  /// ```
  Result<T, E> onSuccess(void Function(T value) action) {
    if (this case Success()) {
      action((this as Success<T, E>).value);
    }
    return this;
  }

  /// Executes a side effect if this is a [Failure].
  ///
  /// The [action] is called with the error, but the original result
  /// is returned unchanged. This is useful for logging, error reporting,
  /// or other side effects.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, String>.failure('error');
  /// final sameResult = result.onFailure((error) => print('Error: $error'));
  /// // Prints: Error: error
  /// print(sameResult == result); // true
  /// ```
  Result<T, E> onFailure(void Function(E error) action) {
    if (this case Failure()) {
      action((this as Failure<T, E>).error);
    }
    return this;
  }

  /// Gets the value if this is a [Success], otherwise returns the default value.
  ///
  /// The [defaultValue] function is only called if this is a [Failure],
  /// allowing for lazy evaluation of the default.
  ///
  /// Example:
  /// ```dart
  /// final success = Result<int, String>.success(42);
  /// final failure = Result<int, String>.failure('error');
  ///
  /// print(success.getOrElse(() => 0)); // 42
  /// print(failure.getOrElse(() => 0)); // 0
  /// ```
  T getOrElse(T Function() defaultValue) => switch (this) {
        Success() => (this as Success<T, E>).value,
        Failure() => defaultValue(),
      };

  /// Gets the value if this is a [Success], otherwise returns `null`.
  ///
  /// This is a convenience method for cases where you want to handle
  /// the success case and ignore failures.
  ///
  /// Example:
  /// ```dart
  /// final success = Result<int, String>.success(42);
  /// final failure = Result<int, String>.failure('error');
  ///
  /// print(success.getOrNull()); // 42
  /// print(failure.getOrNull()); // null
  /// ```
  T? getOrNull() => switch (this) {
        Success() => (this as Success<T, E>).value,
        Failure() => null,
      };

  /// Recovers from a failure by providing a fallback value.
  ///
  /// If this is a [Success], returns the success unchanged. If this is
  /// a [Failure], calls [recovery] with the error and returns a new
  /// [Success] with the recovered value.
  ///
  /// Example:
  /// ```dart
  /// final failure = Result<int, String>.failure('network error');
  /// final recovered = failure.recover((error) => -1);
  /// print(recovered.value); // -1
  /// ```
  Result<T, E> recover(T Function(E error) recovery) => switch (this) {
        Success() => this,
        Failure() => Result.success(recovery((this as Failure<T, E>).error)),
      };

  /// Recovers from a failure by providing another [Result].
  ///
  /// If this is a [Success], returns the success unchanged. If this is
  /// a [Failure], calls [recovery] with the error and returns the
  /// resulting [Result]. This allows for more complex recovery logic.
  ///
  /// Example:
  /// ```dart
  /// final failure = Result<int, String>.failure('network error');
  /// final recovered = failure.recoverWith((error) {
  ///   if (error.contains('network')) {
  ///     return Result.success(-1); // Use cached value
  ///   }
  ///   return Result.failure('Unrecoverable: $error');
  /// });
  /// ```
  Result<T, E> recoverWith(Result<T, E> Function(E error) recovery) =>
      switch (this) {
        Success() => this,
        Failure() => recovery((this as Failure<T, E>).error),
      };
}

/// Extensions for working with [Future<Result>] instances.
///
/// These extensions provide async versions of the core Result operations,
/// allowing for fluent chaining of asynchronous operations.
extension FutureResultExtensions<T, E extends Object> on Future<Result<T, E>> {
  /// Asynchronously transforms the success value.
  ///
  /// If the result is a [Success], applies [mapper] to the value and
  /// returns a new [Success] with the transformed value. If the result
  /// is a [Failure], returns the failure unchanged.
  ///
  /// Example:
  /// ```dart
  /// final futureResult = Future.value(Result<int, String>.success(42));
  /// final mapped = await futureResult.mapAsync((x) async => x.toString());
  /// print(mapped.value); // '42'
  /// ```
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T value) mapper) async {
    final result = await this;
    return switch (result) {
      Success() => Result.success(await mapper(result.getOrNull() as T)),
      Failure() => Result.failure(result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e)),
    };
  }

  /// Asynchronously chains this result with another operation.
  ///
  /// If the result is a [Success], applies [mapper] to the value and
  /// returns the resulting [Result]. If the result is a [Failure],
  /// returns the failure unchanged.
  ///
  /// Example:
  /// ```dart
  /// final futureResult = Future.value(Result<String, String>.success('42'));
  /// final chained = await futureResult.flatMapAsync((value) async {
  ///   final number = int.tryParse(value);
  ///   return number != null
  ///     ? Result.success(number)
  ///     : Result.failure('Invalid number');
  /// });
  /// ```
  Future<Result<U, E>> flatMapAsync<U>(
    Future<Result<U, E>> Function(T value) mapper,
  ) async {
    final result = await this;
    return switch (result) {
      Success() => await mapper(result.getOrNull() as T),
      Failure() => Result.failure(result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e)),
    };
  }

  /// Asynchronous pattern matching for [Future<Result>].
  ///
  /// This method provides exhaustive pattern matching by requiring
  /// async handlers for both success and failure cases.
  ///
  /// Example:
  /// ```dart
  /// final futureResult = Future.value(Result<int, String>.success(42));
  /// final message = await futureResult.whenAsync(
  ///   success: (value) async => 'Got: $value',
  ///   failure: (error) async => 'Error: $error',
  /// );
  /// print(message); // 'Got: 42'
  /// ```
  Future<U> whenAsync<U>({
    required Future<U> Function(T value) success,
    required Future<U> Function(E error) failure,
  }) async {
    final result = await this;
    return switch (result) {
      Success() => await success(result.getOrNull() as T),
      Failure() => await failure(result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e)),
    };
  }
}
