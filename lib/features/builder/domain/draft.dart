import 'package:flutter/painting.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import 'asset.dart';
import 'config.dart';
import 'payments.dart';

const kDefaultPrimaryHex = '#213F80';
const kDefaultSecondaryHex = '#29ABE2';
const kDefaultAccentHex = '#2E9E5B';

/// The fixed reverse-DNS prefix of every package name. Change it here only:
/// the field, the validation, saved data and loading all use this constant.
const kPackagePrefix = 'com.excp.';

/// The iOS bundle ID that mirrors an Android package: iOS does not allow
/// underscores, so every "_" becomes "-" (`com.excp.my_app` -> `com.excp.my-app`).
String mirrorBundleId(String androidPackage) =>
    '$kPackagePrefix${packageSuffix(androidPackage).replaceAll('_', '-')}';

/// Forces a saved bundle ID under [kPackagePrefix] in iOS form (lowercase, no
/// underscores). Another prefix is replaced and only its last part is kept.
String normalizeBundleId(String bundleId) {
  final b = bundleId.trim().toLowerCase().replaceAll('_', '-');
  if (b.isEmpty) return kPackagePrefix;
  if (b.startsWith(kPackagePrefix)) return b;
  final last = b.contains('.') ? b.substring(b.lastIndexOf('.') + 1) : b;
  return '$kPackagePrefix$last';
}

/// The editable part of [package] (everything after [kPackagePrefix]).
String packageSuffix(String package) => package.startsWith(kPackagePrefix)
    ? package.substring(kPackagePrefix.length)
    : package;

/// Forces [package] under [kPackagePrefix]. A value with another prefix
/// (for example data saved before the prefix was fixed) keeps only its last
/// part: `com.example.swift` becomes `com.excp.swift`.
String normalizePackage(String package) {
  final p = package.trim().toLowerCase();
  if (p.isEmpty) return kPackagePrefix;
  if (p.startsWith(kPackagePrefix)) return p;
  final last = p.contains('.') ? p.substring(p.lastIndexOf('.') + 1) : p;
  return '$kPackagePrefix$last';
}

const kSupportedLanguageCodes = ['ar', 'en'];
const kModuleIds = ['individuals', 'hourly', 'mediation'];
const kFontFamilies = ['Cairo', 'Tajawal', 'Almarai', 'IBM Plex Sans Arabic'];

/// Immutable form state for the whole wizard.
class AppConfigDraft {
  const AppConfigDraft({
    this.appId = '',
    this.appIdEdited = false,
    this.existingApp = false,
    this.nameAr = '',
    this.nameEn = '',
    this.androidPackage = kPackagePrefix,
    this.packageEdited = false,
    this.iosBundleId = '',
    this.iosSameAsAndroid = true,
    this.clientName = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.supportEmails = const [],
    this.primaryHex = kDefaultPrimaryHex,
    this.secondaryHex = kDefaultSecondaryHex,
    this.accentHex = kDefaultAccentHex,
    this.backgroundHex = '',
    this.textHex = '',
    this.fontFamily = 'Cairo',
    this.logo,
    this.appIcon,
    this.splashHex = '#FFFFFF',
    this.splashLogo,
    this.defaultLanguage = 'ar',
    this.supportedLanguages = const ['ar', 'en'],
    this.templateId = 'simple',
    this.enabledModules = kModuleIds,
    this.payments = const PaymentsDraft(),
  });

  /// Slug identifying the app across versions.
  final String appId;

  /// True once the user edited [appId] by hand (stops auto-generation).
  final bool appIdEdited;

  /// True when the draft was loaded from a saved config (appId already exists).
  final bool existingApp;

  final String nameAr;
  final String nameEn;
  final String androidPackage;

  /// True once the user edited the package by hand (stops auto-generation).
  final bool packageEdited;
  final String iosBundleId;
  final bool iosSameAsAndroid;
  final String clientName;
  final String clientEmail;
  final String clientPhone;

  /// Optional additional support addresses (each already validated).
  final List<String> supportEmails;
  final String primaryHex;
  final String secondaryHex;

  /// Links, success states and selected items.
  final String accentHex;

  /// Optional page / text colors; empty means the template's own default.
  final String backgroundHex;
  final String textHex;
  final String fontFamily;
  final PickedAsset? logo;
  final PickedAsset? appIcon;
  final String splashHex;

  /// Optional; the main logo is used when null.
  final PickedAsset? splashLogo;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final String templateId;

  /// Service modules the generated app includes.
  final List<String> enabledModules;

  /// The "Payment methods" step. Holds the secret keys too, so it is only
  /// ever serialized through [PaymentsDraft.toJson] (no secrets).
  final PaymentsDraft payments;

  Color get primaryColor =>
      parseHexColor(primaryHex) ?? parseHexColor(kDefaultPrimaryHex)!;
  Color get secondaryColor =>
      parseHexColor(secondaryHex) ?? parseHexColor(kDefaultSecondaryHex)!;
  Color get accentColor =>
      parseHexColor(accentHex) ?? parseHexColor(kDefaultAccentHex)!;
  Color? get backgroundColor => parseHexColor(backgroundHex);
  Color? get textColor => parseHexColor(textHex);

  String get effectiveIosBundleId =>
      iosSameAsAndroid ? mirrorBundleId(androidPackage) : iosBundleId;

  /// True when mirroring changed something (an underscore became a hyphen).
  bool get iosMirrorConverted =>
      iosSameAsAndroid && packageSuffix(androidPackage).contains('_');

