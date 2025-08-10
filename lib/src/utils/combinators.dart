import 'package:tryx/src/core/result.dart';
import 'package:tryx/src/extensions/result_extensions.dart';

/// Utility functions for combining and transforming [Result] instances.
///
/// This library provides functions for working with multiple [Result] instances,
/// converting from nullable values, and other common operations that don't
/// fit into the core [Result] API.

/// Combines multiple [Result] instances into a single [Result] containing a list.
///
/// If all results are successful, returns a [Success] containing a list of all
/// the success values. If any result is a failure, returns the first [Failure]
/// encountered.
///
/// This is useful for operations that need all sub-operations to succeed,
/// such as validating multiple fields or fetching multiple resources.
///
/// Example:
/// ```dart
/// final results = [
///   Result<int, String>.success(1),
///   Result<int, String>.success(2),
///   Result<int, String>.success(3),
/// ];
///
/// final combined = combineResults(results);
/// print(combined.value); // [1, 2, 3]
///
/// final mixedResults = [
///   Result<int, String>.success(1),
///   Result<int, String>.failure('error'),
///   Result<int, String>.success(3),
/// ];
///
/// final combinedMixed = combineResults(mixedResults);
/// print(combinedMixed.error); // 'error'
/// ```
Result<List<T>, E> combineResults<T, E extends Object>(
  List<Result<T, E>> results,
) {
  final values = <T>[];

  for (final result in results) {
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

/// Combines multiple [Result] instances, collecting all errors.
///
/// Unlike [combineResults], this function continues processing even when
/// failures are encountered, collecting all errors. Returns a [Success]
/// with all successful values if there are any successes, or a [Failure]
/// with all errors if there are only failures.
///
/// This is useful for validation scenarios where you want to show all
/// validation errors at once rather than stopping at the first one.
///
/// Example:
/// ```dart
/// final results = [
///   Result<int, String>.success(1),
///   Result<int, String>.failure('error1'),
///   Result<int, String>.success(3),
///   Result<int, String>.failure('error2'),
/// ];
///
/// final combined = combineResultsCollectingErrors(results);
/// // Returns Success([1, 3]) - only successful values
///
/// final allFailures = [
///   Result<int, String>.failure('error1'),
///   Result<int, String>.failure('error2'),
/// ];
///
/// final combinedFailures = combineResultsCollectingErrors(allFailures);
/// // Returns Failure(['error1', 'error2'])
/// ```
Result<List<T>, List<E>> combineResultsCollectingErrors<T, E extends Object>(
  List<Result<T, E>> results,
) {
  final values = <T>[];
  final errors = <E>[];

  for (final result in results) {
    if (result is Success<T, E>) {
      values.add(result.getOrNull() as T);
    } else if (result is Failure<T, E>) {
      result.when(
        success: (_) => throw StateError('Expected failure'),
        failure: errors.add,
      );
    }
  }

  if (errors.isNotEmpty && values.isEmpty) {
    // All failed
    return Result.failure(errors);
  } else if (errors.isNotEmpty) {
    // Mixed results - could return either, but we'll return successes
    // This behavior might need to be configurable in the future
    return Result.success(values);
  } else {
    // All succeeded
    return Result.success(values);
  }
}

/// Combines two [Result] instances using a combining function.
///
/// If both results are successful, applies the [combiner] function to both
/// values and returns a [Success] with the result. If either result is a
/// failure, returns the first failure encountered.
///
/// Example:
/// ```dart
/// final result1 = Result<int, String>.success(5);
/// final result2 = Result<int, String>.success(3);
///
/// final combined = combineResults2(result1, result2, (a, b) => a + b);
/// print(combined.value); // 8
///
/// final result3 = Result<int, String>.failure('error');
/// final combinedWithError = combineResults2(result1, result3, (a, b) => a + b);
/// print(combinedWithError.error); // 'error'
/// ```
Result<R, E> combineResults2<T1, T2, R, E extends Object>(
  Result<T1, E> result1,
  Result<T2, E> result2,
  R Function(T1 value1, T2 value2) combiner,
) => result1.flatMap(
  (value1) => result2.map((value2) => combiner(value1, value2)),
);

/// Combines three [Result] instances using a combining function.
///
/// Similar to [combineResults2] but for three results.
///
/// Example:
/// ```dart
/// final result1 = Result<int, String>.success(5);
/// final result2 = Result<int, String>.success(3);
/// final result3 = Result<int, String>.success(2);
///
/// final combined = combineResults3(
///   result1, result2, result3,
///   (a, b, c) => a + b + c,
/// );
/// print(combined.value); // 10
/// ```
Result<R, E> combineResults3<T1, T2, T3, R, E extends Object>(
  Result<T1, E> result1,
  Result<T2, E> result2,
  Result<T3, E> result3,
  R Function(T1 value1, T2 value2, T3 value3) combiner,
) => result1.flatMap(
  (value1) => result2.flatMap(
    (value2) => result3.map((value3) => combiner(value1, value2, value3)),
  ),
);

/// Converts a nullable value to a [Result].
///
/// If [value] is not null, returns a [Success] containing the value.
/// If [value] is null, calls [errorProvider] and returns a [Failure]
/// with the provided error.
///
/// This is useful for converting nullable values from APIs or databases
/// into the [Result] type for consistent error handling.
///
/// Example:
/// ```dart
/// String? maybeString = getValue();
/// final result = fromNullable(
///   maybeString,
///   () => 'Value was null',
/// );
///
/// result.when(
///   success: (value) => print('Got: $value'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
Result<T, E> fromNullable<T, E extends Object>(
  T? value,
  E Function() errorProvider,
) => value != null ? Result.success(value) : Result.failure(errorProvider());

/// Converts a boolean condition to a [Result].
///
/// If [condition] is true, calls [valueProvider] and returns a [Success]
/// with the provided value. If [condition] is false, calls [errorProvider]
/// and returns a [Failure] with the provided error.
///
/// This is useful for converting boolean checks into [Result] instances
/// for consistent error handling.
///
/// Example:
/// ```dart
/// final age = 25;
/// final result = fromBool(
///   age >= 18,
///   () => 'Adult',
///   () => 'Must be 18 or older',
/// );
///
/// result.when(
///   success: (status) => print('Status: $status'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
Result<T, E> fromBool<T, E extends Object>(
  T Function() valueProvider,
  E Function() errorProvider, {
  required bool condition,
}) => condition
    ? Result.success(valueProvider())
    : Result.failure(errorProvider());

/// Converts a [Result] to a nullable value.
///
/// Returns the success value if the result is successful, or null if
/// the result is a failure. This is useful when you want to ignore
/// errors and just get the value if available.
///
/// Example:
/// ```dart
/// final result = Result<int, String>.success(42);
/// final nullable = toNullable(result);
/// print(nullable); // 42
///
/// final failureResult = Result<int, String>.failure('error');
/// final nullableFailure = toNullable(failureResult);
/// print(nullableFailure); // null
/// ```
T? toNullable<T, E extends Object>(Result<T, E> result) => result.getOrNull();

/// Partitions a list of [Result] instances into successes and failures.
///
/// Returns a record with two lists: the first containing all success values,
/// and the second containing all error values.
///
/// This is useful when you want to process successes and failures separately
/// rather than stopping at the first failure.
///
/// Example:
/// ```dart
/// final results = [
///   Result<int, String>.success(1),
///   Result<int, String>.failure('error1'),
///   Result<int, String>.success(3),
///   Result<int, String>.failure('error2'),
/// ];
///
/// final (successes, failures) = partitionResults(results);
/// print(successes); // [1, 3]
/// print(failures); // ['error1', 'error2']
/// ```
({List<T> successes, List<E> failures}) partitionResults<T, E extends Object>(
  List<Result<T, E>> results,
) {
  final successes = <T>[];
  final failures = <E>[];

  for (final result in results) {
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

/// Traverses a list of values, applying a function that returns a [Result].
///
/// This is similar to [List.map] but for functions that return [Result].
/// If all applications succeed, returns a [Success] containing a list of
/// all results. If any application fails, returns the first [Failure].
///
/// This is useful for applying a potentially failing operation to each
/// element in a list, such as parsing or validation.
///
/// Example:
/// ```dart
/// final strings = ['1', '2', '3', 'invalid'];
/// final results = traverse(strings, (s) => safe(() => int.parse(s)));
///
/// results.when(
///   success: (numbers) => print('All parsed: $numbers'),
///   failure: (error) => print('Parse failed: $error'),
/// );
/// ```
Result<List<R>, E> traverse<T, R, E extends Object>(
  List<T> values,
  Result<R, E> Function(T value) fn,
) {
  final results = values.map(fn).toList();
  return combineResults(results);
}

/// Sequences a list of [Result] instances.
///
/// This is equivalent to [combineResults] but with a more functional
/// programming style name. Converts `List<Result<T, E>>` to
/// `Result<List<T>, E>`.
///
/// Example:
/// ```dart
/// final results = [
///   Result<int, String>.success(1),
///   Result<int, String>.success(2),
///   Result<int, String>.success(3),
/// ];
///
/// final sequenced = sequence(results);
/// print(sequenced.value); // [1, 2, 3]
/// ```
Result<List<T>, E> sequence<T, E extends Object>(List<Result<T, E>> results) =>
    combineResults(results);
