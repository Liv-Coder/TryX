import 'dart:async';

import 'package:tryx/src/core/result.dart';
import 'package:tryx/src/config/retry_policy.dart';

/// Advanced configuration class for safe execution with retry, timeout, and logging.
///
/// The [Safe] class provides a configurable way to execute operations with
/// advanced error handling features including retry policies, timeouts,
/// custom error mapping, and logging integration.
///
/// Example:
/// ```dart
/// final safeExecutor = Safe(
///   timeout: Duration(seconds: 5),
///   retryPolicy: RetryPolicy.exponentialBackoff(
///     maxAttempts: 3,
///     initialDelay: Duration(milliseconds: 100),
///   ),
///   logger: (error, attempt) => print('Attempt $attempt failed: $error'),
/// );
///
/// final result = await safeExecutor.call(() => unreliableApiCall());
/// ```
class Safe {
  /// Creates a Safe instance with the specified configuration.
  ///
  /// All parameters are optional and have sensible defaults:
  /// - [timeout]: No timeout by default
  /// - [retryPolicy]: No retries by default ([RetryPolicies.none])
  /// - [errorMapper]: No error mapping by default
  /// - [logger]: No logging by default
  /// - [onRetry]: No retry callback by default
  const Safe({
    this.timeout,
    this.retryPolicy = RetryPolicies.none,
    this.errorMapper,
    this.logger,
    this.onRetry,
  });

