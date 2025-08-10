// ignore_for_file: avoid_print

/// Basic usage examples for the Tryx library.
///
/// This file demonstrates the fundamental concepts and patterns
/// for using Tryx in your Dart applications.
library;

import 'package:tryx/tryx.dart';

void main() {
  print('=== Tryx Basic Usage Examples ===\n');

  // Example 1: Basic safe() usage
  basicSafeUsage();

  // Example 2: Pattern matching with when()
  patternMatching();

  // Example 3: Method chaining
  methodChaining();

  // Example 4: Error recovery
  errorRecovery();

  // Example 5: Working with nullable values
  nullableValues();
}

/// Example 1: Basic safe() usage
void basicSafeUsage() {
  print('--- Example 1: Basic safe() usage ---');

  // Successful operation
  final successResult = safe(() => int.parse('42'));
  print('Parsing "42": ${successResult.isSuccess ? "Success" : "Failed"}');
  print('Value: ${successResult.getOrNull()}');

  // Failed operation
  final failureResult = safe(() => int.parse('invalid'));
  print('Parsing "invalid": ${failureResult.isSuccess ? "Success" : "Failed"}');
  failureResult.when(
    success: (value) => print('Value: $value'),
    failure: (error) => print('Error: $error'),
  );

  print('');
}

/// Example 2: Pattern matching with when()
void patternMatching() {
  print('--- Example 2: Pattern matching with when() ---');

  final inputs = ['42', '100', 'invalid', '-5'];

  for (final input in inputs) {
    final result = safe(() => int.parse(input));

    final message = result.when(
      success: (value) =>
          value > 0 ? 'Positive number: $value' : 'Non-positive number: $value',
      failure: (error) => 'Failed to parse "$input": ${error.runtimeType}',
    );

    print(message);
  }

  print('');
}

/// Example 3: Method chaining
void methodChaining() {
  print('--- Example 3: Method chaining ---');

  final inputs = ['42', '100', 'invalid'];

  for (final input in inputs) {
    final result = safe(() => int.parse(input))
        .map((number) => number * 2) // Double the number
        .map((doubled) => 'Result: $doubled') // Format as string
        .getOrElse(() => 'Processing failed for "$input"');

    print(result);
  }

  print('');
}

/// Example 4: Error recovery
void errorRecovery() {
  print('--- Example 4: Error recovery ---');

  final inputs = ['42', 'invalid', '100'];

  for (final input in inputs) {
    final result = safe(() => int.parse(input))
        .recover((error) => -1) // Use -1 as fallback for parse errors
        .map((number) => 'Number: $number');

    print('Input "$input" -> ${result.getOrNull()}');
  }

  print('');
}

/// Example 5: Working with nullable values
void nullableValues() {
  print('--- Example 5: Working with nullable values ---');

  final values = ['42', null, '100', 'invalid'];

  for (final value in values) {
    final result = fromNullable(
      value,
      () => Exception('Value is null'),
    ).flatMap((str) => safe(() => int.parse(str))).map((number) => number * 2);

    final message = result.when(
      success: (doubled) => 'Doubled: $doubled',
      failure: (error) => 'Error: ${error.runtimeType}',
    );

    print('Value $value -> $message');
  }

  print('');
}

/// Helper function to demonstrate fromNullable utility
SafeResult<T> fromNullable<T>(T? value, Exception Function() errorProvider) =>
    value != null ? Result.success(value) : Result.failure(errorProvider());
