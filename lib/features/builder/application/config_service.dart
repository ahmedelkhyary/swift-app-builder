import 'dart:typed_data';

import 'package:recruitment_ui/recruitment_ui.dart' show AppTemplate;

import '../data/config_repository.dart';
import '../domain/asset.dart';
import '../domain/config.dart';
import '../domain/draft.dart';
import 'schema_validator.dart';

/// A config ready to be saved, plus the asset bytes it references.
class PreparedConfig {
  const PreparedConfig(this.config, this.assets, this.schemaErrors);
  final AppConfig config;

  /// storage path -> bytes
  final Map<String, Uint8List> assets;
  final List<String> schemaErrors;
  bool get isValid => schemaErrors.isEmpty;
}

class ConfigService {
  ConfigService(this._repo, this._schema, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ConfigRepository _repo;
  final ConfigSchemaValidator _schema;
  final DateTime Function() _now;

  /// Version a save would create right now: latest + 1 (1 for new apps).
  Future<int> nextVersion(String appId) => _repo.nextVersion(appId);

  /// Builds the config and asset map for [draft] without saving.
  /// The draft must contain a logo and an app icon.
  Future<PreparedConfig> prepare(
    AppConfigDraft draft, {
    required String updatedBy,
  }) async {
    final logo = draft.logo;
    final icon = draft.appIcon;
    if (logo == null || icon == null) {
      throw StateError('Logo and app icon are required');
    }
    final latest = await _repo.getLatest(draft.appId);
    final version = (latest?.configVersion ?? 0) + 1;
    final now = _now();

    final logoPath = AssetPaths.forKind(
      draft.appId,
      version,
      AssetKind.logo,
      logo.extension,
    );
    final iconPath = AssetPaths.forKind(
      draft.appId,
      version,
      AssetKind.appIcon,
      icon.extension,
    );
    final splash = draft.splashLogo;
    final splashPath = splash == null
        ? logoPath
        : AssetPaths.forKind(
            draft.appId,
            version,
            AssetKind.splashLogo,
            splash.extension,
          );

    final config = AppConfig(
      appId: draft.appId,
      configVersion: version,
      clientName: draft.clientName.trim(),
      clientEmail: draft.clientEmail.trim(),
      clientPhone: draft.clientPhone.trim(),
      supportEmails: List.unmodifiable(draft.supportEmails),
      appNameAr: draft.nameAr.trim(),
      appNameEn: draft.nameEn.trim(),
      androidPackage: draft.androidPackage.trim(),
      iosBundleId: draft.effectiveIosBundleId.trim(),
      templateId: draft.templateId,
      templateVersion: AppTemplate.version,
      modules: List.unmodifiable(
        kModuleIds.where(draft.enabledModules.contains),
      ),
      primaryColor: draft.primaryHex.toUpperCase(),
      secondaryColor: draft.secondaryHex.toUpperCase(),
      fontFamily: draft.fontFamily,
      logoPath: logoPath,
      appIconPath: iconPath,
      splashBackgroundColor: draft.splashHex.toUpperCase(),
      splashLogoPath: splashPath,
      defaultLanguage: draft.defaultLanguage,
      supportedLanguages: List.unmodifiable(draft.supportedLanguages),
      createdAt: latest?.createdAt ?? now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
    final assets = <String, Uint8List>{
      logoPath: logo.bytes,
      iconPath: icon.bytes,
      if (splash != null) splashPath: splash.bytes,
    };
    return PreparedConfig(config, assets, _schema.validate(config.toJson()));
  }

  /// Validates against the JSON Schema and appends a new immutable version.
  /// Throws [StateError] listing schema errors, or [VersionConflictException].
  Future<AppConfig> save(
    AppConfigDraft draft, {
    required String updatedBy,
  }) async {
    final prepared = await prepare(draft, updatedBy: updatedBy);
    if (!prepared.isValid) {
      throw StateError(
        'Config failed schema validation:\n'
        '${prepared.schemaErrors.join('\n')}',
      );
    }
    await _repo.save(prepared.config, prepared.assets);
    return prepared.config;
  }

  /// Loads the stored asset bytes of [config] into a draft ("restore this
  /// version as new draft").
  Future<AppConfigDraft> draftFromStored(AppConfig config) async {
    Future<PickedAsset?> load(String path) async {
      final bytes = await _repo.getAsset(path);
      if (bytes == null) return null;
      final name = path.split('/').last;
      final ext = name.contains('.') ? name.split('.').last : 'png';
      return PickedAsset(name: name, bytes: bytes, extension: ext);
    }

    return AppConfigDraft.fromConfig(
      config,
      logo: await load(config.logoPath),
      appIcon: await load(config.appIconPath),
      splashLogo: await load(config.splashLogoPath),
    );
  }
}
