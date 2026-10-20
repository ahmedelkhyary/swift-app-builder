// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App Builder';

  @override
  String get toggleLanguage => 'العربية';

  @override
  String get sectionInfo => 'App info';

  @override
  String get sectionBranding => 'Branding';

  @override
  String get sectionLocalization => 'Localization';

  @override
  String get sectionTemplate => 'Template';

  @override
  String get sectionSummary => 'Summary';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get load => 'Load';

  @override
  String get upload => 'Upload';

  @override
  String get remove => 'Remove';

  @override
  String get loadExisting => 'Load existing config';

  @override
  String get loadByAppId => 'Open by app ID';

  @override
  String get importJsonFile => 'Import JSON file';

  @override
  String get loadDialogTitle => 'Load existing configuration';

  @override
  String get appNotFound => 'No configuration found for this app ID';

  @override
  String importFailed(String error) {
    return 'Could not import file: $error';
  }

  @override
  String get loadedFromJsonNote =>
      'Configuration loaded. Re-upload the logo and icon, which are not part of the JSON.';

  @override
  String get fieldNameAr => 'App name (Arabic)';

  @override
  String get fieldNameEn => 'App name (English)';

  @override
  String get fieldAndroidPackage => 'Android package name';

  @override
  String get fieldIosBundleId => 'iOS bundle ID';

  @override
  String get fieldIosSame => 'Same as Android';

  @override
  String get fieldAppId => 'App ID';

  @override
  String get fieldAppIdHelper =>
      'Generated from the English name; you can edit it manually.';

  @override
  String get fieldClientName => 'Client / office name';

  @override
  String get fieldClientEmail => 'Contact email';

  @override
  String get fieldClientPhone => 'Support phone';

  @override
  String get appIdChecking => 'Checking availability…';

  @override
  String get appIdAvailable => 'App ID is available';

  @override
  String get errRequired => 'This field is required';

  @override
  String get errInvalidPackage =>
      'Use lowercase letters without spaces, for example com.excp.enaya';

  @override
  String get errInvalidBundleId =>
      'Use reverse-DNS format without spaces, for example com.excp.enaya';

  @override
  String get errInvalidEmail =>
      'Enter a valid email address, for example name@company.com';

  @override
  String get errInvalidPhone =>
      'Enter a phone number with 8–15 digits, for example +966500000000';

  @override
  String get errInvalidHex => 'Use a hex color like #1565C0';

  @override
  String get errInvalidAppId =>
      'Use 3–40 lowercase letters, digits or underscores, starting with a letter, e.g. khidma_recruitment';

  @override
  String get errAppIdTaken => 'This app ID is already used';

  @override
  String get errDefaultNotSupported =>
      'The default language must be among the supported languages';

  @override
  String get errAssetMissing => 'This file is required';

  @override
  String get primaryColor => 'Primary color';

  @override
  String get secondaryColor => 'Secondary color';

  @override
  String get colorHex => 'Hex value';

  @override
  String get pickColor => 'Pick a color';

  @override
  String contrastWarning(String ratio) {
    return 'White text on this color has a contrast ratio of $ratio:1, below the WCAG AA minimum of 4.5:1.';
  }

  @override
  String contrastOk(String ratio) {
    return 'Text contrast passes WCAG AA ($ratio:1)';
  }

  @override
  String get logoLabel => 'Logo';

  @override
  String get logoHint =>
      'PNG or SVG, transparent background preferred, 1024×1024 (minimum 512)';

  @override
  String get appIconLabel => 'App icon';

  @override
  String get appIconHint => 'PNG, exactly 1024×1024, no transparency';

  @override
  String get splashTitle => 'Splash screen';

  @override
  String get splashBackground => 'Splash background color';

  @override
  String get splashLogoLabel => 'Splash logo (optional)';

  @override
  String get splashLogoHint => 'Uses the main logo when empty';

  @override
  String get fontFamily => 'Font family';

  @override
  String get noFile => 'No file selected';

  @override
  String get issueWrongType => 'Unsupported file type';

  @override
  String get issueTooLarge => 'File is larger than 2 MB';

  @override
  String get issueUndecodable => 'The image could not be read';

  @override
  String get issueTooSmall => 'Image is smaller than 512×512';

  @override
  String get issueWrongSize => 'Image must be exactly 1024×1024';

  @override
  String get issueHasTransparency =>
      'Image has transparency; the app icon must be opaque';

  @override
  String get defaultLanguage => 'Default language';

  @override
  String get supportedLanguages => 'Supported languages';

  @override
  String get langArabic => 'Arabic';

  @override
  String get langEnglish => 'English';

  @override
  String get defaultAlwaysIncluded => 'The default language is always included';

  @override
  String get chooseTemplate => 'Choose a template';

  @override
  String get templateClassic => 'Classic';

  @override
  String get templateModern => 'Modern';

  @override
  String get templateMinimal => 'Minimal';

  @override
  String get templatePremium => 'Premium';

  @override
  String get previewLanguage => 'Preview language';

  @override
  String get previewDark => 'Dark mode';

  @override
  String get screenHome => 'Home';

  @override
  String get screenService => 'Service';

  @override
  String get screenAddress => 'Address';

  @override
  String get screenPackage => 'Package';

  @override
  String get screenWorker => 'Worker';

  @override
  String get screenCheckout => 'Checkout';

  @override
  String get summaryReview => 'Review';

  @override
  String get summaryJson => 'Configuration JSON';

  @override
  String get summaryValidation => 'Validation report';

  @override
  String get validationPassed => 'Configuration is valid against the schema';

  @override
  String get validationFailed => 'Schema validation failed';

  @override
  String get fixSectionsFirst =>
      'Complete the earlier sections to see the summary.';

  @override
  String willSaveAsVersion(int version) {
    return 'Saving will create version $version';
  }

  @override
  String get save => 'Save configuration';

  @override
  String saveSuccess(int version) {
    return 'Saved as version $version';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get downloadJson => 'Download JSON';

  @override
  String get downloadFailed => 'Download is only available in the browser';

  @override
  String get versionHistory => 'Version history';

  @override
  String get noVersions => 'No saved versions yet';

  @override
  String versionLabel(int version) {
    return 'Version $version';
  }

  @override
  String get restoreAsDraft => 'Restore as new draft';

  @override
  String restored(int version) {
    return 'Version $version restored as a new draft';
  }

  @override
  String get valueNotSet => '—';

  @override
  String get labelTemplate => 'Template';

  @override
  String get labelColors => 'Colors';

  @override
  String get labelLogo => 'Logo';

  @override
  String get labelIcon => 'App icon';

  @override
  String get labelLanguages => 'Languages';

  @override
  String get labelClient => 'Client';

  @override
  String get labelAndroid => 'Android';

  @override
  String get labelIos => 'iOS';

  @override
  String get modulesTitle => 'Service modules';

  @override
  String get moduleIndividuals => 'Individuals services';

  @override
  String get moduleHourly => 'Hourly services';

  @override
  String get moduleMediation => 'Mediation services';

  @override
  String get errNoModules => 'Enable at least one service module';

  @override
  String get previewDemoNote =>
      'Interactive demo: mock data, no real payments, SMS or bookings.';

  @override
  String get previewReset => 'Reset demo';

  @override
  String get previewOpenFull => 'Open full preview';

  @override
  String get previewBackToGallery => 'Back to template gallery';

  @override
  String get useThisTemplate => 'Use this template';

  @override
  String get jumpTo => 'Jump to';

  @override
  String get jumpLogin => 'Login';

  @override
  String get jumpHome => 'Home';

  @override
  String get jumpIndividuals => 'Individuals';

  @override
  String get jumpHourly => 'Hourly';

  @override
  String get jumpMediation => 'Mediation';

  @override
  String get previewPageTitle => 'Interactive preview';

  @override
  String previewTemplateSelected(String name) {
    return 'Template selected: $name';
  }

  @override
  String get labelModules => 'Modules';

  @override
  String get labelTemplateVersion => 'Template version';

  @override
  String wizardStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String nextWithName(String name) {
    return 'Next: $name';
  }

  @override
  String get autoBadge => 'Auto';

  @override
  String get editAppId => 'Edit app ID';

  @override
  String get resetAppId => 'Generate again from the English name';

  @override
  String get infoSubtitle =>
      'Core app details and store identifiers. Fields marked * are required.';

  @override
  String get brandingSubtitle =>
      'Pick any color you like from the picker, or type the color code directly.';

  @override
  String get localizationSubtitle =>
      'Choose the default language and the languages the app supports.';

  @override
  String get templateSubtitle =>
      'Pick the service modules, then the look that suits your brand. You can change it later.';

  @override
  String get summarySubtitle =>
      'Review everything, then save a new configuration version.';

  @override
  String get cardNameIdTitle => 'Name & ID';

  @override
  String get cardNameIdDesc => 'How the app appears to users';

  @override
  String get cardStoresTitle => 'Android & iOS';

  @override
  String get cardStoresDesc => 'Store publishing identifiers';

  @override
  String get cardClientTitle => 'Client';

  @override
  String get cardClientDesc => 'The organization the app is built for';

  @override
  String get phNameAr => 'مثال: الخدمة للاستقدام';

  @override
  String get phNameEn => 'e.g. Al Khidma Recruitment';

  @override
  String get phPackage => 'com.excp.enaya';

  @override
  String get helperPackage =>
      'Lowercase English letters and dots only. It cannot be changed after publishing.';

  @override
  String get iosSameTitle => 'Use the same package for iOS';

  @override
  String get iosSameDesc =>
      'The Android identifier is copied to iOS automatically';

  @override
  String get errNameArRequired =>
      'Enter the Arabic app name, e.g. الخدمة للاستقدام';

  @override
  String get errNameEnRequired =>
      'Enter the English app name, e.g. Al Khidma Recruitment';

  @override
  String get errPackageRequired =>
      'Enter the Android package name, e.g. com.excp.enaya';

  @override
  String get errBundleRequired =>
      'Enter the iOS bundle ID, e.g. com.excp.enaya';

  @override
  String get errClientRequired => 'Enter the client or office name';

  @override
  String get errAppIdRequired => 'Enter an app ID, e.g. khidma_recruitment';

  @override
  String get templateHeading => 'Choose the app template';

  @override
  String get modulesHint => 'Choose one or more';

  @override
  String get moduleIndividualsDesc => 'Worker recruitment';

  @override
  String get moduleHourlyDesc => 'Hourly booking';

  @override
  String get moduleMediationDesc => 'Sponsorship transfer';

  @override
  String get templatesTitle => 'Templates';

  @override
  String templatesAvailable(int count) {
    return '$count templates available';
  }

  @override
  String get templateClassicDesc => 'Balanced layout with clear cards';

  @override
  String get templateModernDesc => 'Rounded, soft and airy';

  @override
  String get templateMinimalDesc => 'Clean lines and plain lists';

  @override
  String get templatePremiumDesc => 'Bold gradients and depth';

  @override
  String get selectedPill => 'Selected';

  @override
  String get livePreview => 'Live preview';

  @override
  String get previewDemoShort => 'Demo data, no real payments or bookings';

  @override
  String get deviceIphone => 'iPhone';

  @override
  String get deviceAndroid => 'Android';

  @override
  String enableModuleTooltip(String name) {
    return 'Enable “$name” to view it';
  }

  @override
  String get selectedTemplateLabel => 'Selected template:';

  @override
  String get previewTemplateSwitcher => 'Template';

  @override
  String get colorsCardTitle => 'App colors';

  @override
  String get extractColors => 'Extract colors from logo';

  @override
  String get roleTabsLabel => 'Color roles';

  @override
  String get rolePrimary => 'Primary';

  @override
  String get roleSecondary => 'Secondary';

  @override
  String get roleSplash => 'Splash background';

  @override
  String get roleDescPrimary => 'Buttons, banner, active elements';

  @override
  String get roleDescSecondary => 'Accents, badges, secondary icons';

  @override
  String get roleDescSplash =>
      'Background of the splash screen when the app opens';

  @override
  String get pickerAreaLabel => 'Saturation and brightness';

  @override
  String pickerAreaValue(String s, String v) {
    return 'Saturation $s%, brightness $v%';
  }

  @override
  String get hueLabel => 'Hue';

  @override
  String hueValue(String deg) {
    return '$deg°';
  }

  @override
  String get eyedropperLabel => 'Pick a color from the screen';

  @override
  String get hexLabel => 'HEX';

  @override
  String contrastOkWhite(String ratio) {
    return 'White text is clear on this color (contrast $ratio:1)';
  }

  @override
  String contrastWarnWhite(String ratio) {
    return 'Text may not be clear on this color (contrast $ratio:1)';
  }

  @override
  String contrastOkBg(String ratio) {
    return 'The primary color is clear on this background (contrast $ratio:1)';
  }

  @override
  String contrastWarnBg(String ratio) {
    return 'The primary color may not be clear on this background (contrast $ratio:1)';
  }

  @override
  String get suggestedColors => 'Suggested colors';

  @override
  String get fromLogo => 'From logo';

  @override
  String colorSwatchLabel(String hex) {
    return 'Color $hex';
  }

  @override
  String get changeLogo => 'Change logo';

  @override
  String get uploadLogo => 'Upload logo';

  @override
  String get livePreviewSubtitle => 'Colors update instantly as you choose';

  @override
  String get iconSplashCard => 'App icon & splash screen';

  @override
  String get colorsExtracted => 'Colors extracted from the logo';

  @override
  String get noColorsInLogo => 'No distinct colors were found in the logo';
}
