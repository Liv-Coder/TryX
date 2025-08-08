# Tryx Library - Usage Examples

## 🚀 Quick Start Examples

### Basic Error Handling

```dart
import 'package:tryx/tryx.dart';

// Simple synchronous operation
void basicExample() {
  final result = safe(() => int.parse('42'));

  result.when(
    success: (value) => print('Parsed: $value'), // Prints: Parsed: 42
    failure: (error) => print('Error: $error'),
  );
}

// Asynchronous operation
Future<void> asyncExample() async {
  final result = await safeAsync(() => fetchUserData());

  result
    .map((user) => user.name)
    .onSuccess((name) => print('Welcome, $name!'))
    .onFailure((error) => print('Failed to load user: $error'));
}
```

### Method Chaining

```dart
Future<void> chainingExample() async {
  final result = await safeAsync(() => fetchUserProfile())
    .then((result) => result
      .map((profile) => profile.email)
      .map((email) => email.toLowerCase())
      .flatMap((email) => safe(() => validateEmail(email)))
    );

  final message = result.fold(
    (error) => 'Validation failed: $error',
    (email) => 'Valid email: $email',
  );

  print(message);
}
```

## 🎯 Real-World Scenarios

### 1. API Client with Custom Error Types

```dart
// Define domain-specific errors
sealed class ApiError extends Exception {
  const ApiError(this.message);
  final String message;

  factory ApiError.network(String details) = NetworkError;
  factory ApiError.authentication() = AuthenticationError;
  factory ApiError.validation(String field) = ValidationError;
  factory ApiError.serverError(int statusCode) = ServerError;
}

class NetworkError extends ApiError {
  const NetworkError(super.message);
}

class AuthenticationError extends ApiError {
  const AuthenticationError() : super('Authentication failed');
}

class ValidationError extends ApiError {
  const ValidationError(String field) : super('Validation failed for: $field');
}

class ServerError extends ApiError {
  const ServerError(this.statusCode) : super('Server error');
  final int statusCode;
}

// API Client implementation
class UserApiClient {
  Future<Result<User, ApiError>> getUser(String id) async {
    return await safeWith<User, ApiError>(
      () => _httpClient.get('/users/$id'),
      errorMapper: (error) {
        if (error is SocketException) {
          return ApiError.network(error.message);
        } else if (error is HttpException) {
          return error.statusCode == 401
            ? ApiError.authentication()
            : ApiError.serverError(error.statusCode);
        }
        return ApiError.network(error.toString());
      },
    );
  }

  Future<Result<User, ApiError>> updateUser(String id, UserData data) async {
    return await safeWith<User, ApiError>(
      () async {
        final validation = validateUserData(data);
        if (!validation.isValid) {
          throw ValidationException(validation.errors.first);
        }
        return await _httpClient.put('/users/$id', data);
      },
      errorMapper: (error) {
        if (error is ValidationException) {
          return ApiError.validation(error.field);
        }
        return ApiError.network(error.toString());
      },
    );
  }
}

// Usage
Future<void> apiExample() async {
  final apiClient = UserApiClient();

  final result = await apiClient.getUser('123')
    .then((result) => result.flatMap((user) =>
      apiClient.updateUser(user.id, user.copyWith(name: 'Updated Name'))
    ));

  result.when(
    success: (user) => print('User updated: ${user.name}'),
    failure: (error) => switch (error) {
      NetworkError() => showNetworkErrorDialog(error.message),
      AuthenticationError() => redirectToLogin(),
      ValidationError() => showValidationError(error.message),
      ServerError() => showServerErrorDialog(error.statusCode),
    },
  );
}
```

### 2. Database Operations with Transactions

