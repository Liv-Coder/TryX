# Migration Toolkit: From try-catch to Tryx

This comprehensive toolkit provides step-by-step guidance, automated helpers, and practical examples for migrating from traditional try-catch error handling to Tryx's functional approach.

## Table of Contents

1. [Migration Strategy](#migration-strategy)
2. [Automated Migration Helpers](#automated-migration-helpers)
3. [Step-by-Step Migration Process](#step-by-step-migration-process)
4. [Common Migration Patterns](#common-migration-patterns)
5. [Testing During Migration](#testing-during-migration)
6. [Performance Considerations](#performance-considerations)
7. [Team Migration Guidelines](#team-migration-guidelines)

## Migration Strategy

### Phase 1: Preparation (1-2 weeks)

- [ ] Install Tryx dependency
- [ ] Set up basic configuration
- [ ] Train team on Tryx concepts
- [ ] Identify migration candidates
- [ ] Create migration plan

### Phase 2: New Code (2-4 weeks)

- [ ] Use Tryx for all new features
- [ ] Create wrapper functions for legacy code
- [ ] Establish coding standards
- [ ] Set up code review guidelines

### Phase 3: Critical Path Migration (4-8 weeks)

- [ ] Migrate error-prone functions
- [ ] Migrate API boundaries
- [ ] Migrate data processing pipelines
- [ ] Update error handling strategies

### Phase 4: Complete Migration (8-16 weeks)

- [ ] Migrate remaining functions
- [ ] Remove legacy error handling
- [ ] Optimize performance
- [ ] Update documentation

## Automated Migration Helpers

Tryx provides several automated helpers to ease the migration process:

### MigrationHelper Class

```dart
import 'package:tryx/tryx.dart';

final migrator = MigrationHelper();

// Wrap existing functions
final result = migrator.wrapLegacyFunction(() => legacyParseFunction(input));

// Wrap async functions
final asyncResult = await migrator.wrapLegacyAsyncFunction(() => legacyApiCall());

// Custom error mapping
final mappedResult = await migrator.wrapWithErrorMapping<User, ApiError>(
  () => fetchUser(id),
  errorMapper: (error) => ApiError.fromException(error),
);
```

### Migration Patterns

```dart
// Simple try-catch replacement
String processData(String input) {
  return MigrationPatterns.simpleTryCatch(
    () => complexProcessing(input),
    onError: (error) => 'Processing failed: $error',
  );
}

// Async try-catch replacement
Future<String> fetchData() async {
  return MigrationPatterns.asyncTryCatch(
    () => apiClient.getData(),
    onError: (error) => 'Fetch failed: $error',
  );
}

// Chained operations
String processChain(String input) {
  return MigrationPatterns.chainedOperations(
    () => parseInput(input),
    (parsed) => validateInput(parsed),
    (validated) => processInput(validated),
    onError: (error, step) => '$step failed: $error',
  );
}
```

## Step-by-Step Migration Process

### Step 1: Identify Migration Candidates

Look for functions with these characteristics:

- Multiple try-catch blocks
- Complex error handling logic
- Functions that throw different exception types
- Critical error-prone operations

```dart
// Migration candidate - complex error handling
Future<User> getUserData(String id) async {
  try {
    final response = await http.get('/users/$id');
    try {
      final userData = jsonDecode(response.body);
      try {
        return User.fromJson(userData);
      } catch (e) {
        throw ParseException('Invalid user data: $e');
      }
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  } catch (e) {
    throw NetworkException('Network error: $e');
  }
}
```

### Step 2: Define Error Types

Create domain-specific error types:

```dart
sealed class UserError extends Exception {
  const UserError();
  factory UserError.network(String message) = NetworkUserError;
  factory UserError.parsing(String message) = ParsingUserError;
  factory UserError.notFound(String id) = UserNotFoundError;
}

final class NetworkUserError extends UserError {
  final String message;
  const NetworkUserError(this.message);
}

final class ParsingUserError extends UserError {
  final String message;
  const ParsingUserError(this.message);
}

final class UserNotFoundError extends UserError {
  final String userId;
  const UserNotFoundError(this.userId);
}
```

### Step 3: Migrate Function Signature

```dart
// Before
Future<User> getUserData(String id) async { ... }

// After
Future<Result<User, UserError>> getUserData(String id) async { ... }
```

### Step 4: Implement Migration

```dart
Future<Result<User, UserError>> getUserData(String id) async {
  return safeWith<User, UserError>(
    () async {
      final response = await http.get('/users/$id');
      if (response.statusCode == 404) {
        throw UserError.notFound(id);
      }
      final userData = jsonDecode(response.body);
      return User.fromJson(userData);
    },
    errorMapper: (error) {
      if (error is UserError) return error;
      if (error is SocketException) {
        return UserError.network(error.message);
      }
      if (error is FormatException) {
        return UserError.parsing(error.message);
      }
      return UserError.parsing('Unknown error: $error');
    },
  );
}
```

### Step 5: Update Call Sites

```dart
// Before
try {
  final user = await getUserData('123');
  displayUser(user);
} catch (e) {
  showError('Failed to load user: $e');
}

// After
final userResult = await getUserData('123');
userResult.when(
  success: (user) => displayUser(user),
  failure: (error) => showError('Failed to load user: $error'),
);
```

## Common Migration Patterns

### Pattern 1: Simple Exception Handling

**Before:**

```dart
int divide(int a, int b) {
  try {
    if (b == 0) throw ArgumentError('Division by zero');
    return a ~/ b;
  } catch (e) {
    return -1; // Error indicator
  }
}
```

**After:**

```dart
SafeResult<int> divide(int a, int b) {
  return safe(() {
    if (b == 0) throw ArgumentError('Division by zero');
    return a ~/ b;
  });
}

// Usage
final result = divide(10, 2);
final value = result.getOrElse(() => -1);
```

### Pattern 2: Multiple Exception Types

**Before:**

```dart
String processFile(String path) {
  try {
    final file = File(path);
    final content = file.readAsStringSync();
    return content.toUpperCase();
  } on FileSystemException catch (e) {
    return 'File error: ${e.message}';
  } on FormatException catch (e) {
    return 'Format error: ${e.message}';
  } catch (e) {
    return 'Unknown error: $e';
  }
}
```

**After:**

```dart
sealed class FileError extends Exception {
  const FileError();
  factory FileError.fileSystem(String message) = FileSystemError;
  factory FileError.format(String message) = FormatError;
  factory FileError.unknown(String message) = UnknownFileError;
}

Result<String, FileError> processFile(String path) {
  return safeWith<String, FileError>(
    () {
      final file = File(path);
      final content = file.readAsStringSync();
      return content.toUpperCase();
    },
    errorMapper: (error) {
      if (error is FileSystemException) {
        return FileError.fileSystem(error.message);
      }
      if (error is FormatException) {
        return FileError.format(error.message);
      }
      return FileError.unknown(error.toString());
    },
  );
}

// Usage
final result = processFile('data.txt');
final message = result.when(
  success: (content) => 'Content: $content',
  failure: (error) => switch (error) {
    FileSystemError(message: final msg) => 'File error: $msg',
    FormatError(message: final msg) => 'Format error: $msg',
    UnknownFileError(message: final msg) => 'Unknown error: $msg',
  },
);
```

### Pattern 3: Async Operations with Cleanup

**Before:**

```dart
Future<String> processWithResource() async {
  Resource? resource;
  try {
    resource = await acquireResource();
    final data = await resource.getData();
    return processData(data);
  } catch (e) {
    return 'Error: $e';
  } finally {
    await resource?.release();
  }
}
```

**After:**

```dart
Future<SafeResult<String>> processWithResource() async {
  return safeAsync(() async {
    final resource = await acquireResource();
    try {
      final data = await resource.getData();
      return processData(data);
    } finally {
      await resource.release();
    }
  });
}

// Or using migration helper
Future<String> processWithResource() async {
  return MigrationPatterns.withResource(
    acquire: () => acquireResource(),
    use: (resource) => resource.getData().then(processData),
    release: (resource) => resource.release(),
    onError: (error) => 'Error: $error',
  );
}
```

### Pattern 4: Validation Chains

**Before:**

```dart
User validateAndCreateUser(Map<String, dynamic> data) {
  if (data['name'] == null || data['name'].isEmpty) {
    throw ValidationException('Name is required');
  }
  if (data['email'] == null || !isValidEmail(data['email'])) {
    throw ValidationException('Valid email is required');
  }
  if (data['age'] == null || data['age'] < 18) {
    throw ValidationException('Age must be 18 or older');
  }
  return User(
    name: data['name'],
    email: data['email'],
    age: data['age'],
  );
}
```

**After:**

```dart
sealed class ValidationError extends Exception {
  const ValidationError();
  factory ValidationError.required(String field) = RequiredFieldError;
  factory ValidationError.invalid(String field, String reason) = InvalidFieldError;
}

Result<User, ValidationError> validateAndCreateUser(Map<String, dynamic> data) {
  return safe(() => data['name'])
    .flatMap((name) => name != null && name.isNotEmpty
      ? Result.success(name)
      : Result.failure(ValidationError.required('name')))
    .flatMap((name) => safe(() => data['email'])
      .flatMap((email) => email != null && isValidEmail(email)
        ? Result.success(email)
        : Result.failure(ValidationError.invalid('email', 'must be valid email'))))
    .flatMap((email) => safe(() => data['age'])
      .flatMap((age) => age != null && age >= 18
        ? Result.success(age)
        : Result.failure(ValidationError.invalid('age', 'must be 18 or older'))))
    .map((age) => User(
      name: data['name'],
      email: data['email'],
      age: age,
    ));
}
```

## Testing During Migration

### Test Both Old and New Implementations

```dart
void main() {
  group('Migration Tests', () {
    test('legacy function behavior preserved', () {
      // Test legacy function
      final legacyResult = legacyFunction('input');

      // Test migrated function
      final migratedResult = migratedFunction('input');
      final migratedValue = migratedResult.getOrElse(() => 'default');

      expect(migratedValue, equals(legacyResult));
    });

    test('error cases handled correctly', () {
      // Test legacy error handling
      expect(() => legacyFunction('invalid'), throwsException);

      // Test migrated error handling
      final result = migratedFunction('invalid');
      expect(result.isFailure, isTrue);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  group('Integration Tests', () {
    test('mixed legacy and migrated code works together', () async {
      // Legacy function wrapped for compatibility
      final migrator = MigrationHelper();
      final wrappedLegacy = migrator.wrapLegacyFunction(() => legacyFunction());

      // Chain with migrated function
      final result = wrappedLegacy
        .flatMap((value) => migratedFunction(value));

      expect(result.isSuccess, isTrue);
    });
  });
}
```

## Performance Considerations

### Benchmarking Migration Impact

```dart
void benchmarkMigration() {
  final stopwatch = Stopwatch();

  // Benchmark legacy approach
  stopwatch.start();
  for (int i = 0; i < 10000; i++) {
    try {
      legacyFunction(i.toString());
    } catch (e) {
      // Handle error
    }
  }
  stopwatch.stop();
  print('Legacy: ${stopwatch.elapsedMicroseconds}μs');

  // Benchmark Tryx approach
  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < 10000; i++) {
    final result = safe(() => migratedFunction(i.toString()));
    result.onFailure((error) {
      // Handle error
    });
  }
  stopwatch.stop();
  print('Tryx: ${stopwatch.elapsedMicroseconds}μs');
}
```

### Memory Usage Optimization

```dart
// Avoid creating unnecessary Result objects
SafeResult<String> optimizedFunction(String input) {
  // Pre-validate to avoid Result creation for invalid input
  if (input.isEmpty) {
    return Result.failure(Exception('Input cannot be empty'));
  }

  return safe(() => expensiveOperation(input));
}
```

## Team Migration Guidelines

### Code Review Checklist

- [ ] New error types are well-defined and documented
- [ ] Error mapping is comprehensive and accurate
- [ ] All error cases are handled appropriately
- [ ] Tests cover both success and failure scenarios
- [ ] Performance impact is acceptable
- [ ] Documentation is updated

### Migration Standards

1. **Error Type Naming**: Use descriptive, domain-specific error types
2. **Error Mapping**: Always provide comprehensive error mapping
3. **Documentation**: Document migration decisions and error handling strategies
4. **Testing**: Maintain test coverage during migration
5. **Gradual Migration**: Migrate incrementally, not all at once

### Training Materials

Create team training sessions covering:

- Tryx fundamentals and philosophy
- Migration patterns and best practices
- Error type design principles
- Testing strategies for Result-based code
- Performance considerations

## Migration Checklist

### Pre-Migration

- [ ] Team trained on Tryx concepts
- [ ] Migration plan created and approved
- [ ] Error types designed for domain
- [ ] Testing strategy established

### During Migration

- [ ] Functions migrated incrementally
- [ ] Tests updated for each migrated function
- [ ] Performance monitored
- [ ] Code reviews conducted

### Post-Migration

- [ ] Legacy code removed
- [ ] Documentation updated
- [ ] Performance optimized
- [ ] Team retrospective conducted

## Troubleshooting Common Issues

### Issue: Type Inference Problems

```dart
// Problem: Compiler can't infer types
final result = safe(() => someFunction());

// Solution: Provide explicit types
final result = safe<String>(() => someFunction());
```

### Issue: Complex Error Mapping

```dart
// Problem: Too many error types to map
errorMapper: (error) {
  // 20+ if statements...
}

// Solution: Use error classification
class ErrorClassifier {
  static DomainError classify(Object error) {
    return switch (error.runtimeType) {
      SocketException => DomainError.network(),
      FormatException => DomainError.parsing(),
      _ => DomainError.unknown(),
    };
  }
}
```

### Issue: Performance Degradation

```dart
// Problem: Creating too many Result objects
for (final item in items) {
  final result = safe(() => process(item));
  // ...
}

// Solution: Batch processing
final results = items.map((item) => safe(() => process(item))).toList();
final (successes, failures) = partitionResults(results);
```

## Conclusion

Migrating from try-catch to Tryx is a gradual process that improves code reliability and maintainability. Use the provided tools and patterns to ensure a smooth transition while maintaining code quality and team productivity.

For additional support, refer to:

- [Migration Guide](migration.md) - Detailed migration patterns
- [Flutter Integration](flutter_integration.md) - Flutter-specific migration
- [API Documentation](../api/README.md) - Complete API reference
