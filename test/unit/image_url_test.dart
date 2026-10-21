import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:swiftappbuilder/features/builder/application/image_probe.dart';
import 'package:swiftappbuilder/features/builder/application/image_url_loader.dart';
import 'package:swiftappbuilder/features/builder/domain/asset.dart';
import 'package:swiftappbuilder/features/builder/domain/asset_validator.dart';
import 'package:swiftappbuilder/features/builder/domain/image_source.dart';

import '../helpers.dart';

Uint8List jpgBytes(int w, int h) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(200, 30, 30));
  return Uint8List.fromList(img.encodeJpg(image));
}

Uint8List svgBytes(int w, int h) => Uint8List.fromList(
  '<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h"></svg>'
      .codeUnits,
);

ImageFetch serving(Uint8List bytes) =>
    (_) async => bytes;

/// What the browser's `<img>` element would report for [bytes].
ImageProbe probing(Uint8List bytes) => (url) async {
  final image = img.decodeImage(bytes);
  if (image == null) return const ProbedImage(0, 0); // svg: size unknown
  return ProbedImage(image.width, image.height);
};

/// A link the browser cannot load as an image.
Future<ProbedImage> brokenProbe(String url) =>
    Future.error(const ImageProbeException('error'));

const ownBucket = 'swift-saas-5ac3a.firebasestorage.app';
const firebaseUrl =
    'https://firebasestorage.googleapis.com/v0/b/$ownBucket/o/'
    'app_requests%2Fblkedma_req%2Flogo_1792593994316.png'
    '?alt=media&token=709a3722-3fee-4f74-93e5-df777b635897';

