import 'dart:typed_data';

/// The three uploadable brand assets.
enum AssetKind { logo, appIcon, splashLogo }

/// An uploaded file that already passed validation.
class PickedAsset {
  const PickedAsset({
    required this.name,
    required this.bytes,
    required this.extension,
    this.width,
    this.height,
    this.sourceUrl,
  });

  final String name;
  final Uint8List bytes;

  /// Lower-case extension without dot: `png` or `svg`.
  final String extension;
  final int? width;
  final int? height;

  /// The external link the image was loaded from (kept as a reference; the
  /// bytes are stored like an uploaded file).
  final String? sourceUrl;

  bool get isSvg => extension == 'svg';

  /// An image that stays at its public [sourceUrl] (our own storage): there
  /// are no bytes, and nothing is downloaded or uploaded again.
  bool get isRemote => bytes.isEmpty && sourceUrl != null;
}

/// Storage path helpers: `apps/{appId}/v{configVersion}/...`.
class AssetPaths {
  const AssetPaths._();

  static String prefix(String appId, int version) => 'apps/$appId/v$version';

  static String forKind(
    String appId,
    int version,
    AssetKind kind,
    String extension,
  ) {
    final base = switch (kind) {
      AssetKind.logo => 'logo',
      AssetKind.appIcon => 'app_icon',
      AssetKind.splashLogo => 'splash_logo',
    };
    return '${prefix(appId, version)}/$base.$extension';
  }
}
