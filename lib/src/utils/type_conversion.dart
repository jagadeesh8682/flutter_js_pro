import 'dart:js_interop';
import 'dart:js_util' as js_util;

/// Type conversion utilities for JavaScript and Dart interop
/// 
/// These utilities help convert between JavaScript types (JSArray, JSObject)
/// and Dart types (List, Map) when working with JavaScript evaluation results.
class JsTypeConversion {
  /// Convert a JavaScript array to a Dart List
  /// 
  /// This is primarily useful on web when you need to convert JSArray to List.
  /// On native platforms, the runtime already handles this conversion.
  /// 
  /// Example:
  /// ```dart
  /// final jsArray = await js.evaluate('[1, 2, 3]');
  /// final list = JsTypeConversion.jsArrayToList(jsArray);
  /// ```
  static List<dynamic>? jsArrayToList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;
    
    // On web, use dartify to convert JSArray to List
    if (value is JSArray) {
      return js_util.dartify(value) as List<dynamic>?;
    }
    
    // If it's already a list, return it
    if (value is List) {
      return value;
    }
    
    return null;
  }

  /// Convert a JavaScript object to a Dart Map
  /// 
  /// This is primarily useful on web when you need to convert JSObject to Map.
  /// On native platforms, the runtime already handles this conversion.
  /// 
  /// Example:
  /// ```dart
  /// final jsObj = await js.evaluate('{a: 1, b: 2}');
  /// final map = JsTypeConversion.jsObjectToMap(jsObj);
  /// ```
  static Map<String, dynamic>? jsObjectToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    
    // On web, use dartify to convert JSObject to Map
    if (value is JSObject) {
      final dartified = js_util.dartify(value);
      if (dartified is Map) {
        return Map<String, dynamic>.from(dartified);
      }
    }
    
    // If it's already a map, convert it
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    
    return null;
  }

  /// Convert a Dart List to a JavaScript array representation
  /// 
  /// This converts a Dart List to a JSON string that can be evaluated as a JavaScript array.
  /// 
  /// Example:
  /// ```dart
  /// final list = [1, 2, 3];
  /// final jsCode = 'const arr = ${JsTypeConversion.listToJsArray(list)};';
  /// ```
  static String listToJsArray(List<dynamic> list) {
    // Use JSON encoding to create a valid JavaScript array literal
    final buffer = StringBuffer('[');
    for (var i = 0; i < list.length; i++) {
      if (i > 0) buffer.write(', ');
      buffer.write(_valueToJs(list[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }

  /// Convert a Dart Map to a JavaScript object representation
  /// 
  /// This converts a Dart Map to a JSON string that can be evaluated as a JavaScript object.
  /// 
  /// Example:
  /// ```dart
  /// final map = {'a': 1, 'b': 2};
  /// final jsCode = 'const obj = ${JsTypeConversion.mapToJsObject(map)};';
  /// ```
  static String mapToJsObject(Map<String, dynamic> map) {
    // Use JSON encoding to create a valid JavaScript object literal
    final buffer = StringBuffer('{');
    var first = true;
    for (var entry in map.entries) {
      if (!first) buffer.write(', ');
      first = false;
      buffer.write('"${entry.key}": ${_valueToJs(entry.value)}');
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Convert a Dart value to its JavaScript representation
  static String _valueToJs(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List) return listToJsArray(value);
    if (value is Map) {
      return mapToJsObject(Map<String, dynamic>.from(value));
    }
    return '"${value.toString().replaceAll('"', '\\"')}"';
  }
}

