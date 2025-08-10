/// Advanced error recovery patterns for the Tryx library.
///
/// This module provides sophisticated error recovery mechanisms including
/// circuit breakers, fallback chains, error classification, and adaptive
/// recovery strategies.
library;

import 'dart:async';
import 'dart:math';

import 'package:tryx/src/core/result.dart';
import 'package:tryx/src/extensions/result_extensions.dart';
import 'package:tryx/src/functions/safe.dart';

/// Represents the state of a circuit breaker.
enum CircuitState {
  /// Circuit is closed, allowing operations to proceed normally.
  closed,

  /// Circuit is open, failing fast without attempting operations.
  open,

  /// Circuit is half-open, allowing limited operations to test recovery.
  halfOpen,
}

/// Configuration for circuit breaker behavior.
class CircuitBreakerConfig {
  /// Creates a [CircuitBreakerConfig].
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.successThreshold = 3,
    this.timeWindow = const Duration(minutes: 1),
  });

  /// Number of consecutive failures before opening the circuit.
  final int failureThreshold;

  /// Duration to wait before transitioning from open to half-open.
  final Duration timeout;

  /// Number of successful operations needed to close the circuit from half-open.
  final int successThreshold;

  /// Time window for counting failures.
  final Duration timeWindow;
}

/// A circuit breaker implementation for preventing cascading failures.
///
/// The circuit breaker monitors operation failures and can prevent
/// further operations when a failure threshold is reached, allowing
/// the system to recover.
///
/// Example:
/// ```dart
/// final circuitBreaker = CircuitBreaker(
///   config: CircuitBreakerConfig(
///     failureThreshold: 3,
///     timeout: Duration(seconds: 30),
///   ),
/// );
///
/// final result = await circuitBreaker.execute(() => apiCall());
/// ```
class CircuitBreaker {
  /// Creates a [CircuitBreaker].
  CircuitBreaker({CircuitBreakerConfig? config})
      : _config = config ?? const CircuitBreakerConfig();
  final CircuitBreakerConfig _config;
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _stateChangeTime;

  /// Current state of the circuit breaker.
  CircuitState get state => _state;

  /// Number of consecutive failures recorded.
  int get failureCount => _failureCount;

  /// Number of consecutive successes in half-open state.
  int get successCount => _successCount;

  /// Executes an operation through the circuit breaker.
  ///
  /// Returns a [CircuitBreakerException] if the circuit is open.
  Future<Result<T, E>> execute<T, E extends Object>(
    Future<Result<T, E>> Function() operation,
  ) async {
    if (_shouldReject()) {
      try {
        return Result.failure(
          const CircuitBreakerException('Circuit breaker is open') as E,
        );
      } on Exception catch (_) {
        throw ArgumentError(
          'The error type E is not compatible with CircuitBreakerException. '
          'Consider using a common supertype for your errors.',
        );
      }
    }

    try {
      final result = await operation();

      if (result.isSuccess) {
        _onSuccess();
      } else {
        _onFailure();
      }

      return result;
    } on Exception catch (_) {
      _onFailure();
      rethrow;
    }
  }

  /// Executes a safe operation through the circuit breaker.
  Future<SafeResult<T>> executeSafe<T>(Future<T> Function() operation) async {
    if (_shouldReject()) {
      return Result.failure(
        const CircuitBreakerException('Circuit breaker is open'),
      );
    }

    final result = await safeAsync(operation);

    if (result.isSuccess) {
      _onSuccess();
    } else {
      _onFailure();
    }

    return result;
  }

