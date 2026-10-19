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
  });

  final String name;
  final Uint8List bytes;

  /// Lower-case extension without dot: `png` or `svg`.
  final String extension;
  final int? width;
  final int? height;

  bool get isSvg => extension == 'svg';
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
