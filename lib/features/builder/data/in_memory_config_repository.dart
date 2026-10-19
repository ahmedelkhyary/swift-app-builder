import 'dart:typed_data';

import '../domain/config.dart';
import 'config_repository.dart';

/// Process-local implementation. Data is lost on reload.
class InMemoryConfigRepository implements ConfigRepository {
  final Map<String, List<AppConfig>> _versions = {};
  final Map<String, Uint8List> _assets = {};

  @override
  Future<bool> isAppIdAvailable(String appId) async =>
      !(_versions[appId]?.isNotEmpty ?? false);

  @override
  Future<void> save(AppConfig config, Map<String, Uint8List> assets) async {
    final list = _versions.putIfAbsent(config.appId, () => []);
    final expected = list.length + 1;
    if (config.configVersion != expected) {
      throw VersionConflictException(
        config.appId,
        expected,
        config.configVersion,
      );
    }
    list.add(config);
    _assets.addAll({
      for (final e in assets.entries) e.key: Uint8List.fromList(e.value),
    });
  }

  @override
  Future<AppConfig?> getLatest(String appId) async {
    final list = _versions[appId];
    return (list == null || list.isEmpty) ? null : list.last;
  }

  @override
  Future<List<AppConfig>> listVersions(String appId) async =>
      List.unmodifiable(_versions[appId] ?? const <AppConfig>[]);

  @override
  Future<AppConfig?> getVersion(String appId, int version) async {
    final list = _versions[appId];
    if (list == null || version < 1 || version > list.length) return null;
    return list[version - 1];
  }

  @override
  Future<Uint8List?> getAsset(String path) async => _assets[path];
}