  /// Manually resets the circuit breaker to closed state.
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    // Reset circuit breaker state
    _stateChangeTime = DateTime.now();
  }

  bool _shouldReject() {
    final now = DateTime.now();

    switch (_state) {
      case CircuitState.closed:
        return false;
      case CircuitState.open:
        if (_stateChangeTime != null &&
            now.difference(_stateChangeTime!) >= _config.timeout) {
          _state = CircuitState.halfOpen;
          _successCount = 0;
          _stateChangeTime = now;
          return false;
        }
        return true;
      case CircuitState.halfOpen:
        return false;
    }
  }

  void _onSuccess() {
    switch (_state) {
      case CircuitState.closed:
        _failureCount = 0;
        break;
      case CircuitState.halfOpen:
        _successCount++;
        if (_successCount >= _config.successThreshold) {
          _state = CircuitState.closed;
          _failureCount = 0;
          _successCount = 0;
          _stateChangeTime = DateTime.now();
        }
        break;
      case CircuitState.open:
        // Should not happen
        break;
    }
  }

  void _onFailure() {
    final now = DateTime.now();
    // Record failure time for circuit breaker logic

    switch (_state) {
      case CircuitState.closed:
        _failureCount++;
        if (_failureCount >= _config.failureThreshold) {
          _state = CircuitState.open;
          _stateChangeTime = now;
        }
        break;
      case CircuitState.halfOpen:
        _state = CircuitState.open;
        _failureCount++;
        _successCount = 0;
        _stateChangeTime = now;
        break;
      case CircuitState.open:
        _failureCount++;
        break;
    }
  }
}

/// Exception thrown when circuit breaker rejects an operation.
class CircuitBreakerException implements Exception {
  /// Creates a [CircuitBreakerException].
  const CircuitBreakerException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => 'CircuitBreakerException: $message';
}

/// A fallback chain that tries multiple recovery strategies in sequence.
///
/// Example:
/// ```dart
/// final fallbackChain = FallbackChain<User, ApiError>()
///   .addFallback(() => getCachedUser())
///   .addFallback(() => getDefaultUser())
///   .addFallback(() => Result.success(User.guest()));
///
/// final result = await fallbackChain.execute(() => fetchUser());
/// ```
class FallbackChain<T, E extends Object> {
  final List<Future<Result<T, E>> Function()> _fallbacks = [];

  /// Adds a fallback strategy to the chain.
  void addFallback(Future<Result<T, E>> Function() fallback) {
    _fallbacks.add(fallback);
  }

  /// Adds a synchronous fallback strategy to the chain.
  void addSyncFallback(Result<T, E> Function() fallback) {
    _fallbacks.add(() async => fallback());
  }

  /// Adds a value fallback that always succeeds.
  void addValueFallback(T value) {
    _fallbacks.add(() async => Result.success(value));
  }

  /// Executes the primary operation with fallback chain.
  Future<Result<T, E>> execute(Future<Result<T, E>> Function() primary) async {
    var result = await primary();

    for (final fallback in _fallbacks) {
      if (result.isSuccess) break;

      try {
        result = await fallback();
      } on Exception {
        // Continue to next fallback if this one fails
        continue;
      }
    }

    return result;
  }
}

/// Error classification system for determining recovery strategies.
enum ErrorSeverity {
  /// Temporary errors that may resolve quickly.
  transient,

  /// Errors that may resolve with time or retry.
  recoverable,

  /// Permanent errors that won't resolve without intervention.
  permanent,

  /// Critical errors that indicate system failure.
  critical,
}

/// Classifies errors to determine appropriate recovery strategies.
abstract class ErrorClassifier<E extends Object> {
  /// Classifies an error into a severity category.
  ErrorSeverity classify(E error);

  /// Determines if an error is retryable.
  bool isRetryable(E error) {
    final severity = classify(error);
    return severity == ErrorSeverity.transient ||
        severity == ErrorSeverity.recoverable;
  }

  /// Determines if an error should trigger circuit breaker.
  bool shouldTriggerCircuitBreaker(E error) {
    final severity = classify(error);
    return severity == ErrorSeverity.recoverable ||
        severity == ErrorSeverity.critical;
  }

