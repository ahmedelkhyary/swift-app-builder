import 'package:recruitment_ui/recruitment_ui.dart' show AppTemplate;

import 'draft.dart';
import 'validators.dart' show templateSupportsPayments;

/// The wizard data of a request as stored in Firestore (`app_requests/{appId}`),
/// without `status` and the timestamps, which the backend adds. Images are
/// referenced by their download URLs.
Map<String, dynamic> requestFields(
  AppConfigDraft d, {
  required String logoUrl,
  required String appIconUrl,
  String? splashLogoUrl,
  String? secretsTokenHash,
}) {
  String? clean(String s) => s.trim().isEmpty ? null : s.trim().toUpperCase();
  return {
    'appId': d.appId,
    'appName': {'ar': d.nameAr.trim(), 'en': d.nameEn.trim()},
    'client': {
      'name': d.clientName.trim(),
      'email': d.clientEmail.trim(),
      'phone': d.clientPhone.trim(),
      'supportEmails': List<String>.from(d.supportEmails),
    },
    'android': {'packageName': d.androidPackage.trim()},
    'ios': {
      'bundleId': d.effectiveIosBundleId.trim(),
      'sameAsAndroid': d.iosSameAsAndroid,
    },
    'branding': {
      'primaryColor': d.primaryHex.toUpperCase(),
      'secondaryColor': d.secondaryHex.toUpperCase(),
      'accentColor': d.accentHex.toUpperCase(),
      'backgroundColor': ?clean(d.backgroundHex),
      'textColor': ?clean(d.textHex),
      'fontFamily': d.fontFamily,
      'logoUrl': logoUrl,
      'appIconUrl': appIconUrl,
      'splashBackgroundColor': d.splashHex.toUpperCase(),
      'splashLogoUrl': ?splashLogoUrl,
      'logoSourceUrl': ?d.logo?.sourceUrl,
      'appIconSourceUrl': ?d.appIcon?.sourceUrl,
    },
    'localization': {
      'defaultLanguage': d.defaultLanguage,
      'supportedLanguages': List<String>.from(d.supportedLanguages),
    },
    'templateId': d.templateId,
    'templateVersion': AppTemplate.version,
    'modules': List<String>.from(d.enabledModules),
    // Never any secret: those go to the secrets backend (see
    // `PaymentsDraft.secrets`); only the hash of the one-time token that
    // authorizes that call is stored here.
    if (templateSupportsPayments(d.templateId))
      'payments': {
        ...d.payments.toJson(),
        'secretsTokenHash': ?secretsTokenHash,
      },
  };
}
