import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_js_plus/javascript_runtime.dart';

// Import web runtime - available on web, stub on native
import 'package:flutter_js_plus/web/web_runtime.dart'
    if (dart.library.io) 'web_runtime_stub.dart';
// Import native runtime getter - only available on native platforms
import 'package:flutter_js_plus/src/runtime/get_runtime_native.dart'
    if (dart.library.html) 'package:flutter_js_plus/src/runtime/get_runtime_native_stub.dart' as native_runtime;

import './extensions/fetch.dart';
import './extensions/handle_promises.dart';

export './extensions/handle_promises.dart';
//import 'package:flutter_js_plus/quickjs-sync-server/quickjs_oasis_jsbridge.dart';
//import 'package:flutter_js_plus/quickjs/quickjs_runtime.dart';

export './quickjs/quickjs_runtime.dart' if (dart.library.html) 'web_runtime_stub.dart';
export './quickjs/quickjs_runtime2.dart' if (dart.library.html) 'web_runtime_stub.dart';
export 'javascript_runtime.dart';
export 'js_eval_result.dart';
export 'quickjs-sync-server/quickjs_oasis_jsbridge.dart' if (dart.library.html) 'web_runtime_stub.dart';
export 'web/web_runtime.dart' if (dart.library.html) 'web_runtime_stub.dart';

// Conditional imports to support web platform
// REF:
// - https://medium.com/flutter-community/conditional-imports-across-flutter-and-web-4b88885a886e
// - https://github.com/creativecreatorormaybenot/wakelock/blob/master/wakelock/lib/wakelock.dart
JavascriptRuntime getJavascriptRuntime({
  bool forceJavascriptCoreOnAndroid = false,
  bool xhr = true,
  Map<String, dynamic>? extraArgs = const {},
}) {
  JavascriptRuntime runtime;
  
  // Check if running on web - uses browser's JavaScript engine
  if (kIsWeb) {
    // WebJavascriptRuntime is only available on web (via conditional import)
    runtime = WebJavascriptRuntime();
  } else {
    // On native platforms, use the native runtime getter
    // This function uses Platform.isAndroid, etc., which are only available on native
    runtime = native_runtime.getNativeRuntime(
      forceJavascriptCoreOnAndroid: forceJavascriptCoreOnAndroid,
      extraArgs: extraArgs ?? {},
    );
  }
  
  if (xhr) runtime.enableFetch();
  runtime.enableHandlePromises();
  return runtime;
}

// JavascriptRuntime getJavascriptRuntime({bool xhr = true}) {
//   JavascriptRuntime runtime = JavascriptCoreRuntime();
//   // setFetchDebug(true);
//   if (xhr) runtime.enableFetch();
//   runtime.enableHandlePromises();
//   return runtime;
// }

final Map<int?, FlutterJs> _engineMap = {};

MethodChannel _methodChannel = const MethodChannel('io.abner.flutter_js')
  ..setMethodCallHandler((MethodCall call) {
    if (call.method == "sendMessage") {
      final engineId = call.arguments[0] as int?;
      final channel = call.arguments[1] as String?;
      final message = call.arguments[2] as String?;

      if (_engineMap[engineId] != null) {
        return _engineMap[engineId]!.onMessageReceived(
          channel,
          message,
        );
      } else {
        return Future.value('Error: no engine found with id: $engineId');
      }
    }
    return Future.error('No method "${call.method}" was found!');
  });

bool messageHandlerRegistered = false;

typedef FlutterJsChannelCallbak = Future<String> Function(
  String? args,
);

class FlutterJs {
  int? _engineId;
  static int? _httpPort;

  static int? get httpPort => _httpPort;
  static String? get httpPassword => _httpPassword;

  static var _engineCount = -1;
  static String? _httpPassword;

  bool _ready = false;

  int? get id => _engineId;

  Map<String, FlutterJsChannelCallbak> _channels = {};

  FlutterJs() {
    _engineCount += 1;
    _engineId = _engineCount;
    FlutterJs.initEngine(_engineId).then((_) => _ready = true);
    _engineMap[_engineId] = this;
  }

  dispose() {
    FlutterJs.close(_engineId);
  }

  addChannel(String name, FlutterJsChannelCallbak fn,
      {String? dartChannelAddress}) {
    _channels[name] = fn;
    _methodChannel.invokeMethod(
      "registerChannel",
      {
        "engineId": id,
        "channelName": name,
        "dartChannelAddress": dartChannelAddress
      },
    );
  }

  Future<String> onMessageReceived(String? channel, String? message) {
    if (_channels[channel!] != null) {
      return _channels[channel]!(message);
    } else {
      return Future.error('No channel "$channel" was registered!');
    }
  }

  bool isReady() => _ready;

  // ignore: non_constant_identifier_names
  static bool DEBUG = false;

  Future<String> eval(String code) {
    return evaluate(code, _engineId);
  }

  static Future<String?> get platformVersion async {
    final String? version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int?> initEngine(int? engineId) async {
    Map<dynamic, dynamic> mapResult = await (_methodChannel.invokeMethod(
        "initEngine", engineId) as Future<Map<dynamic, dynamic>>);
    _httpPort = mapResult['httpPort'] as int?;
    _httpPassword = mapResult['httpPassword'] as String?;
    return engineId;
  }

  static Future<int?> close(int? engineId) async {
    await _methodChannel.invokeMethod("close", engineId);
    return engineId;
  }

  static Future<String> evaluate(String command, int? id,
      {String convertTo = ""}) async {
    var arguments = {
      "engineId": id,
      "command": command,
      "convertTo": convertTo
    };
    final rs = await _methodChannel.invokeMethod("evaluate", arguments);
    final String? jsResult = rs is Map || rs is List ? json.encode(rs) : rs;
    if (DEBUG) {
      print("${DateTime.now().toIso8601String()} - JS RESULT : $jsResult");
    }
    return jsResult ?? "null";
  }
}
