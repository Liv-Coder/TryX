# Contributing to Tryx

Thank you for your interest in contributing to Tryx! This guide will help you get started with contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Contributing Guidelines](#contributing-guidelines)
5. [Code Style](#code-style)
6. [Testing](#testing)
7. [Documentation](#documentation)
8. [Pull Request Process](#pull-request-process)
9. [Issue Reporting](#issue-reporting)
10. [Community](#community)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful, inclusive, and constructive in all interactions.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Dart SDK 3.0.0 or later
- Git for version control
- A code editor (VS Code, IntelliJ, etc.)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

   ```bash
   git clone https://github.com/your-username/tryx.git
   cd tryx
   ```

3. Add the upstream repository:

   ```bash
   git remote add upstream https://github.com/original-owner/tryx.git
   ```

## Development Setup

### Install Dependencies

```bash
dart pub get
```

### Run Tests

```bash
dart test
```

### Run Analysis

```bash
dart analyze
```

### Generate Documentation

```bash
dart doc
```

## Contributing Guidelines

### Types of Contributions

We welcome several types of contributions:

- **Bug fixes**: Fix issues in the codebase
- **Feature additions**: Add new functionality
- **Documentation improvements**: Enhance docs, guides, or examples
- **Performance optimizations**: Improve efficiency
- **Test improvements**: Add or improve test coverage
- **Examples**: Create usage examples or tutorials

### Before You Start

1. **Check existing issues**: Look for existing issues or discussions
2. **Create an issue**: For significant changes, create an issue first
3. **Discuss the approach**: Get feedback on your proposed solution
4. **Keep it focused**: One feature/fix per pull request

## Code Style

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables, functions, and parameters
- Use `UpperCamelCase` for classes, enums, and typedefs
- Use `lowercase_with_underscores` for libraries and packages
- Use `SCREAMING_CAPS` for constants

### Formatting

Use `dart format` to format your code:

```bash
dart format .
```

### Linting

Ensure your code passes all linter rules:

```bash
dart analyze
```

### Documentation Comments

Use dartdoc comments for public APIs:

````dart
/// Safely executes a function and returns a [Result].
///
/// This function wraps the execution of [fn] in a try-catch block
/// and returns a [Result] that either contains the successful return
/// value or the caught exception.
///
/// Example:
/// ```dart
/// final result = safe(() => int.parse('42'));
/// print(result.isSuccess); // true
/// ```
SafeResult<T> safe<T>(T Function() fn) {
  // Implementation
}
````

### Architecture Principles

Follow these architectural principles:

1. **Feature-based organization**: Group related functionality together
2. **Immutable design**: Prefer immutable data structures
3. **Type safety**: Use strong typing and avoid dynamic types
4. **Functional patterns**: Prefer functional programming patterns
5. **Error handling**: Use Result types consistently

## Testing

### Test Requirements

- All new features must include tests
- Bug fixes should include regression tests
- Maintain or improve test coverage
- Tests should be clear and well-documented

### Test Structure

```dart
void main() {
  group('Feature Name', () {
    test('should do something specific', () {
      // Arrange
      final input = 'test input';

      // Act
      final result = functionUnderTest(input);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, equals('expected output'));
    });

    test('should handle error case', () {
      // Test error scenarios
      final result = functionUnderTest('invalid input');
      expect(result.isFailure, isTrue);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/specific_test.dart

# Run tests with coverage
dart test --coverage=coverage
```

### Test Categories

- **Unit tests**: Test individual functions and classes
- **Integration tests**: Test component interactions
- **Example tests**: Ensure examples work correctly

## Documentation

### Types of Documentation

1. **API Documentation**: Dartdoc comments in code
2. **User Guides**: Markdown files in `doc/guides/`
3. **Examples**: Code examples in `doc/examples/`
4. **README**: Project overview and quick start

### Documentation Standards

- Use clear, concise language
- Include code examples
- Provide both simple and advanced examples
- Keep documentation up-to-date with code changes

### Writing Examples

````dart
/// Example: Basic usage
/// ```dart
/// final result = safe(() => int.parse('42'));
/// result.when(
///   success: (value) => print('Parsed: $value'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
````

## Pull Request Process

### Before Submitting

1. **Update your fork**:

   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** following the guidelines above

4. **Test your changes**:

   ```bash
   dart test
   dart analyze
   dart format .
   ```

5. **Commit your changes**:

   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions or modifications
- `chore:` Maintenance tasks

Examples:

```
feat: add circuit breaker pattern for error recovery
fix: resolve type inference issue in safe() function
docs: update migration guide with new examples
test: add comprehensive tests for stream extensions
```

### Pull Request Template

When creating a pull request, include:

```markdown
## Description

Brief description of the changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing

- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

### Review Process

1. **Automated checks**: CI will run tests and analysis
2. **Code review**: Maintainers will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

## Issue Reporting

### Bug Reports

Use the bug report template:

````markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Code Example**

```dart
// Minimal code example that reproduces the issue
```
````

**Environment**

- Dart version: [e.g. 3.0.0]
- Flutter version: [e.g. 3.10.0] (if applicable)
- Platform: [e.g. Windows, macOS, Linux]

````

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Any other context or screenshots about the feature request.
````

### Questions and Discussions

For questions and discussions:

- Check existing documentation first
- Search existing issues and discussions
- Use GitHub Discussions for general questions
- Use Issues for specific problems or feature requests

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Pull Requests**: Code contributions and reviews

### Getting Help

If you need help:

1. Check the documentation and examples
2. Search existing issues and discussions
3. Create a new discussion or issue
4. Be specific about your problem and include code examples

### Recognition

Contributors are recognized in:

- GitHub contributors list
- Release notes for significant contributions
- Documentation acknowledgments

## Development Workflow

### Typical Workflow

1. **Find or create an issue** describing the work
2. **Fork and clone** the repository
3. **Create a feature branch** from main
4. **Make your changes** following the guidelines
5. **Write tests** for your changes
6. **Update documentation** as needed
7. **Run tests and analysis** to ensure quality
8. **Commit your changes** with clear messages
9. **Push to your fork** and create a pull request
10. **Respond to feedback** during code review
11. **Celebrate** when your contribution is merged!

### Release Process

Releases follow semantic versioning:

- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes, backward compatible

## Thank You

Thank you for contributing to Tryx! Your contributions help make error handling in Dart better for everyone.

For questions about contributing, feel free to create a discussion or reach out to the maintainers.
