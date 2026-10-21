import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'branding_config.dart';
import 'color_utils.dart';

/// How cards are drawn.
enum CardStyle {
  /// Flat surface with a thin border.
  outlined,

  /// Soft shadow, hairline accent border and a faint gradient.
  luxe,

  /// Translucent layered surface (blur, gradient border, lift on hover).
  glass,
}

enum HeaderStyle { solid, luxe, hero }

enum RuiButtonStyle { flat, luxe, gradient }

enum ServiceGridVariant { list, grid2, featured }

enum NavStyle { line, luxe, floating }

enum InputStyleKind { outlined, luxe, soft }

enum PageTransitionKind { fade, rise, scale }

/// Where the page / surface colors come from.
enum PaletteKind {
  /// Light neutral greys; the brand color is only used for actions.
  neutral,

  /// Deep ink derived from the brand primary with a champagne-gold accent.
  luxe,

  /// Brand-tinted surfaces with dynamic gradients.
  vivid,
}

/// How much motion a template uses.
enum MotionLevel {
  /// Only the page transition.
  none,

  /// Soft transitions and hover feedback.
  soft,

  /// Staggered reveals, skeleton loading, carousels, micro-interactions.
  rich,
}

/// A template is a set of design tokens, not a separate app: every template
/// runs the same screens, data and business logic and only changes how they
/// look. To add a template, define a new constant here and list it in [all].
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
    required this.palette,
    required this.motion,
    this.displayFont = false,
    this.spacing = 1,
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
  final PaletteKind palette;
  final MotionLevel motion;

  /// Headings use an elegant serif display face (Latin and Arabic).
  final bool displayFont;

  /// Multiplier for paddings / gaps (1 = default, >1 = airier).
  final double spacing;

  /// Version of the template implementations. The project generator maps
  /// (id, version) to a concrete design; bump when a template's look or
  /// behavior changes.
  static const version = 2;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  /// The reference design: white screens, solid brand-colored app bars,
  /// flat rounded buttons and cards with a soft shadow.
  static const simple = AppTemplate(
    id: 'simple',
    nameAr: 'البسيط',
    nameEn: 'Simple',
    cornerRadius: 12,
    cardStyle: CardStyle.outlined,
    elevation: 0,
    typographyScale: 1.0,
    headerStyle: HeaderStyle.solid,
    buttonStyle: RuiButtonStyle.flat,
    serviceGrid: ServiceGridVariant.list,
    navStyle: NavStyle.line,
    inputStyle: InputStyleKind.outlined,
    transition: PageTransitionKind.fade,
    palette: PaletteKind.neutral,
    motion: MotionLevel.none,
  );

  /// Dark ink and champagne gold, serif headings, generous spacing.
  static const luxury = AppTemplate(
    id: 'luxury',
    nameAr: 'فاخر',
    nameEn: 'Luxury',
    cornerRadius: 20,
    cardStyle: CardStyle.luxe,
    elevation: 8,
    typographyScale: 1.04,
    headerStyle: HeaderStyle.luxe,
    buttonStyle: RuiButtonStyle.luxe,
    serviceGrid: ServiceGridVariant.grid2,
    navStyle: NavStyle.luxe,
    inputStyle: InputStyleKind.luxe,
    transition: PageTransitionKind.rise,
    palette: PaletteKind.luxe,
    motion: MotionLevel.soft,
    displayFont: true,
    spacing: 1.25,
  );

  /// The most advanced design: glass, gradients, depth, rich motion.
  static const premium = AppTemplate(
    id: 'premium',
    nameAr: 'بريميوم',
    nameEn: 'Premium',
    cornerRadius: 22,
    cardStyle: CardStyle.glass,
    elevation: 10,
    typographyScale: 1.06,
    headerStyle: HeaderStyle.hero,
    buttonStyle: RuiButtonStyle.gradient,
    serviceGrid: ServiceGridVariant.featured,
    navStyle: NavStyle.floating,
    inputStyle: InputStyleKind.soft,
    transition: PageTransitionKind.scale,
    palette: PaletteKind.vivid,
    motion: MotionLevel.rich,
    spacing: 1.1,
  );

  static const all = <AppTemplate>[simple, luxury, premium];

  static AppTemplate byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => simple);

  /// Disable in tests / offline tools to avoid fetching fonts over the network.
  static bool useGoogleFonts = true;

  /// How long rich-motion templates show skeleton placeholders on Home.
  /// Set to [Duration.zero] in tests.
  static Duration skeletonDuration = const Duration(milliseconds: 650);

  /// Builds the Material theme for this template, derived from [branding].
  /// [languageCode] only selects the display font of templates that use one.
  ThemeData buildTheme(
    BrandingConfig branding,
    Brightness brightness, {
    String languageCode = 'ar',
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark
        ? Color.lerp(branding.primaryColor, Colors.white, 0.25)!
        : branding.primaryColor;
    final tokens = RuiTokens.resolve(this, branding, brightness);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: branding.primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onColorFor(primary),
          secondary: branding.secondaryColor,
          onSecondary: onColorFor(branding.secondaryColor),
          surface: tokens.cardFill,
          onSurface: tokens.text,
          outlineVariant: tokens.cardBorder,
        );

    // Typography's themes define a font size for every style (required by
    // `apply(fontSizeFactor:)`), unlike the bare ThemeData text theme.
    final typography = Typography.material2021();
    final base = typography.englishLike.merge(
      isDark ? typography.white : typography.black,
    );
    final scaled = base
        .apply(fontSizeFactor: typographyScale)
        .apply(bodyColor: tokens.text, displayColor: tokens.text);
    var text = scaled;
    if (useGoogleFonts) {
      try {
        text = GoogleFonts.getTextTheme(branding.fontFamily, scaled);
        if (displayFont) {
          final display = GoogleFonts.getTextTheme(
            languageCode == 'ar' ? 'Amiri' : 'Playfair Display',
            scaled,
          );
          text = text.copyWith(
            displayLarge: display.displayLarge,
            displayMedium: display.displayMedium,
            displaySmall: display.displaySmall,
            headlineLarge: display.headlineLarge,
            headlineMedium: display.headlineMedium,
            headlineSmall: display.headlineSmall,
            titleLarge: display.titleLarge,
            titleMedium: display.titleMedium,
          );
        }
      } catch (_) {
        text = scaled;
      }
    }

    final radius = switch (buttonStyle) {
      RuiButtonStyle.gradient => 100.0,
      RuiButtonStyle.luxe => 14.0,
      RuiButtonStyle.flat => cornerRadius.clamp(0, 10).toDouble(),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final filled = switch (buttonStyle) {
      RuiButtonStyle.luxe => FilledButton.styleFrom(
        shape: shape,
        elevation: 0,
        backgroundColor: isDark ? tokens.accent : tokens.chrome,
        foregroundColor: isDark ? tokens.chrome : tokens.accent,
        minimumSize: const Size.fromHeight(52),
      ),
      _ => FilledButton.styleFrom(
        shape: shape,
        elevation: 0,
        minimumSize: Size.fromHeight(
          buttonStyle == RuiButtonStyle.flat ? 46 : 52,
        ),
      ),
    };

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: tokens.page,
      focusColor: tokens.focus,
      dividerColor: tokens.cardBorder,
      extensions: [tokens],
      datePickerTheme: DatePickerThemeData(
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? tokens.link : null,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? onColorFor(tokens.link)
              : null,
        ),
      ),
      inputDecorationTheme: _inputTheme(scheme, tokens, isDark),
      filledButtonTheme: FilledButtonThemeData(style: filled),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shape,
          foregroundColor: buttonStyle == RuiButtonStyle.luxe
              ? tokens.text
              : null,
          side: BorderSide(
            color: buttonStyle == RuiButtonStyle.luxe
                ? tokens.accent
                : scheme.outline,
          ),
          minimumSize: const Size(0, 46),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cornerRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.clamp(6, 16)),
        ),
      ),
    );
  }

  InputDecorationTheme _inputTheme(
    ColorScheme scheme,
    RuiTokens tokens,
    bool isDark,
  ) {
    OutlineInputBorder outline(double r, Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: c, width: w),
        );
    switch (inputStyle) {
      case InputStyleKind.outlined:
        return InputDecorationTheme(
          filled: true,
          fillColor: Color.lerp(
            tokens.cardFill,
            tokens.text,
            isDark ? 0.08 : 0.035,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: outline(10, tokens.cardBorder),
          enabledBorder: outline(10, tokens.cardBorder),
          focusedBorder: outline(10, scheme.primary, 1.5),
          errorBorder: outline(10, scheme.error),
          focusedErrorBorder: outline(10, scheme.error, 1.5),
        );
      case InputStyleKind.luxe:
        return InputDecorationTheme(
          filled: true,
          fillColor: tokens.cardFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: outline(14, tokens.cardBorder),
          enabledBorder: outline(14, tokens.cardBorder),
          focusedBorder: outline(
            14,
            isDark ? tokens.accent : tokens.chrome,
            1.5,
          ),
          errorBorder: outline(14, scheme.error),
          focusedErrorBorder: outline(14, scheme.error, 1.5),
        );
      case InputStyleKind.soft:
        return InputDecorationTheme(
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : scheme.primary.withValues(alpha: 0.07),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: outline(18, Colors.transparent),
          enabledBorder: outline(18, Colors.transparent),
          focusedBorder: outline(18, scheme.primary, 2),
          errorBorder: outline(18, scheme.error),
          focusedErrorBorder: outline(18, scheme.error, 2),
        );
    }
  }
}

