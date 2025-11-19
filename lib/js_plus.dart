/// Main entry point for flutter_js_plus package
/// 
/// This library provides a unified JavaScript runtime API that works across
/// all Flutter platforms: Web, Android, iOS, Windows, macOS, and Linux.
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:flutter_js_plus/js_plus.dart';
/// 
/// final js = JsPlus();
/// 
/// // Evaluate JavaScript code
/// final result = await js.evaluate('1 + 2');
/// print(result); // 3
/// 
/// // Don't forget to dispose
/// js.dispose();
/// ```
/// 
/// ## Platform-Specific Behavior
/// 
/// - **Web**: Uses browser's native JavaScript engine via `dart:js_interop`
/// - **Android**: Uses QuickJS (or JavaScriptCore if forced)
/// - **iOS/macOS**: Uses JavaScriptCore
/// - **Windows/Linux**: Uses QuickJS
library flutter_js_plus;

export 'src/js_plus_runtime.dart' show JsPlus, JsRuntime, JsEvaluationException;
export 'src/utils/type_conversion.dart' show JsTypeConversion;

// Also export the legacy API for backward compatibility
export 'flutter_js.dart' show
    getJavascriptRuntime,
    JavascriptRuntime,
    JsEvalResult,
    FlutterJs;

