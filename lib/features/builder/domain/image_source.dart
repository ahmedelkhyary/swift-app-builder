import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'asset.dart';
import 'asset_validator.dart';

/// Image formats accepted from a URL.
enum ImageFormat { png, jpg, webp, svg }

/// Why an image URL could not be used.
enum UrlFailure {
  /// Not a valid http/https URL.
  invalid,

  /// The download failed (blocked, private, CORS, not found, timeout).
  unreachable,

  /// It downloaded but is not a PNG, JPG, WEBP or SVG image.
  unsupported,

  /// The image loads in the browser, but the host does not allow copying it
  /// (no CORS) and it is not in our own storage. Upload the file instead.
  notCopyable,
}

/// Outcome of loading an image from a URL: an asset, or why not.
class UrlImageResult {
  const UrlImageResult.ok(PickedAsset this.asset)
    : failure = null,
      issue = null,
      width = null,
      height = null;
  const UrlImageResult.failure(UrlFailure this.failure)
    : asset = null,
      issue = null,
      width = null,
      height = null;
  const UrlImageResult.issue(AssetIssue this.issue, {this.width, this.height})
    : asset = null,
      failure = null;

  final PickedAsset? asset;
  final UrlFailure? failure;

  /// The image loaded but breaks the same rules as an uploaded file; [width]
  /// and [height] are its actual size when that is the problem.
  final AssetIssue? issue;
  final int? width;
  final int? height;
}

/// Recognizes an image by its content, not by the URL's extension.
ImageFormat? sniffImage(Uint8List b) {
  bool starts(List<int> sig, [int offset = 0]) {
    if (b.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts(const [0x89, 0x50, 0x4E, 0x47])) return ImageFormat.png;
  if (starts(const [0xFF, 0xD8, 0xFF])) return ImageFormat.jpg;
  if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
      starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return ImageFormat.webp;
  }
  final head = String.fromCharCodes(
    b.sublist(0, b.length < 1024 ? b.length : 1024),
  );
  if (head.contains('<svg')) return ImageFormat.svg;
  return null;
}

/// Turns a downloaded image into the asset an upload would produce: PNG and
/// SVG are kept, JPG and WEBP are converted to PNG. Returns the same
/// validation outcome as an uploaded file of that kind.
UrlImageResult assetFromDownload({
  required Uint8List bytes,
  required ImageFormat format,
  required String baseName,
  required AssetKind kind,
  required String sourceUrl,
}) {
  var data = bytes;
  var ext = format == ImageFormat.svg ? 'svg' : 'png';
  if (format == ImageFormat.jpg || format == ImageFormat.webp) {
    final decoded = format == ImageFormat.jpg
        ? img.decodeJpg(bytes)
        : img.decodeWebP(bytes);
    if (decoded == null) {
      return const UrlImageResult.issue(AssetIssue.undecodable);
    }
    data = Uint8List.fromList(img.encodePng(decoded));
  }
  final name = '$baseName.$ext';
  final check = kind == AssetKind.appIcon
      ? AssetValidator.validateIcon(name, data)
      : AssetValidator.validateLogo(name, data);
  final asset = check.asset;
  if (asset == null) return UrlImageResult.issue(check.issue!);
  return UrlImageResult.ok(
    PickedAsset(
      name: asset.name,
      bytes: asset.bytes,
      extension: asset.extension,
      width: asset.width,
      height: asset.height,
      sourceUrl: sourceUrl,
    ),
  );
}
