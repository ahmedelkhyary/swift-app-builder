import 'package:flutter/painting.dart';

/// WCAG contrast ratio between two colors (1..21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Black or white, whichever reads best on [background].
Color onColorFor(Color background) {
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);
  return contrastRatio(background, white) >= contrastRatio(background, black)
      ? white
      : black;
}

/// True when white text passes WCAG AA (4.5:1) on [background].
bool whiteTextPassesAa(Color background) =>
    contrastRatio(background, const Color(0xFFFFFFFF)) >= 4.5;

/// Parses `#RRGGBB` (or `RRGGBB`); returns null when invalid.
Color? parseHexColor(String input) {
  final s = input.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(s)) return null;
  return Color(0xFF000000 | int.parse(s, radix: 16));
}

/// Formats a color as uppercase `#RRGGBB`.
String colorToHex(Color c) {
  final rgb = c.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
