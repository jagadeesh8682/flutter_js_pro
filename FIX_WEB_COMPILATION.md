# Web Compilation Fix - Implementation Notes

## Issue
The `flutter_js_plus` package failed to compile on web because `lib/flutter_js.dart` accessed `io.Platform` properties, but on web, `io` conditionally resolves to `dart:html` which doesn't have a `Platform` class.

## Root Cause
Even though `kIsWeb` was checked first, the Dart analyzer validates all code paths at compile time. When compiling for web:
- `io` resolves to `dart:html` (via conditional import)
- Analyzer sees `io.Platform.isAndroid`, `io.Platform.isWindows`, etc.
- `dart:html` has no `Platform` class → compilation error

## Solution Implemented
**Solution 2: Platform-Specific Functions via Conditional Imports**

This is the correct approach because:
1. `dart.library.io` cannot be used as a runtime constant in `if` statements
2. Conditional imports ensure platform-specific code is completely isolated
3. The analyzer only sees the appropriate code for each platform

### Implementation

1. **Created `lib/src/runtime/get_runtime_native.dart`**
   - Contains all `Platform.isAndroid`, `Platform.isWindows`, etc. checks
   - Only compiles on native platforms (has `dart:io` available)
   - Returns appropriate runtime based on platform

2. **Created `lib/src/runtime/get_runtime_native_stub.dart`**
   - Stub version for web compilation
   - Throws `UnimplementedError` (never called due to `kIsWeb` check)
   - Prevents compilation errors on web

3. **Updated `lib/flutter_js.dart`**
   - Removed all direct `io.Platform` usage
   - Uses conditional import to get native runtime function
   - On web: imports stub (never called)
   - On native: imports real implementation

### Code Structure

```dart
// lib/flutter_js.dart
import 'package:flutter_js_plus/src/runtime/get_runtime_native.dart'
    if (dart.library.html) 'package:flutter_js_plus/src/runtime/get_runtime_native_stub.dart' as native_runtime;

JavascriptRuntime getJavascriptRuntime({...}) {
  if (kIsWeb) {
    return WebJavascriptRuntime();
  } else {
    // This function only exists with Platform on native
    return native_runtime.getNativeRuntime(...);
  }
}
```

```dart
// lib/src/runtime/get_runtime_native.dart (native only)
import 'dart:io';

JavascriptRuntime getNativeRuntime({...}) {
  if (Platform.isAndroid && !forceJavascriptCoreOnAndroid) {
    return QuickJsRuntime2(...);
  } else if (Platform.isWindows) {
    return QuickJsRuntime2();
  } else if (Platform.isLinux) {
    return QuickJsRuntime2();
  } else {
    return JavascriptCoreRuntime(); // iOS/macOS
  }
}
```

## Why This Works

1. **Compile-time isolation**: On web, the analyzer never sees `Platform` usage
2. **Type safety**: Each platform gets the correct implementation
3. **No runtime overhead**: Conditional imports are resolved at compile time
4. **Clear separation**: Platform detection logic is isolated in its own file

## Testing

✅ **Web compilation**: `flutter build web` - no errors
✅ **Android compilation**: `flutter build apk` - works correctly
✅ **iOS compilation**: `flutter build ios` - works correctly
✅ **All platforms**: Analyzer passes on all platforms

## Why Solution 1 Won't Work

The suggested Solution 1 uses:
```dart
else if (dart.library.io && io.Platform.isAndroid) {
```

**This is invalid** because:
- `dart.library.io` is not a runtime constant
- It can only be used in conditional import syntax: `import 'x' if (dart.library.io) 'y'`
- Cannot be used in `if` statements or boolean expressions

## Verification

To verify no `io.Platform` usage remains:
```bash
grep -r "io\.Platform" lib/
# Should return no results
```

## Commit
- Commit: `43550b0`
- Files: `lib/flutter_js.dart`, `lib/src/runtime/get_runtime_native.dart`, `lib/src/runtime/get_runtime_native_stub.dart`

