import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'branding_config.dart';
import 'color_utils.dart';

enum CardStyle { elevated, outlined, filled, glass }

enum HeaderStyle { solid, curved, plain, gradient }

enum RuiButtonStyle { rounded, pill, square, gradient }

enum ServiceGridVariant { grid2, list, grid3, featured }

enum NavStyle { standard, floating, line, dark }

enum InputStyleKind { outlined, filled, underline, soft }

enum PageTransitionKind { slide, fade, rise, scale }

/// A template is a set of design tokens, not a separate app.
class AppTemplate {
  const AppTemplate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cornerRadius,
    required this.cardStyle,
    required this.elevation,
    required this.typographyScale,
    required this.headerStyle,
    required this.buttonStyle,
    required this.serviceGrid,
    required this.navStyle,
    required this.inputStyle,
    required this.transition,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double cornerRadius;
  final CardStyle cardStyle;
  final double elevation;
  final double typographyScale;
  final HeaderStyle headerStyle;
  final RuiButtonStyle buttonStyle;
  final ServiceGridVariant serviceGrid;
  final NavStyle navStyle;
  final InputStyleKind inputStyle;
  final PageTransitionKind transition;

  /// Version of this template implementation. The project generator maps
  /// (id, version) to a concrete template; bump when its behaviour changes.
  static const version = 1;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  static const classic = AppTemplate(
    id: 'classic',
    nameAr: 'كلاسيكي',
    nameEn: 'Classic',
    cornerRadius: 12,
    cardStyle: CardStyle.elevated,
    elevation: 2,
    typographyScale: 1.0,
    headerStyle: HeaderStyle.solid,
    buttonStyle: RuiButtonStyle.rounded,
    serviceGrid: ServiceGridVariant.grid2,
    navStyle: NavStyle.standard,
    inputStyle: InputStyleKind.outlined,
    transition: PageTransitionKind.slide,
  );

  static const modern = AppTemplate(
    id: 'modern',
    nameAr: 'عصري',
    nameEn: 'Modern',
    cornerRadius: 24,
    cardStyle: CardStyle.filled,
    elevation: 0,
    typographyScale: 1.05,
    headerStyle: HeaderStyle.curved,
    buttonStyle: RuiButtonStyle.pill,
    serviceGrid: ServiceGridVariant.grid3,
    navStyle: NavStyle.floating,
    inputStyle: InputStyleKind.filled,
    transition: PageTransitionKind.rise,
  );

  static const minimal = AppTemplate(
    id: 'minimal',
    nameAr: 'بسيط',
    nameEn: 'Minimal',
    cornerRadius: 4,
    cardStyle: CardStyle.outlined,
    elevation: 0,
    typographyScale: 0.95,
    headerStyle: HeaderStyle.plain,
    buttonStyle: RuiButtonStyle.square,
    serviceGrid: ServiceGridVariant.list,
    navStyle: NavStyle.line,
    inputStyle: InputStyleKind.underline,
    transition: PageTransitionKind.fade,
  );

  static const premium = AppTemplate(
    id: 'premium',
    nameAr: 'فاخر',
    nameEn: 'Premium',
    cornerRadius: 18,
    cardStyle: CardStyle.glass,
    elevation: 6,
    typographyScale: 1.1,
    headerStyle: HeaderStyle.gradient,
    buttonStyle: RuiButtonStyle.gradient,
    serviceGrid: ServiceGridVariant.featured,
    navStyle: NavStyle.dark,
    inputStyle: InputStyleKind.soft,
    transition: PageTransitionKind.scale,
  );

  static const all = <AppTemplate>[classic, modern, minimal, premium];

  static AppTemplate byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);

  /// Disable in tests / offline tools to avoid fetching fonts over the network.
  static bool useGoogleFonts = true;

  /// Builds the Material theme for this template, derived from [branding].
  ThemeData buildTheme(BrandingConfig branding, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark
        ? Color.lerp(branding.primaryColor, Colors.white, 0.25)!
        : branding.primaryColor;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: branding.primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onColorFor(primary),
          secondary: branding.secondaryColor,
          onSecondary: onColorFor(branding.secondaryColor),
        );

    // Typography's themes define a font size for every style (required by
    // `apply(fontSizeFactor:)`), unlike the bare ThemeData text theme.
    final typography = Typography.material2021();
    final base = typography.englishLike.merge(
      isDark ? typography.white : typography.black,
    );
    final scaled = base.apply(fontSizeFactor: typographyScale);
    var text = scaled;
    if (useGoogleFonts) {
      try {
        text = GoogleFonts.getTextTheme(branding.fontFamily, scaled);
      } catch (_) {
        text = scaled;
      }
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        buttonStyle == RuiButtonStyle.pill
            ? 100
            : buttonStyle == RuiButtonStyle.square
            ? 2
            : cornerRadius,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : (cardStyle == CardStyle.filled
                ? Color.lerp(Colors.white, primary, 0.04)
                : Colors.white),
      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shape,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
    );
  }

  InputDecorationTheme _inputTheme(ColorScheme scheme) {
    final r = BorderRadius.circular(cornerRadius);
    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: r,
      borderSide: BorderSide(color: c, width: w),
    );
    switch (inputStyle) {
      case InputStyleKind.outlined:
        return InputDecorationTheme(
          border: outline(scheme.outline),
          enabledBorder: outline(scheme.outline),
          focusedBorder: outline(scheme.primary, 2),
          errorBorder: outline(scheme.error),
          focusedErrorBorder: outline(scheme.error, 2),
        );
      case InputStyleKind.filled:
        return InputDecorationTheme(
          filled: true,
          fillColor: scheme.primary.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: r,
            borderSide: BorderSide.none,
          ),
          focusedBorder: outline(scheme.primary, 2),
          errorBorder: outline(scheme.error),
        );
      case InputStyleKind.underline:
        return InputDecorationTheme(
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.outline),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
        );
      case InputStyleKind.soft:
        return InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: scheme.secondary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        );
    }
  }
}
