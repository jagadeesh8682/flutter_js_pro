# Flutter JS Plus

A unified JavaScript runtime for Flutter that works seamlessly across all platforms: **Web**, **Android**, **iOS**, **Windows**, **macOS**, and **Linux**.

## Features

- ✅ **Cross-platform**: Single API works on all Flutter platforms
- ✅ **Web Support**: Uses browser's native JavaScript engine via `dart:js_interop`
- ✅ **Native Performance**: QuickJS on Android/Windows/Linux, JavaScriptCore on iOS/macOS
- ✅ **Promise Support**: Automatically converts JavaScript Promises to Dart Futures (on web)
- ✅ **Type Conversion**: Automatic conversion between JavaScript and Dart types
- ✅ **Error Handling**: Proper exception handling with stack traces
- ✅ **Zero Configuration**: Works out of the box on all platforms

## Installation

Add `flutter_js_plus` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_js_plus: ^0.0.1
```

### Platform-Specific Setup

#### Android

Set minimum SDK version to 21 or higher in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

#### iOS/macOS

No additional setup required. Uses native JavaScriptCore.

#### Web

No additional setup required. Uses browser's JavaScript engine.

#### Windows/Linux

No additional setup required. Uses QuickJS.

## Quick Start

### Basic Usage

```dart
import 'package:flutter_js_plus/js_plus.dart';

void main() async {
  // Create a JavaScript runtime
  final js = JsPlus();
  
  try {
    // Evaluate simple expressions
    final result = await js.evaluate('1 + 2');
    print(result); // 3
    
    // Evaluate with variables
    await js.evaluate('const x = 10;');
    final sum = await js.evaluate('x + 5');
    print(sum); // 15
    
    // Work with objects
    final obj = await js.evaluate('''
      ({ name: "Flutter", version: 3.0 })
    ''');
    print(obj); // {name: Flutter, version: 3.0}
    
    // Work with arrays
    final arr = await js.evaluate('[1, 2, 3, 4, 5]');
    print(arr); // [1, 2, 3, 4, 5]
    
  } catch (e) {
    if (e is JsEvaluationException) {
      print('JavaScript error: ${e.message}');
    }
  } finally {
    // Always dispose when done
    js.dispose();
  }
}
```

### Working with Promises (Web)

On web, JavaScript Promises are automatically converted to Dart Futures:

```dart
final js = JsPlus();

// Promise automatically becomes a Future
final result = await js.evaluate('''
  Promise.resolve(42)
''');
print(result); // 42

// Async operations
final data = await js.evaluate('''
  fetch('https://api.example.com/data')
    .then(response => response.json())
''');
print(data); // The JSON data

js.dispose();
```

### Error Handling

```dart
final js = JsPlus();

try {
  await js.evaluate('throw new Error("Something went wrong")');
} on JsEvaluationException catch (e) {
  print('Error: ${e.message}');
  print('Stack: ${e.stackTrace}');
} finally {
  js.dispose();
}
```

### Type Conversion

The runtime automatically converts JavaScript types to Dart types:

```dart
final js = JsPlus();

// Numbers
final num = await js.evaluate('42');
print(num is int); // true

// Strings
final str = await js.evaluate('"Hello"');
print(str is String); // true

// Booleans
final bool = await js.evaluate('true');
print(bool is bool); // true

// Objects → Maps
final obj = await js.evaluate('{a: 1, b: 2}');
print(obj is Map); // true
print(obj['a']); // 1

// Arrays → Lists
final arr = await js.evaluate('[1, 2, 3]');
print(arr is List); // true
print(arr[0]); // 1

js.dispose();
```

For advanced type conversion, use the `JsTypeConversion` utilities:

```dart
import 'package:flutter_js_plus/js_plus.dart';

final js = JsPlus();
final jsArray = await js.evaluate('[1, 2, 3]');
final list = JsTypeConversion.jsArrayToList(jsArray);
print(list); // [1, 2, 3]

final jsObj = await js.evaluate('{a: 1}');
final map = JsTypeConversion.jsObjectToMap(jsObj);
print(map); // {a: 1}

js.dispose();
```

## Platform-Specific Behavior

### Web

On Flutter Web, `flutter_js_plus` uses the browser's native JavaScript engine through `dart:js_interop`. This means:

- Full access to browser APIs (`document`, `window`, `localStorage`, etc.)
- DOM manipulation capabilities
- Native Promise support (automatically converted to Futures)
- No additional JavaScript engine bundled (uses browser's engine)

**Example - DOM Manipulation (Web only):**

```dart
final js = JsPlus();

// Create HTML elements
await js.evaluate('''
  const div = document.createElement('div');
  div.id = 'my-element';
  div.innerHTML = 'Hello from JavaScript!';
  document.body.appendChild(div);
''');

