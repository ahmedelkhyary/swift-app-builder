import 'package:recruitment_ui/recruitment_ui.dart';

import 'draft.dart';

enum WizardSection { info, branding, localization, template, summary }

enum FieldError {
  required,
  invalidPackage,
  invalidBundleId,
  invalidEmail,
  invalidPhone,
  invalidHex,
  invalidAppId,
  appIdTaken,
  defaultNotSupported,
  assetMissing,
  noModules,
}

enum DraftField {
  nameAr,
  nameEn,
  androidPackage,
  iosBundleId,
  appId,
  clientName,
  clientEmail,
  clientPhone,
  primaryColor,
  secondaryColor,
  splashColor,
  logo,
  appIcon,
  supportedLanguages,
  modules,
}

/// Pure, synchronous field validators. Return null when valid.
class Validators {
  const Validators._();

  static final androidPackageRegex = RegExp(
    r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
  );
  static final bundleIdRegex = RegExp(
    r'^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$',
  );
  static final appIdRegex = RegExp(r'^[a-z][a-z0-9_]{2,39}$');
  static final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final phoneRegex = RegExp(r'^\+?[0-9][0-9 \-]{6,18}$');

  static FieldError? required(String v) =>
      v.trim().isEmpty ? FieldError.required : null;

  static FieldError? androidPackage(String v) {
    if (v.trim().isEmpty || v.trim() == kPackagePrefix) {
      return FieldError.required;
    }
    return androidPackageRegex.hasMatch(v) ? null : FieldError.invalidPackage;
  }

  static FieldError? iosBundleId(String v) {
    if (v.trim().isEmpty) return FieldError.required;
    return bundleIdRegex.hasMatch(v) ? null : FieldError.invalidBundleId;
  }

  static FieldError? appId(String v) {
    if (v.trim().isEmpty) return FieldError.required;
    return appIdRegex.hasMatch(v) ? null : FieldError.invalidAppId;
  }

  static FieldError? email(String v) {
    if (v.trim().isEmpty) return FieldError.required;
    return emailRegex.hasMatch(v.trim()) ? null : FieldError.invalidEmail;
  }

  static FieldError? phone(String v) {
    if (v.trim().isEmpty) return FieldError.required;
    return phoneRegex.hasMatch(v.trim()) ? null : FieldError.invalidPhone;
  }

  static FieldError? hexColor(String v) {
    if (v.trim().isEmpty) return FieldError.required;
    return parseHexColor(v) == null || !v.trim().startsWith('#')
        ? FieldError.invalidHex
        : null;
  }
}

/// Section-level validation over an [AppConfigDraft].
class DraftValidator {
  const DraftValidator._();

  static Map<DraftField, FieldError> validateSection(
    AppConfigDraft d,
    WizardSection section,
  ) {
    final errors = <DraftField, FieldError>{};
    void add(DraftField f, FieldError? e) {
      if (e != null) errors[f] = e;
    }

    switch (section) {
      case WizardSection.info:
        add(DraftField.nameAr, Validators.required(d.nameAr));
        add(DraftField.nameEn, Validators.required(d.nameEn));
        add(
          DraftField.androidPackage,
          Validators.androidPackage(d.androidPackage),
        );
        add(
          DraftField.iosBundleId,
          Validators.iosBundleId(d.effectiveIosBundleId),
        );
        add(DraftField.appId, Validators.appId(d.appId));
        add(DraftField.clientName, Validators.required(d.clientName));
        add(DraftField.clientEmail, Validators.email(d.clientEmail));
        add(DraftField.clientPhone, Validators.phone(d.clientPhone));
      case WizardSection.branding:
        add(DraftField.primaryColor, Validators.hexColor(d.primaryHex));
        add(DraftField.secondaryColor, Validators.hexColor(d.secondaryHex));
        add(DraftField.splashColor, Validators.hexColor(d.splashHex));
        if (d.logo == null) errors[DraftField.logo] = FieldError.assetMissing;
        if (d.appIcon == null) {
          errors[DraftField.appIcon] = FieldError.assetMissing;
        }
      case WizardSection.localization:
        if (d.supportedLanguages.isEmpty ||
            !d.supportedLanguages.contains(d.defaultLanguage)) {
          errors[DraftField.supportedLanguages] =
              FieldError.defaultNotSupported;
        }
      case WizardSection.template:
        if (d.enabledModules.isEmpty) {
          errors[DraftField.modules] = FieldError.noModules;
        }
      case WizardSection.summary:
        for (final s in WizardSection.values) {
          if (s != WizardSection.summary) errors.addAll(validateSection(d, s));
        }
    }
    return errors;
  }

  static bool isSectionValid(AppConfigDraft d, WizardSection s) =>
      validateSection(d, s).isEmpty;

  /// First section (in order) that is invalid, or null if all are valid.
  static WizardSection? firstInvalid(AppConfigDraft d) {
    for (final s in WizardSection.values) {
      if (s == WizardSection.summary) continue;
      if (!isSectionValid(d, s)) return s;
    }
    return null;
  }
}