/// Resolved colors of a template for one brand and brightness. Widgets read
/// these instead of hard-coding colors, so every template follows the client's
/// visual identity.
@immutable
class RuiTokens extends ThemeExtension<RuiTokens> {
  const RuiTokens({
    required this.page,
    required this.text,
    required this.cardFill,
    required this.cardBorder,
    required this.chrome,
    required this.onChrome,
    required this.accent,
    required this.focus,
    required this.heroGradient,
    required this.link,
  });

  /// Scaffold background.
  final Color page;

  /// Default text color on [page] / [cardFill].
  final Color text;
  final Color cardFill;
  final Color cardBorder;

  /// Header / bar background of templates with a solid "chrome".
  final Color chrome;
  final Color onChrome;

  /// Decorative accent (gold in the luxury template).
  final Color accent;

  /// Keyboard-focus highlight.
  final Color focus;

  /// Gradient used by hero headers, banners and gradient buttons.
  final List<Color> heroGradient;

  /// The client's accent: links ("عرض الكل"), success states, selected items.
  final Color link;

  static RuiTokens of(BuildContext context) =>
      Theme.of(context).extension<RuiTokens>()!;

  static const _champagne = Color(0xFFE8CE8A);

  /// The client's colors always win over the template defaults: the page and
  /// text colors when chosen, and the accent for links and success states.
  /// Templates only derive shades from them.
  factory RuiTokens.resolve(
    AppTemplate t,
    BrandingConfig b,
    Brightness brightness,
  ) {
    final base = _resolveBase(t, b, brightness);
    return base.copyWith(page: b.backgroundColor, text: b.textColor);
  }

