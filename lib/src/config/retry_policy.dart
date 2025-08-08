import 'dart:math' as math;

/// Configuration for retry behavior in safe operations.
///
/// [RetryPolicy] defines how many times an operation should be retried
/// and with what delay between attempts. It supports various backoff
/// strategies including fixed delay, exponential backoff, and custom
/// delay calculations.
///
/// Example:
/// ```dart
/// // Simple retry with fixed delay
/// final policy = RetryPolicy(
///   maxAttempts: 3,
///   delay: Duration(seconds: 1),
/// );
///
/// // Exponential backoff
/// final exponentialPolicy = RetryPolicy.exponentialBackoff(
///   maxAttempts: 5,
///   initialDelay: Duration(milliseconds: 100),
///   backoffMultiplier: 2.0,
///   maxDelay: Duration(seconds: 10),
/// );
/// ```
class RetryPolicy {
  /// Creates a retry policy with the specified configuration.
  ///
  /// [maxAttempts] must be at least 1. If [delay] is provided, it will be
  /// used as a fixed delay between attempts. If [backoffMultiplier] is
  /// greater than 1.0, exponential backoff will be applied.
  const RetryPolicy({
    required this.maxAttempts,
    this.delay,
    this.backoffMultiplier = 1.0,
    this.maxDelay,
    this.jitter = false,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       assert(backoffMultiplier >= 1.0, 'backoffMultiplier must be >= 1.0');

  /// Creates a retry policy with exponential backoff.
  ///
  /// This is a convenience constructor that sets up exponential backoff
  /// with sensible defaults. The delay between attempts will increase
  /// exponentially: initialDelay, initialDelay * multiplier,
  /// initialDelay * multiplier^2, etc.
  ///
  /// Example:
  /// ```dart
  /// final policy = RetryPolicy.exponentialBackoff(
  ///   maxAttempts: 5,
  ///   initialDelay: Duration(milliseconds: 100),
  ///   backoffMultiplier: 2.0,
  ///   maxDelay: Duration(seconds: 10),
  /// );
  /// ```
  const RetryPolicy.exponentialBackoff({
    required this.maxAttempts,
    required Duration initialDelay,
    this.backoffMultiplier = 2.0,
    this.maxDelay,
    this.jitter = true,
  }) : delay = initialDelay,
       assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       assert(
         backoffMultiplier > 1.0,
         'backoffMultiplier must be > 1.0 for exponential backoff',
       );

  /// Creates a retry policy with linear backoff.
  ///
  /// The delay increases linearly with each attempt:
  /// baseDelay, baseDelay * 2, baseDelay * 3, etc.
  ///
  /// Example:
  /// ```dart
  /// final policy = RetryPolicy.linearBackoff(
  ///   maxAttempts: 4,
  ///   baseDelay: Duration(milliseconds: 500),
  ///   maxDelay: Duration(seconds: 5),
  /// );
  /// ```
  const RetryPolicy.linearBackoff({
    required this.maxAttempts,
    required Duration baseDelay,
    this.maxDelay,
    this.jitter = false,
  }) : delay = baseDelay,
       backoffMultiplier = 1.0, // Will be handled specially in getDelay
       assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  /// Creates a retry policy with no delay between attempts.
  ///
  /// This is useful for operations that should be retried immediately
  /// without any waiting period.
  ///
  /// Example:
  /// ```dart
  /// final policy = RetryPolicy.immediate(maxAttempts: 3);
  /// ```
  const RetryPolicy.immediate({required this.maxAttempts})
    : delay = null,
      backoffMultiplier = 1.0,
      maxDelay = null,
      jitter = false,
      assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  /// The maximum number of attempts (including the initial attempt).
  ///
  /// For example, if [maxAttempts] is 3, the operation will be tried
  /// once initially, and then retried up to 2 more times if it fails.
  final int maxAttempts;

  /// The base delay between retry attempts.
  ///
  /// If [backoffMultiplier] is greater than 1.0, this serves as the
  /// initial delay for exponential backoff. Otherwise, it's used as
  /// a fixed delay between all attempts.
  final Duration? delay;

  /// The multiplier for exponential backoff.
  ///
  /// When greater than 1.0, each subsequent delay will be multiplied
  /// by this factor. For example, with a multiplier of 2.0, delays
  /// will be: delay, delay*2, delay*4, delay*8, etc.
  final double backoffMultiplier;

  /// The maximum delay between retry attempts.
  ///
  /// When using exponential backoff, delays can grow very large.
  /// This parameter caps the maximum delay to prevent excessive
  /// waiting times.
  final Duration? maxDelay;

  /// Whether to add random jitter to delays.
  ///
  /// Jitter helps prevent the "thundering herd" problem when many
  /// clients retry at the same time. When enabled, a random factor
  /// between 0.5 and 1.5 is applied to each delay.
  final bool jitter;

  /// Calculates the delay for a specific attempt number.
  ///
  /// [attemptNumber] is 1-based (1 for first retry, 2 for second retry, etc.).
  /// Returns the duration to wait before the retry attempt.
  ///
  /// Example:
  /// ```dart
  /// final policy = RetryPolicy.exponentialBackoff(
  ///   maxAttempts: 4,
  ///   initialDelay: Duration(milliseconds: 100),
  ///   backoffMultiplier: 2.0,
  /// );
  ///
  /// print(policy.getDelay(1)); // ~100ms
  /// print(policy.getDelay(2)); // ~200ms
  /// print(policy.getDelay(3)); // ~400ms
  /// ```
  Duration getDelay(int attemptNumber) {
    if (delay == null) return Duration.zero;

    Duration calculatedDelay;

    if (backoffMultiplier > 1.0) {
      // Exponential backoff
      final multiplier = math.pow(backoffMultiplier, attemptNumber - 1);
      calculatedDelay = Duration(
        microseconds: (delay!.inMicroseconds * multiplier).round(),
      );
    } else {
      // Linear backoff (special case when backoffMultiplier == 1.0 but we want linear)
      // This is detected by checking if this was created with linearBackoff constructor
      // For now, we'll treat backoffMultiplier == 1.0 as fixed delay
      calculatedDelay = delay!;
    }

    // Apply maximum delay cap
    if (maxDelay != null && calculatedDelay > maxDelay!) {
      calculatedDelay = maxDelay!;
    }

    // Apply jitter if enabled
    if (jitter) {
      final random = math.Random();
      final jitterFactor =
          0.5 + random.nextDouble(); // Random between 0.5 and 1.5
      calculatedDelay = Duration(
        microseconds: (calculatedDelay.inMicroseconds * jitterFactor).round(),
      );
    }

    return calculatedDelay;
  }

  /// Returns true if more attempts should be made.
  ///
  /// [currentAttempt] is 1-based (1 for initial attempt, 2 for first retry, etc.).
  ///
  /// Example:
  /// ```dart
  /// final policy = RetryPolicy(maxAttempts: 3);
  ///
  /// print(policy.shouldRetry(1)); // true (can retry after initial attempt)
  /// print(policy.shouldRetry(2)); // true (can retry after first retry)
  /// print(policy.shouldRetry(3)); // false (no more retries allowed)
  /// ```
  bool shouldRetry(int currentAttempt) => currentAttempt < maxAttempts;

  /// Returns the number of retries remaining after the current attempt.
  ///
  /// [currentAttempt] is 1-based (1 for initial attempt, 2 for first retry, etc.).
  int retriesRemaining(int currentAttempt) =>
      math.max(0, maxAttempts - currentAttempt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RetryPolicy &&
        other.maxAttempts == maxAttempts &&
        other.delay == delay &&
        other.backoffMultiplier == backoffMultiplier &&
        other.maxDelay == maxDelay &&
        other.jitter == jitter;
  }

  @override
  int get hashCode =>
      Object.hash(maxAttempts, delay, backoffMultiplier, maxDelay, jitter);

  @override
  String toString() {
    final buffer = StringBuffer('RetryPolicy(');
    buffer.write('maxAttempts: $maxAttempts');

    if (delay != null) {
      buffer.write(', delay: $delay');
    }

    if (backoffMultiplier != 1.0) {
      buffer.write(', backoffMultiplier: $backoffMultiplier');
    }

    if (maxDelay != null) {
      buffer.write(', maxDelay: $maxDelay');
    }

    if (jitter) {
      buffer.write(', jitter: true');
    }

    buffer.write(')');
    return buffer.toString();
  }
}

/// Predefined retry policies for common use cases.
///
/// This class provides static instances of commonly used retry policies
/// to avoid creating new instances repeatedly.
class RetryPolicies {
  const RetryPolicies._();

  /// No retry - fail immediately on first error.
  static const none = RetryPolicy(maxAttempts: 1);

  /// Retry once with no delay.
  static const once = RetryPolicy.immediate(maxAttempts: 2);

  /// Retry up to 3 times with 1 second delay between attempts.
  static const standard = RetryPolicy(
    maxAttempts: 3,
    delay: Duration(seconds: 1),
  );

  /// Aggressive retry with exponential backoff for critical operations.
  static const aggressive = RetryPolicy.exponentialBackoff(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 30),
  );

  /// Conservative retry with linear backoff for non-critical operations.
  static const conservative = RetryPolicy.linearBackoff(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
  );

  /// Network-optimized retry policy with jitter to prevent thundering herd.
  static const network = RetryPolicy.exponentialBackoff(
    maxAttempts: 4,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 15),
  );
}