// Modify elements
await js.evaluate('''
  const element = document.getElementById('my-element');
  element.style.color = 'blue';
''');

js.dispose();
```

### Native Platforms

On native platforms (Android, iOS, Windows, macOS, Linux), `flutter_js_plus` uses:

- **Android**: QuickJS (default) or JavaScriptCore (if forced)
- **iOS/macOS**: JavaScriptCore (native to Apple platforms)
- **Windows/Linux**: QuickJS

**Native Configuration:**

```dart
// Use JavaScriptCore on Android instead of QuickJS
final js = JsPlus(
  forceJavascriptCoreOnAndroid: true,
);

// Configure stack size for QuickJS
final js = JsPlus(
  extraArgs: {'stackSize': 2 * 1024 * 1024}, // 2MB
);

js.dispose();
```

## Advanced Usage

### Sharing Data Between Evaluations

```dart
final js = JsPlus();

// Set a variable
await js.evaluate('const myVar = "Hello";');

// Use it in another evaluation
final result = await js.evaluate('myVar + " World"');
print(result); // "Hello World"

js.dispose();
```

### Complex JavaScript Code

```dart
final js = JsPlus();

final result = await js.evaluate('''
  (function() {
    function factorial(n) {
      return n <= 1 ? 1 : n * factorial(n - 1);
    }
    return factorial(5);
  })()
''');
print(result); // 120

js.dispose();
```

## API Reference

### `JsPlus`

Main class for JavaScript evaluation.

#### Constructor

```dart
JsPlus({
  bool forceJavascriptCoreOnAndroid = false,
  Map<String, dynamic>? extraArgs,
})
```

- `forceJavascriptCoreOnAndroid`: Use JavaScriptCore instead of QuickJS on Android
- `extraArgs`: Additional arguments for native runtime (e.g., `{'stackSize': 1024 * 1024}`)

#### Methods

- `Future<dynamic> evaluate(String code)`: Evaluate JavaScript code and return the result
- `void dispose()`: Dispose of the runtime and free resources

### `JsEvaluationException`

Exception thrown when JavaScript evaluation fails.

- `String message`: Error message
- `String? stackTrace`: JavaScript stack trace (if available)

### `JsTypeConversion`

Utility class for type conversion between JavaScript and Dart.

- `List<dynamic>? jsArrayToList(dynamic value)`: Convert JS array to Dart List
- `Map<String, dynamic>? jsObjectToMap(dynamic value)`: Convert JS object to Dart Map
- `String listToJsArray(List<dynamic> list)`: Convert Dart List to JS array string
- `String mapToJsObject(Map<String, dynamic> map)`: Convert Dart Map to JS object string

## Limitations

### Web

- Uses `eval()` internally, which may be blocked by Content Security Policy (CSP) in some environments
- JavaScript code runs in the global scope (be careful with variable pollution)
- Some browser APIs may not be available depending on the context

### Native

- QuickJS has some limitations compared to full JavaScript engines (see [QuickJS documentation](https://bellard.org/quickjs/))
- JavaScriptCore on iOS/macOS is the full engine, but has different performance characteristics than QuickJS

## Safety Notes

### Using `eval()` on Web

This package uses JavaScript's `eval()` function on web platforms. While this is necessary for dynamic code evaluation, be aware that:

- **Security**: Only evaluate code from trusted sources
- **CSP**: Some Content Security Policies may block `eval()`
- **Performance**: `eval()` can be slower than pre-compiled code

### Memory Management

Always call `dispose()` when you're done with a `JsPlus` instance, especially on native platforms:

```dart
final js = JsPlus();
try {
  // Use js...
} finally {
  js.dispose(); // Important!
}
```

## Examples

See the `example/` directory for complete examples including:

- Basic JavaScript evaluation
- Promise handling
- Type conversion
- Error handling
- DOM manipulation (web)

## Migration from Legacy API

If you're using the legacy `getJavascriptRuntime()` API, you can migrate to the new `JsPlus` API:

**Before:**
```dart
final runtime = getJavascriptRuntime();
final result = runtime.evaluate('1 + 2');
print(result.stringResult);
runtime.dispose();
```

**After:**
```dart
final js = JsPlus();
final result = await js.evaluate('1 + 2');
print(result); // Direct value, no need for .stringResult
js.dispose();
```

The legacy API is still available for backward compatibility.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source under the MIT license.

## Acknowledgments

- QuickJS by Fabrice Bellard and Charlie Gordon
- JavaScriptCore bindings from [flutter_jscore](https://pub.dev/packages/flutter_jscore)
- QuickJS FFI bindings inspired by [flutter_qjs](https://pub.dev/packages/flutter_qjs)
