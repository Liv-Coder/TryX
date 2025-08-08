import 'dart:async';
import 'package:test/test.dart';
import 'package:tryx/tryx.dart';

void main() {
  group('StreamSafeExtensions', () {
    test(
      'safeStream converts values to Success and errors to Failure',
      () async {
        final controller = StreamController<String>();
        final safeStream = controller.stream.safeStream<String, Exception>();

        final results = <Result<String, Exception>>[];
        final subscription = safeStream.listen(results.add);

        controller.add('hello');
        controller.add('world');
        controller.addError(Exception('test error'));
        controller.add('after error');
        await controller.close();

        await subscription.cancel();

        expect(results, hasLength(4));
        expect(results[0].isSuccess, isTrue);
        expect(results[0].value, equals('hello'));
        expect(results[1].isSuccess, isTrue);
        expect(results[1].value, equals('world'));
        expect(results[2].isFailure, isTrue);
        expect(results[2].error.toString(), contains('test error'));
        expect(results[3].isSuccess, isTrue);
        expect(results[3].value, equals('after error'));
      },
    );

    test('safeMap transforms values safely', () async {
      final stream = Stream.fromIterable(['1', '2', 'invalid', '4']);
      final results = <Result<int, Exception>>[];

      await for (final result in stream.safeMap<int, Exception>(int.parse)) {
        results.add(result);
      }

      expect(results, hasLength(4));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals(2));
      expect(results[2].isFailure, isTrue);
      expect(results[3].isSuccess, isTrue);
      expect(results[3].value, equals(4));
    });

    test('safeAsyncMap transforms values asynchronously', () async {
      final stream = Stream.fromIterable([1, 2, 3]);
      final results = <Result<String, Exception>>[];

      await for (final result in stream.safeAsyncMap<String, Exception>(
        (n) async => 'Number: $n',
      )) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals('Number: 1'));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals('Number: 2'));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].value, equals('Number: 3'));
    });

    test('safeExpand expands values safely', () async {
      final stream = Stream.fromIterable(['1,2', '3,4', 'invalid']);
      final results = <Result<int, Exception>>[];

      await for (final result in stream.safeExpand<int, Exception>(
        (s) => s.split(',').map(int.parse),
      )) {
        results.add(result);
      }

      expect(results, hasLength(5)); // 2 + 2 + 1 error
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals(2));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].value, equals(3));
      expect(results[3].isSuccess, isTrue);
      expect(results[3].value, equals(4));
      expect(results[4].isFailure, isTrue);
    });

    test('safeWhere filters values safely', () async {
      final stream = Stream.fromIterable([1, 2, 3, 4, 5]);
      final results = <Result<int, Exception>>[];

      await for (final result in stream.safeWhere<Exception>((n) => n.isEven)) {
        results.add(result);
      }

      expect(results, hasLength(2)); // Only even numbers
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(2));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals(4));
    });

    test('errorMapper transforms errors', () async {
      final stream = Stream.fromIterable(['1', 'invalid', '3']);
      final results = <Result<int, String>>[];

      await for (final result in stream.safeMap<int, String>(
        int.parse,
        errorMapper: (error) => 'Parse error: $error',
      )) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isFailure, isTrue);
      expect(results[1].error, startsWith('Parse error:'));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].value, equals(3));
    });
  });

  group('StreamResultExtensions', () {
    test('successes filters only successful results', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final successes = <int>[];
      await for (final value in resultStream.successes()) {
        successes.add(value);
      }

      expect(successes, equals([1, 3]));
    });

    test('failures filters only failed results', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error1'),
        const Result<int, String>.failure('error2'),
      ]);

      final failures = <String>[];
      await for (final error in resultStream.failures()) {
        failures.add(error);
      }

      expect(failures, equals(['error1', 'error2']));
    });

    test('mapSuccesses transforms only successful values', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final results = <Result<int, String>>[];
      await for (final result in resultStream.mapSuccesses((x) => x * 2)) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(2));
      expect(results[1].isFailure, isTrue);
      expect(results[1].error, equals('error'));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].value, equals(6));
    });

    test('safeMapSuccesses handles transformation errors', () async {
      final resultStream = Stream.fromIterable([
        const Result<String, String>.success('1'),
        const Result<String, String>.success('invalid'),
        const Result<String, String>.failure('original error'),
      ]);

      final results = <Result<int, String>>[];
      await for (final result in resultStream.safeMapSuccesses<int>(
        int.parse,
        errorMapper: (error) => 'Parse error: $error',
      )) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isFailure, isTrue);
      expect(results[1].error, startsWith('Parse error:'));
      expect(results[2].isFailure, isTrue);
      expect(results[2].error, equals('original error'));
    });

    test('flatMapSuccesses chains operations', () async {
      final resultStream = Stream.fromIterable([
        const Result<String, String>.success('1'),
        const Result<String, String>.success('invalid'),
        const Result<String, String>.failure('original error'),
      ]);

      final results = <Result<int, String>>[];
      await for (final result in resultStream.flatMapSuccesses(
        (s) => safe(() => int.parse(s)).mapError((e) => e.toString()),
      )) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isFailure, isTrue);
      expect(results[2].isFailure, isTrue);
      expect(results[2].error, equals('original error'));
    });

    test('onSuccesses executes side effects on successes', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final sideEffects = <int>[];
      final results = <Result<int, String>>[];

      await for (final result in resultStream.onSuccesses(sideEffects.add)) {
        results.add(result);
      }

      expect(sideEffects, equals([1, 3]));
      expect(results, hasLength(3));
    });

    test('onFailures executes side effects on failures', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error1'),
        const Result<int, String>.failure('error2'),
      ]);

      final sideEffects = <String>[];
      final results = <Result<int, String>>[];

      await for (final result in resultStream.onFailures(sideEffects.add)) {
        results.add(result);
      }

      expect(sideEffects, equals(['error1', 'error2']));
      expect(results, hasLength(3));
    });

    test('recover provides fallback values for failures', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final results = <Result<int, String>>[];
      await for (final result in resultStream.recover((error) => -1)) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals(-1));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].value, equals(3));
    });

    test('recoverWith provides fallback Results for failures', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('recoverable'),
        const Result<int, String>.failure('unrecoverable'),
      ]);

      final results = <Result<int, String>>[];
      await for (final result in resultStream.recoverWith(
        (error) => error == 'recoverable'
            ? const Result.success(0)
            : Result.failure(error),
      )) {
        results.add(result);
      }

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].value, equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].value, equals(0));
      expect(results[2].isFailure, isTrue);
      expect(results[2].error, equals('unrecoverable'));
    });

    test(
      'collectResults collects all successes or returns first failure',
      () async {
        // All successes
        final successStream = Stream.fromIterable([
          const Result<int, String>.success(1),
          const Result<int, String>.success(2),
          const Result<int, String>.success(3),
        ]);

        final successResult = await successStream.collectResults();
        expect(successResult.isSuccess, isTrue);
        expect(successResult.value, equals([1, 2, 3]));

        // With failure
        final failureStream = Stream.fromIterable([
          const Result<int, String>.success(1),
          const Result<int, String>.failure('error'),
          const Result<int, String>.success(3),
        ]);

        final failureResult = await failureStream.collectResults();
        expect(failureResult.isFailure, isTrue);
        expect(failureResult.error, equals('error'));
      },
    );

    test('partition separates successes and failures', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error1'),
        const Result<int, String>.success(3),
        const Result<int, String>.failure('error2'),
      ]);

      final partition = await resultStream.partition();
      final successes = partition.successes;
      final failures = partition.failures;

      expect(successes, equals([1, 3]));
      expect(failures, equals(['error1', 'error2']));
    });
  });

  group('Integration Tests', () {
    test('complex stream processing pipeline', () async {
      final inputStream = Stream.fromIterable([
        '1',
        '2',
        'invalid',
        '4',
        '5',
        'bad',
        '6',
      ]);

      final results = <int>[];
      final errors = <String>[];

      await for (final _
          in inputStream
              .safeMap<int, String>(
                int.parse,
                errorMapper: (error) => 'Parse error: $error',
              )
              .where(
                (result) =>
                    result.isSuccess ||
                    (result.isFailure && result.error!.contains('invalid')),
              )
              .mapSuccesses((n) => n * 2)
              .onSuccesses(results.add)
              .onFailures(errors.add)) {
        // Results are collected via side effects
      }

      expect(results, equals([2, 4, 8, 10, 12])); // 1,2,4,5,6 * 2
      expect(errors, hasLength(1));
      expect(errors[0], contains('invalid'));
    });

    test('async stream processing with error recovery', () async {
      final inputStream = Stream.fromIterable([1, 2, 3, 4, 5]);

      final results = <String>[];

      await for (final result
          in inputStream
              .safeAsyncMap<String, String>((n) async {
                await Future.delayed(const Duration(milliseconds: 10));
                if (n == 3) throw Exception('Async error');
                return 'Value: $n';
              })
              .recover((error) => 'Recovered from error')
              .successes()) {
        results.add(result);
      }

      expect(
        results,
        equals([
          'Value: 1',
          'Value: 2',
          'Recovered from error',
          'Value: 4',
          'Value: 5',
        ]),
      );
    });
  });
}
