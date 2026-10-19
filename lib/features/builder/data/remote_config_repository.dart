import 'dart:typed_data';

import '../domain/config.dart';
import 'config_repository.dart';

/// STUB – NOT IMPLEMENTED.
///
/// Placeholder for the real backend (Firebase / custom API / Azure – still to
/// be decided). Implement each method against the chosen service, keeping the
/// append-only guarantee: a new version is a new document/blob, versions are
/// never overwritten, and `save` must fail with [VersionConflictException]
/// when `config.configVersion != latest + 1` (use a transaction or an
/// if-not-exists write). Assets go under `apps/{appId}/v{configVersion}/...`.
class RemoteConfigRepository implements ConfigRepository {
  const RemoteConfigRepository();

  Never _todo() => throw UnimplementedError(
    'RemoteConfigRepository is a stub; choose a backend first.',
  );

  @override
  Future<bool> isAppIdAvailable(String appId) async => _todo();

  @override
  Future<void> save(AppConfig config, Map<String, Uint8List> assets) async =>
      _todo();

  @override
  Future<AppConfig?> getLatest(String appId) async => _todo();

  @override
  Future<List<AppConfig>> listVersions(String appId) async => _todo();

  @override
  Future<AppConfig?> getVersion(String appId, int version) async => _todo();

  @override
  Future<Uint8List?> getAsset(String path) async => _todo();
}