  /// Gets recommended retry delay based on error severity.
  Duration getRetryDelay(E error, int attemptNumber) {
    final severity = classify(error);
    final baseDelay = switch (severity) {
      ErrorSeverity.transient => const Duration(milliseconds: 100),
      ErrorSeverity.recoverable => const Duration(seconds: 1),
      ErrorSeverity.permanent => Duration.zero,
      ErrorSeverity.critical => Duration.zero,
    };

    // Exponential backoff
    return baseDelay * pow(2, attemptNumber - 1).toInt();
  }
}

/// Default error classifier for Exception types.
class DefaultErrorClassifier extends ErrorClassifier<Exception> {
  @override
  ErrorSeverity classify(Exception error) =>
      switch (error.runtimeType.toString()) {
        'TimeoutException' => ErrorSeverity.transient,
        'SocketException' => ErrorSeverity.recoverable,
        'FormatException' => ErrorSeverity.permanent,
        'ArgumentError' => ErrorSeverity.permanent,
        'StateError' => ErrorSeverity.critical,
        _ => ErrorSeverity.recoverable,
      };
}

/// Adaptive recovery strategy that learns from error patterns.
class AdaptiveRecovery<T, E extends Object> {
  /// Creates an [AdaptiveRecovery].
  AdaptiveRecovery({ErrorClassifier<E>? classifier})
      : _classifier =
            classifier ?? DefaultErrorClassifier() as ErrorClassifier<E>;
  final ErrorClassifier<E> _classifier;
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};
  final Map<String, Duration> _adaptiveDelays = {};

  /// Executes an operation with adaptive recovery.
  Future<Result<T, E>> execute(
    Future<Result<T, E>> Function() operation, {
    int maxAttempts = 3,
    Duration? maxDelay,
  }) async {
    var attempt = 1;
    Result<T, E>? lastResult;

    while (attempt <= maxAttempts) {
      lastResult = await operation();

      if (lastResult.isSuccess) {
        _onSuccess();
        return lastResult;
      }

      if (lastResult.isFailure) {
        final error = lastResult.when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        );
        final errorKey = error.runtimeType.toString();

        if (!_classifier.isRetryable(error) || attempt >= maxAttempts) {
          _recordError(errorKey);
          return lastResult;
        }

        final delay = _getAdaptiveDelay(error, attempt);
        if (maxDelay != null && delay > maxDelay) {
          _recordError(errorKey);
          return lastResult;
        }

        await Future<void>.delayed(delay);
        attempt++;
      }
    }

    return lastResult!;
  }

  Duration _getAdaptiveDelay(E error, int attempt) {
    final errorKey = error.runtimeType.toString();
    final baseDelay = _classifier.getRetryDelay(error, attempt);

    // Adapt delay based on error frequency
    final errorCount = _errorCounts[errorKey] ?? 0;
    final adaptiveFactor =
        1.0 + (errorCount * 0.1); // Increase delay for frequent errors

    final adaptiveDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * adaptiveFactor).round(),
    );

    _adaptiveDelays[errorKey] = adaptiveDelay;
    return adaptiveDelay;
  }

  void _recordError(String errorKey) {
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTimes[errorKey] = DateTime.now();
  }

  void _onSuccess() {
    // Gradually reduce error counts on success
    for (final key in _errorCounts.keys.toList()) {
      final count = _errorCounts[key]!;
      if (count > 0) {
        _errorCounts[key] = (count * 0.9).round();
        if (_errorCounts[key] == 0) {
          _errorCounts.remove(key);
          _lastErrorTimes.remove(key);
          _adaptiveDelays.remove(key);
        }
      }
    }
  }

  /// Gets statistics about error patterns.
  Map<String, dynamic> getStatistics() => {
        'errorCounts': Map<String, int>.from(_errorCounts),
        'lastErrorTimes': _lastErrorTimes.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
        'adaptiveDelays': _adaptiveDelays.map(
          (key, value) => MapEntry(key, value.inMilliseconds),
        ),
      };
}

