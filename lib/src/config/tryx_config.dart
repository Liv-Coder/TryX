/// Global configuration system for Tryx library.
///
/// This module provides a centralized configuration system that allows users
/// to set global defaults for error handling, logging, retry policies, and
/// other behaviors throughout the Tryx library.
library;

import 'dart:developer' as developer;

import 'package:tryx/src/config/retry_policy.dart';

/// Global configuration for the Tryx library.
///
/// This class provides a centralized way to configure default behaviors
/// for error handling, logging, retry policies, and other aspects of the
/// Tryx library. The configuration is applied globally and affects all
/// operations unless explicitly overridden.
///
/// Example:
/// ```dart
/// // Configure global settings
/// TryxConfig.configure(
///   defaultRetryPolicy: RetryPolicies.network,
///   enableGlobalLogging: true,
///   logLevel: LogLevel.warning,
///   globalErrorMapper: (error) => 'Global: $error',
/// );
///
/// // Use safe operations with global config applied
/// final result = safe(() => riskyOperation());
/// ```
class TryxConfig {
  /// Private constructor to prevent instantiation.
  TryxConfig._();

  /// The current global configuration instance.
  static TryxConfig _instance = TryxConfig._();

  /// Gets the current global configuration.
  static TryxConfig get instance => _instance;

  /// Default retry policy applied to all operations.
  RetryPolicy? _defaultRetryPolicy;

  /// Whether global logging is enabled.
  bool _enableGlobalLogging = false;

  /// The minimum log level for global logging.
  LogLevel _logLevel = LogLevel.error;

  /// Global error mapper function.
  String Function(Object error)? _globalErrorMapper;

  /// Global timeout duration for operations.
  Duration? _globalTimeout;

  /// Whether to include stack traces in error logs.
  bool _includeStackTraces = true;

  /// Custom logger function for global logging.
  void Function(
    String message,
    LogLevel level,
    Object? error,
    StackTrace? stackTrace,
  )?
  _customLogger;

  /// Global error handler for unhandled errors.
  void Function(Object error, StackTrace stackTrace)? _globalErrorHandler;

  /// Whether to enable performance monitoring.
  bool _enablePerformanceMonitoring = false;

  /// Performance threshold for slow operation warnings.
  Duration _slowOperationThreshold = const Duration(seconds: 1);

  /// Gets the default retry policy.
  RetryPolicy? get defaultRetryPolicy => _defaultRetryPolicy;

  /// Gets whether global logging is enabled.
  bool get enableGlobalLogging => _enableGlobalLogging;

  /// Gets the current log level.
  LogLevel get logLevel => _logLevel;

  /// Gets the global error mapper.
  String Function(Object error)? get globalErrorMapper => _globalErrorMapper;

  /// Gets the global timeout duration.
  Duration? get globalTimeout => _globalTimeout;

  /// Gets whether stack traces are included in logs.
  bool get includeStackTraces => _includeStackTraces;

  /// Gets the custom logger function.
  void Function(
    String message,
    LogLevel level,
    Object? error,
    StackTrace? stackTrace,
  )?
  get customLogger => _customLogger;

  /// Gets the global error handler.
  void Function(Object error, StackTrace stackTrace)? get globalErrorHandler =>
      _globalErrorHandler;

  /// Gets whether performance monitoring is enabled.
  bool get enablePerformanceMonitoring => _enablePerformanceMonitoring;

  /// Gets the slow operation threshold.
  Duration get slowOperationThreshold => _slowOperationThreshold;

