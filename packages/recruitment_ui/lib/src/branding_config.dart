import 'dart:typed_data';

import 'package:flutter/painting.dart';

/// Logo bytes plus a flag telling whether they are SVG or a raster image.
/// A logo can also be shown from a public [url] (no bytes), for images that
/// live in our own storage.
class BrandLogo {
  const BrandLogo(this.bytes, {this.isSvg = false, this.url});

  /// A logo shown straight from [url].
  BrandLogo.network(String this.url) : bytes = Uint8List(0), isSvg = false;

  final Uint8List bytes;
  final bool isSvg;
  final String? url;
}

/// Everything the UI needs to know about a client's branding.
class BrandingConfig {
  const BrandingConfig({
    required this.primaryColor,
    required this.secondaryColor,
    this.accentColor = const Color(0xFF2E9E5B),
    this.backgroundColor,
    this.textColor,
    this.fontFamily = 'Cairo',
    this.appNameAr = '',
    this.appNameEn = '',
    this.logo,
  });

  final Color primaryColor;
  final Color secondaryColor;

  /// Links ("عرض الكل"), success states and selected items.
  final Color accentColor;

  /// Optional overrides of the template's page and text colors.
  final Color? backgroundColor;
  final Color? textColor;
  final String fontFamily;
  final String appNameAr;
  final String appNameEn;
  final BrandLogo? logo;

  String appName(String languageCode) {
    final preferred = languageCode == 'ar' ? appNameAr : appNameEn;
    final fallback = languageCode == 'ar' ? appNameEn : appNameAr;
    if (preferred.trim().isNotEmpty) return preferred;
    if (fallback.trim().isNotEmpty) return fallback;
    return languageCode == 'ar' ? 'اسم التطبيق' : 'App name';
  }
}
