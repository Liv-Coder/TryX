# Safe Functions

The safe functions are the primary entry points for the Tryx library. They wrap potentially failing operations and return `Result` instances instead of throwing exceptions.

## Functions

### safe<T>(T Function() fn)

Safely executes a synchronous function and returns a `SafeResult<T>`.

**Parameters:**

- `fn`: A function that returns a value of type `T`

**Returns:** `SafeResult<T>` (alias for `Result<T, Exception>`)

**Example:**

```dart
// Successful execution
final result = safe(() => int.parse('42'));
print(result.isSuccess); // true
print(result.value); // 42

// Failed execution
final failedResult = safe(() => int.parse('invalid'));
print(failedResult.isFailure); // true
print(failedResult.error); // FormatException: Invalid radix-10 number
```

**Error Handling:**

- Any thrown object that is not an `Exception` will be converted to an `Exception` with the object's string representation as the message.

### safeAsync<T>(Future<T> Function() fn)

Safely executes an asynchronous function and returns a `Future<SafeResult<T>>`.

**Parameters:**

- `fn`: A function that returns a `Future<T>`

**Returns:** `Future<SafeResult<T>>`

**Example:**

```dart
// Successful async execution
final result = await safeAsync(() => Future.value(42));
print(result.isSuccess); // true
print(result.value); // 42

// Failed async execution
final failedResult = await safeAsync(() => Future.error('Network error'));
print(failedResult.isFailure); // true
print(failedResult.error); // Exception: Network error
```

**Error Handling:**

- Catches both synchronous exceptions thrown by `fn` and asynchronous errors from the returned `Future`.
- Any thrown object that is not an `Exception` will be converted to an `Exception`.

### safeWith<T, E>(FutureOr<T> Function() fn, {E Function(Object error)? errorMapper})

Safely executes a function with custom error mapping.

**Parameters:**

- `fn`: A function that returns either `T` or `Future<T>`
- `errorMapper`: Optional function to map caught errors to type `E`

**Returns:** `Future<Result<T, E>>`

**Example:**

```dart
// Custom error mapping
sealed class ApiError extends Exception {
  const ApiError();
  factory ApiError.network(String message) = NetworkError;
  factory ApiError.validation(String field) = ValidationError;
}

final class NetworkError extends ApiError {
  final String message;
  const NetworkError(this.message);
}

final class ValidationError extends ApiError {
  final String field;
  const ValidationError(this.field);
}

final result = await safeWith<User, ApiError>(
  () => fetchUser('123'),
  errorMapper: (error) {
    if (error is SocketException) {
      return ApiError.network(error.message);
    }
    return ApiError.validation('Invalid user ID');
  },
);
```

**Error Handling:**

- If `errorMapper` is provided, all caught errors are passed through it.
- If `errorMapper` is not provided, the caught error must be of type `E` or a `TypeError` will be thrown.

## Usage Patterns

### Basic Error Handling

```dart
final result = safe(() => riskyOperation());
result.when(
  success: (value) => print('Success: $value'),
  failure: (error) => print('Error: $error'),
);
```

### Chaining Operations

```dart
final result = await safeAsync(() => fetchData())
  .then((result) => result.map((data) => processData(data)));
```

### Custom Error Types

```dart
sealed class DatabaseError extends Exception {
  const DatabaseError();
  factory DatabaseError.connectionFailed() = ConnectionFailedError;
  factory DatabaseError.queryFailed(String query) = QueryFailedError;
}

final result = await safeWith<List<User>, DatabaseError>(
  () => database.getUsers(),
  errorMapper: (error) {
    if (error is SocketException) {
      return DatabaseError.connectionFailed();
    }
    return DatabaseError.queryFailed('SELECT * FROM users');
  },
);
```

### Mixed Sync/Async Operations

```dart
// safeWith can handle both sync and async functions
final syncResult = await safeWith<int, String>(
  () => int.parse('42'), // synchronous
  errorMapper: (error) => 'Parse error: $error',
);

final asyncResult = await safeWith<String, String>(
  () => fetchDataFromApi(), // asynchronous
  errorMapper: (error) => 'API error: $error',
);
```

## Best Practices

### 1. Use Appropriate Function for Your Use Case

- Use `safe()` for synchronous operations
- Use `safeAsync()` for asynchronous operations with default error handling
- Use `safeWith()` for custom error types or when you need specific error mapping

### 2. Design Meaningful Error Types

```dart
// Good: Specific error types
sealed class ValidationError extends Exception {
  const ValidationError();
  factory ValidationError.required(String field) = RequiredFieldError;
  factory ValidationError.invalid(String field, String reason) = InvalidFieldError;
}

// Avoid: Generic error types
// String errors are less type-safe and harder to handle programmatically
```

### 3. Handle Both Success and Failure Cases

```dart
// Good: Exhaustive handling
final result = safe(() => parseInput(userInput));
final message = result.when(
  success: (value) => 'Parsed successfully: $value',
  failure: (error) => 'Failed to parse: $error',
);

// Avoid: Only handling success case
// if (result.isSuccess) { ... } // What about failures?
```

### 4. Use Method Chaining for Complex Operations

```dart
final result = await safeAsync(() => fetchUser())
  .then((result) => result
    .map((user) => user.email)
    .flatMap((email) => safe(() => validateEmail(email)))
    .map((email) => email.toLowerCase())
  );
```

## Error Conversion

The safe functions automatically convert non-Exception errors:

```dart
// Throwing a string
final result1 = safe(() => throw 'Something went wrong');
print(result1.error); // Exception: Something went wrong

// Throwing a custom object
class CustomError {
  final String message;
  CustomError(this.message);
  @override
  String toString() => 'CustomError: $message';
}

final result2 = safe(() => throw CustomError('Custom error'));
print(result2.error); // Exception: CustomError: Custom error

// Exception objects are preserved
final result3 = safe(() => throw FormatException('Invalid format'));
print(result3.error); // FormatException: Invalid format
```

## See Also

- [Result<T, E>](result.md) - The return type of safe functions
- [Result Extensions](result_extensions.md) - Methods for working with results
- [Advanced Configuration](advanced_config.md) - Advanced error handling with retry and timeout