  /// Configures the global Tryx settings.
  ///
  /// This method allows you to set various global configuration options
  /// that will be applied to all Tryx operations unless explicitly overridden.
  ///
  /// Parameters:
  /// - [defaultRetryPolicy]: Default retry policy for all operations
  /// - [enableGlobalLogging]: Whether to enable global logging
  /// - [logLevel]: Minimum log level for global logging
  /// - [globalErrorMapper]: Global error mapper function
  /// - [globalTimeout]: Global timeout for operations
  /// - [includeStackTraces]: Whether to include stack traces in logs
  /// - [customLogger]: Custom logger function
  /// - [globalErrorHandler]: Global error handler for unhandled errors
  /// - [enablePerformanceMonitoring]: Whether to enable performance monitoring
  /// - [slowOperationThreshold]: Threshold for slow operation warnings
  ///
  /// Example:
  /// ```dart
  /// TryxConfig.configure(
  ///   defaultRetryPolicy: RetryPolicies.network,
  ///   enableGlobalLogging: true,
  ///   logLevel: LogLevel.info,
  ///   globalTimeout: Duration(seconds: 30),
  ///   enablePerformanceMonitoring: true,
  /// );
  /// ```
  static void configure({
    RetryPolicy? defaultRetryPolicy,
    bool? enableGlobalLogging,
    LogLevel? logLevel,
    String Function(Object error)? globalErrorMapper,
    Duration? globalTimeout,
    bool? includeStackTraces,
    void Function(
      String message,
      LogLevel level,
      Object? error,
      StackTrace? stackTrace,
    )?
    customLogger,
    void Function(Object error, StackTrace stackTrace)? globalErrorHandler,
    bool? enablePerformanceMonitoring,
    Duration? slowOperationThreshold,
  }) {
    if (defaultRetryPolicy != null) {
      _instance._defaultRetryPolicy = defaultRetryPolicy;
    }
    if (enableGlobalLogging != null) {
      _instance._enableGlobalLogging = enableGlobalLogging;
    }
    if (logLevel != null) {
      _instance._logLevel = logLevel;
    }
    if (globalErrorMapper != null) {
      _instance._globalErrorMapper = globalErrorMapper;
    }
    if (globalTimeout != null) {
      _instance._globalTimeout = globalTimeout;
    }
    if (includeStackTraces != null) {
      _instance._includeStackTraces = includeStackTraces;
    }
    if (customLogger != null) {
      _instance._customLogger = customLogger;
    }
    if (globalErrorHandler != null) {
      _instance._globalErrorHandler = globalErrorHandler;
    }
    if (enablePerformanceMonitoring != null) {
      _instance._enablePerformanceMonitoring = enablePerformanceMonitoring;
    }
    if (slowOperationThreshold != null) {
      _instance._slowOperationThreshold = slowOperationThreshold;
    }
  }

  /// Resets the global configuration to default values.
  ///
  /// This method restores all configuration options to their default values.
  /// Useful for testing or when you want to start with a clean configuration.
  ///
  /// Example:
  /// ```dart
  /// TryxConfig.reset();
  /// ```
  static void reset() {
    _instance = TryxConfig._();
  }

  /// Logs a message using the global logging configuration.
  ///
  /// This method respects the global logging settings including log level,
  /// custom logger, and stack trace inclusion.
  ///
  /// Parameters:
  /// - [message]: The message to log
  /// - [level]: The log level
  /// - [error]: Optional error object
  /// - [stackTrace]: Optional stack trace
  ///
  /// Example:
  /// ```dart
  /// TryxConfig.log('Operation failed', LogLevel.error, error, stackTrace);
  /// ```
  static void log(
    String message,
    LogLevel level, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_instance._enableGlobalLogging ||
        level.index < _instance._logLevel.index) {
      return;
    }