void main() {
  const url = 'https://example.com/assets/logo.png';

  group('parseImageUrl', () {
    test('accepts only http and https with a host', () {
      expect(parseImageUrl('https://example.com/a.png'), isNotNull);
      expect(parseImageUrl(' http://example.com/a.png '), isNotNull);
      expect(parseImageUrl('ftp://example.com/a.png'), isNull);
      expect(parseImageUrl('example.com/a.png'), isNull);
      expect(parseImageUrl('javascript:alert(1)'), isNull);
      expect(parseImageUrl(''), isNull);
    });

    test('query strings and missing extensions are fine', () {
      expect(parseImageUrl(firebaseUrl), isNotNull);
      expect(parseImageUrl('https://cdn.example.com/image/123'), isNotNull);
    });
  });

  group('isOwnStorageUrl', () {
    test('matches our bucket only', () {
      expect(isOwnStorageUrl(Uri.parse(firebaseUrl), [ownBucket]), isTrue);
      expect(
        isOwnStorageUrl(Uri.parse(firebaseUrl), ['other-project.appspot.com']),
        isFalse,
      );
      expect(
        isOwnStorageUrl(Uri.parse('https://example.com/o/x.png'), [ownBucket]),
        isFalse,
      );
    });
  });

  group('sniffImage', () {
    test('recognizes formats by content, not by extension', () {
      expect(sniffImage(pngBytes(8, 8)), ImageFormat.png);
      expect(sniffImage(jpgBytes(8, 8)), ImageFormat.jpg);
      expect(sniffImage(svgBytes(8, 8)), ImageFormat.svg);
      expect(sniffImage(Uint8List.fromList('<html></html>'.codeUnits)), isNull);
    });
  });

  group('loadImageFromUrl', () {
    test(
      'our own Firebase Storage link is accepted as is, untouched',
      () async {
        var downloaded = false;
        final r = await loadImageFromUrl(
          '  $firebaseUrl  ',
          AssetKind.logo,
          (_) async {
            downloaded = true;
            return Uint8List(0);
          },
          probe: (u) async {
            // The browser gets the link exactly as entered: %2F stays %2F.
            expect(u, firebaseUrl);
            return const ProbedImage(1024, 1024);
          },
          ownBuckets: [ownBucket],
        );
        expect(downloaded, isFalse, reason: 'no download, no re-upload');
        expect(r.asset, isNotNull);
        expect(r.asset!.isRemote, isTrue);
        expect(r.asset!.sourceUrl, firebaseUrl);
        expect(r.asset!.name, 'logo_1792593994316.png');
        expect(r.asset!.width, 1024);
      },
    );

    test('logo: PNG on another host is copied like an upload', () async {
      final bytes = pngBytes(600, 600);
      final r = await loadImageFromUrl(
        url,
        AssetKind.logo,
        serving(bytes),
        probe: probing(bytes),
      );
      expect(r.asset!.extension, 'png');
      expect(r.asset!.name, 'logo.png');
      expect(r.asset!.sourceUrl, url);
      expect(r.asset!.isRemote, isFalse);
    });

    test('an URL without an extension works (content decides)', () async {
      final bytes = pngBytes(600, 600);
      final r = await loadImageFromUrl(
        'https://cdn.example.com/image/123?w=600',
        AssetKind.logo,
        serving(bytes),
        probe: probing(bytes),
      );
      expect(r.asset, isNotNull);
      expect(r.asset!.name, '123.png');
    });

    test('logo: JPG is converted to PNG', () async {
      final bytes = jpgBytes(600, 600);
      final r = await loadImageFromUrl(
        'https://example.com/photo.jpeg',
        AssetKind.logo,
        serving(bytes),
        probe: probing(bytes),
      );
      expect(r.asset!.extension, 'png');
      expect(r.asset!.name, 'photo.png');
      expect(sniffImage(r.asset!.bytes), ImageFormat.png);
    });

    test('logo: SVG is kept as SVG', () async {
      final bytes = svgBytes(600, 600);
      final r = await loadImageFromUrl(
        'https://example.com/logo.svg',
        AssetKind.logo,
        serving(bytes),
        probe: probing(bytes),
      );
      expect(r.asset!.isSvg, isTrue);
    });

    test('wrong dimensions report the actual size', () async {
      final small = pngBytes(100, 100);
      final tooSmall = await loadImageFromUrl(
        url,
        AssetKind.logo,
        serving(small),
        probe: probing(small),
      );
      expect(tooSmall.asset, isNull);
      expect(tooSmall.issue, AssetIssue.tooSmall);
      expect((tooSmall.width, tooSmall.height), (100, 100));

      final half = pngBytes(512, 512);
      final wrongIcon = await loadImageFromUrl(
        url,
        AssetKind.appIcon,
        serving(half),
        probe: probing(half),
      );
      expect(wrongIcon.issue, AssetIssue.wrongSize);
      expect((wrongIcon.width, wrongIcon.height), (512, 512));

      final ok = pngBytes(AssetValidator.iconSide, AssetValidator.iconSide);
      final icon = await loadImageFromUrl(
        url,
        AssetKind.appIcon,
        serving(ok),
        probe: probing(ok),
      );
      expect(icon.asset, isNotNull);
    });

    test(
      'a bad link, a broken image and a non-image fail differently',
      () async {
        final bytes = pngBytes(600, 600);
        final invalid = await loadImageFromUrl(
          'not a url',
          AssetKind.logo,
          serving(bytes),
          probe: probing(bytes),
        );
        expect(invalid.failure, UrlFailure.invalid);

        final broken = await loadImageFromUrl(
          'https://example.com/missing.png',
          AssetKind.logo,
          serving(bytes),
          probe: brokenProbe,
        );
        expect(broken.failure, UrlFailure.unreachable);

        // A page that is not an image never loads in an <img> element.
        final page = await loadImageFromUrl(
          'https://example.com/index.html',
          AssetKind.logo,
          serving(Uint8List.fromList('<html>hi</html>'.codeUnits)),
          probe: brokenProbe,
        );
        expect(page.failure, UrlFailure.unreachable);
      },
    );

    test(
      'another host that loads but blocks reading asks for an upload',
      () async {
        final bytes = pngBytes(600, 600);
        final r = await loadImageFromUrl(
          url,
          AssetKind.logo,
          (_) async => throw StateError('CORS'),
          probe: probing(bytes),
        );
        expect(r.failure, UrlFailure.notCopyable);
      },
    );
  });
}
