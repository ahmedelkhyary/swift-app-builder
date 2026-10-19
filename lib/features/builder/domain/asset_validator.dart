import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'asset.dart';

enum AssetIssue {
  wrongType,
  tooLarge,
  undecodable,
  tooSmall,
  wrongSize,
  hasTransparency,
}

/// Result of validating an upload: either an asset or an issue.
class AssetCheck {
  const AssetCheck.ok(PickedAsset this.asset) : issue = null;
  const AssetCheck.fail(AssetIssue this.issue) : asset = null;
  final PickedAsset? asset;
  final AssetIssue? issue;
  bool get isOk => asset != null;
}

class AssetValidator {
  const AssetValidator._();

  static const maxLogoBytes = 2 * 1024 * 1024;
  static const minLogoSide = 512;
  static const iconSide = 1024;

  static String _ext(String name) {
    final i = name.lastIndexOf('.');
    return i < 0 ? '' : name.substring(i + 1).toLowerCase();
  }

  /// PNG or SVG, <= 2 MB, at least 512x512 (SVG: when its size is declared).
  static AssetCheck validateLogo(String name, Uint8List bytes) {
    final ext = _ext(name);
    if (ext != 'png' && ext != 'svg') {
      return const AssetCheck.fail(AssetIssue.wrongType);
    }
    if (bytes.length > maxLogoBytes) {
      return const AssetCheck.fail(AssetIssue.tooLarge);
    }
    if (ext == 'svg') {
      final size = _svgSize(String.fromCharCodes(bytes));
      if (size == null && !String.fromCharCodes(bytes).contains('<svg')) {
        return const AssetCheck.fail(AssetIssue.undecodable);
      }
      if (size != null && (size.$1 < minLogoSide || size.$2 < minLogoSide)) {
        return const AssetCheck.fail(AssetIssue.tooSmall);
      }
      return AssetCheck.ok(
        PickedAsset(
          name: name,
          bytes: bytes,
          extension: 'svg',
          width: size?.$1.round(),
          height: size?.$2.round(),
        ),
      );
    }
    final image = _decodePng(bytes);
    if (image == null) return const AssetCheck.fail(AssetIssue.undecodable);
    if (image.width < minLogoSide || image.height < minLogoSide) {
      return const AssetCheck.fail(AssetIssue.tooSmall);
    }
    return AssetCheck.ok(
      PickedAsset(
        name: name,
        bytes: bytes,
        extension: 'png',
        width: image.width,
        height: image.height,
      ),
    );
  }

  /// PNG, exactly 1024x1024, fully opaque.
  static AssetCheck validateIcon(String name, Uint8List bytes) {
    if (_ext(name) != 'png') return const AssetCheck.fail(AssetIssue.wrongType);
    if (bytes.length > 10 * 1024 * 1024) {
      return const AssetCheck.fail(AssetIssue.tooLarge);
    }
    final image = _decodePng(bytes);
    if (image == null) return const AssetCheck.fail(AssetIssue.undecodable);
    if (image.width != iconSide || image.height != iconSide) {
      return const AssetCheck.fail(AssetIssue.wrongSize);
    }
    if (image.hasAlpha) {
      for (final p in image) {
        if (p.a < p.maxChannelValue) {
          return const AssetCheck.fail(AssetIssue.hasTransparency);
        }
      }
    }
    return AssetCheck.ok(
      PickedAsset(
        name: name,
        bytes: bytes,
        extension: 'png',
        width: image.width,
        height: image.height,
      ),
    );
  }

  static img.Image? _decodePng(Uint8List bytes) {
    try {
      return img.decodePng(bytes);
    } catch (_) {
      return null;
    }
  }

  static (double, double)? _svgSize(String svg) {
    final head = RegExp(r'<svg[^>]*>', dotAll: true).firstMatch(svg)?.group(0);
    if (head == null) return null;
    double? attr(String name) {
      final m = RegExp(
        '\\b$name\\s*=\\s*["\']([0-9.]+)(px)?["\']',
      ).firstMatch(head);
      return m == null ? null : double.tryParse(m.group(1)!);
    }

    final w = attr('width');
    final h = attr('height');
    if (w != null && h != null) return (w, h);
    final vb = RegExp('viewBox\\s*=\\s*["\']([^"\']+)["\']').firstMatch(head);
    if (vb != null) {
      final parts = vb
          .group(1)!
          .split(RegExp(r'[\s,]+'))
          .map(double.tryParse)
          .toList();
      if (parts.length == 4 && parts[2] != null && parts[3] != null) {
        return (parts[2]!, parts[3]!);
      }
    }
    return null;
  }
}
