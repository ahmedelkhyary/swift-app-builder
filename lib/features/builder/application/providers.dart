import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../data/config_repository.dart';
import '../data/app_id_checker.dart';
import '../data/firebase_request_submitter.dart';
import '../data/in_memory_config_repository.dart';
import '../data/request_submitter.dart';
import '../domain/asset.dart';
import '../../../firebase_options.dart';
import 'image_probe.dart';
import 'image_url_loader.dart';
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
      iosBundleId: pkg != null && state.iosSameAsAndroid
          ? mirrorBundleId(pkg)
          : null,
    );
  }

  void setAppId(String v) =>
      state = state.copyWith(appId: normalizeAppId(v), appIdEdited: true);

  void regenerateAppId() => state = state.copyWith(
    appId: slugifyAppId(state.nameEn),
    appIdEdited: false,
  );

  void setAndroidPackage(String v) => state = state.copyWith(
    androidPackage: v,
    packageEdited: true,
    iosBundleId: state.iosSameAsAndroid ? mirrorBundleId(v) : null,
  );

  /// Checked: iOS follows Android. Unchecked: iOS becomes editable on its own,
  /// starting from the value it has now.
  void setIosSameAsAndroid(bool v) => state = state.copyWith(
    iosSameAsAndroid: v,
    iosBundleId: mirrorBundleId(state.androidPackage),
  );

  void setIosBundleId(String v) => state = state.copyWith(iosBundleId: v);

  void setClientName(String v) => state = state.copyWith(clientName: v);
  void setClientEmail(String v) => state = state.copyWith(clientEmail: v);
  void setClientPhone(String v) => state = state.copyWith(clientPhone: v);
  void setSupportEmails(List<String> v) =>
      state = state.copyWith(supportEmails: List.unmodifiable(v));

  void setPrimary(String hex) => state = state.copyWith(primaryHex: hex);
  void setSecondary(String hex) => state = state.copyWith(secondaryHex: hex);
  void setAccent(String hex) => state = state.copyWith(accentHex: hex);

  /// An empty value goes back to the template's own page / text color.
  void setBackground(String hex) => state = state.copyWith(backgroundHex: hex);
  void setText(String hex) => state = state.copyWith(textHex: hex);

  /// Applies a ready-made palette (primary, secondary and accent together).
  void setPalette(String primary, String secondary, String accent) =>
      state = state.copyWith(
        primaryHex: primary,
        secondaryHex: secondary,
        accentHex: accent,
      );

  /// Back to the template defaults: default brand colors, no page / text
  /// override, white splash.
  void resetColors() => state = state.copyWith(
    primaryHex: kDefaultPrimaryHex,
    secondaryHex: kDefaultSecondaryHex,
    accentHex: kDefaultAccentHex,
    backgroundHex: '',
    textHex: '',
    splashHex: '#FFFFFF',
  );
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

/// Backend check of App IDs. Replaced in tests.
final appIdCheckerProvider = Provider<AppIdChecker>(
  (ref) => FirestoreAppIdChecker(),
);

/// How long typing must pause before the App ID is checked.
final appIdDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 500),
);

/// IDs found to be taken during a submit (someone else got them first). They
/// stay unavailable even if an earlier check said otherwise.
final appIdTakenProvider = StateProvider<Set<String>>((ref) => const {});

/// Whether [appId] (already normalized) is free in the backend. A malformed
/// ID is not asked about: the format error is shown instead.
///
/// The provider is per ID and auto-disposed, so when the user keeps typing the
/// previous check is cancelled and its result can never be applied.
final appIdAvailabilityProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, appId) async {
      if (appId.isEmpty || !Validators.appIdRegex.hasMatch(appId)) return true;
      if (ref.watch(appIdTakenProvider).contains(appId)) return false;
      var disposed = false;
      ref.onDispose(() => disposed = true);
      final debounce = ref.read(appIdDebounceProvider);
      if (debounce > Duration.zero) await Future<void>.delayed(debounce);
      if (disposed) return true; // outdated: nobody is listening anymore
      return ref.read(appIdCheckerProvider).isAvailable(appId);
    });

