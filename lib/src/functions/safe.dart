import 'dart:async';

import 'package:tryx/src/core/result.dart';

/// Safely executes a synchronous function and returns a [SafeResult].
///
/// This function wraps the execution of [fn] in a try-catch block and
/// returns a [Result] that either contains the successful return value
/// or the caught exception.
///
/// Any thrown object that is not an [Exception] will be converted to
/// an [Exception] with the object's string representation as the message.
///
/// Example:
/// ```dart
/// // Successful execution
/// final result = safe(() => int.parse('42'));
/// print(result.isSuccess); // true
/// print(result.value); // 42
///
/// // Failed execution
/// final failedResult = safe(() => int.parse('invalid'));
/// print(failedResult.isFailure); // true
/// print(failedResult.error); // FormatException: Invalid radix-10 number
/// ```
///
/// See also:
/// * [safeAsync] for asynchronous operations
/// * [safeWith] for custom error mapping
SafeResult<T> safe<T>(T Function() fn) {
  try {
    final result = fn();
    return Result.success(result);
  } catch (error, stackTrace) {
    final exception = _convertToException(error, stackTrace);
    return Result.failure(exception);
  }
}

/// Safely executes an asynchronous function and returns a [Future] of [SafeResult].
///
/// This function wraps the execution of [fn] in a try-catch block and
/// returns a [Future<Result>] that either contains the successful return value
/// or the caught exception.
///
/// Any thrown object that is not an [Exception] will be converted to
/// an [Exception] with the object's string representation as the message.
///
/// Example:
/// ```dart
/// // Successful async execution
/// final result = await safeAsync(() => Future.value(42));
/// print(result.isSuccess); // true
/// print(result.value); // 42
///
/// // Failed async execution
/// final failedResult = await safeAsync(() => Future.error('Network error'));
/// print(failedResult.isFailure); // true
/// print(failedResult.error); // Exception: Network error
/// ```
///
/// See also:
/// * [safe] for synchronous operations
/// * [safeWith] for custom error mapping
Future<SafeResult<T>> safeAsync<T>(Future<T> Function() fn) async {
  try {
    final result = await fn();
    return Result.success(result);
  } catch (error, stackTrace) {
    final exception = _convertToException(error, stackTrace);
    return Result.failure(exception);
  }
}

/// Safely executes a function with custom error mapping.
///
/// This function wraps the execution of [fn] in a try-catch block and
/// returns a [Future<Result>] that either contains the successful return value
/// or the mapped error using the provided [errorMapper].
///
/// The [fn] parameter can return either a synchronous value [T] or a
/// [Future<T>], making this function suitable for both sync and async operations.
///
/// If [errorMapper] is not provided, the caught error will be used directly
/// if it's of type [E], otherwise a [TypeError] will be thrown.
///
/// Example:
/// ```dart
/// // Custom error mapping
/// sealed class ApiError {
///   factory ApiError.network(String message) = NetworkError;
///   factory ApiError.validation(String field) = ValidationError;
/// }
///
/// final result = await safeWith<User, ApiError>(
///   () => fetchUser('123'),
///   errorMapper: (error) {
///     if (error is SocketException) {
///       return ApiError.network(error.message);
///     }
///     return ApiError.validation('Invalid user ID');
///   },
/// );
/// ```
///
/// See also:
/// * [safe] for synchronous operations with default error handling
/// * [safeAsync] for asynchronous operations with default error handling
Future<Result<T, E>> safeWith<T, E extends Object>(
  FutureOr<T> Function() fn, {
  E Function(Object error)? errorMapper,
}) async {
  try {
    final result = await fn();
    return Result.success(result);
  } on Object catch (error) {
    if (errorMapper != null) {
      final mappedError = errorMapper(error);
      return Result.failure(mappedError);
    } else {
      // If no error mapper is provided, try to cast the error to E
      if (error is E) {
        return Result.failure(error);
      } else {
        // If the error can't be cast to E, this is a programming error
        throw TypeError();
      }
    }
  }
}

/// Converts any thrown object to an [Exception].
///
/// If the [error] is already an [Exception], it's returned as-is.
/// Otherwise, a new [Exception] is created with the error's string
/// representation as the message.
///
/// The [stackTrace] parameter is currently unused but reserved for
/// future enhancements that might include stack trace information
/// in the exception.
Exception _convertToException(Object error, StackTrace? stackTrace) {
  if (error is Exception) {
    return error;
  } else {
    return Exception(error.toString());
  }
}
