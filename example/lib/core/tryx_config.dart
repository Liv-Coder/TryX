import 'dart:async';
import 'package:tryx/tryx.dart';

/// Configure Tryx globally for the demo application
void configureTryxForDemo() {
  TryxConfig.configure(
    // Enable global logging to see all errors in the demo
    enableGlobalLogging: true,

    // Set log level to info to capture all operations
    logLevel: LogLevel.info,

    // Configure default retry policy for network operations
    defaultRetryPolicy: const RetryPolicy.exponentialBackoff(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 5),
    ),

    // Enable performance monitoring for demo insights
    enablePerformanceMonitoring: true,

    // Set custom global error handler for demo logging
    globalErrorHandler: (error, stackTrace) {
      print('🚨 Global Error Handler: $error');
      print('Stack trace: $stackTrace');
    },

    // Configure timeout defaults
    globalTimeout: const Duration(seconds: 10),

    // Include stack traces for better debugging
    includeStackTraces: true,

    // Set slow operation threshold for performance monitoring
    slowOperationThreshold: const Duration(milliseconds: 1000),
  );
}

/// Demo-specific error types for showcasing custom error handling
sealed class DemoError {
  const DemoError();

  factory DemoError.network(String message) = NetworkError;
  factory DemoError.validation(String field, String message) = ValidationError;
  factory DemoError.business(String message) = BusinessLogicError;
  factory DemoError.timeout(Duration timeout) = TimeoutError;
  factory DemoError.unknown(String message) = UnknownError;
}

class NetworkError extends DemoError {
  final String message;
  const NetworkError(this.message);

  @override
  String toString() => 'Network Error: $message';
}

class ValidationError extends DemoError {
  final String field;
  final String message;
  const ValidationError(this.field, this.message);

  @override
  String toString() => 'Validation Error in $field: $message';
}

class BusinessLogicError extends DemoError {
  final String message;
  const BusinessLogicError(this.message);

  @override
  String toString() => 'Business Logic Error: $message';
}

class TimeoutError extends DemoError {
  final Duration timeout;
  const TimeoutError(this.timeout);

  @override
  String toString() =>
      'Timeout Error: Operation timed out after ${timeout.inSeconds}s';
}

class UnknownError extends DemoError {
  final String message;
  const UnknownError(this.message);

  @override
  String toString() => 'Unknown Error: $message';
}

/// Helper function to convert exceptions to demo errors
DemoError mapExceptionToDemoError(Object exception) {
  if (exception is FormatException) {
    return DemoError.validation('input', exception.message);
  } else if (exception is ArgumentError) {
    return DemoError.validation(
        'argument', exception.message ?? 'Invalid argument');
  } else if (exception is StateError) {
    return DemoError.business(exception.message);
  } else if (exception is TimeoutException) {
    return DemoError.timeout(const Duration(seconds: 30));
  } else {
    return DemoError.unknown(exception.toString());
  }
}
