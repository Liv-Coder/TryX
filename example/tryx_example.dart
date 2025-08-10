// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:tryx/tryx.dart';

/// Comprehensive example demonstrating Tryx error handling library features.
void main() async {
  print('🚀 Tryx Error Handling Library Examples\n');

  // Basic usage examples
  await basicUsageExamples();

  // Async operations
  await asyncOperationExamples();

  // Stream processing
  await streamProcessingExamples();

  // Advanced patterns
  await advancedPatternExamples();

  // Configuration examples
  configurationExamples();

  print('\n✅ All examples completed successfully!');
}

/// Demonstrates basic Result usage and safe function execution.
Future<void> basicUsageExamples() async {
  print('📚 Basic Usage Examples');
  print('=' * 50);

  // Safe function execution
  print('\n1. Safe Function Execution:');
  final parseResult = safe(() => int.parse('42'));
  parseResult.when(
    success: (value) => print('   ✅ Parsed successfully: $value'),
    failure: (error) => print('   ❌ Parse failed: $error'),
  );

  // Handling failures
  final failResult = safe(() => int.parse('invalid'));
  failResult.when(
    success: (value) => print('   ✅ Parsed: $value'),
    failure: (error) => print('   ❌ Expected failure: ${error.runtimeType}'),
  );

  // Chaining operations
  print('\n2. Chaining Operations:');
  final chainResult = safe(() => '123')
      .flatMap((str) => safe(() => int.parse(str)))
      .map((number) => number * 2)
      .map((doubled) => 'Result: $doubled');

  print('   Chain result: ${chainResult.getOrNull()}');

  // Using getOrElse for defaults
  print('\n3. Default Values:');
  final defaultResult = safe(() => int.parse('invalid')).getOrElse(() => 0);
  print('   With default: $defaultResult');

  // Recovery patterns
  print('\n4. Recovery Patterns:');
  final recoveredResult = safe(() => int.parse('invalid'))
      .recover((error) => -1)
      .map((value) => 'Recovered value: $value');
  print('   ${recoveredResult.getOrNull()}');
}

/// Demonstrates async operations with Result types.
Future<void> asyncOperationExamples() async {
  print('\n\n🔄 Async Operation Examples');
  print('=' * 50);

  // Basic async safe execution
  print('\n1. Async Safe Execution:');
  final asyncResult = await safeAsync(() => simulateAsyncOperation(true));
  asyncResult.when(
    success: (value) => print('   ✅ Async success: $value'),
    failure: (error) => print('   ❌ Async failure: $error'),
  );

  // Async chaining
  print('\n2. Async Chaining:');
  final chainAsyncResult = await safeAsync(() => simulateAsyncOperation(true));

  final processedResult = await chainAsyncResult.when(
    success: (value) async => safeAsync(() => processValue(value)),
    failure: (error) async => Result<String, Exception>.failure(error),
  );

  final finalResult = processedResult.when(
    success: (processed) => 'Final: $processed',
    failure: (error) => 'Error: $error',
  );
  print('   $finalResult');

  // Error handling in async chains
  print('\n3. Async Error Handling:');
  final errorChain = await safeAsync(() => simulateAsyncOperation(false))
      .then((result) => result.recover((error) => 'Fallback value'));
  print('   Recovered: ${errorChain.getOrNull()}');
}

/// Demonstrates stream processing with Result types.
Future<void> streamProcessingExamples() async {
  print('\n\n🌊 Stream Processing Examples');
  print('=' * 50);

  // Safe stream mapping
  print('\n1. Safe Stream Mapping:');
  final numberStrings = Stream.fromIterable(['1', '2', 'invalid', '4', '5']);

  await numberStrings
      .safeMap<int, String>(
    int.parse,
    errorMapper: (error) => 'Parse error: ${error.toString()}',
  )
      .listen((result) {
    result.when(
      success: (number) => print('   ✅ Parsed: $number'),
      failure: (error) => print('   ❌ $error'),
    );
  }).asFuture();

  // Stream filtering and processing
  print('\n2. Stream Success Filtering:');
  final processedStream = Stream.fromIterable(['10', '20', 'bad', '30'])
      .safeMap<int, String>(int.parse)
      .where((result) => result.isSuccess)
      .successes()
      .map((number) => number * 2);

  await processedStream.forEach((doubled) => print('   Doubled: $doubled'));

  // Stream error recovery
  print('\n3. Stream Error Recovery:');
  await Stream.fromIterable(['1', 'invalid', '3'])
      .safeMap<int, String>(int.parse)
      .recover((error) => 0)
      .successes()
      .forEach((number) => print('   Recovered: $number'));
}

