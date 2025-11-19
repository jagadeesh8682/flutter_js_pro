import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../javascript_runtime.dart';
import '../js_eval_result.dart';

/// Web-compatible JavaScript runtime using the browser's JavaScript engine
/// 
/// This runtime allows full access to browser APIs including:
/// - DOM manipulation (document, window, etc.)
/// - HTML element creation and modification
/// - All standard browser JavaScript APIs
/// 
/// Example:
/// ```dart
/// final runtime = getJavascriptRuntime();
/// runtime.evaluate('''
///   const div = document.createElement('div');
///   div.innerHTML = 'Hello from JavaScript!';
///   document.body.appendChild(div);
/// ''');
/// ```
class WebJavascriptRuntime extends JavascriptRuntime {
  static int _instanceCounter = 0;
  final String _instanceId;
  
  // Store callbacks for setTimeout
  final Map<String, Timer> _timers = {};

  WebJavascriptRuntime() : _instanceId = 'web_${_instanceCounter++}' {
    init();
  }

  @override
  void initChannelFunctions() {
    JavascriptRuntime.channelFunctionsRegistered[_instanceId] = {};
    
    // Setup sendMessage function in global scope
    _evaluateJS('''
      (function() {
        window.__flutter_js_sendMessage = function(channelName, message) {
          if (window.__flutter_js_channels && window.__flutter_js_channels[channelName]) {
            try {
              const result = window.__flutter_js_channels[channelName](JSON.parse(message));
              return result !== undefined ? JSON.stringify(result) : null;
            } catch (e) {
              console.error('Error in channel ' + channelName + ':', e);
              return null;
            }
          } else {
            console.warn('No channel registered: ' + channelName);
            return null;
          }
        };
      })();
    ''');
  }

  @override
  JsEvalResult evaluate(String code, {String? sourceUrl}) {
    try {
      // Use eval in a try-catch to handle errors
      final result = _evaluateJS(code);
      return JsEvalResult(
        result?.toString() ?? 'undefined',
        result,
        isError: false,
      );
    } catch (e) {
      return JsEvalResult(
        e.toString(),
        e,
        isError: true,
      );
    }
  }

  @override
  Future<JsEvalResult> evaluateAsync(String code, {String? sourceUrl}) async {
    // For web, we can use async evaluation
    return Future.microtask(() => evaluate(code, sourceUrl: sourceUrl));
  }

  @override
  int executePendingJob() {
    // On web, JavaScript runs in the browser's event loop
    // No need to manually execute pending jobs
    return 0;
  }

  @override
  String getEngineInstanceId() {
    return _instanceId;
  }

  @override
  void dispose() {
    // Cancel all timers
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // Clean up channels
    _evaluateJS('''
      if (window.__flutter_js_channels) {
        delete window.__flutter_js_channels;
      }
      if (window.__flutter_js_sendMessage) {
        delete window.__flutter_js_sendMessage;
      }
    ''');
  }

  @override
  bool setupBridge(String channelName, void Function(dynamic args) fn) {
    final channelFunctions = JavascriptRuntime.channelFunctionsRegistered[_instanceId]!;
    
    if (channelFunctions.containsKey(channelName)) {
      return false;
    }

    channelFunctions[channelName] = fn;

    // Register channel in JavaScript
    _evaluateJS('''
      (function() {
        if (!window.__flutter_js_channels) {
          window.__flutter_js_channels = {};
        }
        window.__flutter_js_channels['$channelName'] = function(args) {
          // This will be called from sendMessage
          return window.__flutter_js_sendMessage('$channelName', JSON.stringify(args));
        };
      })();
    ''');

    return true;
  }

  @override
  void setInspectable(bool inspectable) {
    // On web, the browser devtools are always available
    // Nothing to do here
  }

  @override
  String jsonStringify(JsEvalResult jsValue) {
    try {
      return jsonEncode(jsValue.rawResult);
    } catch (e) {
      return jsValue.stringResult;
    }
  }

  // Helper method to evaluate JavaScript code
  dynamic _evaluateJS(String code) {
    // Use JS interop to evaluate code
    return _evalJS(code);
  }

