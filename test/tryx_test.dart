import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('Result<T, E>', () {
    group('Success', () {
      test('should create success result', () {
        const result = Result<int, String>.success(42);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.value, equals(42));
        expect(result.error, isNull);
      });

      test('should maintain type safety', () {
        const result = Result<String, Exception>.success('hello');

        expect(result, isA<Success<String, Exception>>());
        expect(result.value, isA<String>());
      });

      test('should support equality', () {
        const result1 = Result<int, String>.success(42);
        const result2 = Result<int, String>.success(42);
        const result3 = Result<int, String>.success(43);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have correct toString', () {
        const result = Result<int, String>.success(42);
        expect(result.toString(), equals('Success(42)'));
      });
    });

    group('Failure', () {
      test('should create failure result', () {
        final error = Exception('test error');
        final result = Result<int, Exception>.failure(error);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.value, isNull);
        expect(result.error, equals(error));
      });

      test('should maintain error type', () {
        const result = Result<int, String>.failure('error message');

        expect(result, isA<Failure<int, String>>());
        expect(result.error, isA<String>());
      });

      test('should support equality', () {
        const result1 = Result<int, String>.failure('error');
        const result2 = Result<int, String>.failure('error');
        const result3 = Result<int, String>.failure('different');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have correct toString', () {
        const result = Result<int, String>.failure('error');
        expect(result.toString(), equals('Failure(error)'));
      });
    });

    group('Pattern Matching', () {
      test('should support switch expressions', () {
        const successResult = Result<int, String>.success(42);
        const failureResult = Result<int, String>.failure('error');

        final successValue = switch (successResult) {
          Success(value: final v) => 'success: $v',
          Failure(error: final e) => 'failure: $e',
        };

        final failureValue = switch (failureResult) {
          Success(value: final v) => 'success: $v',
          Failure(error: final e) => 'failure: $e',
        };

        expect(successValue, equals('success: 42'));
        expect(failureValue, equals('failure: error'));
      });
    });
  });

  group('safe()', () {
    test('should wrap successful function', () {
      final result = safe(() => 42);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });

    test('should catch exceptions', () {
      final result = safe(() => throw Exception('test error'));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
      expect(result.error.toString(), contains('test error'));
    });

    test('should handle different return types', () {
      final stringResult = safe(() => 'hello');
      final intResult = safe(() => 42);
      final listResult = safe(() => [1, 2, 3]);

      expect(stringResult.value, isA<String>());
      expect(intResult.value, isA<int>());
      expect(listResult.value, isA<List<int>>());
    });

    test('should convert non-Exception errors', () {
      final result = safe(() => throw 'string error');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
      expect(result.error.toString(), contains('string error'));
    });

    test('should handle FormatException', () {
      final result = safe(() => int.parse('not-a-number'));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FormatException>());
    });
  });

  group('safeAsync()', () {
    test('should wrap successful async function', () async {
      final result = await safeAsync(() async => 42);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });

    test('should catch async exceptions', () async {
      final result = await safeAsync(
        () async => throw Exception('async error'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
      expect(result.error.toString(), contains('async error'));
    });

    test('should handle Future.delayed', () async {
      final result = await safeAsync(
        () => Future.delayed(
          const Duration(milliseconds: 10),
          () => 'delayed result',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('delayed result'));
    });

    test('should handle Future.error', () async {
      final result = await safeAsync(() => Future<int>.error('async error'));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
    });
  });

  group('safeWith()', () {
    test('should use custom error mapper', () async {
      final result = await safeWith<int, String>(
        () => throw Exception('original error'),
        errorMapper: (e) => 'mapped: ${e.toString()}',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, startsWith('mapped:'));
    });

    test('should handle sync functions', () async {
      final result = await safeWith<int, String>(
        () => 42,
        errorMapper: (e) => 'error',
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(42));
    });

    test('should handle async functions', () async {
      final result = await safeWith<String, String>(
        () => Future.value('async result'),
        errorMapper: (e) => 'error',
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('async result'));
    });

    test('should cast error when no mapper provided', () async {
      final result = await safeWith<int, Exception>(
        () => throw Exception('test'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<Exception>());
    });
  });

  group('ResultExtensions', () {
    group('map', () {
      test('should transform success value', () {
        const result = Result<int, String>.success(42);
        final mapped = result.map((x) => x.toString());

        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, equals('42'));
      });

      test('should preserve failure', () {
        const result = Result<int, String>.failure('error');
        final mapped = result.map((x) => x.toString());

        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals('error'));
      });
    });

    group('flatMap', () {
      test('should chain successful operations', () {
        const result = Result<int, String>.success(42);
        final chained = result.flatMap((x) => Result.success(x.toString()));

        expect(chained.isSuccess, isTrue);
        expect(chained.value, equals('42'));
      });

      test('should short-circuit on failure', () {
        const result = Result<int, String>.failure('error');
        final chained = result.flatMap((x) => Result.success(x.toString()));

        expect(chained.isFailure, isTrue);
        expect(chained.error, equals('error'));
      });

      test('should propagate inner failure', () {
        const result = Result<int, String>.success(42);
        final chained = result.flatMap(
          (x) => const Result<String, String>.failure('inner error'),
        );

        expect(chained.isFailure, isTrue);
        expect(chained.error, equals('inner error'));
      });
    });

    group('when', () {
      test('should call success callback', () {
        const result = Result<int, String>.success(42);
        var called = false;

        final output = result.when(
          success: (value) {
            called = true;
            return 'success: $value';
          },
          failure: (error) => 'failure: $error',
        );

        expect(called, isTrue);
        expect(output, equals('success: 42'));
      });

      test('should call failure callback', () {
        const result = Result<int, String>.failure('error');
        var called = false;

        final output = result.when(
          success: (value) => 'success: $value',
          failure: (error) {
            called = true;
            return 'failure: $error';
          },
        );

        expect(called, isTrue);
        expect(output, equals('failure: error'));
      });
    });

    group('getOrElse', () {
      test('should return value on success', () {
        const result = Result<int, String>.success(42);
        final value = result.getOrElse(() => 0);

        expect(value, equals(42));
      });

      test('should return default on failure', () {
        const result = Result<int, String>.failure('error');
        final value = result.getOrElse(() => 0);

        expect(value, equals(0));
      });
    });

    group('getOrNull', () {
      test('should return value on success', () {
        const result = Result<int, String>.success(42);
        final value = result.getOrNull();

        expect(value, equals(42));
      });

      test('should return null on failure', () {
        const result = Result<int, String>.failure('error');
        final value = result.getOrNull();

        expect(value, isNull);
      });
    });

    group('recover', () {
      test('should not affect success', () {
        const result = Result<int, String>.success(42);
        final recovered = result.recover((error) => 0);

        expect(recovered.isSuccess, isTrue);
        expect(recovered.value, equals(42));
      });

      test('should recover from failure', () {
        const result = Result<int, String>.failure('error');
        final recovered = result.recover((error) => 0);

        expect(recovered.isSuccess, isTrue);
        expect(recovered.value, equals(0));
      });
    });

    group('onSuccess', () {
      test('should execute action on success', () {
        var executed = false;
        const result = Result<int, String>.success(42);

        final sameResult = result.onSuccess((value) {
          executed = true;
          expect(value, equals(42));
        });

        expect(executed, isTrue);
        expect(sameResult, equals(result));
      });

      test('should not execute action on failure', () {
        var executed = false;
        const result = Result<int, String>.failure('error');

        final sameResult = result.onSuccess((value) => executed = true);

        expect(executed, isFalse);
        expect(sameResult, equals(result));
      });
    });

    group('onFailure', () {
      test('should execute action on failure', () {
        var executed = false;
        const result = Result<int, String>.failure('error');

        final sameResult = result.onFailure((error) {
          executed = true;
          expect(error, equals('error'));
        });

        expect(executed, isTrue);
        expect(sameResult, equals(result));
      });

      test('should not execute action on success', () {
        var executed = false;
        const result = Result<int, String>.success(42);

        final sameResult = result.onFailure((error) => executed = true);

        expect(executed, isFalse);
        expect(sameResult, equals(result));
      });
    });
  });

  group('Integration Tests', () {
    test('should chain multiple operations', () {
      final result = safe(() => '42')
          .flatMap((str) => safe(() => int.parse(str)))
          .map((num) => num * 2)
          .map((doubled) => 'Result: $doubled');

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('Result: 84'));
    });

    test('should handle failure in chain', () {
      final result = safe(
        () => 'not-a-number',
      ).flatMap((str) => safe(() => int.parse(str))).map((num) => num * 2);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FormatException>());
    });

    test('should work with async operations', () async {
      final result = await safeAsync(() => Future.value('42')).then(
        (result) => result
            .flatMap((str) => safe(() => int.parse(str)))
            .map((num) => num * 2),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(84));
    });
  });

  group('SafeResult typedef', () {
    test('should work as expected', () {
      SafeResult<int> parseNumber(String input) => safe(() => int.parse(input));

      final success = parseNumber('42');
      final failure = parseNumber('invalid');

      expect(success.isSuccess, isTrue);
      expect(success.value, equals(42));
      expect(failure.isFailure, isTrue);
      expect(failure.error, isA<Exception>());
    });
  });
}
