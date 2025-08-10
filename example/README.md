# Tryx Examples

This directory contains comprehensive examples demonstrating the Tryx error handling library features.

## Running the Examples

To run the main example:

```bash
cd example
dart pub get
dart run tryx_example.dart
```

## What's Included

The example demonstrates:

- **Basic Usage**: Safe function execution and Result handling
- **Async Operations**: Working with Future<Result> types
- **Stream Processing**: Safe stream transformations and error handling
- **Advanced Patterns**: Circuit breakers, fallback chains, and custom error types
- **Configuration**: Global configuration and logging setup

## Example Output

When you run the example, you'll see output demonstrating each feature:

```
🚀 Tryx Error Handling Library Examples

📚 Basic Usage Examples
==================================================

1. Safe Function Execution:
   ✅ Parsed successfully: 42
   ❌ Expected failure: FormatException

2. Chaining Operations:
   Chain result: Result: 246

3. Default Values:
   With default: 0

4. Recovery Patterns:
   Recovered value: -1

... and more!
```

## Key Concepts Demonstrated

### Safe Function Execution

```dart
final result = safe(() => int.parse('42'));
result.when(
  success: (value) => print('Parsed: $value'),
  failure: (error) => print('Error: $error'),
);
```

### Functional Chaining

```dart
final result = safe(() => '123')
    .flatMap((str) => safe(() => int.parse(str)))
    .map((number) => number * 2)
    .recover((error) => 0);
```

### Stream Processing

```dart
Stream.fromIterable(['1', '2', 'invalid', '4'])
    .safeMap<int, String>(int.parse)
    .where((result) => result.isSuccess)
    .successes()
    .listen((number) => print('Parsed: $number'));
```

### Advanced Patterns

```dart
final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig(
    failureThreshold: 5,
    timeout: Duration(seconds: 30),
  ),
);

final result = await circuitBreaker.executeSafe(() => apiCall());
```

## Learn More

- [Main Documentation](../README.md)
- [API Reference](https://pub.dev/documentation/tryx/latest/)
- [Package on pub.dev](https://pub.dev/packages/tryx)
