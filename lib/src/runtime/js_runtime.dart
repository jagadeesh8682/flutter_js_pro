/// Abstract interface for JavaScript runtime implementations
/// 
/// This interface provides a unified API for evaluating JavaScript code
/// across all platforms (Web, Android, iOS, Windows, macOS, Linux).
abstract class JsRuntime {
  /// Evaluate JavaScript code and return the result
  /// 
  /// [code] - JavaScript code to evaluate
  /// 
  /// Returns the result of the evaluation, which can be:
  /// - Primitive types (String, num, bool, null)
  /// - Collections (List, Map)
  /// - Any other Dart-compatible type
  /// 
  /// Throws [JsEvaluationException] if the JavaScript code throws an error
  Future<dynamic> evaluate(String code);
  
  /// Dispose of the runtime and free any resources
  void dispose();
}

/// Exception thrown when JavaScript evaluation fails
class JsEvaluationException implements Exception {
  final String message;
  final String? stackTrace;
  
  JsEvaluationException(this.message, [this.stackTrace]);
  
  @override
  String toString() => 'JsEvaluationException: $message${stackTrace != null ? '\n$stackTrace' : ''}';
}

