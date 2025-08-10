# Tryx

[![Pub Version](https://img.shields.io/pub/v/tryx)](https://pub.dev/packages/tryx)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/tryx)](https://pub.dev/packages/tryx)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/Liv-Coder/tryx/workflows/CI/badge.svg)](https://github.com/Liv-Coder/tryx/actions)

A powerful Dart library for **functional, reliable, and expressive error handling** using Result types. Tryx provides type-safe error handling without exceptions, with comprehensive support for async operations, streams, and advanced recovery patterns.

## 🚀 Features

- **🔒 Type-Safe Error Handling**: Eliminate runtime exceptions with compile-time safety
- **⚡ Zero-Cost Abstractions**: Minimal performance overhead with maximum safety
- **🌊 Async & Stream Support**: Seamless integration with `Future` and `Stream`
- **🔗 Functional Chaining**: Chain operations with `map`, `flatMap`, `recover`, and more
- **🛡️ Advanced Recovery Patterns**: Circuit breakers, retry policies, and fallback chains
- **📊 Performance Monitoring**: Built-in performance tracking and slow operation detection
- **🎯 Migration Helpers**: Easy transition from try-catch to functional error handling
- **📚 Comprehensive Documentation**: Extensive examples and API documentation

## 📦 Installation

Add `tryx` to your `pubspec.yaml`:

```yaml
dependencies:
  tryx: ^1.0.0
```

Then run:

```bash
dart pub get
```

## 🎯 Quick Start

### Basic Usage

```dart
import 'package:tryx/tryx.dart';

void main() {
  // Safe function execution
  final result = safe(() => int.parse('42'));

  result.when(
    success: (value) => print('Parsed: $value'), // Parsed: 42
    failure: (error) => print('Error: $error'),
  );

  // Chaining operations
  final chainedResult = safe(() => '123')
      .flatMap((str) => safe(() => int.parse(str)))
      .map((number) => number * 2)
      .recover((error) => 0); // Fallback value

  print('Result: ${chainedResult.getOrNull()}'); // Result: 246
}
```

### Async Operations

```dart
import 'package:tryx/tryx.dart';

Future<void> fetchUserData() async {
  final result = await safeAsync(() => fetchUser('123'));

  final userData = await result
      .mapAsync((user) async => await enrichUserData(user))
      .whenAsync(
        success: (enrichedUser) async {
          await saveToCache(enrichedUser);
          return 'Success: ${enrichedUser.name}';
        },
        failure: (error) async => 'Failed to fetch user: $error',
      );

  print(userData);
}
```

### Stream Processing

```dart
import 'package:tryx/tryx.dart';

void processNumberStream() {
  final numberStrings = Stream.fromIterable(['1', '2', 'invalid', '4']);

  numberStrings
      .safeMap<int, String>(
        int.parse,
        errorMapper: (error) => 'Parse error: $error',
      )
      .where((result) => result.isSuccess)
      .successes()
      .listen((number) => print('Parsed: $number'));
  // Output: Parsed: 1, Parsed: 2, Parsed: 4
}
```

## 📖 Core Concepts

### Result Type

The `Result<T, E>` type represents either a success with value `T` or a failure with error `E`:

```dart
// Creating Results
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('Something went wrong');

// Pattern matching
final message = result.when(
  success: (value) => 'Got: $value',
  failure: (error) => 'Error: $error',
);

// Safe access
final value = result.getOrNull(); // Returns value or null
final valueOrDefault = result.getOrElse(() => 0); // Returns value or default
```

### Safe Function Execution

```dart
// Synchronous
final result = safe(() => riskyOperation());

// Asynchronous
final asyncResult = await safeAsync(() => asyncRiskyOperation());

// With custom error mapping
final customResult = await safeWith<String, CustomError>(
  () => someOperation(),
  errorMapper: (error) => CustomError.from(error),
);
```

### Functional Chaining

```dart
final result = safe(() => '42')
    .map((str) => str.length)           // Transform success value
    .flatMap((len) => validateLength(len)) // Chain with another Result
    .mapError((error) => 'Validation failed: $error') // Transform error
    .recover((error) => 0)              // Provide fallback
    .onSuccess((value) => print('Success: $value')) // Side effects
    .onFailure((error) => logError(error));
```

## 🛡️ Advanced Features

### Circuit Breaker Pattern

```dart
import 'package:tryx/tryx.dart';

final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig(
    failureThreshold: 5,
    timeout: Duration(seconds: 30),
  ),
);

final result = await circuitBreaker.execute(() => apiCall());
```

### Retry Policies

```dart
// Configure global retry policy
TryxConfig.configure(
  defaultRetryPolicy: RetryPolicies.exponentialBackoff(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 100),
  ),
);

// Use with safe functions
final result = await safeAsync(() => unreliableOperation());
```

### Error Recovery Chains

```dart
final fallbackChain = FallbackChain<User, ApiError>()
  ..addFallback(() => getCachedUser())
  ..addFallback(() => getDefaultUser())
  ..addValueFallback(User.guest());

final user = await fallbackChain.execute(() => fetchUser());
```

## 🔧 Configuration

### Global Configuration

```dart
import 'package:tryx/tryx.dart';

void main() {
  // Configure Tryx globally
  TryxConfig.configure(
    enableGlobalLogging: true,
    logLevel: LogLevel.warning,
    enablePerformanceMonitoring: true,
    globalTimeout: Duration(seconds: 30),
  );

  // Or use presets
  TryxConfigPresets.production(); // For production
  TryxConfigPresets.development(); // For development
  TryxConfigPresets.testing(); // For testing
}
```

### Custom Error Types

```dart
sealed class ApiError {
  const ApiError();
}

class NetworkError extends ApiError {
  final String message;
  const NetworkError(this.message);
}

class ValidationError extends ApiError {
  final List<String> errors;
  const ValidationError(this.errors);
}

// Usage
Result<User, ApiError> fetchUser(String id) {
  return safeWith<User, ApiError>(
    () => apiClient.getUser(id),
    errorMapper: (error) {
      if (error is SocketException) {
        return NetworkError('Network connection failed');
      }
      return ValidationError(['Invalid user ID']);
    },
  );
}
```

## 🧪 Testing

Tryx makes testing error scenarios straightforward:

```dart
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('User Service Tests', () {
    test('should handle network errors gracefully', () async {
      final result = await safeAsync(() => throw SocketException('No internet'));

      expect(result.isFailure, isTrue);
      expect(result.getOrNull(), isNull);

      final errorMessage = result.when(
        success: (_) => 'Should not reach here',
        failure: (error) => error.toString(),
      );

      expect(errorMessage, contains('SocketException'));
    });
  });
}
```

## 🚀 Migration from try-catch

Tryx provides migration helpers to ease the transition:

```dart
// Before (try-catch)
String parseNumber(String input) {
  try {
    return int.parse(input).toString();
  } catch (e) {
    return 'Error: $e';
  }
}

// After (Tryx)
String parseNumber(String input) {
  return safe(() => int.parse(input))
      .map((number) => number.toString())
      .getOrElse(() => 'Error: Invalid number');
}

// Or use migration helpers
String parseNumber(String input) {
  return MigrationPatterns.simpleTryCatch(
    () => int.parse(input).toString(),
    onError: (error) => 'Error: $error',
  );
}
```

## 📊 Performance

Tryx is designed for minimal overhead:

- **Zero-cost abstractions**: No performance penalty for type safety
- **Lazy evaluation**: Operations are only performed when needed
- **Memory efficient**: Minimal memory allocation
- **Built-in monitoring**: Track slow operations automatically

```dart
// Enable performance monitoring
TryxConfig.configure(
  enablePerformanceMonitoring: true,
  slowOperationThreshold: Duration(milliseconds: 100),
);

// Automatic logging of slow operations
final result = await safeAsync(() => slowDatabaseQuery());
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Liv-Coder/tryx.git
cd tryx

# Install dependencies
dart pub get

# Run tests
dart test

# Run analysis
dart analyze

# Generate documentation
dart doc
```

## 📚 Documentation

- [API Documentation](https://pub.dev/documentation/tryx/latest/)
- [Examples](example/)
- [Migration Guide](doc/guides/migration.md)
- [Best Practices](doc/guides/best_practices.md)

## 🆚 Comparison with Other Libraries

| Feature                | Tryx | dartz | fpdart |
| ---------------------- | ---- | ----- | ------ |
| Result Type            | ✅   | ✅    | ✅     |
| Async Support          | ✅   | ❌    | ✅     |
| Stream Integration     | ✅   | ❌    | ❌     |
| Circuit Breaker        | ✅   | ❌    | ❌     |
| Performance Monitoring | ✅   | ❌    | ❌     |
| Migration Helpers      | ✅   | ❌    | ❌     |
| Global Configuration   | ✅   | ❌    | ❌     |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Rust's `Result` type and functional programming principles
- Built with ❤️ for the Dart and Flutter community

---

**Made with ❤️ by the Tryx team**

[⭐ Star us on GitHub](https://github.com/Liv-Coder/tryx) | [📦 View on pub.dev](https://pub.dev/packages/tryx) | [🐛 Report Issues](https://github.com/Liv-Coder/tryx/issues)
