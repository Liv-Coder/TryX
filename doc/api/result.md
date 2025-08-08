# Result<T, E>

The `Result<T, E>` type is the foundation of the Tryx library. It represents the outcome of an operation that can either succeed with a value of type `T` or fail with an error of type `E`.

## Overview

`Result` is a sealed class with two implementations:

- `Success<T, E>`: Contains a successful value of type `T`
- `Failure<T, E>`: Contains an error of type `E`

## Type Alias

- `SafeResult<T>`: Alias for `Result<T, Exception>` for common usage

## Constructors

### Result.success(T value)

Creates a successful result containing the given value.

```dart
final result = Result<int, String>.success(42);
print(result.isSuccess); // true
print(result.value); // 42
```

### Result.failure(E error)

Creates a failure result containing the given error.

```dart
final result = Result<int, String>.failure('Something went wrong');
print(result.isFailure); // true
print(result.error); // 'Something went wrong'
```

## Properties

### isSuccess

Returns `true` if this is a `Success` result.

```dart
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('error');

print(success.isSuccess); // true
print(failure.isSuccess); // false
```

### isFailure

Returns `true` if this is a `Failure` result.

```dart
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('error');

print(success.isFailure); // false
print(failure.isFailure); // true
```

### value

Gets the success value or `null` if this is a failure.

```dart
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('error');

print(success.value); // 42
print(failure.value); // null
```

### error

Gets the error or `null` if this is a success.

```dart
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('error');

print(success.error); // null
print(failure.error); // 'error'
```

## Pattern Matching

Since `Result` is a sealed class, you can use exhaustive pattern matching:

```dart
final result = Result<int, String>.success(42);

switch (result) {
  case Success(value: final v):
    print('Success: $v');
  case Failure(error: final e):
    print('Error: $e');
}
```

## Equality and Hashing

`Result` implements proper equality and hashing:

```dart
final result1 = Result<int, String>.success(42);
final result2 = Result<int, String>.success(42);
final result3 = Result<int, String>.failure('error');

print(result1 == result2); // true
print(result1 == result3); // false
print(result1.hashCode == result2.hashCode); // true
```

## String Representation

```dart
final success = Result<int, String>.success(42);
final failure = Result<int, String>.failure('error');

print(success.toString()); // Success(42)
print(failure.toString()); // Failure(error)
```

## Usage Examples

### Basic Usage

```dart
Result<int, String> parseNumber(String input) {
  final number = int.tryParse(input);
  return number != null
    ? Result.success(number)
    : Result.failure('Invalid number: $input');
}

final result = parseNumber('42');
if (result.isSuccess) {
  print('Parsed: ${result.value}');
} else {
  print('Error: ${result.error}');
}
```

### With Custom Error Types

```dart
sealed class ValidationError extends Exception {
  const ValidationError();
  factory ValidationError.empty() = EmptyError;
  factory ValidationError.tooShort(int minLength) = TooShortError;
}

final class EmptyError extends ValidationError {
  const EmptyError();
}

final class TooShortError extends ValidationError {
  final int minLength;
  const TooShortError(this.minLength);
}

Result<String, ValidationError> validateInput(String input) {
  if (input.isEmpty) {
    return Result.failure(ValidationError.empty());
  }
  if (input.length < 3) {
    return Result.failure(ValidationError.tooShort(3));
  }
  return Result.success(input);
}
```

## See Also

- [Safe Functions](safe_functions.md) - Functions that return `Result` instances
- [Result Extensions](result_extensions.md) - Methods for transforming and chaining results
- [Migration Guide](../guides/migration.md) - Migrating from try-catch to Result
