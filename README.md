# tryx

[![Pub Version](https://img.shields.io/pub/v/tryx)](https://pub.dev/packages/tryx)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Dart library for functional, reliable, and expressive error handling.

## Features

- **Functional Approach**: Handle errors using `Result` and `Either` types.
- **Type-Safe**: Avoid runtime errors with compile-time checks.
- **Async Support**: Seamless integration with `Future` and `Stream`.
- **Expressive API**: Chain operations with `map`, `flatMap`, and `recover`.

## Getting Started

Add `tryx` to your `pubspec.yaml` dependencies:

```bash
dart pub add tryx
```

## Usage

Here's a simple example of how to use `tryx` to handle potential errors when parsing a string:

```dart
import 'package:tryx/tryx.dart';

void main() {
  final result = safe(() => int.parse('123'));

  result.when(
    success: (value) => print('Parsed value: $value'),
    failure: (error) => print('Failed to parse: $error'),
  );
}
```
