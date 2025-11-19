import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_js_plus/js_plus.dart';

/// Example demonstrating the new JsPlus API
class JsPlusExample extends StatefulWidget {
  const JsPlusExample({super.key});

  @override
  State<JsPlusExample> createState() => _JsPlusExampleState();
}

class _JsPlusExampleState extends State<JsPlusExample> {
  late final JsPlus js;
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    js = JsPlus();
  }

  @override
  void dispose() {
    js.dispose();
    super.dispose();
  }

  Future<void> _evaluate(String code, String description) async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final result = await js.evaluate(code);
      setState(() {
        _result = 'Result: $result\nType: ${result.runtimeType}';
        _isLoading = false;
      });
    } on JsEvaluationException catch (e) {
      setState(() {
        _result = 'Error: ${e.message}\n${e.stackTrace ?? ''}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JsPlus Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Result:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _result.isEmpty ? 'No evaluation yet' : _result,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Example buttons
            const Text(
              'Examples:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildExampleButton(
              'Simple Arithmetic',
              '1 + 2 + 3',
              '1 + 2 + 3',
            ),
            _buildExampleButton(
              'String Operations',
              '"Hello" + " " + "World"',
              '"Hello" + " " + "World"',
            ),
            _buildExampleButton(
              'Math Functions',
              'Math.max(1, 2, 3, 4, 5)',
              'Math.max(1, 2, 3, 4, 5)',
            ),
            _buildExampleButton(
              'JavaScript Object',
              '{a: 1, b: 2, c: 3}',
              '{a: 1, b: 2, c: 3}',
            ),
            _buildExampleButton(
              'JavaScript Array',
              '[1, 2, 3, 4, 5]',
              '[1, 2, 3, 4, 5]',
            ),
            _buildExampleButton(
              'Complex Function',
              'Factorial of 5',
              '''
(function() {
  function factorial(n) {
    return n <= 1 ? 1 : n * factorial(n - 1);
  }
  return factorial(5);
})()
''',
            ),
            _buildExampleButton(
              'Variables',
              'Set x=10, then x*2',
              '''
(() => {
  const x = 10;
  return x * 2;
})()
''',
            ),
            _buildExampleButton(
              'JSON Parse',
              'Parse JSON string',
              'JSON.parse(\'{"name": "Flutter", "version": 3.0}\')',
            ),

            // Promise example (works on web)
            if (kIsWeb)
              _buildExampleButton(
                'Promise (Web)',
                'Promise.resolve(42)',
                'Promise.resolve(42)',
              ),

            const SizedBox(height: 24),

            // Custom code input
            const Text(
              'Custom Code:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter JavaScript code...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (code) {
                if (code.isNotEmpty) {
                  _evaluate(code, 'Custom');
                }
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // This would need a TextEditingController in a real app
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter code in the field above and press Enter'),
                  ),
                );
              },
              child: const Text('Evaluate Custom Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(String title, String description, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => _evaluate(code, title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

