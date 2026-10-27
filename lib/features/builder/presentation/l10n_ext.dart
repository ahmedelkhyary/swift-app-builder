import '../data/request_submitter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/asset_validator.dart';
import '../domain/validators.dart';

extension FieldErrorText on AppLocalizations {
  String fieldError(FieldError e) => switch (e) {
    FieldError.required => errRequired,
    FieldError.invalidPackage => errInvalidPackage,
    FieldError.bundleTooLong => errBundleTooLong,
    FieldError.reservedPackage => errReservedPackage,
    FieldError.packageTooLong => errPackageTooLong,
    FieldError.invalidBundleId => errInvalidBundleId,
    FieldError.invalidEmail => errInvalidEmail,
    FieldError.invalidPhone => errInvalidPhone,
    FieldError.invalidHex => errInvalidHex,
    FieldError.invalidAppId => errInvalidAppId,
    FieldError.appIdTaken => errAppIdTaken,
    FieldError.defaultNotSupported => errDefaultNotSupported,
    FieldError.assetMissing => errAssetMissing,
    FieldError.noModules => errNoModules,
    FieldError.noGatewayEnabled => errNoGatewayEnabled,
    FieldError.gatewayFieldsMissing => errGatewayFieldsMissing,
  };

  String submitError(SubmitErrorKind k) => switch (k) {
    SubmitErrorKind.notConfigured => submitErrNotConfigured,
    SubmitErrorKind.invalidAppId => submitErrInvalidAppId,
    SubmitErrorKind.permission => submitErrPermission,
    SubmitErrorKind.network => submitErrNetwork,
    SubmitErrorKind.unknown => submitErrUnknown,
  };

  String assetIssue(AssetIssue i) => switch (i) {
    AssetIssue.wrongType => issueWrongType,
    AssetIssue.tooLarge => issueTooLarge,
    AssetIssue.undecodable => issueUndecodable,
    AssetIssue.tooSmall => issueTooSmall,
    AssetIssue.wrongSize => issueWrongSize,
    AssetIssue.hasTransparency => issueHasTransparency,
  };

  String sectionTitle(WizardSection s) => switch (s) {
    WizardSection.info => sectionInfo,
    WizardSection.branding => sectionBranding,
    WizardSection.localization => sectionLocalization,
    WizardSection.template => sectionTemplate,
    WizardSection.payments => sectionPayments,
    WizardSection.summary => sectionSummary,
  };

  String templateName(String id) => switch (id) {
    'simple' => templateSimple,
    'luxury' => templateLuxury,
    'premium' => templatePremium,
    _ => id,
  };
}
