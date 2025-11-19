import 'package:flutter/foundation.dart' show kIsWeb;

import 'runtime/js_runtime.dart';
// Conditional imports: web runtime on web, native runtime on native platforms
import 'runtime/js_runtime_web.dart' if (dart.library.io) 'runtime/js_runtime_native.dart' as runtime_impl;

// Export runtime types
export 'runtime/js_runtime.dart' show JsRuntime, JsEvaluationException;

/// Unified JavaScript runtime for Flutter
/// 
/// This class provides a single API for evaluating JavaScript code across
/// all platforms:
/// - **Web**: Uses browser's native JavaScript engine via `dart:js_interop`
/// - **Android**: Uses QuickJS (or JavaScriptCore if forced)
/// - **iOS/macOS**: Uses JavaScriptCore
/// - **Windows/Linux**: Uses QuickJS
/// 
/// Example:
/// ```dart
/// final js = JsPlus();
/// 
/// // Evaluate simple expressions
/// final result = await js.evaluate('1 + 2');
/// print(result); // 3
/// 
/// // Evaluate with variables
/// await js.evaluate('const x = 10;');
/// final sum = await js.evaluate('x + 5');
/// print(sum); // 15
/// 
/// // Handle Promises (on web)
/// final promiseResult = await js.evaluate('''
///   Promise.resolve(42)
/// ''');
/// print(promiseResult); // 42
/// 
/// // Don't forget to dispose
/// js.dispose();
/// ```
class JsPlus {
  late final JsRuntime _runtime;

  /// Create a new JavaScript runtime instance
  /// 
  /// On native platforms, you can optionally:
  /// - [forceJavascriptCoreOnAndroid]: Use JavaScriptCore instead of QuickJS on Android
  /// - [extraArgs]: Additional arguments for native runtime (e.g., stackSize)
  JsPlus({
    bool forceJavascriptCoreOnAndroid = false,
    Map<String, dynamic>? extraArgs,
  }) {
    if (kIsWeb) {
      // Use factory function from conditional import
      // On web: resolves to createWebRuntime from js_runtime_web.dart
      // On native: resolves to stub from js_runtime_native.dart (never called)
      _runtime = runtime_impl.createWebRuntime();
    } else {
      // On native platforms, import resolves to js_runtime_native.dart
      _runtime = runtime_impl.createNativeRuntime(
        forceJavascriptCoreOnAndroid: forceJavascriptCoreOnAndroid,
        extraArgs: extraArgs,
      );
    }
  }


  /// Evaluate JavaScript code
  /// 
  /// [code] - JavaScript code to evaluate
  /// 
  /// Returns the result of the evaluation. The result type depends on what
  /// the JavaScript code returns:
  /// - Numbers return as `num` (int or double)
  /// - Strings return as `String`
  /// - Booleans return as `bool`
  /// - Objects return as `Map<String, dynamic>`
  /// - Arrays return as `List<dynamic>`
  /// - Promises (on web) are automatically converted to Futures
  /// 
  /// Throws [JsEvaluationException] if the JavaScript code throws an error
  /// 
  /// Example:
  /// ```dart
  /// final result = await js.evaluate('Math.max(1, 2, 3)');
  /// print(result); // 3
  /// ```
  Future<dynamic> evaluate(String code) {
    return _runtime.evaluate(code);
  }

  /// Dispose of the runtime and free resources
  /// 
  /// Always call this when you're done with the runtime to prevent
  /// memory leaks, especially on native platforms.
  void dispose() {
    _runtime.dispose();
  }
}

