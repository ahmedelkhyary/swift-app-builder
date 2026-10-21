import 'package:flutter/painting.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import 'asset.dart';
import 'config.dart';

const kDefaultPrimaryHex = '#213F80';
const kDefaultSecondaryHex = '#29ABE2';

/// Default reverse-DNS prefix of generated package names.
const kPackagePrefix = 'com.excp.';

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
    this.fontFamily = 'Cairo',
    this.logo,
    this.appIcon,
    this.splashHex = '#FFFFFF',
    this.splashLogo,
    this.defaultLanguage = 'ar',
    this.supportedLanguages = const ['ar', 'en'],
    this.templateId = 'simple',
    this.enabledModules = kModuleIds,
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

  Color get primaryColor =>
      parseHexColor(primaryHex) ?? parseHexColor(kDefaultPrimaryHex)!;
  Color get secondaryColor =>
      parseHexColor(secondaryHex) ?? parseHexColor(kDefaultSecondaryHex)!;

  String get effectiveIosBundleId =>
      iosSameAsAndroid ? androidPackage : iosBundleId;

  /// Branding used by the live preview.
  BrandingConfig get branding => BrandingConfig(
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    fontFamily: fontFamily,
    appNameAr: nameAr,
    appNameEn: nameEn,
    logo: logo == null ? null : BrandLogo(logo!.bytes, isSvg: logo!.isSvg),
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
      fontFamily: fontFamily ?? this.fontFamily,
      logo: clearLogo ? null : (logo ?? this.logo),
      appIcon: clearAppIcon ? null : (appIcon ?? this.appIcon),
      splashHex: splashHex ?? this.splashHex,
      splashLogo: clearSplashLogo ? null : (splashLogo ?? this.splashLogo),
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      templateId: templateId ?? this.templateId,
      enabledModules: enabledModules ?? this.enabledModules,
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
      androidPackage: c.androidPackage,
      packageEdited: true,
      iosBundleId: c.iosBundleId,
      iosSameAsAndroid: c.iosBundleId == c.androidPackage,
      clientName: c.clientName,
      clientEmail: c.clientEmail,
      clientPhone: c.clientPhone,
      supportEmails: List.unmodifiable(c.supportEmails),
      primaryHex: c.primaryColor,
      secondaryHex: c.secondaryColor,
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
    );
  }
}

/// `com.excp.` + the English name without separators, e.g. 'Enaya' ->
/// `com.excp.enaya`. Just the prefix when nothing usable remains.
String suggestPackage(String nameEn) =>
    '$kPackagePrefix${slugifyAppId(nameEn).replaceAll('_', '')}';

/// Lower-case slug derived from an English name, e.g. "Swift Maids" ->
/// `swift_maids`. Returns '' when nothing usable remains.
String slugifyAppId(String input) {
  var s = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  s = s.replaceFirst(RegExp(r'^[0-9_]+'), '');
  return s.length > 40 ? s.substring(0, 40) : s;
}
