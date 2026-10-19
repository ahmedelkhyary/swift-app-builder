import 'dart:typed_data';

import '../domain/config.dart';

/// Thrown when saving a version that is not exactly latest + 1.
class VersionConflictException implements Exception {
  VersionConflictException(this.appId, this.expected, this.actual);
  final String appId;
  final int expected;
  final int actual;

  @override
  String toString() =>
      'VersionConflictException: $appId expected v$expected but got v$actual';
}

/// Append-only store of immutable config versions and their assets.
///
/// Every `save` creates a new version; existing versions are never modified.
abstract class ConfigRepository {
  /// True when no config exists yet for [appId].
  Future<bool> isAppIdAvailable(String appId);

  /// Stores [config] (whose `configVersion` must equal latest + 1) together
  /// with [assets] at the paths the config references.
  ///
  /// [assets] maps each storage path (e.g. `apps/x/v1/logo.png`) to its bytes.
  Future<void> save(AppConfig config, Map<String, Uint8List> assets);

  Future<AppConfig?> getLatest(String appId);

  /// All versions, oldest first.
  Future<List<AppConfig>> listVersions(String appId);

  Future<AppConfig?> getVersion(String appId, int version);

  /// Bytes of a stored asset, or null when unknown.
  Future<Uint8List?> getAsset(String path);
}

/// Convenience used by the service layer.
extension ConfigRepositoryX on ConfigRepository {
  Future<int> nextVersion(String appId) async =>
      ((await getLatest(appId))?.configVersion ?? 0) + 1;
}