    if (_instance._customLogger != null) {
      _instance._customLogger!(
        message,
        level,
        error,
        _instance._includeStackTraces ? stackTrace : null,
      );
    } else {
      _defaultLog(message, level, error, stackTrace);
    }
  }

  /// Default logging implementation using dart:developer.
  static void _defaultLog(
    String message,
    LogLevel level,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final logMessage = StringBuffer()
      ..write('[${level.name.toUpperCase()}] $message')
      ..write(error != null ? ' | Error: $error' : '');

    if (_instance._includeStackTraces && stackTrace != null) {
      logMessage.write('\nStack trace:\n$stackTrace');
    }

    developer.log(
      logMessage.toString(),
      name: 'Tryx',
      level: _logLevelToInt(level),
      error: error,
      stackTrace: _instance._includeStackTraces ? stackTrace : null,
    );
  }

  /// Converts LogLevel to integer for dart:developer.
  static int _logLevelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  /// Handles a global error using the configured error handler.
  ///
  /// This method is called when an unhandled error occurs in Tryx operations.
  /// It uses the global error handler if configured, otherwise logs the error.
  ///
  /// Parameters:
  /// - [error]: The error object
  /// - [stackTrace]: The stack trace
  ///
  /// Example:
  /// ```dart
  /// TryxConfig.handleGlobalError(error, stackTrace);
  /// ```
  static void handleGlobalError(Object error, StackTrace stackTrace) {
    if (_instance._globalErrorHandler != null) {
      try {
        _instance._globalErrorHandler!(error, stackTrace);
      } on Exception catch (handlerError) {
        // If the error handler itself throws, fall back to logging
        log(
          'Global error handler failed: $handlerError',
          LogLevel.error,
          handlerError,
          stackTrace,
        );
      }
    } else {
      log('Unhandled error', LogLevel.error, error, stackTrace);
    }
  }

  /// Records performance metrics for an operation.
  ///
  /// This method is called to record performance metrics when performance
  /// monitoring is enabled. It logs slow operations based on the configured
  /// threshold.
  ///
  /// Parameters:
  /// - [operationName]: Name of the operation
  /// - [duration]: Duration of the operation
  /// - [success]: Whether the operation was successful
  ///
  /// Example:
  /// ```dart
  /// TryxConfig.recordPerformance('parseJson', duration, true);
  /// ```
  static void recordPerformance(
    String operationName,
    Duration duration, {
    bool success = true,
  }) {
    if (!_instance._enablePerformanceMonitoring) {
      return;
    }

    if (duration >= _instance._slowOperationThreshold) {
      log(
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms (${success ? 'success' : 'failure'})',
        LogLevel.warning,
      );
    }

    // In a real implementation, you might want to send metrics to an analytics service
    // or store them for later analysis
  }

  /// Creates a copy of the current configuration with modified values.
  ///
  /// This method allows you to create a modified copy of the current
  /// configuration without affecting the global settings.
  ///
  /// Parameters are the same as [configure] method.
  ///
  /// Returns a new [TryxConfig] instance with the modified values.
  ///
  /// Example:
  /// ```dart
  /// final testConfig = TryxConfig.instance.copyWith(
  ///   enableGlobalLogging: false,
  ///   logLevel: LogLevel.debug,
  /// );
  /// ```
  TryxConfig copyWith({
    RetryPolicy? defaultRetryPolicy,
    bool? enableGlobalLogging,
    LogLevel? logLevel,
    String Function(Object error)? globalErrorMapper,
    Duration? globalTimeout,
    bool? includeStackTraces,
    void Function(
      String message,
      LogLevel level,
      Object? error,
      StackTrace? stackTrace,
    )?
    customLogger,
    void Function(Object error, StackTrace stackTrace)? globalErrorHandler,
    bool? enablePerformanceMonitoring,
    Duration? slowOperationThreshold,
  }) => TryxConfig._()
    .._defaultRetryPolicy = defaultRetryPolicy ?? _defaultRetryPolicy
    .._enableGlobalLogging = enableGlobalLogging ?? _enableGlobalLogging
    .._logLevel = logLevel ?? _logLevel
    .._globalErrorMapper = globalErrorMapper ?? _globalErrorMapper
    .._globalTimeout = globalTimeout ?? _globalTimeout
    .._includeStackTraces = includeStackTraces ?? _includeStackTraces
    .._customLogger = customLogger ?? _customLogger
    .._globalErrorHandler = globalErrorHandler ?? _globalErrorHandler
    .._enablePerformanceMonitoring =
        enablePerformanceMonitoring ?? _enablePerformanceMonitoring
    .._slowOperationThreshold =
        slowOperationThreshold ?? _slowOperationThreshold;

  /// Returns a string representation of the current configuration.
  @override
  String toString() =>
      'TryxConfig('
      'defaultRetryPolicy: $_defaultRetryPolicy, '
      'enableGlobalLogging: $_enableGlobalLogging, '
      'logLevel: $_logLevel, '
      'globalTimeout: $_globalTimeout, '
      'includeStackTraces: $_includeStackTraces, '
      'enablePerformanceMonitoring: $_enablePerformanceMonitoring, '
      'slowOperationThreshold: $_slowOperationThreshold'
      ')';
}

