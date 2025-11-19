import 'dart:io';

import 'package:flutter_js_plus/javascript_runtime.dart';
import 'package:flutter_js_plus/javascriptcore/jscore_runtime.dart';
import 'package:flutter_js_plus/quickjs/quickjs_runtime2.dart';

/// Get native JavaScript runtime based on platform
/// This function is only used on native platforms (not web)
JavascriptRuntime getNativeRuntime({
  required bool forceJavascriptCoreOnAndroid,
  required Map<String, dynamic> extraArgs,
}) {
  if (Platform.isAndroid && !forceJavascriptCoreOnAndroid) {
    int stackSize = extraArgs['stackSize'] ?? 1024 * 1024;
    return QuickJsRuntime2(stackSize: stackSize);
  } else if (Platform.isWindows) {
    return QuickJsRuntime2();
  } else if (Platform.isLinux) {
    return QuickJsRuntime2();
  } else {
    // iOS, macOS, or forced JavaScriptCore on Android
    return JavascriptCoreRuntime();
  }
}