  // Setup console log for web
  @override
  void _setupConsoleLog() {
    // On web, console is already available, but we can override it to send messages
    evaluate('''
      (function() {
        const originalLog = console.log;
        const originalWarn = console.warn;
        const originalError = console.error;
        
        console.log = function() {
          originalLog.apply(console, arguments);
          if (window.__flutter_js_sendMessage) {
            window.__flutter_js_sendMessage('ConsoleLog', JSON.stringify(['log', ...Array.from(arguments)]));
          }
        };
        
        console.warn = function() {
          originalWarn.apply(console, arguments);
          if (window.__flutter_js_sendMessage) {
            window.__flutter_js_sendMessage('ConsoleLog', JSON.stringify(['warn', ...Array.from(arguments)]));
          }
        };
        
        console.error = function() {
          originalError.apply(console, arguments);
          if (window.__flutter_js_sendMessage) {
            window.__flutter_js_sendMessage('ConsoleLog', JSON.stringify(['error', ...Array.from(arguments)]));
          }
        };
      })();
    ''');
    
    onMessage('ConsoleLog', (dynamic args) {
      if (args is List && args.isNotEmpty) {
        final level = args[0] as String;
        args.removeAt(0);
        final output = args.join(' ');
        print('[$level] $output');
      }
    });
  }

  // Setup setTimeout for web
  @override
  void _setupSetTimeout() {
    evaluate('''
      (function() {
        if (window.__flutter_js_setTimeoutCount === undefined) {
          window.__flutter_js_setTimeoutCount = -1;
          window.__flutter_js_setTimeoutCallbacks = {};
        }
        
        const originalSetTimeout = window.setTimeout;
        window.setTimeout = function(fnTimeout, timeout) {
          window.__flutter_js_setTimeoutCount += 1;
          const timeoutIndex = '' + window.__flutter_js_setTimeoutCount;
          window.__flutter_js_setTimeoutCallbacks[timeoutIndex] = fnTimeout;
          
          if (window.__flutter_js_sendMessage) {
            window.__flutter_js_sendMessage('SetTimeout', JSON.stringify({
              timeoutIndex: timeoutIndex,
              timeout: timeout || 0
            }));
          }
          
          return timeoutIndex;
        };
      })();
    ''');
    
    onMessage('SetTimeout', (dynamic args) {
      try {
        final duration = args['timeout'] as int? ?? 0;
        final idx = args['timeoutIndex'] as String?;
        
        if (idx != null) {
          final timer = Timer(Duration(milliseconds: duration), () {
            evaluate('''
              if (window.__flutter_js_setTimeoutCallbacks && window.__flutter_js_setTimeoutCallbacks['$idx']) {
                window.__flutter_js_setTimeoutCallbacks['$idx'].call();
                delete window.__flutter_js_setTimeoutCallbacks['$idx'];
              }
            ''');
            _timers.remove(idx);
          });
          _timers[idx] = timer;
        }
      } catch (e) {
        print('Exception in setTimeout: $e');
      }
    });
  }

  // Placeholder methods that are not needed on web
  @override
  JsEvalResult callFunction(dynamic fn, dynamic obj) {
    // Not applicable for web runtime
    throw UnimplementedError('callFunction is not supported on web');
  }

  @override
  T? convertValue<T>(JsEvalResult jsValue) {
    return jsValue.rawResult as T?;
  }
}

// Helper function to evaluate JavaScript using JS interop
dynamic _evalJS(String code) {
  try {
    // Use window.eval through JS interop
    final result = _jsEval(code.toJS);
    // Convert JSAny back to Dart type
    if (result == null) return null;
    if (result.isA<JSString>()) {
      return (result as JSString).toDart;
    } else if (result.isA<JSNumber>()) {
      return (result as JSNumber).toDartDouble;
    } else if (result.isA<JSBoolean>()) {
      return (result as JSBoolean).toDart;
    } else if (result.isA<JSObject>()) {
      // Try to convert to JSON string
      try {
        final jsonStr = _jsonStringify(result as JSObject);
        return jsonDecode(jsonStr);
      } catch (e) {
        return result;
      }
    }
    return result;
  } catch (e) {
    rethrow;
  }
}

// JS interop: access to eval function
@JS('eval')
external JSAny? _jsEval(JSString code);

// JS interop: access to JSON.stringify
@JS('JSON.stringify')
external String _jsonStringify(JSObject obj);

