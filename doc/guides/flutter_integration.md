# Flutter Integration Guide

This guide shows how to effectively use Tryx in Flutter applications for robust error handling and state management.

## Table of Contents

1. [Basic Integration](#basic-integration)
2. [State Management](#state-management)
3. [Widget Error Handling](#widget-error-handling)
4. [Async Operations](#async-operations)
5. [Form Validation](#form-validation)
6. [API Integration](#api-integration)
7. [Stream Integration](#stream-integration)
8. [Best Practices](#best-practices)

## Basic Integration

### Adding Tryx to Your Flutter Project

Add Tryx to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  tryx: ^1.0.0
```

### Basic Usage in Widgets

```dart
import 'package:flutter/material.dart';
import 'package:tryx/tryx.dart';

class NumberParserWidget extends StatefulWidget {
  @override
  _NumberParserWidgetState createState() => _NumberParserWidgetState();
}

class _NumberParserWidgetState extends State<NumberParserWidget> {
  final _controller = TextEditingController();
  String _result = '';

  void _parseNumber() {
    final result = safe(() => int.parse(_controller.text));

    setState(() {
      _result = result.when(
        success: (number) => 'Parsed: $number',
        failure: (error) => 'Error: Invalid number',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _controller),
        ElevatedButton(
          onPressed: _parseNumber,
          child: Text('Parse'),
        ),
        Text(_result),
      ],
    );
  }
}
```

## State Management

### Using Result with ValueNotifier

```dart
class UserController extends ChangeNotifier {
  Result<User, ApiError>? _userResult;
  bool _isLoading = false;

  Result<User, ApiError>? get userResult => _userResult;
  bool get isLoading => _isLoading;

  User? get user => _userResult?.value;
  ApiError? get error => _userResult?.error;

  Future<void> loadUser(String id) async {
    _isLoading = true;
    notifyListeners();

    final result = await safeWith<User, ApiError>(
      () => ApiClient.getUser(id),
      errorMapper: (e) => ApiError.fromException(e),
    );

    _userResult = result;
    _isLoading = false;
    notifyListeners();
  }

  void clearUser() {
    _userResult = null;
    _isLoading = false;
    notifyListeners();
  }
}
```

### Custom Result Widget Builder

```dart
class ResultBuilder<T, E extends Object> extends StatelessWidget {
  final Result<T, E>? result;
  final bool isLoading;
  final Widget Function()? loading;
  final Widget Function(T value) success;
  final Widget Function(E error) failure;
  final Widget Function()? empty;

  const ResultBuilder({
    Key? key,
    this.result,
    this.isLoading = false,
    this.loading,
    required this.success,
    required this.failure,
    this.empty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loading?.call() ?? const CircularProgressIndicator();
    }

    final currentResult = result;
    if (currentResult == null) {
      return empty?.call() ?? const SizedBox.shrink();
    }

    return currentResult.when(
      success: success,
      failure: failure,
    );
  }
}
```

### Usage with Provider

```dart
class UserView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, controller, child) {
        return ResultBuilder<User, ApiError>(
          result: controller.userResult,
          isLoading: controller.isLoading,
          loading: () => const CircularProgressIndicator(),
          success: (user) => Column(
            children: [
              Text('Welcome, ${user.name}!'),
              Text('Email: ${user.email}'),
            ],
          ),
          failure: (error) => Column(
            children: [
              Icon(Icons.error, color: Colors.red),
              Text('Error: ${error.message}'),
              ElevatedButton(
                onPressed: () => controller.loadUser('123'),
                child: Text('Retry'),
              ),
            ],
          ),
          empty: () => ElevatedButton(
            onPressed: () => controller.loadUser('123'),
            child: Text('Load User'),
          ),
        );
      },
    );
  }
}
```

## Widget Error Handling

### Safe Widget Building

```dart
class SafeWidget extends StatelessWidget {
  final Widget Function() builder;
  final Widget Function(Exception error)? errorBuilder;

  const SafeWidget({
    Key? key,
    required this.builder,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = safe(builder);

    return result.when(
      success: (widget) => widget,
      failure: (error) => errorBuilder?.call(error) ??
        ErrorWidget('Widget build failed: $error'),
    );
  }
}

// Usage
SafeWidget(
  builder: () => ComplexWidget(data: complexData),
  errorBuilder: (error) => Text('Failed to build widget'),
)
```

### Error Boundary Pattern

```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Exception error)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Exception? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
        ErrorWidget('Error: $_error');
    }

    return SafeWidget(
      builder: () => widget.child,
      errorBuilder: (error) {
        setState(() => _error = error);
        return widget.errorBuilder?.call(error) ??
          ErrorWidget('Error: $error');
      },
    );
  }
}
```

## Async Operations

### FutureBuilder with Result

```dart
class AsyncDataWidget extends StatelessWidget {
  final Future<Result<Data, ApiError>> dataFuture;

  const AsyncDataWidget({Key? key, required this.dataFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<Data, ApiError>>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData) {
          return const Text('No data');
        }

        return snapshot.data!.when(
          success: (data) => DataDisplay(data: data),
          failure: (error) => ErrorDisplay(error: error),
        );
      },
    );
  }
}
```

### Safe Async Actions

```dart
class AsyncActionHelper {
  static Future<void> safeAsyncAction(
    BuildContext context,
    Future<void> Function() action, {
    String Function(Exception error)? errorMessage,
    VoidCallback? onSuccess,
  }) async {
    final result = await safeAsync(action);

    if (!context.mounted) return;

    result.when(
      success: (_) => onSuccess?.call(),
      failure: (error) {
        final message = errorMessage?.call(error) ?? 'An error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }
}

// Usage in button press
ElevatedButton(
  onPressed: () => AsyncActionHelper.safeAsyncAction(
    context,
    () => saveUserData(),
    errorMessage: (error) => 'Failed to save: ${error.toString()}',
    onSuccess: () => Navigator.pop(context),
  ),
  child: Text('Save'),
)
```

## Form Validation

### Result-based Form Validation

```dart
sealed class ValidationError extends Exception {
  const ValidationError();
  factory ValidationError.required(String field) = RequiredFieldError;
  factory ValidationError.invalid(String field, String reason) = InvalidFieldError;
  factory ValidationError.tooShort(String field, int minLength) = TooShortError;
}

class FormValidator {
  static Result<String, ValidationError> validateEmail(String? email) {
    return safe(() {
      if (email == null || email.isEmpty) {
        throw ValidationError.required('email');
      }
      if (!email.contains('@')) {
        throw ValidationError.invalid('email', 'must contain @');
      }
      return email;
    });
  }

  static Result<String, ValidationError> validatePassword(String? password) {
    return safe(() {
      if (password == null || password.isEmpty) {
        throw ValidationError.required('password');
      }
      if (password.length < 8) {
        throw ValidationError.tooShort('password', 8);
      }
      return password;
    });
  }

  static Result<UserData, ValidationError> validateUserForm({
    required String? email,
    required String? password,
  }) {
    final emailResult = validateEmail(email);
    final passwordResult = validatePassword(password);

    return combineResults2(emailResult, passwordResult)
      .map((data) => UserData(email: data.$1, password: data.$2));
  }
}
```

### Form Widget with Result Validation

```dart
class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Result<UserData, ValidationError>? _validationResult;

  void _validateForm() {
    setState(() {
      _validationResult = FormValidator.validateUserForm(
        email: _emailController.text,
        password: _passwordController.text,
      );
    });
  }

  String? _getFieldError(String field) {
    return _validationResult?.error?.when(
      required: (f) => f == field ? 'This field is required' : null,
      invalid: (f, reason) => f == field ? reason : null,
      tooShort: (f, minLength) => f == field ? 'Must be at least $minLength characters' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: _getFieldError('email'),
          ),
          onChanged: (_) => _validateForm(),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _getFieldError('password'),
          ),
          obscureText: true,
          onChanged: (_) => _validateForm(),
        ),
        ElevatedButton(
          onPressed: _validationResult?.isSuccess == true
            ? () => _submitForm(_validationResult!.value!)
            : null,
          child: Text('Submit'),
        ),
      ],
    );
  }

  void _submitForm(UserData userData) {
    // Handle form submission
  }
}
```

## API Integration

### API Client with Result

```dart
class ApiClient {
  static const String baseUrl = 'https://api.example.com';