/// Log levels for global logging.
///
/// These levels determine the severity of log messages and can be used
/// to filter which messages are actually logged based on the configured
/// minimum log level.
enum LogLevel {
  /// Debug level - most verbose, for development only.
  debug,

  /// Info level - general information about operation flow.
  info,

  /// Warning level - potentially harmful situations.
  warning,

  /// Error level - error events that might still allow the application to continue.
  error,
}

/// Predefined configuration presets for common use cases.
///
/// These presets provide convenient starting points for different types
/// of applications and environments.
class TryxConfigPresets {
  /// Private constructor to prevent instantiation.
  TryxConfigPresets._();

  /// Development configuration with verbose logging and monitoring.
  ///
  /// This preset is suitable for development environments where you want
  /// detailed logging and performance monitoring.
  ///
  /// Example:
  /// ```dart
  /// TryxConfigPresets.development();
  /// ```
  static void development() {
    TryxConfig.configure(
      defaultRetryPolicy: RetryPolicies.standard,
      enableGlobalLogging: true,
      logLevel: LogLevel.debug,
      includeStackTraces: true,
      enablePerformanceMonitoring: true,
      slowOperationThreshold: const Duration(milliseconds: 500),
    );
  }

  /// Production configuration with minimal logging and error handling.
  ///
  /// This preset is suitable for production environments where you want
  /// minimal overhead and only critical error logging.
  ///
  /// Example:
  /// ```dart
  /// TryxConfigPresets.production();
  /// ```
  static void production() {
    TryxConfig.configure(
      defaultRetryPolicy: RetryPolicies.network,
      enableGlobalLogging: true,
      logLevel: LogLevel.error,
      includeStackTraces: false,
      enablePerformanceMonitoring: false,
      globalTimeout: const Duration(seconds: 30),
    );
  }

  /// Testing configuration with no logging and fast timeouts.
  ///
  /// This preset is suitable for testing environments where you want
  /// predictable behavior and no logging interference.
  ///
  /// Example:
  /// ```dart
  /// TryxConfigPresets.testing();
  /// ```
  static void testing() {
    TryxConfig.configure(
      defaultRetryPolicy: RetryPolicies.none,
      enableGlobalLogging: false,
      logLevel: LogLevel.error,
      includeStackTraces: false,
      enablePerformanceMonitoring: false,
      globalTimeout: const Duration(seconds: 5),
    );
  }

  /// Network-optimized configuration for network-heavy applications.
  ///
  /// This preset is suitable for applications that make many network requests
  /// and need robust retry policies and timeout handling.
  ///
  /// Example:
  /// ```dart
  /// TryxConfigPresets.networkOptimized();
  /// ```
  static void networkOptimized() {
    TryxConfig.configure(
      defaultRetryPolicy: RetryPolicies.aggressive,
      enableGlobalLogging: true,
      logLevel: LogLevel.warning,
      includeStackTraces: true,
      enablePerformanceMonitoring: true,
      globalTimeout: const Duration(seconds: 60),
      slowOperationThreshold: const Duration(seconds: 2),
    );
  }

  /// Database-optimized configuration for database-heavy applications.
  ///
  /// This preset is suitable for applications that perform many database
  /// operations and need appropriate retry policies and monitoring.
  ///
  /// Example:
  /// ```dart
  /// TryxConfigPresets.databaseOptimized();
  /// ```
  static void databaseOptimized() {
    TryxConfig.configure(
      defaultRetryPolicy: const RetryPolicy.exponentialBackoff(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 5),
      ),
      enableGlobalLogging: true,
      logLevel: LogLevel.info,
      includeStackTraces: true,
      enablePerformanceMonitoring: true,
      globalTimeout: const Duration(seconds: 30),
      slowOperationThreshold: const Duration(milliseconds: 1000),
    );
  }
}
