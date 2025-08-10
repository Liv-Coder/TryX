/// Migration helpers for transitioning from try-catch to Tryx patterns.
///
/// This module provides utilities and patterns to help developers
/// migrate existing code from traditional try-catch error handling
/// to Tryx's functional error handling approach.
library;

import 'dart:async';

import 'package:tryx/src/core/result.dart';
import 'package:tryx/src/extensions/result_extensions.dart';
import 'package:tryx/src/functions/safe.dart';

/// A wrapper that helps migrate existing try-catch code to Tryx patterns.
///
/// This class provides utilities to gradually transition code from
/// traditional exception-based error handling to Result-based patterns.
///
/// Example:
/// ```dart
/// // Legacy code
/// String legacyFunction() {
///   if (someCondition) {
///     throw Exception('Something went wrong');
///   }
///   return 'success';
/// }
///
/// // Migration wrapper
/// final migrator = MigrationHelper();
/// final result = migrator.wrapLegacyFunction(() => legacyFunction());
/// ```
class MigrationHelper {
  /// Wraps a legacy function that throws exceptions into a safe Result.
  ///
  /// This is useful for gradually migrating existing code that uses
  /// exceptions for error handling.
  SafeResult<T> wrapLegacyFunction<T>(T Function() legacyFunction) =>
      safe(legacyFunction);

  /// Wraps a legacy async function that throws exceptions into a safe Result.
  ///
  /// This is useful for gradually migrating existing async code that uses
  /// exceptions for error handling.
  Future<SafeResult<T>> wrapLegacyAsyncFunction<T>(
    Future<T> Function() legacyAsyncFunction,
  ) => safeAsync(legacyAsyncFunction);

  /// Converts a legacy function with custom error mapping.
  ///
  /// This allows you to map specific exception types to custom error types
  /// during migration.
  ///
  /// Example:
  /// ```dart
  /// final result = migrator.wrapWithErrorMapping<String, ApiError>(
  ///   () => legacyApiCall(),
  ///   errorMapper: (error) {
  ///     if (error is SocketException) return ApiError.network();
  ///     if (error is FormatException) return ApiError.parsing();
  ///     return ApiError.unknown();
  ///   },
  /// );
  /// ```
  Future<Result<T, E>> wrapWithErrorMapping<T, E extends Object>(
    FutureOr<T> Function() legacyFunction, {
    required E Function(Object error) errorMapper,
  }) => safeWith<T, E>(legacyFunction, errorMapper: errorMapper);

  /// Creates a bridge between Result-based and exception-based code.
  ///
  /// This method converts a Result back to exceptions, which can be useful
  /// when you need to integrate Tryx code with legacy systems that expect
  /// exceptions.
  ///
  /// Example:
  /// ```dart
  /// final result = safe(() => parseNumber('42'));
  /// final value = migrator.resultToException(result); // Throws on failure
  /// ```
  T resultToException<T, E extends Object>(Result<T, E> result) => result.when(
    success: (value) => value,
    failure: (error) {
      if (error is Exception) {
        throw error;
      } else {
        throw Exception(error.toString());
      }
    },
  );

  /// Creates a bridge for async Results.
  Future<T> asyncResultToException<T, E extends Object>(
    Future<Result<T, E>> resultFuture,
  ) async {
    final result = await resultFuture;
    return resultToException(result);
  }
}

/// Patterns for common migration scenarios.
class MigrationPatterns {
  MigrationPatterns._();

  /// Migrates a simple try-catch block to Result pattern.
  ///
  /// Before:
  /// ```dart
  /// String parseNumber(String input) {
  ///   try {
  ///     return int.parse(input).toString();
  ///   } catch (e) {
  ///     return 'Error: $e';
  ///   }
  /// }
  /// ```
  ///
  /// After:
  /// ```dart
  /// String parseNumber(String input) {
  ///   return MigrationPatterns.simpleTryCatch(
  ///     () => int.parse(input).toString(),
  ///     onError: (error) => 'Error: $error',
  ///   );
  /// }
  /// ```
  static T simpleTryCatch<T>(
    T Function() operation,
    T Function(Exception error) onError,
  ) {
    final result = safe(operation);
    return result.when(success: (value) => value, failure: onError);
  }

