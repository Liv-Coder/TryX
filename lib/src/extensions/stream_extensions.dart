import 'dart:async';

import 'package:tryx/src/core/result.dart';
import 'package:tryx/src/extensions/result_extensions.dart';

/// Extensions for working with [Stream] instances and converting them to safe streams.
///
/// These extensions provide functionality to convert regular streams into
/// streams of [Result] instances, enabling safe stream processing without
/// traditional try-catch blocks in stream transformations.
extension StreamSafeExtensions<T> on Stream<T> {
  /// Converts a stream to a stream of [Result] instances.
  ///
  /// Each emitted value is wrapped in a [Success], and any errors are
  /// caught and wrapped in [Failure] instances. This allows for safe
  /// stream processing without losing any data or stopping the stream
  /// on errors.
  ///
  /// The [errorMapper] function can be used to transform caught errors
  /// into custom error types.
  ///
  /// Example:
  /// ```dart
  /// final numberStream = Stream.fromIterable(['1', '2', 'invalid', '4']);
  /// final safeStream = numberStream
  ///   .map((s) => int.parse(s))
  ///   .safeStream<int, Exception>();
  ///
  /// await for (final result in safeStream) {
  ///   result.when(
  ///     success: (number) => print('Parsed: $number'),
  ///     failure: (error) => print('Parse error: $error'),
  ///   );
  /// }
  /// ```
  Stream<Result<R, E>> safeStream<R, E extends Object>({
    E Function(Object error)? errorMapper,
  }) => transform(
    StreamTransformer<T, Result<R, E>>.fromHandlers(
      handleData: (T data, EventSink<Result<R, E>> sink) {
        try {
          sink.add(Result<R, E>.success(data as R));
        } on Exception catch (error) {
          final mappedError = errorMapper?.call(error) ?? error;
          if (mappedError is E) {
            sink.add(Result<R, E>.failure(mappedError));
          } else {
            sink.addError(error);
          }
        }
      },
      handleError:
          (Object error, StackTrace stackTrace, EventSink<Result<R, E>> sink) {
            final mappedError = errorMapper?.call(error) ?? error;
            if (mappedError is E) {
              sink.add(Result<R, E>.failure(mappedError));
            } else {
              sink.addError(error, stackTrace);
            }
          },
    ),
  );

  /// Safely transforms each element using the provided function.
  ///
  /// This is similar to [Stream.map] but wraps the transformation in a
  /// safe execution context. If the transformation throws an error,
  /// it's caught and wrapped in a [Failure].
  ///
  /// Example:
  /// ```dart
  /// final stringStream = Stream.fromIterable(['1', '2', 'invalid', '4']);
  /// final safeNumbers = stringStream.safeMap<int, Exception>(
  ///   (s) => int.parse(s),
  /// );
  ///
  /// await for (final result in safeNumbers) {
  ///   result.when(
  ///     success: (number) => print('Number: $number'),
  ///     failure: (error) => print('Error: $error'),
  ///   );
  /// }
  /// ```
  Stream<Result<U, E>> safeMap<U, E extends Object>(
    U Function(T value) mapper, {
    E Function(Object error)? errorMapper,
  }) => map((value) {
    try {
      return Result<U, E>.success(mapper(value));
    } catch (error) {
      final mappedError = errorMapper?.call(error) ?? error;
      if (mappedError is E) {
        return Result<U, E>.failure(mappedError);
      } else {
        rethrow;
      }
    }
  });

  /// Safely transforms each element using an async function.
  ///
  /// Similar to [safeMap] but for asynchronous transformations.
  /// Each transformation is executed safely and errors are caught
  /// and wrapped in [Failure] instances.
  ///
  /// Example:
  /// ```dart
  /// final urlStream = Stream.fromIterable(['http://api1.com', 'invalid-url']);
  /// final responses = urlStream.safeAsyncMap<String, Exception>(
  ///   (url) => httpClient.get(url).then((response) => response.body),
  /// );
  /// ```
  Stream<Result<U, E>> safeAsyncMap<U, E extends Object>(
    Future<U> Function(T value) mapper, {
    E Function(Object error)? errorMapper,
  }) => asyncMap((value) async {
    try {
      final result = await mapper(value);
      return Result<U, E>.success(result);
    } catch (error) {
      final mappedError = errorMapper?.call(error) ?? error;
      if (mappedError is E) {
        return Result<U, E>.failure(mappedError);
      } else if (error is E) {
        return Result<U, E>.failure(error);
      } else {
        // If no error mapper provided and error is not of type E,
        // try to convert error to string if E is String
        if (E == String) {
          return Result<U, E>.failure(error.toString() as E);
        }
        rethrow;
      }
    }
  });