  /// Branding used by the live preview.
  BrandingConfig get branding => BrandingConfig(
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    accentColor: accentColor,
    backgroundColor: backgroundColor,
    textColor: textColor,
    fontFamily: fontFamily,
    appNameAr: nameAr,
    appNameEn: nameEn,
    logo: logo == null ? null : brandLogoOf(logo!),
  );

  AppConfigDraft copyWith({
    String? appId,
    bool? appIdEdited,
    bool? existingApp,
    String? nameAr,
    String? nameEn,
    String? androidPackage,
    bool? packageEdited,
    String? iosBundleId,
    bool? iosSameAsAndroid,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    List<String>? supportEmails,
    String? primaryHex,
    String? secondaryHex,
    String? accentHex,
    String? backgroundHex,
    String? textHex,
    String? fontFamily,
    PickedAsset? logo,
    bool clearLogo = false,
    PickedAsset? appIcon,
    bool clearAppIcon = false,
    String? splashHex,
    PickedAsset? splashLogo,
    bool clearSplashLogo = false,
    String? defaultLanguage,
    List<String>? supportedLanguages,
    String? templateId,
    List<String>? enabledModules,
    PaymentsDraft? payments,
  }) {
    return AppConfigDraft(
      appId: appId ?? this.appId,
      appIdEdited: appIdEdited ?? this.appIdEdited,
      existingApp: existingApp ?? this.existingApp,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      androidPackage: androidPackage ?? this.androidPackage,
      packageEdited: packageEdited ?? this.packageEdited,
      iosBundleId: iosBundleId ?? this.iosBundleId,
      iosSameAsAndroid: iosSameAsAndroid ?? this.iosSameAsAndroid,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      supportEmails: supportEmails ?? this.supportEmails,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      accentHex: accentHex ?? this.accentHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      textHex: textHex ?? this.textHex,
      fontFamily: fontFamily ?? this.fontFamily,
      logo: clearLogo ? null : (logo ?? this.logo),
      appIcon: clearAppIcon ? null : (appIcon ?? this.appIcon),
      splashHex: splashHex ?? this.splashHex,
      splashLogo: clearSplashLogo ? null : (splashLogo ?? this.splashLogo),
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      templateId: templateId ?? this.templateId,
      enabledModules: enabledModules ?? this.enabledModules,
      payments: payments ?? this.payments,
    );
  }

  /// Builds a draft from a saved config. Assets are optional (not present when
  /// importing a bare JSON file).
  factory AppConfigDraft.fromConfig(
    AppConfig c, {
    PickedAsset? logo,
    PickedAsset? appIcon,
    PickedAsset? splashLogo,
  }) {
    return AppConfigDraft(
      appId: c.appId,
      appIdEdited: true,
      existingApp: true,
      nameAr: c.appNameAr,
      nameEn: c.appNameEn,
      androidPackage: normalizePackage(c.androidPackage),
      packageEdited: true,
      // Old data may have another prefix or no iOS value at all: it is rebuilt
      // from the Android value (with syncing on) in that case.
      iosBundleId: c.iosBundleId.trim().isEmpty
          ? mirrorBundleId(normalizePackage(c.androidPackage))
          : normalizeBundleId(c.iosBundleId),
      iosSameAsAndroid:
          c.iosBundleId.trim().isEmpty ||
          (c.iosSameAsAndroid ??
              normalizeBundleId(c.iosBundleId) ==
                  mirrorBundleId(normalizePackage(c.androidPackage))),
      clientName: c.clientName,
      clientEmail: c.clientEmail,
      clientPhone: c.clientPhone,
      supportEmails: List.unmodifiable(c.supportEmails),
      primaryHex: c.primaryColor,
      secondaryHex: c.secondaryColor,
      accentHex: c.accentColor,
      backgroundHex: c.backgroundColor ?? '',
      textHex: c.textColor ?? '',
      fontFamily: c.fontFamily,
      logo: logo,
      appIcon: appIcon,
      splashHex: c.splashBackgroundColor,
      // Only keep a dedicated splash logo when it differs from the main one.
      splashLogo: c.splashLogoPath == c.logoPath ? null : splashLogo,
      defaultLanguage: c.defaultLanguage,
      supportedLanguages: List.unmodifiable(c.supportedLanguages),
      templateId: c.templateId,
      enabledModules: List.unmodifiable(c.modules),
      payments: c.payments == null
          ? const PaymentsDraft()
          : PaymentsDraft.fromJson(c.payments!),
    );
  }
}

/// `com.excp.` + the English name without separators, e.g. 'Enaya' ->
/// `com.excp.enaya`. Just the prefix when nothing usable remains.
String suggestPackage(String nameEn) =>
    '$kPackagePrefix${slugifyAppId(nameEn).replaceAll('_', '')}';

/// The preview logo of an asset: its bytes, or its public URL when remote.
BrandLogo brandLogoOf(PickedAsset a) => a.isRemote
    ? BrandLogo.network(a.sourceUrl!)
    : BrandLogo(a.bytes, isSvg: a.isSvg);

/// Lower-case slug derived from an English name, e.g. "Swift Maids" ->
/// `swift_maids`. Returns '' when nothing usable remains.
String slugifyAppId(String input) {
  var s = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  s = s.replaceFirst(RegExp(r'^[0-9_]+'), '');
  return s.length > 30 ? s.substring(0, 30) : s;
}

/// The canonical form of an App ID: "Enaya", " enaya " and "ENAYA" are the
/// same ID. Used for the format check, the availability check and storage.
String normalizeAppId(String input) => input.trim().toLowerCase();
