/// A minimalistic and expressive Dart library for handling errors without traditional try-catch blocks.
///
/// Tryx provides a clean, functional, and beginner-friendly alternative using a declarative API
/// similar to Result, Either, or safeCall patterns from Kotlin, Swift, or Rust.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:tryx/tryx.dart';
///
/// // Synchronous operations
/// final result = safe(() => int.parse('42'));
/// result.when(
///   success: (value) => print('Parsed: $value'),
///   failure: (error) => print('Error: $error'),
/// );
///
/// // Asynchronous operations
/// final asyncResult = await safeAsync(() => fetchUserData());
/// asyncResult
///   .map((user) => user.name)
///   .onSuccess((name) => print('Welcome, $name!'))
///   .onFailure((error) => logError(error));
/// ```
///
/// ## Core Concepts
///
/// ### Result<T, E>
/// The foundation of Tryx is the [Result] type that encapsulates success and failure states:
/// - [Success]: Contains a value of type T
/// - [Failure]: Contains an error of type E
/// - [SafeResult]: Type alias for Result<T, Exception>
///
/// ### Safe Functions
/// - [safe]: Wraps synchronous operations
/// - [safeAsync]: Wraps asynchronous operations
/// - [safeWith]: Wraps operations with custom error mapping
///
/// ### Method Chaining
/// Results support functional programming patterns:
/// - [ResultExtensions.map]: Transform success values
/// - [ResultExtensions.flatMap]: Chain operations that can fail
/// - [ResultExtensions.when]: Pattern matching
/// - [ResultExtensions.fold]: Reduce to a single value
/// - [ResultExtensions.recover]: Handle failures with fallback values
///
/// ## Examples
///
/// ### Basic Usage
/// ```dart
/// // Parse a number safely
/// final result = safe(() => int.parse(userInput));
/// final message = result.when(
///   success: (number) => 'You entered: $number',
///   failure: (error) => 'Invalid input: $error',
/// );
/// ```
///
/// ### Method Chaining
/// ```dart
/// final result = await safeAsync(() => fetchUser())
///   .then((result) => result
///     .map((user) => user.email)
///     .flatMap((email) => safe(() => validateEmail(email)))
///     .map((email) => email.toLowerCase())
///   );
/// ```
///
/// ### Custom Error Types
/// ```dart
/// sealed class ApiError extends Exception {
///   const ApiError();
///   factory ApiError.network() = NetworkError;
///   factory ApiError.auth() = AuthError;
/// }
///
/// final result = await safeWith<User, ApiError>(
///   () => apiClient.getUser(),
///   errorMapper: (e) => e is SocketException
///       ? ApiError.network()
///       : ApiError.auth(),
/// );
/// ```
///
/// See also:
/// - [Result] for the core type documentation
/// - [safe] for synchronous operation wrapping
/// - [safeAsync] for asynchronous operation wrapping
/// - [ResultExtensions] for method chaining operations
library;

import 'package:tryx/src/core/result.dart'
    show Result, Success, Failure, SafeResult;
import 'package:tryx/src/extensions/result_extensions.dart'
    show ResultExtensions;
import 'package:tryx/tryx.dart'
    show Result, Success, Failure, SafeResult, ResultExtensions;

// Remove circular import - exports handle the public API

// Core types
export 'src/core/result.dart';

// Primary API functions
export 'src/functions/safe.dart';

// Extensions for functional programming
export 'src/extensions/result_extensions.dart';

// Advanced configuration and retry policies
export 'src/config/retry_policy.dart';
export 'src/advanced/safe_class.dart';

// Utility functions for combining and transforming results
export 'src/utils/combinators.dart';

// Stream extensions for reactive programming
export 'src/extensions/stream_extensions.dart';

// Global configuration system
export 'src/config/tryx_config.dart';

// Advanced error recovery patterns
export 'src/advanced/error_recovery.dart';

// Migration helpers and tools
export 'src/migration/migration_helpers.dart';
