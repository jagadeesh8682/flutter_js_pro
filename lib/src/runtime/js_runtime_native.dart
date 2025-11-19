import 'dart:convert' as convert;

// Conditional import: only import native runtime on non-web platforms
import 'package:flutter_js_plus/flutter_js.dart' if (dart.library.html) 'package:flutter_js_plus/src/runtime/js_runtime_native_stub.dart';
import 'package:flutter_js_plus/javascript_runtime.dart' if (dart.library.html) 'package:flutter_js_plus/src/runtime/js_runtime_native_stub.dart';
import 'package:flutter_js_plus/js_eval_result.dart' if (dart.library.html) 'package:flutter_js_plus/src/runtime/js_runtime_native_stub.dart';

import 'js_runtime.dart';

/// Native implementation of JavaScript runtime
/// 
/// This implementation wraps the existing native JavaScript engines:
/// - QuickJS on Android, Windows, Linux
/// - JavaScriptCore on iOS, macOS
class JsRuntimeNative implements JsRuntime {
  late final JavascriptRuntime _runtime;
  final bool _forceJavascriptCoreOnAndroid;
  final Map<String, dynamic>? _extraArgs;

  JsRuntimeNative({
    bool forceJavascriptCoreOnAndroid = false,
    Map<String, dynamic>? extraArgs,
  })  : _forceJavascriptCoreOnAndroid = forceJavascriptCoreOnAndroid,
        _extraArgs = extraArgs {
    _initializeRuntime();
  }

  void _initializeRuntime() {
    // Use the existing getJavascriptRuntime function
    _runtime = getJavascriptRuntime(
      forceJavascriptCoreOnAndroid: _forceJavascriptCoreOnAndroid,
      extraArgs: _extraArgs ?? {},
    );
  }

  @override
  Future<dynamic> evaluate(String code) async {
    try {
      final result = _runtime.evaluate(code);
      
      // Check if result is an error
      if (result.isError) {
        throw JsEvaluationException(
          result.stringResult,
        );
      }
      
      // Check if result is a Promise (for native runtimes that support it)
      if (result.isPromise) {
        // Use evaluateAsync for promises
        final asyncResult = await _runtime.evaluateAsync(code);
        if (asyncResult.isError) {
          throw JsEvaluationException(
            asyncResult.stringResult,
          );
        }
        return _convertResult(asyncResult);
      }
      
      return _convertResult(result);
    } catch (e) {
      if (e is JsEvaluationException) {
        rethrow;
      }
      throw JsEvaluationException(
        'Native runtime error: ${e.toString()}',
      );
    }
  }

  /// Convert JsEvalResult to Dart value
  dynamic _convertResult(JsEvalResult result) {
    // Try to convert using the runtime's convertValue method
    try {
      // First try runtime's convertValue (works for JavaScriptCore)
      try {
        final converted = _runtime.convertValue<dynamic>(result);
        if (converted != null && converted != true) { // QuickJS returns true as default
          return converted;
        }
      } catch (_) {
        // convertValue not available or failed, continue
      }
      
      // Try to parse as JSON if it's a string
      if (result.stringResult.isNotEmpty) {
        final trimmed = result.stringResult.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          try {
            return convert.jsonDecode(trimmed);
          } catch (_) {
            // Not valid JSON, continue
          }
        }
        
        // Try to parse as number
        if (trimmed == 'null') {
          return null;
        }
        if (trimmed == 'true') {
          return true;
        }
        if (trimmed == 'false') {
          return false;
        }
        
        // Try parsing as number
        final numValue = num.tryParse(trimmed);
        if (numValue != null) {
          return numValue;
        }
      }
      
      // Fallback to raw result or string result
      return result.rawResult ?? result.stringResult;
    } catch (e) {
      // If conversion fails, return string result
      return result.stringResult;
    }
  }

  @override
  void dispose() {
    _runtime.dispose();
  }
}

/// Factory function for creating web runtime (stub on native)
/// This is never actually called on native, but needed for type compatibility
JsRuntime createWebRuntime() {
  throw UnimplementedError('Web runtime not available on native');
}

/// Factory function for creating native runtime
JsRuntime createNativeRuntime({
  required bool forceJavascriptCoreOnAndroid,
  required Map<String, dynamic>? extraArgs,
}) {
  return JsRuntimeNative(
    forceJavascriptCoreOnAndroid: forceJavascriptCoreOnAndroid,
    extraArgs: extraArgs,
  );
}

