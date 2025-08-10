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
        safeStream.listen(results.add);

        controller
          ..add('hello')
          ..add('world')
          ..addError(Exception('test error'))
          ..add('after error');
        unawaited(controller.close());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(results, hasLength(4));
        expect(results[0].isSuccess, isTrue);
        expect(results[0].getOrNull(), equals('hello'));
        expect(results[1].isSuccess, isTrue);
        expect(results[1].getOrNull(), equals('world'));
        expect(results[2].isFailure, isTrue);
        expect(
          results[2].when(
            success: (_) => throw StateError('Expected failure'),
            failure: (e) => e.toString(),
          ),
          contains('test error'),
        );
        expect(results[3].isSuccess, isTrue);
        expect(results[3].getOrNull(), equals('after error'));
      },
    );

    test('safeMap transforms values safely', () async {
      final stream = Stream.fromIterable(['1', '2', 'invalid', '4']);
      final results = <Result<int, Exception>>[];

      await stream.safeMap<int, Exception>(int.parse).forEach(results.add);

      expect(results, hasLength(4));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals(2));
      expect(results[2].isFailure, isTrue);
      expect(results[3].isSuccess, isTrue);
      expect(results[3].getOrNull(), equals(4));
    });

    test('safeAsyncMap transforms values asynchronously', () async {
      final stream = Stream.fromIterable([1, 2, 3]);
      final results = <Result<String, Exception>>[];

      await stream
          .safeAsyncMap<String, Exception>((n) async => 'Number: $n')
          .forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals('Number: 1'));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals('Number: 2'));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].getOrNull(), equals('Number: 3'));
    });

    test('safeExpand expands values safely', () async {
      final stream = Stream.fromIterable(['1,2', '3,4', 'invalid']);
      final results = <Result<int, Exception>>[];

      await stream
          .safeExpand<int, Exception>((s) => s.split(',').map(int.parse))
          .forEach(results.add);

      expect(results, hasLength(5)); // 2 + 2 + 1 error
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals(2));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].getOrNull(), equals(3));
      expect(results[3].isSuccess, isTrue);
      expect(results[3].getOrNull(), equals(4));
      expect(results[4].isFailure, isTrue);
    });

    test('safeWhere filters values safely', () async {
      final stream = Stream.fromIterable([1, 2, 3, 4, 5]);
      final results = <Result<int, Exception>>[];

      await stream.safeWhere<Exception>((n) => n.isEven).forEach(results.add);

      expect(results, hasLength(2)); // Only even numbers
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(2));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals(4));
    });

    test('errorMapper transforms errors', () async {
      final stream = Stream.fromIterable(['1', 'invalid', '3']);
      final results = <Result<int, String>>[];

      await stream
          .safeMap<int, String>(
            int.parse,
            errorMapper: (error) => 'Parse error: $error',
          )
          .forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isFailure, isTrue);
      expect(
        results[1].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        startsWith('Parse error:'),
      );
      expect(results[2].isSuccess, isTrue);
      expect(results[2].getOrNull(), equals(3));
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
      await resultStream.successes().forEach(successes.add);

      expect(successes, equals([1, 3]));
    });

    test('failures filters only failed results', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error1'),
        const Result<int, String>.failure('error2'),
      ]);

      final failures = <String>[];
      await resultStream.failures().forEach(failures.add);

      expect(failures, equals(['error1', 'error2']));
    });

    test('mapSuccesses transforms only successful values', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final results = <Result<int, String>>[];
      await resultStream.mapSuccesses((x) => x * 2).forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(2));
      expect(results[1].isFailure, isTrue);
      expect(
        results[1].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        equals('error'),
      );
      expect(results[2].isSuccess, isTrue);
      expect(results[2].getOrNull(), equals(6));
    });

    test('safeMapSuccesses handles transformation errors', () async {
      final resultStream = Stream.fromIterable([
        const Result<String, String>.success('1'),
        const Result<String, String>.success('invalid'),
        const Result<String, String>.failure('original error'),
      ]);

      final results = <Result<int, String>>[];
      await resultStream
          .safeMapSuccesses<int>(
            int.parse,
            errorMapper: (error) => 'Parse error: $error',
          )
          .forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isFailure, isTrue);
      expect(
        results[1].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        startsWith('Parse error:'),
      );
      expect(
        results[2].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        equals('original error'),
      );
    });

    test('flatMapSuccesses chains operations', () async {
      final resultStream = Stream.fromIterable([
        const Result<String, String>.success('1'),
        const Result<String, String>.success('invalid'),
        const Result<String, String>.failure('original error'),
      ]);

      final results = <Result<int, String>>[];
      await resultStream
          .flatMapSuccesses(
            (s) => safe(() => int.parse(s)).mapError((e) => e.toString()),
          )
          .forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isFailure, isTrue);
      expect(results[2].isFailure, isTrue);
      expect(
        results[2].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        equals('original error'),
      );
    });

    test('onSuccesses executes side effects on successes', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('error'),
        const Result<int, String>.success(3),
      ]);

      final sideEffects = <int>[];
      final results = <Result<int, String>>[];

      await resultStream.onSuccesses(sideEffects.add).forEach(results.add);

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

      await resultStream.onFailures(sideEffects.add).forEach(results.add);

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
      await resultStream.recover((error) => -1).forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals(-1));
      expect(results[2].isSuccess, isTrue);
      expect(results[2].getOrNull(), equals(3));
    });

    test('recoverWith provides fallback Results for failures', () async {
      final resultStream = Stream.fromIterable([
        const Result<int, String>.success(1),
        const Result<int, String>.failure('recoverable'),
        const Result<int, String>.failure('unrecoverable'),
      ]);

      final results = <Result<int, String>>[];
      await resultStream
          .recoverWith(
            (error) => error == 'recoverable'
                ? const Result.success(0)
                : Result.failure(error),
          )
          .forEach(results.add);

      expect(results, hasLength(3));
      expect(results[0].isSuccess, isTrue);
      expect(results[0].getOrNull(), equals(1));
      expect(results[1].isSuccess, isTrue);
      expect(results[1].getOrNull(), equals(0));
      expect(results[2].isFailure, isTrue);
      expect(
        results[2].when(
          success: (_) => throw StateError('Expected failure'),
          failure: (e) => e,
        ),
        equals('unrecoverable'),
      );
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
        expect(successResult.getOrNull(), equals([1, 2, 3]));

        // With failure
        final failureStream = Stream.fromIterable([
          const Result<int, String>.success(1),
          const Result<int, String>.failure('error'),
          const Result<int, String>.success(3),
        ]);

        final failureResult = await failureStream.collectResults();
        expect(failureResult.isFailure, isTrue);
        expect(
          failureResult.when(
            success: (_) => throw StateError('Expected failure'),
            failure: (e) => e,
          ),
          equals('error'),
        );
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
                    (result.isFailure &&
                        result
                            .when(
                              success: (_) =>
                                  throw StateError('Expected failure'),
                              failure: (e) => e.toString(),
                            )
                            .contains('invalid')),
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

      await inputStream
          .safeAsyncMap<String, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            if (n == 3) throw Exception('Async error');
            return 'Value: $n';
          })
          .recover((error) => 'Recovered from error')
          .successes()
          .forEach(results.add);

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