  static RuiTokens _resolveBase(
    AppTemplate t,
    BrandingConfig b,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final link = dark
        ? Color.lerp(b.accentColor, Colors.white, 0.2)!
        : b.accentColor;
    final primary = dark
        ? Color.lerp(b.primaryColor, Colors.white, 0.25)!
        : b.primaryColor;
    final secondary = b.secondaryColor;
    switch (t.palette) {
      case PaletteKind.neutral:
        final chrome = dark
            ? Color.lerp(b.primaryColor, Colors.black, 0.45)!
            : b.primaryColor;
        return RuiTokens(
          link: link,
          page: dark ? const Color(0xFF121316) : Colors.white,
          text: dark ? const Color(0xFFECEDF0) : const Color(0xFF1A1F2E),
          cardFill: dark ? const Color(0xFF1A1B1F) : Colors.white,
          cardBorder: dark ? const Color(0xFF30323A) : const Color(0xFFE6E9F0),
          chrome: chrome,
          onChrome: onColorFor(chrome),
          accent: secondary,
          focus: primary.withValues(alpha: 0.18),
          heroGradient: [chrome, Color.lerp(chrome, Colors.black, 0.22)!],
        );
      case PaletteKind.luxe:
        final ink = Color.lerp(
          b.primaryColor,
          Colors.black,
          dark ? 0.92 : 0.84,
        )!;
        final gold = Color.lerp(secondary, _champagne, 0.55)!;
        return RuiTokens(
          link: link,
          page: dark
              ? Color.lerp(b.primaryColor, Colors.black, 0.9)!
              : Color.lerp(const Color(0xFFFBF8F1), b.primaryColor, 0.03)!,
          text: dark ? const Color(0xFFF4EEE0) : const Color(0xFF1C1710),
          cardFill: dark
              ? Color.lerp(b.primaryColor, Colors.black, 0.8)!
              : const Color(0xFFFFFDF8),
          cardBorder: gold.withValues(alpha: dark ? 0.35 : 0.5),
          chrome: ink,
          onChrome: const Color(0xFFF7F1E3),
          accent: gold,
          focus: gold.withValues(alpha: 0.3),
          heroGradient: [ink, Color.lerp(ink, b.primaryColor, 0.45)!],
        );
      case PaletteKind.vivid:
        final mid = Color.lerp(primary, secondary, 0.55)!;
        return RuiTokens(
          link: link,
          page: dark
              ? Color.lerp(const Color(0xFF0D0E13), primary, 0.08)!
              : Color.lerp(Colors.white, primary, 0.06)!,
          text: dark ? const Color(0xFFF1F2F6) : const Color(0xFF14161F),
          cardFill: dark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.72),
          cardBorder: dark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.9),
          chrome: primary,
          onChrome: onColorFor(primary),
          accent: secondary,
          focus: primary.withValues(alpha: 0.28),
          heroGradient: [
            primary,
            mid,
            Color.lerp(primary, Colors.black, dark ? 0.55 : 0.35)!,
          ],
        );
    }
  }

  @override
  RuiTokens copyWith({
    Color? page,
    Color? text,
    Color? cardFill,
    Color? cardBorder,
    Color? chrome,
    Color? onChrome,
    Color? accent,
    Color? focus,
    List<Color>? heroGradient,
    Color? link,
  }) => RuiTokens(
    page: page ?? this.page,
    text: text ?? this.text,
    cardFill: cardFill ?? this.cardFill,
    cardBorder: cardBorder ?? this.cardBorder,
    chrome: chrome ?? this.chrome,
    onChrome: onChrome ?? this.onChrome,
    accent: accent ?? this.accent,
    focus: focus ?? this.focus,
    heroGradient: heroGradient ?? this.heroGradient,
    link: link ?? this.link,
  );

  @override
  RuiTokens lerp(ThemeExtension<RuiTokens>? other, double t) {
    if (other is! RuiTokens) return this;
    return RuiTokens(
      page: Color.lerp(page, other.page, t)!,
      text: Color.lerp(text, other.text, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
      onChrome: Color.lerp(onChrome, other.onChrome, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      link: Color.lerp(link, other.link, t)!,
      heroGradient: [
        for (var i = 0; i < heroGradient.length; i++)
          Color.lerp(
            heroGradient[i],
            other.heroGradient[i % other.heroGradient.length],
            t,
          )!,
      ],
    );
  }
}
