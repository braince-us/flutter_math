// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether the CanvasKit renderer is being used on web.
///
/// Always returns `false` on non-web.
///
/// See https://stackoverflow.com/a/66777112/6509751 for reference.
bool get isCanvasKit => globalContext['flutterCanvasKit'] != null;
