import 'dart:js_interop';
import 'dart:js_util' as js_util;

import 'js_runtime.dart';

/// Web implementation of JavaScript runtime using browser's native JavaScript engine
/// 
/// This implementation uses `dart:js_interop` and `dart:js_util` to evaluate
/// JavaScript code directly in the browser. It supports:
/// - Promise handling (automatically converts to Future)
/// - Full browser APIs (document, window, localStorage, etc.)
/// - Type conversion from JS to Dart
class JsRuntimeWeb implements JsRuntime {
  JsRuntimeWeb() {
    // Initialize if needed
  }

  @override
  Future<dynamic> evaluate(String code) async {
    try {
      // Use window.eval through JS interop
      // Wrap code in an IIFE to avoid variable pollution
      final wrappedCode = '(() => { return ($code); })()';
      final result = _jsEval(wrappedCode.toJS);
      
      // Check if result is a Promise
      if (result != null) {
        final PromiseConstructor = js_util.getProperty<JSFunction>(
          js_util.globalThis,
          'Promise',
        );
        
        if (js_util.instanceof(result, PromiseConstructor)) {
          // Convert Promise to Future
          final promiseResult = await js_util.promiseToFuture<JSAny?>(result);
          return _jsToDart(promiseResult);
        }
      }
      
      // Convert JS value to Dart value
      return _jsToDart(result);
    } catch (e, stackTrace) {
      // Try to extract error message from JS exception
      String errorMessage = e.toString();
      String? jsStackTrace;
      
      if (e is JSObject) {
        try {
          final message = js_util.getProperty<JSString?>(e, 'message');
          if (message != null) {
            errorMessage = message.toDart;
          }
          
          final stack = js_util.getProperty<JSString?>(e, 'stack');
          if (stack != null) {
            jsStackTrace = stack.toDart;
          }
        } catch (_) {
          // Fallback to toString
        }
      }
      
      throw JsEvaluationException(
        errorMessage,
        jsStackTrace ?? stackTrace.toString(),
      );
    }
  }

  /// Evaluate JavaScript code using window.eval
  @JS('eval')
  external JSAny? _jsEval(JSString code);

  /// Convert JavaScript value to Dart value
  dynamic _jsToDart(JSAny? value) {
    if (value == null) {
      return null;
    }
    
    // Use dartify from js_util to convert JS values to Dart
    return js_util.dartify(value);
  }

  @override
  void dispose() {
    // No cleanup needed for web runtime
    // Browser handles garbage collection
  }
}

/// Factory function for creating web runtime
JsRuntime createWebRuntime() {
  return JsRuntimeWeb();
}

/// Factory function for creating native runtime (stub on web)
/// This is never actually called on web, but needed for type compatibility
JsRuntime createNativeRuntime({
  required bool forceJavascriptCoreOnAndroid,
  required Map<String, dynamic>? extraArgs,
}) {
  throw UnimplementedError('Native runtime not available on web');
}

