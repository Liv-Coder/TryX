# Migration Guide: From try-catch to Tryx

This guide helps you migrate from traditional try-catch error handling to the Tryx library's functional approach.

## Table of Contents

1. [Why Migrate?](#why-migrate)
2. [Basic Patterns](#basic-patterns)
3. [Advanced Patterns](#advanced-patterns)
4. [Common Scenarios](#common-scenarios)
5. [Best Practices](#best-practices)
6. [Gradual Migration Strategy](#gradual-migration-strategy)

## Why Migrate?

### Problems with try-catch

```dart
// Traditional approach - problems:
// 1. Easy to forget error handling
// 2. Exceptions can be thrown anywhere
// 3. No compile-time guarantees
// 4. Difficult to compose operations
String processUserInput(String input) {
  try {
    final number = int.parse(input);
    final result = expensiveCalculation(number);
    return result.toString();
  } catch (e) {
    // What type of error? How to handle different cases?
    return 'Error occurred';
  }
}
```

### Benefits of Tryx

```dart
// Tryx approach - benefits:
// 1. Explicit error handling
// 2. Type-safe error types
// 3. Compile-time guarantees
// 4. Composable operations
SafeResult<String> processUserInput(String input) {
  return safe(() => int.parse(input))
    .flatMap((number) => safe(() => expensiveCalculation(number)))
    .map((result) => result.toString());
}
```

## Basic Patterns

### 1. Simple try-catch

**Before:**

```dart
String parseNumber(String input) {
  try {
    final number = int.parse(input);
    return 'Number: $number';
  } catch (e) {
    return 'Error: $e';
  }
}
```

**After:**

```dart
String parseNumber(String input) {
  final result = safe(() => int.parse(input));
  return result.when(
    success: (number) => 'Number: $number',
    failure: (error) => 'Error: $error',
  );
}
```

### 2. Async try-catch

**Before:**

```dart
Future<String> fetchUserData(String userId) async {
  try {
    final response = await http.get(Uri.parse('/users/$userId'));
    final user = User.fromJson(jsonDecode(response.body));
    return user.name;
  } catch (e) {
    return 'Failed to fetch user';
  }
}
```

**After:**

```dart
Future<String> fetchUserData(String userId) async {
  final result = await safeAsync(() async {
    final response = await http.get(Uri.parse('/users/$userId'));
    final user = User.fromJson(jsonDecode(response.body));
    return user.name;
  });

  return result.when(
    success: (name) => name,
    failure: (error) => 'Failed to fetch user',
  );
}
```

### 3. Multiple operations

**Before:**

```dart
String processData(String input) {
  try {
    final number = int.parse(input);
    final doubled = number * 2;
    final result = doubled.toString();
    return result;
  } catch (e) {
    return 'Processing failed';
  }
}
```

**After:**

```dart
SafeResult<String> processData(String input) {
  return safe(() => int.parse(input))
    .map((number) => number * 2)
    .map((doubled) => doubled.toString());
}

// Usage:
final result = processData('42');
final output = result.getOrElse(() => 'Processing failed');
```

## Advanced Patterns

### 1. Custom Error Types

**Before:**

```dart
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
}

Future<User> fetchUser(String id) async {
  try {
    final response = await http.get(Uri.parse('/users/$id'));
    if (response.statusCode != 200) {
      throw ApiException('User not found', response.statusCode);
    }
    return User.fromJson(jsonDecode(response.body));
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Network error', 500);
  }
}
```

**After:**

```dart
sealed class ApiError extends Exception {
  const ApiError();
  factory ApiError.notFound(String id) = UserNotFoundError;
  factory ApiError.network(String message) = NetworkError;
  factory ApiError.parsing(String message) = ParsingError;
}

final class UserNotFoundError extends ApiError {
  final String userId;
  const UserNotFoundError(this.userId);
}

final class NetworkError extends ApiError {
  final String message;
  const NetworkError(this.message);
}

final class ParsingError extends ApiError {
  final String message;
  const ParsingError(this.message);
}

Future<Result<User, ApiError>> fetchUser(String id) {
  return safeWith<User, ApiError>(
    () async {
      final response = await http.get(Uri.parse('/users/$id'));
      if (response.statusCode != 200) {
        throw ApiError.notFound(id);
      }
      return User.fromJson(jsonDecode(response.body));
    },
    errorMapper: (error) {
      if (error is ApiError) return error;
      if (error is SocketException) {
        return ApiError.network(error.message);
      }
      return ApiError.parsing(error.toString());
    },
  );
}
```

### 2. Error Recovery

**Before:**

```dart
Future<String> getUserName(String id) async {
  try {
    final user = await fetchUser(id);
    return user.name;
  } catch (e) {
    // Fallback to cache
    try {
      final cachedUser = await getCachedUser(id);
      return cachedUser.name;
    } catch (e2) {
      return 'Unknown User';
    }
  }
}
```

**After:**

```dart
Future<String> getUserName(String id) async {
  final result = await safeAsync(() => fetchUser(id))
    .then((result) => result.recoverWith((error) =>
      safeAsync(() => getCachedUser(id))
    ))
    .then((result) => result.map((user) => user.name))
    .then((result) => result.getOrElse(() => 'Unknown User'));

  return result;
}
```

### 3. Combining Multiple Operations

**Before:**

```dart
Future<String> getUserProfile(String userId) async {
  try {
    final user = await fetchUser(userId);
    final posts = await fetchUserPosts(userId);
    final followers = await fetchFollowers(userId);

    return 'User: ${user.name}, Posts: ${posts.length}, Followers: ${followers.length}';
  } catch (e) {
    return 'Failed to load profile';
  }
}
```

**After:**

```dart
Future<String> getUserProfile(String userId) async {
  final userResult = safeAsync(() => fetchUser(userId));
  final postsResult = safeAsync(() => fetchUserPosts(userId));
  final followersResult = safeAsync(() => fetchFollowers(userId));

  final combined = await combineResults3(
    await userResult,
    await postsResult,
    await followersResult,
  );

  return combined.when(
    success: (data) {
      final (user, posts, followers) = data;
      return 'User: ${user.name}, Posts: ${posts.length}, Followers: ${followers.length}';
    },
    failure: (error) => 'Failed to load profile',
  );
}
```

## Common Scenarios

### 1. File Operations

**Before:**

```dart
String readConfigFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (e) {
    return '{}'; // Default config
  }
}
```

**After:**

```dart
String readConfigFile(String path) {
  return safe(() => File(path).readAsStringSync())
    .getOrElse(() => '{}');
}
```

### 2. JSON Parsing

**Before:**

```dart
Map<String, dynamic> parseJson(String json) {
  try {
    return jsonDecode(json) as Map<String, dynamic>;
  } catch (e) {
    return <String, dynamic>{};
  }
}
```

**After:**

```dart
SafeResult<Map<String, dynamic>> parseJson(String json) {
  return safe(() => jsonDecode(json) as Map<String, dynamic>);
}

// Usage with default:
final data = parseJson(jsonString).getOrElse(() => <String, dynamic>{});
```

### 3. Database Operations

**Before:**

```dart
Future<List<User>> getUsers() async {
  try {
    final result = await database.query('SELECT * FROM users');
    return result.map((row) => User.fromMap(row)).toList();
  } catch (e) {
    print('Database error: $e');
    return [];
  }
}
```

**After:**

```dart
Future<List<User>> getUsers() async {
  final result = await safeAsync(() async {
    final result = await database.query('SELECT * FROM users');
    return result.map((row) => User.fromMap(row)).toList();
  });

  return result
    .onFailure((error) => print('Database error: $error'))
    .getOrElse(() => []);
}
```

## Best Practices

### 1. Use Specific Error Types

```dart
// Good: Specific error types
sealed class ValidationError extends Exception {
  const ValidationError();
  factory ValidationError.required(String field) = RequiredFieldError;
  factory ValidationError.invalid(String field) = InvalidFieldError;
}

// Avoid: Generic error types
// Using String or Exception directly loses type information
```

### 2. Handle All Cases

```dart
// Good: Exhaustive handling
final message = result.when(
  success: (value) => 'Success: $value',
  failure: (error) => 'Error: $error',
);

// Avoid: Ignoring failures
// final value = result.value; // Could be null!
```

### 3. Use Method Chaining

```dart
// Good: Fluent chaining
final result = safe(() => parseInput(input))
  .flatMap((parsed) => safe(() => validate(parsed)))
  .map((validated) => process(validated));

// Avoid: Nested try-catch
// try {
//   final parsed = parseInput(input);
//   try {
//     final validated = validate(parsed);
//     return process(validated);
//   } catch (e2) { ... }
// } catch (e1) { ... }
```

### 4. Provide Meaningful Defaults

```dart
// Good: Meaningful defaults
final config = parseConfig(configFile)
  .getOrElse(() => Config.defaultConfig());

// Avoid: Null or empty defaults without context
// final config = parseConfig(configFile).getOrNull(); // What if null?
```

## Gradual Migration Strategy

### Phase 1: New Code

Start using Tryx for all new code:

```dart
// New functions use Tryx
SafeResult<User> createUser(UserData data) {
  return safe(() => User.fromData(data))
    .flatMap((user) => safe(() => validateUser(user)));
}
```

### Phase 2: Wrapper Functions

Create Tryx wrappers for existing functions:

```dart
// Existing function
String legacyParseNumber(String input) {
  try {
    return int.parse(input).toString();
  } catch (e) {
    throw Exception('Parse failed');
  }
}

// Tryx wrapper
SafeResult<String> parseNumber(String input) {
  return safe(() => legacyParseNumber(input));
}
```

### Phase 3: Refactor Critical Paths

Gradually refactor important code paths:

```dart
// Before: Critical error-prone function
Future<void> processPayment(PaymentData data) async {
  try {
    await validatePayment(data);
    await chargeCard(data.cardToken, data.amount);
    await updateDatabase(data);
    await sendConfirmation(data.email);
  } catch (e) {
    // Critical errors might be lost
    logger.error('Payment failed: $e');
    rethrow;
  }
}

// After: Explicit error handling
Future<Result<void, PaymentError>> processPayment(PaymentData data) async {
  return safeWith<void, PaymentError>(
    () async {
      await validatePayment(data);
      await chargeCard(data.cardToken, data.amount);
      await updateDatabase(data);
      await sendConfirmation(data.email);
    },
    errorMapper: (error) => PaymentError.fromException(error),
  ).then((result) => result.onFailure((error) =>
    logger.error('Payment failed: $error')
  ));
}
```

### Phase 4: Complete Migration

Eventually migrate all error-handling code to use Tryx patterns.

## Migration Checklist

- [ ] Identify error-prone functions in your codebase
- [ ] Define custom error types for your domain
- [ ] Start with new code using Tryx patterns
- [ ] Create wrapper functions for existing code
- [ ] Refactor critical paths to use explicit error handling
- [ ] Update tests to verify both success and failure cases
- [ ] Remove old try-catch blocks as you migrate
- [ ] Update documentation to reflect new error handling patterns

## See Also

- [Safe Functions](../api/safe_functions.md) - Primary API functions
- [Result Extensions](../api/result_extensions.md) - Methods for working with results
- [Advanced Configuration](../api/advanced_config.md) - Retry policies and timeouts
- [Examples](../examples/) - Comprehensive usage examples