  /// Safely expands each element into multiple elements.
  ///
  /// Similar to [Stream.expand] but wraps the expansion in a safe
  /// execution context. If the expansion function throws an error,
  /// it's caught and the stream continues with the next element.
  ///
  /// Example:
  /// ```dart
  /// final stringStream = Stream.fromIterable(['1,2', '3,4', 'invalid']);
  /// final numbers = stringStream.safeExpand<int, Exception>(
  ///   (s) => s.split(',').map(int.parse),
  /// );
  /// ```
  Stream<Result<U, E>> safeExpand<U, E extends Object>(
    Iterable<U> Function(T value) expander, {
    E Function(Object error)? errorMapper,
  }) => transform(
    StreamTransformer<T, Result<U, E>>.fromHandlers(
      handleData: (T data, EventSink<Result<U, E>> sink) {
        try {
          final expanded = expander(data);
          for (final item in expanded) {
            sink.add(Result<U, E>.success(item));
          }
        } on Exception catch (error) {
          final mappedError = errorMapper?.call(error) ?? error;
          if (mappedError is E) {
            sink.add(Result<U, E>.failure(mappedError));
          } else {
            sink.addError(error);
          }
        }
      },
    ),
  );

  /// Safely filters elements using the provided predicate.
  ///
  /// If the predicate throws an error for an element, that element
  /// is wrapped in a [Failure] and included in the stream.
  ///
  /// Example:
  /// ```dart
  /// final numberStream = Stream.fromIterable([1, 2, 3, 4, 5]);
  /// final evenNumbers = numberStream.safeWhere<Exception>(
  ///   (n) => n.isEven,
  /// );
  /// ```
  Stream<Result<T, E>> safeWhere<E extends Object>(
    bool Function(T value) predicate, {
    E Function(Object error)? errorMapper,
  }) => map((value) {
    try {
      if (predicate(value)) {
        return Result<T, E>.success(value);
      } else {
        return null; // Will be filtered out
      }
    } catch (error) {
      final mappedError = errorMapper?.call(error) ?? error;
      if (mappedError is E) {
        return Result<T, E>.failure(mappedError);
      } else {
        rethrow;
      }
    }
  }).where((result) => result != null).cast<Result<T, E>>();
}

/// Extensions for working with [Stream<Result>] instances.
///
/// These extensions provide functionality to work with streams that already
/// contain [Result] instances, allowing for filtering, transformation, and
/// error handling of result streams.
extension StreamResultExtensions<T, E extends Object> on Stream<Result<T, E>> {
  /// Filters the stream to only emit successful results.
  ///
  /// Returns a stream of the success values, effectively filtering out
  /// all failures. This is useful when you want to process only the
  /// successful results and ignore errors.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error'),
  ///   Result<int, String>.success(3),
  /// ]);
  ///
  /// final successStream = resultStream.successes();
  /// await for (final value in successStream) {
  ///   print('Success: $value'); // Prints: 1, 3
  /// }
  /// ```
  Stream<T> successes() =>
      where((result) => result is Success).map((result) => result.getOrNull()!);

  /// Filters the stream to only emit failed results.
  ///
  /// Returns a stream of the error values, effectively filtering out
  /// all successes. This is useful for error monitoring and logging.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error1'),
  ///   Result<int, String>.failure('error2'),
  /// ]);
  ///
  /// final errorStream = resultStream.failures();
  /// await for (final error in errorStream) {
  ///   print('Error: $error'); // Prints: error1, error2
  /// }
  /// ```
  Stream<E> failures() => where((result) => result is Failure).map(
    (result) => result.when(
      success: (_) => throw StateError('Expected failure'),
      failure: (error) => error,
    ),
  );

  /// Maps successful values while preserving failures.
  ///
  /// Applies the mapper function only to successful results, leaving
  /// failures unchanged. This allows for safe transformation of success
  /// values without affecting error handling.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error'),
  ///   Result<int, String>.success(3),
  /// ]);
  ///
  /// final doubledStream = resultStream.mapSuccesses((x) => x * 2);
  /// ```
  Stream<Result<U, E>> mapSuccesses<U>(U Function(T value) mapper) =>
      map((result) => result.map(mapper));

  /// Safely maps successful values with error handling.
  ///
  /// Similar to [mapSuccesses] but wraps the mapping function in a
  /// safe execution context. If the mapper throws an error, it's
  /// caught and converted to a failure.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<String, String>.success('1'),
  ///   Result<String, String>.success('invalid'),
  /// ]);
  ///
  /// final numberStream = resultStream.safeMapSuccesses<int>(
  ///   (s) => int.parse(s),
  /// );
  /// ```
  Stream<Result<U, E>> safeMapSuccesses<U>(
    U Function(T value) mapper, {
    E Function(Object error)? errorMapper,
  }) => map((result) {
    if (result is Success<T, E>) {
      try {
        final value = result.getOrNull() as T;
        return Result<U, E>.success(mapper(value));
      } catch (error) {
        final mappedError = errorMapper?.call(error) ?? error;
        if (mappedError is E) {
          return Result<U, E>.failure(mappedError);
        } else {
          rethrow;
        }
      }
    } else {
      return result as Result<U, E>;
    }
  });