/// Bulkhead pattern implementation for isolating failures.
class Bulkhead<T, E extends Object> {
  /// Creates a [Bulkhead].
  /// Creates a [Bulkhead].
  Bulkhead({
    int maxConcurrentOperations = 10,
    Duration timeout = const Duration(seconds: 30),
  })  : _maxConcurrentOperations = maxConcurrentOperations,
        _timeout = timeout;
  final int _maxConcurrentOperations;
  final Duration _timeout;
  int _currentOperations = 0;
  final List<Completer<void>> _waitingQueue = [];

  /// Current number of operations in progress.
  int get currentOperations => _currentOperations;

  /// Number of operations waiting in queue.
  int get queueLength => _waitingQueue.length;

  /// Executes an operation through the bulkhead.
  Future<Result<T, E>> execute(
    Future<Result<T, E>> Function() operation,
  ) async {
    // Wait for available slot
    await _acquireSlot();

    try {
      return await operation().timeout(_timeout);
    } catch (error) {
      if (error is TimeoutException) {
        return Result.failure(
          const BulkheadTimeoutException('Operation timed out') as E,
        );
      }
      rethrow;
    } finally {
      _releaseSlot();
    }
  }

  Future<void> _acquireSlot() async {
    if (_currentOperations < _maxConcurrentOperations) {
      _currentOperations++;
      return;
    }

    final completer = Completer<void>();
    _waitingQueue.add(completer);

    try {
      await completer.future.timeout(_timeout);
      _currentOperations++;
    } catch (error) {
      _waitingQueue.remove(completer);
      rethrow;
    }
  }

  void _releaseSlot() {
    _currentOperations--;

    if (_waitingQueue.isNotEmpty) {
      _waitingQueue.removeAt(0).complete();
    }
  }
}

/// Exception thrown when bulkhead operation times out.
class BulkheadTimeoutException implements Exception {
  /// Creates a [BulkheadTimeoutException].
  /// Creates a [BulkheadTimeoutException].
  const BulkheadTimeoutException(this.message);

  /// The exception message.
  /// The exception message.
  final String message;

  @override
  String toString() => 'BulkheadTimeoutException: $message';
}

/// Comprehensive recovery orchestrator that combines multiple patterns.
class RecoveryOrchestrator<T, E extends Object> {
  /// Creates a [RecoveryOrchestrator].
  /// Creates a [RecoveryOrchestrator].
  RecoveryOrchestrator({
    CircuitBreaker? circuitBreaker,
    FallbackChain<T, E>? fallbackChain,
    AdaptiveRecovery<T, E>? adaptiveRecovery,
    Bulkhead<T, E>? bulkhead,
  })  : _circuitBreaker = circuitBreaker,
        _fallbackChain = fallbackChain,
        _adaptiveRecovery = adaptiveRecovery,
        _bulkhead = bulkhead;
  final CircuitBreaker? _circuitBreaker;
  final FallbackChain<T, E>? _fallbackChain;
  final AdaptiveRecovery<T, E>? _adaptiveRecovery;
  final Bulkhead<T, E>? _bulkhead;

  /// Executes an operation through all configured recovery patterns.
  Future<Result<T, E>> execute(
    Future<Result<T, E>> Function() operation,
  ) async {
    var wrappedOperation = operation;

    // Apply bulkhead if configured
    if (_bulkhead != null) {
      final currentOperation = wrappedOperation;
      wrappedOperation = () => _bulkhead!.execute(currentOperation);
    }

    // Apply circuit breaker if configured
    if (_circuitBreaker != null) {
      final currentOperation = wrappedOperation;
      wrappedOperation = () async {
        final result = await _circuitBreaker!.execute(currentOperation);
        return result;
      };
    }

    // Apply adaptive recovery if configured
    if (_adaptiveRecovery != null) {
      final currentOperation = wrappedOperation;
      wrappedOperation = () => _adaptiveRecovery!.execute(currentOperation);
    }

    // Apply fallback chain if configured
    if (_fallbackChain != null) {
      return _fallbackChain!.execute(wrappedOperation);
    }

    return wrappedOperation();
  }
}
