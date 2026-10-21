import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'image_probe_types.dart';

/// Checks an image with a plain `<img>` element, the one way that works for
/// public images on hosts without CORS headers (Firebase Storage, CDNs...).
/// `fetch` or a HEAD request would be blocked there although the image is fine.
///
/// The URL is used exactly as given (no decoding or re-encoding, so `%2F`
/// stays `%2F`) and `crossOrigin` is deliberately not set, because that would
/// make hosts without CORS headers fail.
Future<ProbedImage> probeImageElement(String url) {
  final completer = Completer<ProbedImage>();
  final img = web.HTMLImageElement();
  Timer? timeout;

  void fail(String reason) {
    timeout?.cancel();
    img.onload = null;
    img.onerror = null;
    debugPrint('Image URL check failed ($reason): $url');
    if (!completer.isCompleted) {
      completer.completeError(ImageProbeException(reason));
    }
  }

  img.onload = ((web.Event _) {
    timeout?.cancel();
    if (!completer.isCompleted) {
      completer.complete(ProbedImage(img.naturalWidth, img.naturalHeight));
    }
  }).toJS;
  img.onerror = ((web.Event _) => fail('the browser could not load it')).toJS;
  timeout = Timer(const Duration(seconds: 10), () => fail('timeout'));
  img.src = url;
  return completer.future;
}
