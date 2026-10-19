import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('EyeDropper')
extension type _EyeDropper._(JSObject _) implements JSObject {
  external factory _EyeDropper();
  external JSPromise<_EyeDropperResult> open();
}

extension type _EyeDropperResult._(JSObject _) implements JSObject {
  external String get sRGBHex;
}

/// True in browsers that implement the EyeDropper API (Chromium).
bool get eyeDropperSupported => globalContext.has('EyeDropper');

/// Opens the screen color picker; returns `#RRGGBB` or null when cancelled
/// or unsupported.
Future<String?> pickColorFromScreen() async {
  if (!eyeDropperSupported) return null;
  try {
    final result = await _EyeDropper().open().toDart;
    return result.sRGBHex.toUpperCase();
  } catch (_) {
    return null; // user pressed Esc
  }
}