```dart
class DatabaseService {
  Future<Result<T, DatabaseError>> transaction<T>(
    Future<T> Function() operation,
  ) async {
    return await Safe(
      timeout: Duration(seconds: 30),
      retryPolicy: RetryPolicy(
        maxAttempts: 3,
        delay: Duration(milliseconds: 500),
      ),
    ).call<T, DatabaseError>(() async {
      final transaction = await database.beginTransaction();
      try {
        final result = await operation();
        await transaction.commit();
        return result;
      } catch (e) {
        await transaction.rollback();
        rethrow;
      }
    });
  }

  Future<Result<User, DatabaseError>> createUserWithProfile(
    UserData userData,
    ProfileData profileData,
  ) async {
    return await transaction(() async {
      final user = await userRepository.create(userData);
      final profile = await profileRepository.create(
        profileData.copyWith(userId: user.id),
      );
      return user.copyWith(profile: profile);
    });
  }
}

// Usage
Future<void> databaseExample() async {
  final dbService = DatabaseService();

  final result = await dbService.createUserWithProfile(
    UserData(name: 'John Doe', email: 'john@example.com'),
    ProfileData(bio: 'Software Developer'),
  );

  result
    .onSuccess((user) => print('User created with ID: ${user.id}'))
    .onFailure((error) => logError('Database operation failed', error));
}
```

### 3. File Operations with Validation

```dart
class FileService {
  Future<Result<String, FileError>> readConfigFile(String path) async {
    return await safeWith<String, FileError>(
      () => File(path).readAsString(),
      errorMapper: (error) => switch (error) {
        FileSystemException() => FileError.notFound(path),
        _ => FileError.readError(error.toString()),
      },
    ).then((result) => result.flatMap((content) =>
      safe(() => validateJsonConfig(content))
        .mapError((e) => FileError.invalidFormat(e.toString()))
    ));
  }

  Future<Result<void, FileError>> saveUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    return await safeWith<void, FileError>(
      () async {
        final json = jsonEncode(preferences);
        final file = File('user_preferences.json');
        await file.writeAsString(json);
      },
      errorMapper: (error) => FileError.writeError(error.toString()),
    );
  }
}

sealed class FileError extends Exception {
  const FileError(this.message);
  final String message;

  factory FileError.notFound(String path) = FileNotFoundError;
  factory FileError.readError(String details) = FileReadError;
  factory FileError.writeError(String details) = FileWriteError;
  factory FileError.invalidFormat(String details) = InvalidFormatError;
}

// Usage with recovery
Future<void> fileExample() async {
  final fileService = FileService();

  final config = await fileService.readConfigFile('config.json')
    .then((result) => result.recover((error) => switch (error) {
      FileNotFoundError() => getDefaultConfig(),
      InvalidFormatError() => getDefaultConfig(),
      FileReadError() => throw error, // Don't recover from read errors
    }));

  config.when(
    success: (configData) => initializeApp(configData),
    failure: (error) => showErrorAndExit(error.message),
  );
}
```

### 4. Stream Processing with Error Handling

```dart
class DataProcessor {
  Stream<Result<ProcessedData, ProcessingError>> processDataStream(
    Stream<RawData> input,
  ) {
    return input
      .safeStream<RawData, ProcessingError>(
        errorMapper: (error) => ProcessingError.streamError(error.toString()),
      )
      .mapSuccesses((data) => validateData(data))
      .asyncMap((result) => result.flatMapAsync((validData) =>
        safeWith<ProcessedData, ProcessingError>(
          () => transformData(validData),
          errorMapper: (e) => ProcessingError.transformError(e.toString()),
        )
      ));
  }

  Future<Result<List<ProcessedData>, ProcessingError>> processBatch(
    List<RawData> batch,
  ) async {
    final results = await Future.wait(
      batch.map((data) => safeWith<ProcessedData, ProcessingError>(
        () => processItem(data),
        errorMapper: (e) => ProcessingError.itemError(e.toString()),
      )),
    );

    return combineResults(results);
  }
}

// Usage
Future<void> streamExample() async {
  final processor = DataProcessor();
  final rawDataStream = getRawDataStream();

  await for (final result in processor.processDataStream(rawDataStream)) {
    result.when(
      success: (processedData) => saveToDatabase(processedData),
      failure: (error) => logProcessingError(error),
    );
  }
}
```

### 5. Flutter Widget Integration

