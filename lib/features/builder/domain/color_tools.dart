import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:image/image.dart' as img;

/// Parses `#RGB`, `#RRGGBB`, `RGB` or `RRGGBB` (case-insensitive).
/// Returns null when invalid.
Color? parseFlexibleHex(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (!RegExp(r'^([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(s)) return null;
  if (s.length == 3) {
    s = s.split('').map((c) => '$c$c').join();
  }
  return Color(0xFF000000 | int.parse(s, radix: 16));
}

/// `#RRGGBB`, uppercase — the format stored in the draft and the config.
String hexOf(Color c) {
  final rgb = c.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

int _channel(double v) => (v * 255).round().clamp(0, 255);

/// Red / green / blue as 0-255 integers.
(int, int, int) rgbOf(Color c) => (_channel(c.r), _channel(c.g), _channel(c.b));

/// Up to [max] dominant, visually distinct colors of a PNG, most frequent
/// first. Transparent pixels and near-white backgrounds are ignored.
/// Returns an empty list when the image cannot be decoded (e.g. SVG).
List<Color> dominantColors(Uint8List bytes, {int max = 5}) {
  img.Image? image;
  try {
    image = img.decodePng(bytes);
  } catch (_) {
    return const [];
  }
  if (image == null) return const [];
  final small = image.width > 64 ? img.copyResize(image, width: 64) : image;

  // 4 bits per channel buckets, remembering the real average of each bucket.
  final counts = <int, int>{};
  final sums = <int, List<int>>{};
  for (final p in small) {
    if (p.a < p.maxChannelValue * 0.5) continue;
    final scale = 255 / p.maxChannelValue;
    final r = (p.r * scale).round(),
        g = (p.g * scale).round(),
        b = (p.b * scale).round();
    if (math.min(r, math.min(g, b)) > 235) continue; // near-white
    final key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    counts[key] = (counts[key] ?? 0) + 1;
    final s = sums.putIfAbsent(key, () => [0, 0, 0]);
    s[0] += r;
    s[1] += g;
    s[2] += b;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  final result = <Color>[];
  for (final k in keys) {
    final n = counts[k]!;
    final c = Color.fromARGB(
      255,
      sums[k]![0] ~/ n,
      sums[k]![1] ~/ n,
      sums[k]![2] ~/ n,
    );
    final distinct = result.every((o) {
      final (r1, g1, b1) = rgbOf(o);
      final (r2, g2, b2) = rgbOf(c);
      final d = math.sqrt(
        math.pow(r1 - r2, 2) + math.pow(g1 - g2, 2) + math.pow(b1 - b2, 2),
      );
      return d >= 60;
    });
    if (distinct) result.add(c);
    if (result.length >= max) break;
  }
  return result;
}
