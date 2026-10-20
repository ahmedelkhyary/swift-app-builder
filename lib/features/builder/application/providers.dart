import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../data/config_repository.dart';
import '../data/in_memory_config_repository.dart';
import '../domain/asset.dart';
import '../domain/config.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'config_service.dart';
import 'schema_validator.dart';

/// Swap this override to plug in the real backend.
final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => InMemoryConfigRepository(),
);

/// Loaded once at startup (see main.dart) via an override.
final schemaValidatorProvider = Provider<ConfigSchemaValidator>(
  (ref) => throw UnimplementedError('schemaValidatorProvider not overridden'),
);

final currentUserProvider = Provider<String>((ref) => 'app-builder-web');

final configServiceProvider = Provider<ConfigService>(
  (ref) => ConfigService(
    ref.watch(configRepositoryProvider),
    ref.watch(schemaValidatorProvider),
  ),
);

/// The single source of truth for the wizard form.
final draftProvider = NotifierProvider<DraftController, AppConfigDraft>(
  DraftController.new,
);

class DraftController extends Notifier<AppConfigDraft> {
  @override
  AppConfigDraft build() => const AppConfigDraft();

  void replace(AppConfigDraft draft) => state = draft;

  void reset() => state = const AppConfigDraft();

  void setNameAr(String v) => state = state.copyWith(nameAr: v);

  void setNameEn(String v) {
    final pkg = state.packageEdited || state.existingApp
        ? null
        : suggestPackage(v);
    state = state.copyWith(
      nameEn: v,
      appId: state.appIdEdited || state.existingApp ? null : slugifyAppId(v),
      androidPackage: pkg,
      iosBundleId: pkg != null && state.iosSameAsAndroid ? pkg : null,
    );
  }

  void setAppId(String v) =>
      state = state.copyWith(appId: v.toLowerCase(), appIdEdited: true);

  void regenerateAppId() => state = state.copyWith(
    appId: slugifyAppId(state.nameEn),
    appIdEdited: false,
  );

  void setAndroidPackage(String v) => state = state.copyWith(
    androidPackage: v,
    packageEdited: true,
    iosBundleId: state.iosSameAsAndroid ? v : null,
  );

  void setIosSameAsAndroid(bool v) => state = state.copyWith(
    iosSameAsAndroid: v,
    iosBundleId: v ? state.androidPackage : null,
  );

  void setIosBundleId(String v) => state = state.copyWith(iosBundleId: v);

  void setClientName(String v) => state = state.copyWith(clientName: v);
  void setClientEmail(String v) => state = state.copyWith(clientEmail: v);
  void setClientPhone(String v) => state = state.copyWith(clientPhone: v);

  void setPrimary(String hex) => state = state.copyWith(primaryHex: hex);
  void setSecondary(String hex) => state = state.copyWith(secondaryHex: hex);
  void setSplashColor(String hex) => state = state.copyWith(splashHex: hex);
  void setFont(String family) => state = state.copyWith(fontFamily: family);

  void setAsset(AssetKind kind, PickedAsset? asset) {
    state = switch (kind) {
      AssetKind.logo =>
        asset == null
            ? state.copyWith(clearLogo: true)
            : state.copyWith(logo: asset),
      AssetKind.appIcon =>
        asset == null
            ? state.copyWith(clearAppIcon: true)
            : state.copyWith(appIcon: asset),
      AssetKind.splashLogo =>
        asset == null
            ? state.copyWith(clearSplashLogo: true)
            : state.copyWith(splashLogo: asset),
    };
  }

  void setDefaultLanguage(String code) {
    final langs = state.supportedLanguages.contains(code)
        ? state.supportedLanguages
        : [...state.supportedLanguages, code];
    state = state.copyWith(defaultLanguage: code, supportedLanguages: langs);
  }

  /// Toggles a supported language; the default language cannot be removed.
  void toggleLanguage(String code, bool enabled) {
    if (!enabled && code == state.defaultLanguage) return;
    final set = {...state.supportedLanguages};
    enabled ? set.add(code) : set.remove(code);
    state = state.copyWith(
      supportedLanguages: kSupportedLanguageCodes
          .where(set.contains)
          .toList(growable: false),
    );
  }

  void setTemplate(String id) => state = state.copyWith(templateId: id);

  void setModule(String id, bool enabled) {
    final set = {...state.enabledModules};
    enabled ? set.add(id) : set.remove(id);
    state = state.copyWith(
      enabledModules: kModuleIds.where(set.contains).toList(growable: false),
    );
  }
}

/// Whether [appId] is free. Loaded drafts (existing apps) are always fine.
final appIdAvailabilityProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, appId) async {
      if (appId.isEmpty) return true;
      return ref.watch(configRepositoryProvider).isAppIdAvailable(appId);
    });

/// True when every field of [section] is valid, including async appId check.
final sectionValidProvider = Provider.autoDispose.family<bool, WizardSection>((
  ref,
  section,
) {
  final draft = ref.watch(draftProvider);
  if (!DraftValidator.isSectionValid(draft, section)) return false;
  final needsAppId =
      section == WizardSection.info || section == WizardSection.summary;
  if (needsAppId && !draft.existingApp) {
    final available = ref.watch(appIdAvailabilityProvider(draft.appId));
    return available.value == true;
  }
  return true;
});

/// Sections are reachable only when all earlier ones are valid.
final sectionEnabledProvider = Provider.autoDispose.family<bool, WizardSection>(
  (ref, section) {
    for (final s in WizardSection.values) {
      if (s == section) return true;
      if (!ref.watch(sectionValidProvider(s))) return false;
    }
    return true;
  },
);

/// Branding for the live preview.
final brandingProvider = Provider.autoDispose<BrandingConfig>(
  (ref) => ref.watch(draftProvider).branding,
);

/// Versions already stored for the draft's app (newest last).
final versionHistoryProvider = FutureProvider.autoDispose<List<AppConfig>>((
  ref,
) {
  final id = ref.watch(draftProvider.select((d) => d.appId));
  if (id.isEmpty) return const <AppConfig>[];
  return ref.watch(configRepositoryProvider).listVersions(id);
});

/// The config (and schema errors) that "Save" would produce right now.
final preparedConfigProvider = FutureProvider.autoDispose<PreparedConfig?>((
  ref,
) async {
  final draft = ref.watch(draftProvider);
  if (DraftValidator.firstInvalid(draft) != null) return null;
  return ref
      .watch(configServiceProvider)
      .prepare(draft, updatedBy: ref.watch(currentUserProvider));
});

/// Mock backend of the interactive preview. Swapped in tests (zero latency).
final demoRepositoryProvider = Provider<DemoRepository>(
  (ref) => MockDemoRepository(),
);

/// One preview session for the whole builder: it keeps the customer's
/// progress while they switch templates, language or theme. Enabled modules
/// follow the draft.
final demoSessionProvider = Provider<DemoSession>((ref) {
  final session = DemoSession(repository: ref.watch(demoRepositoryProvider));
  ref.listen<List<String>>(
    draftProvider.select((d) => d.enabledModules),
    (_, ids) => session.setEnabledModules({
      for (final m in ServiceModule.values)
        if (ids.contains(m.name)) m,
    }),
    fireImmediately: true,
  );
  ref.onDispose(session.dispose);
  return session;
});