  static Future<Result<T, ApiError>> _request<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return safeWith<T, ApiError>(
      () async {
        final response = await http.get(Uri.parse('$baseUrl$endpoint'));

        if (response.statusCode != 200) {
          throw ApiError.httpError(response.statusCode, response.body);
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      },
      errorMapper: (error) {
        if (error is ApiError) return error;
        if (error is SocketException) {
          return ApiError.networkError(error.message);
        }
        if (error is FormatException) {
          return ApiError.parseError(error.message);
        }
        return ApiError.unknownError(error.toString());
      },
    );
  }

  static Future<Result<User, ApiError>> getUser(String id) {
    return _request('/users/$id', User.fromJson);
  }

  static Future<Result<List<Post>, ApiError>> getUserPosts(String userId) {
    return _request('/users/$userId/posts', (json) {
      final posts = json['posts'] as List;
      return posts.map((p) => Post.fromJson(p)).toList();
    });
  }
}
```

### Repository Pattern with Result

```dart
class UserRepository {
  final ApiClient _apiClient;
  final CacheService _cache;

  UserRepository(this._apiClient, this._cache);

  Future<Result<User, RepositoryError>> getUser(String id) async {
    // Try cache first
    final cachedResult = safe(() => _cache.getUser(id));
    if (cachedResult.isSuccess) {
      return Result.success(cachedResult.value!);
    }

    // Fetch from API
    final apiResult = await _apiClient.getUser(id);

    return apiResult
      .onSuccess((user) => _cache.setUser(id, user))
      .mapError((apiError) => RepositoryError.fromApiError(apiError));
  }

