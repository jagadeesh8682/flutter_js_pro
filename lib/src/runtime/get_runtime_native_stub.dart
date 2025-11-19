import 'package:flutter_js_plus/javascript_runtime.dart';

/// Stub for native runtime getter (only used on web)
/// This should never be called on web
JavascriptRuntime getNativeRuntime({
  required bool forceJavascriptCoreOnAndroid,
  required Map<String, dynamic> extraArgs,
}) {
  throw UnimplementedError('getNativeRuntime should not be called on web');
}

