import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens of the builder UI. Change [accent] to re-brand everything.
class AppColors {
  const AppColors._();

  static const accent = Color(0xFF2F4B8A);
  static const text = Color(0xFF1A1F2E);
  static const muted = Color(0xFF5B6275);
  static const pageBackground = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E6EE);
  static const inputBorder = Color(0xFFD5D9E4);
  static const stepBorder = Color(0xFFC9CEDB);
  static const progressTrack = Color(0xFFE8EBF2);
  static const iconTile = Color(0xFFEBEFF8);
  static const fieldFill = Color(0xFFF8F9FC);
  static const error = Color(0xFFB4441C);
}

/// Disabled in tests to avoid network font fetches.
bool appUsesGoogleFonts = true;

ThemeData buildAppTheme({bool useGoogleFonts = true}) {
  appUsesGoogleFonts = useGoogleFonts;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.error,
        outline: AppColors.inputBorder,
        outlineVariant: AppColors.border,
      );
  var theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.pageBackground,
    dividerColor: AppColors.border,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.accent,
      ),
    ),
  );
  if (useGoogleFonts) {
    try {
      theme = theme.copyWith(
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(
          theme.textTheme,
        ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      );
    } catch (_) {
      // Falls back to the platform font when fonts cannot be loaded.
    }
  }
  return theme;
}

/// Monospace style for technical values (package names, app ID).
TextStyle monoStyle({double size = 14}) {
  if (appUsesGoogleFonts) {
    try {
      return GoogleFonts.ibmPlexMono(fontSize: size, color: AppColors.text);
    } catch (_) {}
  }
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    color: AppColors.text,
  );
}