  /// Creates a Safe instance optimized for network operations.
  ///
  /// This factory constructor provides defaults suitable for network calls:
  /// - 30 second timeout
  /// - Exponential backoff with jitter
  /// - Network-optimized retry policy
  ///
  /// Example:
  /// ```dart
  /// final networkSafe = Safe.network(
  ///   logger: (error, attempt) => logNetworkError(error, attempt),
  /// );
  /// ```
  const Safe.network({
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Object Function(Object error)? errorMapper,
    void Function(Object error, int attempt)? logger,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) : timeout = timeout ?? const Duration(seconds: 30),
       retryPolicy = retryPolicy ?? RetryPolicies.network,
       errorMapper = errorMapper,
       logger = logger,
       onRetry = onRetry;

  /// Creates a Safe instance optimized for database operations.
  ///
  /// This factory constructor provides defaults suitable for database calls:
  /// - 10 second timeout
  /// - Conservative retry policy
  /// - Suitable for transactional operations
  ///
  /// Example:
  /// ```dart
  /// final dbSafe = Safe.database(
  ///   logger: (error, attempt) => logDatabaseError(error, attempt),
  /// );
  /// ```
  const Safe.database({
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Object Function(Object error)? errorMapper,
    void Function(Object error, int attempt)? logger,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) : timeout = timeout ?? const Duration(seconds: 10),
       retryPolicy = retryPolicy ?? RetryPolicies.conservative,
       errorMapper = errorMapper,
       logger = logger,
       onRetry = onRetry;

  /// Creates a Safe instance for critical operations that need aggressive retry.
  ///
  /// This factory constructor provides defaults for critical operations:
  /// - 60 second timeout
  /// - Aggressive retry policy with exponential backoff
  /// - Suitable for operations that must succeed
  ///
  /// Example:
  /// ```dart
  /// final criticalSafe = Safe.critical(
  ///   logger: (error, attempt) => logCriticalError(error, attempt),
  /// );
  /// ```
  const Safe.critical({
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Object Function(Object error)? errorMapper,
    void Function(Object error, int attempt)? logger,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) : timeout = timeout ?? const Duration(seconds: 60),
       retryPolicy = retryPolicy ?? RetryPolicies.aggressive,
       errorMapper = errorMapper,
       logger = logger,
       onRetry = onRetry;

  /// The timeout for the operation.
  ///
  /// If specified, the operation will be cancelled if it takes longer
  /// than this duration. The timeout applies to each individual attempt,
  /// not the total time including retries.
  final Duration? timeout;

  /// The retry policy to use for failed operations.
  ///
  /// Defines how many times to retry and with what delays.
  /// Defaults to [RetryPolicies.none] (no retries).
  final RetryPolicy retryPolicy;

  /// Optional function to map caught errors to different types.
  ///
  /// This is useful for converting generic exceptions into domain-specific
  /// error types or for normalizing different error types.
  ///
  /// Example:
  /// ```dart
  /// final safe = Safe(
  ///   errorMapper: (error) {
  ///     if (error is SocketException) {
  ///       return NetworkError(error.message);
  ///     }
  ///     return UnknownError(error.toString());
  ///   },
  /// );
  /// ```
  final Object Function(Object error)? errorMapper;

  /// Optional logger function called when errors occur.
  ///
  /// The logger receives the error and the current attempt number.
  /// This is useful for monitoring, debugging, and alerting.
  ///
  /// Example:
  /// ```dart
  /// final safe = Safe(
  ///   logger: (error, attempt) {
  ///     print('Attempt $attempt failed with: $error');
  ///     if (attempt == 1) {
  ///       // Log first failure
  ///       analytics.logError(error);
  ///     }
  ///   },
  /// );
  /// ```
  final void Function(Object error, int attempt)? logger;

  /// Optional callback called before each retry attempt.
  ///
  /// The callback receives the error that caused the retry, the attempt
  /// number, and the delay before the retry. This is useful for monitoring
  /// retry behavior and implementing custom retry logic.
  ///
  /// Example:
  /// ```dart
  /// final safe = Safe(
  ///   onRetry: (error, attempt, delay) {
  ///     print('Retrying in ${delay.inMilliseconds}ms (attempt $attempt)');
  ///     metrics.incrementRetryCounter();
  ///   },
  /// );
  /// ```
  final void Function(Object error, int attempt, Duration delay)? onRetry;

  /// Executes the given function with the configured safety features.
  ///
  /// This method applies timeout, retry policy, error mapping, and logging
  /// to the execution of [fn]. The function can be either synchronous or
  /// asynchronous.
  ///
  /// Type parameters:
  /// - [T]: The return type of the function
  /// - [E]: The error type for the result
  ///
  /// Example:
  /// ```dart
  /// final safe = Safe(
  ///   timeout: Duration(seconds: 5),
  ///   retryPolicy: RetryPolicies.standard,
  /// );
  ///
  /// final result = await safe.call<String, Exception>(
  ///   () => httpClient.get('/api/data'),
  /// );
  /// ```
  Future<Result<T, E>> call<T, E extends Object>(
    FutureOr<T> Function() fn,
  ) async {
    var attempt = 1;

    while (true) {
      try {
        // Execute the function with optional timeout
        final T result;
        if (timeout != null) {
          result = await Future.value(fn()).timeout(timeout!);
        } else {
          result = await Future.value(fn());
        }

        return Result.success(result);
      } on Object catch (error) {
        // Log the error
        logger?.call(error, attempt);

        // Check if we should retry
        if (retryPolicy.shouldRetry(attempt)) {
          final delay = retryPolicy.getDelay(attempt);

          // Call retry callback
          onRetry?.call(error, attempt, delay);

          // Wait before retrying
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }

          attempt++;
          continue;
        }

        // No more retries, return failure
        final mappedError = errorMapper?.call(error) ?? error;

        if (mappedError is E) {
          return Result.failure(mappedError);
        } else {
          // If the mapped error can't be cast to E, this is a programming error
          throw TypeError();
        }
      }
    }
  }

  /// Convenience method for executing functions that return [SafeResult].
  ///
  /// This is equivalent to calling [call] with [Exception] as the error type.
  ///
  /// Example:
  /// ```dart
  /// final safe = Safe(retryPolicy: RetryPolicies.standard);
  /// final result = await safe.execute(() => parseJson(jsonString));
  /// ```
  Future<SafeResult<T>> execute<T>(FutureOr<T> Function() fn) =>
      call<T, Exception>(fn);

  /// Creates a new Safe instance with modified configuration.
  ///
  /// This method allows you to create variations of a Safe instance
  /// without having to specify all parameters again.
  ///
  /// Example:
  /// ```dart
  /// final baseSafe = Safe(timeout: Duration(seconds: 5));
  /// final retrySafe = baseSafe.copyWith(
  ///   retryPolicy: RetryPolicies.standard,
  /// );
  /// ```
  Safe copyWith({
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Object Function(Object error)? errorMapper,
    void Function(Object error, int attempt)? logger,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) => Safe(
    timeout: timeout ?? this.timeout,
    retryPolicy: retryPolicy ?? this.retryPolicy,
    errorMapper: errorMapper ?? this.errorMapper,
    logger: logger ?? this.logger,
    onRetry: onRetry ?? this.onRetry,
  );

  /// Static convenience method for one-off safe execution.
  ///
  /// This method provides a quick way to execute a function with
  /// specific configuration without creating a Safe instance.
  ///
  /// Example:
  /// ```dart
  /// final result = await Safe.executeWith(
  ///   () => apiCall(),
  ///   timeout: Duration(seconds: 10),
  ///   retryPolicy: RetryPolicies.network,
  /// );
  /// ```
  static Future<Result<T, E>> executeWith<T, E extends Object>(
    FutureOr<T> Function() fn, {
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Object Function(Object error)? errorMapper,
    void Function(Object error, int attempt)? logger,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) {
    final safe = Safe(
      timeout: timeout,
      retryPolicy: retryPolicy ?? RetryPolicies.none,
      errorMapper: errorMapper,
      logger: logger,
      onRetry: onRetry,
    );

    return safe.call<T, E>(fn);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Safe &&
        other.timeout == timeout &&
        other.retryPolicy == retryPolicy &&
        other.errorMapper == errorMapper &&
        other.logger == logger &&
        other.onRetry == onRetry;
  }

  @override
  int get hashCode =>
      Object.hash(timeout, retryPolicy, errorMapper, logger, onRetry);

  @override
  String toString() {
    final buffer = StringBuffer('Safe(');

    if (timeout != null) {
      buffer.write('timeout: $timeout');
    }

    if (retryPolicy != RetryPolicies.none) {
      if (buffer.length > 5) buffer.write(', ');
      buffer.write('retryPolicy: $retryPolicy');
    }

    if (errorMapper != null) {
      if (buffer.length > 5) buffer.write(', ');
      buffer.write('errorMapper: provided');
    }

    if (logger != null) {
      if (buffer.length > 5) buffer.write(', ');
      buffer.write('logger: provided');
    }

    if (onRetry != null) {
      if (buffer.length > 5) buffer.write(', ');
      buffer.write('onRetry: provided');
    }

    buffer.write(')');
    return buffer.toString();
  }
}
