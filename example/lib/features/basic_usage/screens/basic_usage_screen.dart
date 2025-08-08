import 'package:flutter/material.dart';
import 'package:tryx/tryx.dart';

/// Basic usage demonstration screen
class BasicUsageScreen extends StatefulWidget {
  const BasicUsageScreen({super.key});

  @override
  State<BasicUsageScreen> createState() => _BasicUsageScreenState();
}

class _BasicUsageScreenState extends State<BasicUsageScreen> {
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Usage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Tryx Usage Examples',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Example 1: Simple parsing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example 1: Safe Parsing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _demonstrateParsing,
                      child: const Text('Try Safe Parsing'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Example 2: Async operations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example 2: Async Operations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _demonstrateAsync,
                      child: const Text('Try Async Operation'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (_result.isNotEmpty) ...[
              Text(
                'Result:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  void _demonstrateParsing() {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    // Simulate some processing time
    Future.delayed(const Duration(milliseconds: 500), () {
      final result1 = safe(() => int.parse('42'));
      final result2 = safe(() => int.parse('not-a-number'));

      final output = StringBuffer();
      output.writeln('// Parsing valid number');
      output.writeln('safe(() => int.parse("42"))');

      result1.when(
        success: (value) => output.writeln('✅ Success: $value'),
        failure: (error) => output.writeln('❌ Error: $error'),
      );

      output.writeln('\n// Parsing invalid number');
      output.writeln('safe(() => int.parse("not-a-number"))');

      result2.when(
        success: (value) => output.writeln('✅ Success: $value'),
        failure: (error) => output.writeln('❌ Error: ${error.runtimeType}'),
      );

      setState(() {
        _result = output.toString();
        _isLoading = false;
      });
    });
  }

  void _demonstrateAsync() {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    _performAsyncOperation().then((result) {
      final output = StringBuffer();
      output.writeln('// Async operation with method chaining');
      output.writeln('safeAsync(() => simulateNetworkCall())');
      output.writeln('  .map((data) => data.toUpperCase())');
      output.writeln('  .recover((error) => "fallback-value")');

      result.when(
        success: (value) => output.writeln('✅ Final result: $value'),
        failure: (error) => output.writeln('❌ Error: $error'),
      );

      setState(() {
        _result = output.toString();
        _isLoading = false;
      });
    });
  }

  Future<SafeResult<String>> _performAsyncOperation() async {
    return safeAsync(() => _simulateNetworkCall()).then((result) => result
        .map((data) => data.toUpperCase())
        .recover((error) => 'fallback-value'));
  }

  Future<String> _simulateNetworkCall() async {
    await Future.delayed(const Duration(seconds: 1));
    // Randomly succeed or fail for demonstration
    if (DateTime.now().millisecond % 2 == 0) {
      return 'network-data-success';
    } else {
      throw Exception('Network error');
    }
  }
}