/// Up to three alternatives to a taken [appId] that were checked and are free.
final appIdSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, appId) async {
      final checker = ref.read(appIdCheckerProvider);
      final taken = ref.read(appIdTakenProvider);
      final candidates = <String>[];
      for (final suffix in ['-app', '-2', '-3', '-4']) {
        final base = appId.length > 30 - suffix.length
            ? appId.substring(0, 30 - suffix.length)
            : appId;
        final c = '$base$suffix';
        if (Validators.appIdRegex.hasMatch(c) && !taken.contains(c)) {
          candidates.add(c);
        }
      }
      final free = <String>[];
      for (final c in candidates) {
        if (free.length == 3) break;
        try {
          if (await checker.isAvailable(c)) free.add(c);
        } on AppIdCheckException {
          break; // offline: no suggestions rather than unchecked ones
        }
      }
      return free;
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
  // Checked for loaded drafts too: an ID that is already requested is taken.
  if (needsAppId) {
    final available = ref.watch(appIdAvailabilityProvider(draft.appId));
    return available.valueOrNull == true;
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

/// The config (and schema errors) the request would contain right now.
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

/// Where a brand image comes from. UI-only; the choice is remembered while
/// the user moves between steps.
enum AssetSource { file, url }

final assetSourceProvider = StateProvider.family<AssetSource?, AssetKind>(
  (ref, kind) => null,
);

/// Downloads images added by URL. Replaced in tests.
final imageFetchProvider = Provider<ImageFetch>((ref) => defaultImageFetch);

/// Checks that an image URL really loads and reads its size (browser `<img>`).
final imageProbeProvider = Provider<ImageProbe>((ref) => probeImageElement);

/// Storage buckets of this project: images in them are kept as they are.
final ownStorageBucketsProvider = Provider<List<String>>(
  (ref) => [
    DefaultFirebaseOptions.web.storageBucket!,
    '${DefaultFirebaseOptions.web.projectId}.appspot.com',
  ],
);

/// Template shown by the full-size preview page. It is only applied to the
/// draft when the user presses "Use this template"; null means the draft's.
final previewTemplateProvider = StateProvider<String?>((ref) => null);

/// UI-only state of step 4: the templates ticked in the grid, the one shown in
/// the preview panel and whether the compare view is open. It is never saved
/// and is dropped when the user leaves step 4 (so coming back shows just the
/// final template selected).
class TemplatePick {
  const TemplatePick({
    required this.selected,
    required this.preview,
    this.comparing = false,
  });

  /// Ordered by when each template was ticked.
  final List<String> selected;

  /// The template most recently clicked.
  final String preview;
  final bool comparing;

  TemplatePick copyWith({
    List<String>? selected,
    String? preview,
    bool? comparing,
  }) => TemplatePick(
    selected: selected ?? this.selected,
    preview: preview ?? this.preview,
    comparing: comparing ?? this.comparing,
  );
}

final templatePickProvider =
    NotifierProvider.autoDispose<TemplatePickController, TemplatePick>(
      TemplatePickController.new,
    );

class TemplatePickController extends AutoDisposeNotifier<TemplatePick> {
  @override
  TemplatePick build() {
    final id = ref.read(draftProvider).templateId;
    return TemplatePick(selected: [id], preview: id);
  }

  /// Ticks / unticks [id]. With exactly one template left it becomes the
  /// final choice, exactly like the old single-select behavior.
  void toggle(String id) {
    final selected = [...state.selected];
    var preview = state.preview;
    if (selected.remove(id)) {
      if (preview == id && selected.isNotEmpty) preview = selected.last;
    } else {
      selected.add(id);
      preview = id;
    }
    state = state.copyWith(selected: selected, preview: preview);
    if (selected.length == 1) {
      ref.read(draftProvider.notifier).setTemplate(selected.single);
    }
  }

  void openCompare() {
    if (state.selected.length >= 2) state = state.copyWith(comparing: true);
  }

  void closeCompare() => state = state.copyWith(comparing: false);
}

/// Sends the finished wizard to the backend. Replaced in tests.
final requestSubmitterProvider = Provider<RequestSubmitter>(
  (ref) => FirebaseRequestSubmitter(),
);

enum SubmitStatus { idle, submitting, error }

class SubmitState {
  const SubmitState({this.status = SubmitStatus.idle, this.error});
  final SubmitStatus status;
  final SubmitErrorKind? error;

  bool get submitting => status == SubmitStatus.submitting;
}

final submitProvider = NotifierProvider<SubmitController, SubmitState>(
  SubmitController.new,
);

class SubmitController extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState();

  /// Submits the current draft. Returns null on failure (see [state]); the
  /// draft is never touched, so the user can retry with everything filled in.
  Future<SubmitResult?> submit() async {
    if (state.submitting) return null; // no double submissions
    state = const SubmitState(status: SubmitStatus.submitting);
    try {
      final result = await ref
          .read(requestSubmitterProvider)
          .submit(ref.read(draftProvider));
      state = const SubmitState();
      return result;
    } on SubmitException catch (e) {
      state = SubmitState(status: SubmitStatus.error, error: e.kind);
    } catch (_) {
      state = const SubmitState(
        status: SubmitStatus.error,
        error: SubmitErrorKind.unknown,
      );
    }
    return null;
  }

  void clearError() => state = const SubmitState();
}
