import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/asset.dart';
import '../domain/asset_validator.dart';
import '../domain/image_source.dart';
import 'image_probe.dart';

/// Downloads the bytes behind [url]. Throws when it cannot be fetched (for
/// example when the host sends no CORS headers). Replaceable in tests, and by
/// a server-side fetcher once there is a backend.
typedef ImageFetch = Future<Uint8List> Function(Uri url);

/// Upper bound for a downloaded file; larger files are rejected up front.
const maxDownloadBytes = 12 * 1024 * 1024;

Future<Uint8List> defaultImageFetch(Uri url) async {
  final response = await http.get(url).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode}');
  }
  if (response.bodyBytes.length > maxDownloadBytes) {
    throw StateError('too large');
  }
  return response.bodyBytes;
}

/// Parses [raw] as an http/https URL, or returns null. The caller keeps using
/// the string exactly as typed: this is only a format check.
Uri? parseImageUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

/// True when [uri] points into our own Firebase Storage bucket(s).
bool isOwnStorageUrl(Uri uri, Iterable<String> buckets) {
  for (final bucket in buckets) {
    if (bucket.isEmpty) continue;
    if (uri.host == 'firebasestorage.googleapis.com' &&
        uri.path.startsWith('/v0/b/$bucket/')) {
      return true;
    }
    if (uri.host == 'storage.googleapis.com' &&
        uri.path.startsWith('/$bucket/')) {
      return true;
    }
  }
  return false;
}

bool _meetsSize(AssetKind kind, int w, int h) => kind == AssetKind.appIcon
    ? (w == AssetValidator.iconSide && h == AssetValidator.iconSide)
    : (w >= AssetValidator.minLogoSide && h >= AssetValidator.minLogoSide);

/// Loads an image from a URL with the same rules as an uploaded file.
///
/// 1. The link is only trimmed, never decoded or rebuilt (`%2F` stays).
/// 2. It is checked by loading it in the browser ([probe], an `<img>` element:
///    no fetch/HEAD, which public hosts without CORS headers refuse). That also
///    gives its natural size for the dimension rules.
/// 3. Images in our own storage are kept as they are: no download, no
///    re-upload, the URL is the stored reference.
/// 4. Any other host must allow reading its bytes so a copy can be stored like
///    an uploaded file; otherwise the user is asked to upload the file.
Future<UrlImageResult> loadImageFromUrl(
  String raw,
  AssetKind kind,
  ImageFetch fetch, {
  required ImageProbe probe,
  Iterable<String> ownBuckets = const [],
}) async {
  final url = raw.trim();
  final uri = parseImageUrl(url);
  if (uri == null) return const UrlImageResult.failure(UrlFailure.invalid);

  final ProbedImage size;
  try {
    size = await probe(url);
  } catch (_) {
    return const UrlImageResult.failure(UrlFailure.unreachable);
  }
  // SVGs may report no size: the byte check below covers them.
  final known = size.width > 0 && size.height > 0;
  if (known && !_meetsSize(kind, size.width, size.height)) {
    return UrlImageResult.issue(
      kind == AssetKind.appIcon ? AssetIssue.wrongSize : AssetIssue.tooSmall,
      width: size.width,
      height: size.height,
    );
  }

  final decodedPath = Uri.decodeFull(uri.path);
  final last = decodedPath.split('/').where((p) => p.isNotEmpty).lastOrNull;
  final name = (last == null || last.isEmpty) ? 'image' : last;
  final dot = name.lastIndexOf('.');
  final stem = dot > 0 ? name.substring(0, dot) : name;
  final pathExt = dot > 0 ? name.substring(dot + 1).toLowerCase() : '';

  if (isOwnStorageUrl(uri, ownBuckets)) {
    if (kind == AssetKind.appIcon && pathExt == 'svg') {
      return const UrlImageResult.issue(AssetIssue.wrongType);
    }
    return UrlImageResult.ok(
      PickedAsset(
        name: name,
        bytes: Uint8List(0),
        extension: pathExt == 'svg' ? 'svg' : 'png',
        width: known ? size.width : null,
        height: known ? size.height : null,
        sourceUrl: url,
      ),
    );
  }

  final Uint8List bytes;
  try {
    bytes = await fetch(uri);
  } catch (_) {
    return const UrlImageResult.failure(UrlFailure.notCopyable);
  }
  if (bytes.isEmpty) {
    return const UrlImageResult.failure(UrlFailure.notCopyable);
  }
  final format = sniffImage(bytes);
  if (format == null) {
    return const UrlImageResult.failure(UrlFailure.unsupported);
  }
  return assetFromDownload(
    bytes: bytes,
    format: format,
    baseName: stem.isEmpty ? 'image' : stem,
    kind: kind,
    sourceUrl: url,
  );
}
