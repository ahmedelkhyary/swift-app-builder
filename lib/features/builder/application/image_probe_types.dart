/// Natural size of an image that loaded successfully (0 when the browser does
/// not know it, for example an SVG without a size).
class ProbedImage {
  const ProbedImage(this.width, this.height);
  final int width;
  final int height;
}

/// The image could not be loaded (blocked, not an image, not found, timeout).
class ImageProbeException implements Exception {
  const ImageProbeException(this.reason);
  final String reason;
  @override
  String toString() => 'ImageProbeException($reason)';
}

/// Loads an image to check that it is real and to read its natural size.
typedef ImageProbe = Future<ProbedImage> Function(String url);