  /// Migrates async try-catch to Result pattern.
  ///
  /// Before:
  /// ```dart
  /// Future<String> fetchData() async {
  ///   try {
  ///     final data = await apiCall();
  ///     return data.toString();
  ///   } catch (e) {
  ///     return 'Error: $e';
  ///   }
  /// }
  /// ```
  ///
  /// After:
  /// ```dart
  /// Future<String> fetchData() async {
  ///   return MigrationPatterns.asyncTryCatch(
  ///     () => apiCall().then((data) => data.toString()),
  ///     onError: (error) => 'Error: $error',
  ///   );
  /// }
  /// ```
  static Future<T> asyncTryCatch<T>(
    Future<T> Function() operation,
    T Function(Exception error) onError,
  ) async {
    final result = await safeAsync(operation);
    return result.when(success: (value) => value, failure: onError);
  }

  /// Migrates multiple try-catch blocks to Result chaining.
  ///
  /// Before:
  /// ```dart
  /// String processData(String input) {
  ///   try {
  ///     final parsed = int.parse(input);
  ///     try {
  ///       final validated = validateNumber(parsed);
  ///       return processNumber(validated);
  ///     } catch (e2) {
  ///       return 'Validation error: $e2';
  ///     }
  ///   } catch (e1) {
  ///     return 'Parse error: $e1';
  ///   }
  /// }
  /// ```
  ///
  /// After:
  /// ```dart
  /// String processData(String input) {
  ///   return MigrationPatterns.chainedOperations(
  ///     () => int.parse(input),
  ///     (parsed) => validateNumber(parsed),
  ///     (validated) => processNumber(validated),
  ///     onError: (error, step) => '$step error: $error',
  ///   );
  /// }
  /// ```
  static T chainedOperations<A, B, T>(
    A Function() step1,
    B Function(A) step2,
    T Function(B) step3,
    T Function(Exception error, String step) onError,
  ) {
    final result = safe(
      step1,
    ).flatMap((a) => safe(() => step2(a))).flatMap((b) => safe(() => step3(b)));

    return result.when(
      success: (value) => value,
      failure: (error) => onError(error, 'processing'),
    );
  }

  /// Migrates resource management with try-finally to Result pattern.
  ///
  /// Before:
  /// ```dart
  /// String readFile(String path) {
  ///   File? file;
  ///   try {
  ///     file = File(path);
  ///     return file.readAsStringSync();
  ///   } catch (e) {
  ///     return 'Error: $e';
  ///   } finally {
  ///     file?.close();
  ///   }
  /// }
  /// ```
  ///
  /// After:
  /// ```dart
  /// String readFile(String path) {
  ///   return MigrationPatterns.withResource(
  ///     acquire: () => File(path),
  ///     use: (file) => file.readAsStringSync(),
  ///     release: (file) => file.close(),
  ///     onError: (error) => 'Error: $error',
  ///   );
  /// }
  /// ```
  static T withResource<R, T>(
    R Function() acquire,
    T Function(R resource) use,
    void Function(R resource) release,
    T Function(Exception error) onError,
  ) {
    R? resource;
    try {
      final result = safe(() {
        resource = acquire();
        return use(resource as R);
      });

      return result.when(success: (value) => value, failure: onError);
    } finally {
      if (resource != null) {
        try {
          release(resource as R);
        } on Exception {
          // Ignore cleanup errors
        }
      }
    }
  }

  /// Migrates exception-based validation to Result pattern.
  ///
  /// Before:
  /// ```dart
  /// User validateUser(Map<String, dynamic> data) {
  ///   if (data['name'] == null) throw ValidationException('Name required');
  ///   if (data['email'] == null) throw ValidationException('Email required');
  ///   return User(name: data['name'], email: data['email']);
  /// }
  /// ```
  ///
  /// After:
  /// ```dart
  /// Result<User, ValidationError> validateUser(Map<String, dynamic> data) {
  ///   return MigrationPatterns.validation([
  ///     () => data['name'] != null ? data['name'] : throw ValidationError('Name required'),
  ///     () => data['email'] != null ? data['email'] : throw ValidationError('Email required'),
  ///   ]).map((values) => User(name: values[0], email: values[1]));
  /// }
  /// ```
  static SafeResult<List<T>> validation<T>(List<T Function()> validators) {
    final results = <T>[];

    for (final validator in validators) {
      final result = safe(validator);
      if (result is Failure<T, Exception>) {
        return result.when(
          success: (_) => throw StateError('Expected failure'),
          failure: Result.failure,
        );
      }
      if (result is Success<T, Exception>) {
        results.add(result.getOrNull() as T);
      }
    }

    return Result.success(results);
  }
}
