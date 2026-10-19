import 'dart:typed_data';

import 'package:flutter/painting.dart';

/// Logo bytes plus a flag telling whether they are SVG or a raster image.
class BrandLogo {
  const BrandLogo(this.bytes, {this.isSvg = false});
  final Uint8List bytes;
  final bool isSvg;
}

/// Everything the UI needs to know about a client's branding.
class BrandingConfig {
  const BrandingConfig({
    required this.primaryColor,
    required this.secondaryColor,
    this.fontFamily = 'Cairo',
    this.appNameAr = '',
    this.appNameEn = '',
    this.logo,
  });

  final Color primaryColor;
  final Color secondaryColor;
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
