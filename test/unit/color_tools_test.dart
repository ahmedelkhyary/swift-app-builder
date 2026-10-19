import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:swiftappbuilder/features/builder/domain/color_tools.dart';

Uint8List twoColorPng() {
  // 60% orange, 30% blue, 10% transparent; plus a white strip that must be ignored.
  final image = img.Image(width: 20, height: 20, numChannels: 4);
  for (final p in image) {
    final i = p.y;
    if (i < 12) {
      p.setRgba(255, 140, 0, 255);
    } else if (i < 16) {
      p.setRgba(21, 101, 192, 255);
    } else if (i < 18) {
      p.setRgba(255, 255, 255, 255);
    } else {
      p.setRgba(0, 0, 0, 0);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('parseFlexibleHex / hexOf', () {
    test('accepts 3 and 6 digits with or without #', () {
      expect(hexOf(parseFlexibleHex('#1565c0')!), '#1565C0');
      expect(hexOf(parseFlexibleHex('1565C0')!), '#1565C0');
      expect(hexOf(parseFlexibleHex('0a5')!), '#00AA55');
      expect(hexOf(parseFlexibleHex('#FFF')!), '#FFFFFF');
    });

    test('rejects everything else', () {
      for (final bad in [
        '',
        '#',
        '12',
        '#12345',
        '#1234567',
        'ggg',
        '#12 345',
      ]) {
        expect(parseFlexibleHex(bad), isNull, reason: bad);
      }
    });

    test('rgbOf round trips', () {
      expect(rgbOf(const Color(0xFF1565C0)), (21, 101, 192));
    });
  });

  group('dominantColors', () {
    test(
      'returns the most frequent distinct colors, ignoring white/transparent',
      () {
        final colors = dominantColors(twoColorPng());
        expect(colors.length, 2);
        expect(hexOf(colors[0]), '#FF8C00');
        expect(hexOf(colors[1]), '#1565C0');
      },
    );

    test('respects max and returns empty for undecodable data (e.g. SVG)', () {
      expect(dominantColors(twoColorPng(), max: 1).length, 1);
      expect(dominantColors(Uint8List.fromList('<svg/>'.codeUnits)), isEmpty);
    });
  });
}
