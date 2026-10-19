import '../../../l10n/app_localizations.dart';
import '../domain/asset_validator.dart';
import '../domain/validators.dart';

extension FieldErrorText on AppLocalizations {
  String fieldError(FieldError e) => switch (e) {
    FieldError.required => errRequired,
    FieldError.invalidPackage => errInvalidPackage,
    FieldError.invalidBundleId => errInvalidBundleId,
    FieldError.invalidEmail => errInvalidEmail,
    FieldError.invalidPhone => errInvalidPhone,
    FieldError.invalidHex => errInvalidHex,
    FieldError.invalidAppId => errInvalidAppId,
    FieldError.appIdTaken => errAppIdTaken,
    FieldError.defaultNotSupported => errDefaultNotSupported,
    FieldError.assetMissing => errAssetMissing,
    FieldError.noModules => errNoModules,
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
    WizardSection.summary => sectionSummary,
  };

  String templateName(String id) => switch (id) {
    'classic' => templateClassic,
    'modern' => templateModern,
    'minimal' => templateMinimal,
    'premium' => templatePremium,
    _ => id,
  };
}