```dart
class UserProfileWidget extends StatefulWidget {
  @override
  _UserProfileWidgetState createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  Result<UserProfile, ApiError>? _profileResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final result = await safeWith<UserProfile, ApiError>(
      () => userService.getCurrentUserProfile(),
      errorMapper: (error) => ApiError.network(error.toString()),
    );

    setState(() {
      _profileResult = result;
      _isLoading = false;
    });
  }

  Future<void> _updateProfile(UserProfile updatedProfile) async {
    final result = await safeWith<UserProfile, ApiError>(
      () => userService.updateProfile(updatedProfile),
      errorMapper: (error) => ApiError.network(error.toString()),
    );

    result.when(
      success: (profile) {
        setState(() => _profileResult = Result.success(profile));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      },
      failure: (error) => _showErrorDialog(error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return _profileResult?.when(
      success: (profile) => ProfileView(
        profile: profile,
        onUpdate: _updateProfile,
      ),
      failure: (error) => ErrorView(
        error: error.message,
        onRetry: _loadProfile,
      ),
    ) ?? Container();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### 6. Testing with Tryx

```dart
// Test helpers
Result<T, E> mockSuccess<T, E extends Object>(T value) => Result.success(value);
Result<T, E> mockFailure<T, E extends Object>(E error) => Result.failure(error);

// Unit tests
void main() {
  group('UserService', () {
    late UserService userService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      userService = UserService(mockApiClient);
    });

    test('should return user when API call succeeds', () async {
      // Arrange
      final expectedUser = User(id: '1', name: 'John');
      when(mockApiClient.getUser('1'))
        .thenAnswer((_) async => Result.success(expectedUser));

      // Act
      final result = await userService.getUser('1');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(expectedUser));
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      final expectedError = ApiError.network('Connection failed');
      when(mockApiClient.getUser('1'))
        .thenAnswer((_) async => Result.failure(expectedError));

      // Act
      final result = await userService.getUser('1');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error, equals(expectedError));
    });

    test('should chain operations correctly', () async {
      // Arrange
      final user = User(id: '1', name: 'John');
      final profile = UserProfile(userId: '1', bio: 'Developer');

      when(mockApiClient.getUser('1'))
        .thenAnswer((_) async => Result.success(user));
      when(mockApiClient.getUserProfile('1'))
        .thenAnswer((_) async => Result.success(profile));

      // Act
      final result = await userService.getUserWithProfile('1');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value?.profile, equals(profile));
    });
  });
}
```

## 🎨 Best Practices

### 1. Error Type Design

```dart
// ✅ Good: Sealed classes with specific error types
sealed class ValidationError extends Exception {
  const ValidationError(this.field, this.message);
  final String field;
  final String message;

  factory ValidationError.required(String field) = RequiredFieldError;
  factory ValidationError.format(String field, String expected) = FormatError;
  factory ValidationError.length(String field, int min, int max) = LengthError;
}

// ❌ Bad: Generic string errors
Result<User, String> validateUser(UserData data) {
  // Hard to handle different error types
}
```

### 2. Method Chaining

```dart
// ✅ Good: Clear, readable chains
final result = await safeAsync(() => fetchUser())
  .then((result) => result
    .map((user) => user.email)
    .flatMap((email) => safe(() => validateEmail(email)))
    .map((email) => email.toLowerCase())
  );

// ❌ Bad: Nested callbacks
final result = await safeAsync(() => fetchUser());
if (result.isSuccess) {
  final emailResult = safe(() => validateEmail(result.value!.email));
  if (emailResult.isSuccess) {
    // More nesting...
  }
}
```

### 3. Error Recovery

```dart
// ✅ Good: Specific recovery strategies
final config = await loadConfig()
  .then((result) => result.recover((error) => switch (error) {
    FileNotFoundError() => getDefaultConfig(),
    CorruptedFileError() => getDefaultConfig(),
    PermissionError() => throw error, // Don't recover
  }));

// ❌ Bad: Generic recovery
final config = await loadConfig()
  .then((result) => result.recover((_) => getDefaultConfig()));
```

These examples demonstrate how Tryx can be used in real-world scenarios while maintaining clean, readable, and maintainable code.
