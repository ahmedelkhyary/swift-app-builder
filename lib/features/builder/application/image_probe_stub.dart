import 'image_probe_types.dart';

/// Outside the browser there is no `<img>` element to load an image with.
Future<ProbedImage> probeImageElement(String url) =>
    throw const ImageProbeException('not supported on this platform');