  /// Flat maps successful values while preserving failures.
  ///
  /// Applies the mapper function only to successful results, which should
  /// return a new [Result]. This allows for chaining operations that can
  /// fail while preserving the error handling chain.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<String, String>.success('1'),
  ///   Result<String, String>.success('invalid'),
  /// ]);
  ///
  /// final numberStream = resultStream.flatMapSuccesses(
  ///   (s) => safe(() => int.parse(s)),
  /// );
  /// ```
  Stream<Result<U, E>> flatMapSuccesses<U>(
    Result<U, E> Function(T value) mapper,
  ) => map((result) => result.flatMap(mapper));

  /// Executes side effects on successful results.
  ///
  /// Calls the provided action for each successful result without
  /// modifying the stream. This is useful for logging, caching, or
  /// other side effects.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error'),
  /// ]);
  ///
  /// final loggedStream = resultStream.onSuccesses(
  ///   (value) => print('Success: $value'),
  /// );
  /// ```
  Stream<Result<T, E>> onSuccesses(void Function(T value) action) =>
      map((result) => result.onSuccess(action));

  /// Executes side effects on failed results.
  ///
  /// Calls the provided action for each failed result without
  /// modifying the stream. This is useful for error logging,
  /// monitoring, or alerting.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error'),
  /// ]);
  ///
  /// final loggedStream = resultStream.onFailures(
  ///   (error) => logError(error),
  /// );
  /// ```
  Stream<Result<T, E>> onFailures(void Function(E error) action) =>
      map((result) => result.onFailure(action));

  /// Recovers from failures using the provided recovery function.
  ///
  /// For each failed result, calls the recovery function to provide
  /// a fallback value, converting the failure to a success.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error'),
  /// ]);
  ///
  /// final recoveredStream = resultStream.recover(
  ///   (error) => -1, // Default value for errors
  /// );
  /// ```
  Stream<Result<T, E>> recover(T Function(E error) recovery) =>
      map((result) => result.recover(recovery));

  /// Recovers from failures using another [Result].
  ///
  /// For each failed result, calls the recovery function which should
  /// return another [Result]. This allows for more complex recovery
  /// logic that might also fail.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('network_error'),
  /// ]);
  ///
  /// final recoveredStream = resultStream.recoverWith(
  ///   (error) => error == 'network_error'
  ///     ? Result.success(0) // Use cached value
  ///     : Result.failure(error), // Don't recover from other errors
  /// );
  /// ```
  Stream<Result<T, E>> recoverWith(Result<T, E> Function(E error) recovery) =>
      map((result) => result.recoverWith(recovery));

  /// Collects all results into a single [Result] containing a list.
  ///
  /// If all results in the stream are successful, returns a [Success]
  /// containing a list of all values. If any result is a failure,
  /// returns the first [Failure] encountered.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.success(2),
  ///   Result<int, String>.success(3),
  /// ]);
  ///
  /// final collected = await resultStream.collectResults();
  /// print(collected.value); // [1, 2, 3]
  /// ```
  Future<Result<List<T>, E>> collectResults() async {
    final values = <T>[];

    await for (final result in this) {
      if (result is Success<T, E>) {
        values.add(result.getOrNull() as T);
      } else if (result is Failure<T, E>) {
        return result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: Result.failure,
        );
      }
    }

    return Result.success(values);
  }

  /// Partitions the stream into successes and failures.
  ///
  /// Returns a record containing two lists: one with all successful
  /// values and another with all error values.
  ///
  /// Example:
  /// ```dart
  /// final resultStream = Stream.fromIterable([
  ///   Result<int, String>.success(1),
  ///   Result<int, String>.failure('error1'),
  ///   Result<int, String>.success(3),
  /// ]);
  ///
  /// final (successes, failures) = await resultStream.partition();
  /// print(successes); // [1, 3]
  /// print(failures); // ['error1']
  /// ```
  Future<({List<T> successes, List<E> failures})> partition() async {
    final successes = <T>[];
    final failures = <E>[];

    await for (final result in this) {
      if (result is Success<T, E>) {
        successes.add(result.getOrNull() as T);
      } else if (result is Failure<T, E>) {
        result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: failures.add,
        );
      }
    }

    return (successes: successes, failures: failures);
  }
}