/// Demonstrates advanced error handling patterns.
Future<void> advancedPatternExamples() async {
  print('\n\n🛡️ Advanced Pattern Examples');
  print('=' * 50);

  // Circuit breaker pattern
  print('\n1. Circuit Breaker Pattern:');
  final circuitBreaker = CircuitBreaker(
    config: const CircuitBreakerConfig(
      failureThreshold: 2,
      timeout: Duration(seconds: 1),
    ),
  );

  // Simulate some failures to trip the circuit breaker
  for (var i = 0; i < 4; i++) {
    final result =
        await circuitBreaker.executeSafe(() => simulateUnreliableService(i));
    result.when(
      success: (value) => print('   ✅ Service call $i: $value'),
      failure: (error) =>
          print('   ❌ Service call $i failed: ${error.runtimeType}'),
    );
  }

  // Fallback chain
  print('\n2. Fallback Chain:');
  final fallbackChain = FallbackChain<String, Exception>()
    ..addFallback(() async => simulateFailingService('primary'))
    ..addFallback(() async => simulateFailingService('secondary'))
    ..addValueFallback('default-value');

  final fallbackResult =
      await fallbackChain.execute(() => simulateFailingService('main'));
  fallbackResult.when(
    success: (value) => print('   ✅ Fallback result: $value'),
    failure: (error) => print('   ❌ All fallbacks failed: $error'),
  );

  // Custom error types
  print('\n3. Custom Error Types:');
  final customResult = await safeWith<String, CustomError>(
    simulateCustomErrorOperation,
    errorMapper: (error) => CustomError('Mapped: ${error.toString()}'),
  );

  customResult.when(
    success: (value) => print('   ✅ Custom success: $value'),
    failure: (error) => print('   ❌ Custom error: ${error.message}'),
  );
}

/// Demonstrates configuration options.
void configurationExamples() {
  print('\n\n⚙️ Configuration Examples');
  print('=' * 50);

  // Global configuration
  print('\n1. Global Configuration:');
  TryxConfig.configure(
    enableGlobalLogging: true,
    logLevel: LogLevel.info,
    enablePerformanceMonitoring: true,
    slowOperationThreshold: const Duration(milliseconds: 100),
  );
  print('   ✅ Global configuration applied');

  // Using presets
  print('\n2. Configuration Presets:');
  TryxConfigPresets.development();
  print('   ✅ Development preset applied');

  // Custom logging
  print('\n3. Custom Logging:');
  TryxConfig.log('This is a test log message', LogLevel.info);
  print('   ✅ Custom log message sent');

  // Reset configuration
  TryxConfig.reset();
  print('   ✅ Configuration reset to defaults');
}

// Helper functions for examples

/// Simulates an async operation that can succeed or fail.
Future<String> simulateAsyncOperation(bool shouldSucceed) async {
  await Future.delayed(const Duration(milliseconds: 50));
  if (shouldSucceed) {
    return 'Async operation completed';
  } else {
    throw Exception('Async operation failed');
  }
}

/// Processes a value asynchronously.
Future<String> processValue(String value) async {
  await Future.delayed(const Duration(milliseconds: 30));
  return 'Processed: $value';
}

/// Simulates an unreliable service for circuit breaker demo.
Future<String> simulateUnreliableService(int attempt) async {
  await Future.delayed(const Duration(milliseconds: 20));
  if (attempt < 2) {
    throw Exception('Service unavailable');
  }
  return 'Service response $attempt';
}

/// Simulates a failing service for fallback demo.
Future<Result<String, Exception>> simulateFailingService(
  String serviceName,
) async {
  await Future.delayed(const Duration(milliseconds: 10));
  if (serviceName == 'default') {
    return Result.success('$serviceName-response');
  }
  return Result.failure(Exception('$serviceName service failed'));
}

/// Simulates an operation that throws custom errors.
String simulateCustomErrorOperation() {
  final random = Random();
  if (random.nextBool()) {
    return 'Custom operation success';
  } else {
    throw StateError('Custom operation failed');
  }
}

/// Custom error class for demonstration.
class CustomError {
  const CustomError(this.message);
  final String message;

  @override
  String toString() => 'CustomError: $message';
}