  Future<Result<void, RepositoryError>> updateUser(User user) async {
    final result = await safeWith<void, RepositoryError>(
      () => _apiClient.updateUser(user),
      errorMapper: (error) => RepositoryError.fromException(error),
    );

    // Update cache on success
    result.onSuccess((_) => _cache.setUser(user.id, user));

    return result;
  }
}
```

## Stream Integration

### StreamBuilder with Result Streams

```dart
class LiveDataWidget extends StatelessWidget {
  final Stream<Result<Data, ApiError>> dataStream;

  const LiveDataWidget({Key? key, required this.dataStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Result<Data, ApiError>>(
      stream: dataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData) {
          return const Text('No data');
        }

        return snapshot.data!.when(
          success: (data) => DataWidget(data: data),
          failure: (error) => ErrorWidget(error: error),
        );
      },
    );
  }
}
```

### Real-time Updates with Safe Streams

```dart
class RealtimeController extends ChangeNotifier {
  final StreamController<Result<Message, ConnectionError>> _messageController;
  late final Stream<Result<Message, ConnectionError>> messageStream;

  RealtimeController() : _messageController = StreamController.broadcast() {
    messageStream = _messageController.stream;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    final stream = WebSocketService.connect();

    stream.safeMap((data) => Message.fromJson(data))
      .listen((result) => _messageController.add(result));
  }

  @override
  void dispose() {
    _messageController.close();
    super.dispose();
  }
}
```

## Best Practices

### 1. Consistent Error Types

Define domain-specific error types for different layers:

```dart
// API Layer
sealed class ApiError extends Exception {
  factory ApiError.network(String message) = NetworkError;
  factory ApiError.auth() = AuthError;
  factory ApiError.notFound() = NotFoundError;
}

// Repository Layer
sealed class RepositoryError extends Exception {
  factory RepositoryError.cache(String message) = CacheError;
  factory RepositoryError.api(ApiError apiError) = ApiRepositoryError;
}

// UI Layer
sealed class UiError extends Exception {
  factory UiError.validation(String message) = ValidationError;
  factory UiError.repository(RepositoryError repoError) = RepositoryUiError;
}
```

### 2. Error Mapping Between Layers

```dart
extension ApiErrorMapping on ApiError {
  RepositoryError toRepositoryError() {
    return switch (this) {
      NetworkError(message: final msg) => RepositoryError.api(this),
      AuthError() => RepositoryError.api(this),
      NotFoundError() => RepositoryError.api(this),
    };
  }
}
```

### 3. Global Error Handling

```dart
class GlobalErrorHandler {
  static void handleError(BuildContext context, Object error) {
    final message = switch (error) {
      ApiError() => 'Network error occurred',
      ValidationError() => 'Please check your input',
      _ => 'An unexpected error occurred',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Usage in widgets
result.onFailure((error) => GlobalErrorHandler.handleError(context, error));
```

### 4. Loading States

```dart
class LoadingState<T, E extends Object> {
  final bool isLoading;
  final Result<T, E>? result;

  const LoadingState({this.isLoading = false, this.result});

  LoadingState<T, E> loading() => LoadingState(isLoading: true, result: result);
  LoadingState<T, E> success(T value) => LoadingState(
    isLoading: false,
    result: Result.success(value),
  );
  LoadingState<T, E> failure(E error) => LoadingState(
    isLoading: false,
    result: Result.failure(error),
  );
}
```

### 5. Testing with Result

```dart
void main() {
  group('UserController', () {
    testWidgets('should display user data on successful load', (tester) async {
      final mockApi = MockApiClient();
      when(mockApi.getUser('123')).thenAnswer(
        (_) async => Result.success(User(id: '123', name: 'John')),
      );

      final controller = UserController(mockApi);
      await controller.loadUser('123');

      expect(controller.userResult?.isSuccess, true);
      expect(controller.user?.name, 'John');
    });

    testWidgets('should display error on failed load', (tester) async {
      final mockApi = MockApiClient();
      when(mockApi.getUser('123')).thenAnswer(
        (_) async => Result.failure(ApiError.notFound()),
      );

      final controller = UserController(mockApi);
      await controller.loadUser('123');

      expect(controller.userResult?.isFailure, true);
      expect(controller.error, isA<NotFoundError>());
    });
  });
}
```

## Conclusion

Tryx provides excellent integration with Flutter applications by:

- Providing type-safe error handling
- Enabling declarative UI patterns
- Supporting reactive programming with streams
- Facilitating clean architecture patterns
- Making testing more predictable

The key is to use Result types consistently throughout your application layers and provide appropriate error mapping between different domains.
