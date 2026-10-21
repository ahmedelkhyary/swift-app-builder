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
  String get fieldAndroidPackage => 'Package name for Android';

  @override
  String get fieldIosBundleId => 'Bundle ID for iOS';

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
  String get fieldClientEmail => 'Primary email';

  @override
  String get fieldClientPhone => 'Support phone';

  @override
  String get appIdChecking => 'Checking...';

  @override
  String get appIdAvailable => 'App ID is available';

  @override
  String get errRequired => 'This field is required';

  @override
  String get errInvalidPackage =>
      'Use lowercase English letters and digits only (underscores and dots are allowed); each part starts with a letter';

  @override
  String get errInvalidBundleId =>
      'Use English letters, digits and hyphens (-) only; parts are separated by dots and cannot start or end with a hyphen';

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
      'Use 3–30 lowercase letters, digits, hyphens or underscores, starting with a letter, e.g. khidma-recruitment';

  @override
  String get errAppIdTaken =>
      'This App ID is already taken, choose another one';

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
  String get summaryValidation => 'Validation report';

  @override
  String get validationPassed => 'Configuration is valid against the schema';

  @override
  String get validationFailed => 'Schema validation failed';

  @override
  String get fixSectionsFirst =>
      'Complete the earlier sections to see the summary.';

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
  String get phPackage => 'myapp';

  @override
  String get helperPackage =>
      'Lowercase English letters and dots only. It cannot be changed after publishing.';

  @override
  String get iosSameTitle => 'Same as the Android package name';

  @override
  String get errNameArRequired =>
      'Enter the Arabic app name, e.g. الخدمة للاستقدام';

  @override
  String get errNameEnRequired =>
      'Enter the English app name, e.g. Al Khidma Recruitment';

  @override
  String get errPackageRequired => 'This field is required';

  @override
  String get errBundleRequired => 'This field is required';

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
  String get templatePremiumDesc =>
      'Most advanced: glass, gradients and smooth motion';

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

  @override
  String get fieldSupportEmails => 'Support emails';

  @override
  String get helperSupportEmails =>
      'Add one or more emails. Press Enter or comma after each.';

  @override
  String get phSupportEmails => 'support@example.com';

  @override
  String get errSupportEmailInvalid => 'Invalid email format';

  @override
  String get hintSupportEmailDuplicate => 'This email is already added';

  @override
  String removeEmailLabel(String email) {
    return 'Remove $email';
  }

  @override
  String templatesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count templates selected',
      one: '1 template selected',
      zero: 'No templates selected',
    );
    return '$_temp0';
  }

  @override
  String get pickAtLeastOneTemplate => 'Pick at least one template';

  @override
  String get multipleTemplatesSelectedLabel => 'Several templates to compare';

  @override
  String compareTemplates(int count) {
    return 'Compare templates ($count)';
  }

  @override
  String get compareHeading => 'Compare and pick your template';

  @override
  String get compareSubtitle => 'Choose one template for your app';

  @override
  String get chooseThisTemplate => 'Choose this template';

  @override
  String get backToTemplates => 'Back to templates';

  @override
  String compareIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get comparePrevious => 'Previous template';

  @override
  String get compareNext => 'Next template';

  @override
  String get compareScreenLabel => 'Screen shown on every phone';

  @override
  String get templateSimple => 'Simple';

  @override
  String get templateLuxury => 'Luxury';

  @override
  String get templateSimpleDesc =>
      'Clean, flat and lightweight with thin lines';

  @override
  String get templateLuxuryDesc => 'Dark tones, gold accents and elegant type';

  @override
  String get templateBadgeAdvanced => 'Advanced';

  @override
  String get templatePreviewAction => 'Preview';

  @override
  String get roleAccent => 'Accent';

  @override
  String get roleBackground => 'Background';

  @override
  String get roleText => 'Text';

  @override
  String get roleDescAccent =>
      'Links such as \"View all\", success states and selected items';

  @override
  String get roleDescBackground =>
      'Screen background (optional; the template color is used otherwise)';

  @override
  String get roleDescText =>
      'Text color (optional; the template color is used otherwise)';

  @override
  String contrastOkAccent(String ratio) {
    return 'The link color is clear on the background (contrast $ratio:1)';
  }

  @override
  String contrastWarnAccent(String ratio) {
    return 'The link color may not be clear on the background (contrast $ratio:1)';
  }

  @override
  String contrastOkText(String ratio) {
    return 'Text is readable on the background (contrast $ratio:1)';
  }

  @override
  String contrastWarnText(String ratio) {
    return 'Text may not be readable on the background (contrast $ratio:1)';
  }

  @override
  String get palettesTitle => 'Ready-made palettes';

  @override
  String get paletteNavy => 'Navy';

  @override
  String get paletteTeal => 'Teal';

  @override
  String get paletteBurgundy => 'Burgundy';

  @override
  String get palettePurple => 'Purple';

  @override
  String get paletteCharcoal => 'Charcoal';

  @override
  String get resetColors => 'Reset to template defaults';

  @override
  String get useTemplateDefault => 'Use the template default';

  @override
  String get assetSourceLabel => 'Image source';

  @override
  String get assetSourceFile => 'Upload file';

  @override
  String get assetSourceUrl => 'Image URL';

  @override
  String get imageUrlPlaceholder => 'https://example.com/logo.png';

  @override
  String get imageUrlLoad => 'Load';

  @override
  String get imageUrlChange => 'Change';

  @override
  String get imageUrlLoading => 'Checking the image…';

  @override
  String get imageUrlInvalid => 'The link is not valid';

  @override
  String get imageUrlLoadFailed =>
      'Couldn\'t load image from this link. Make sure the link is public and points directly to an image.';

  @override
  String get imageUrlUnsupported =>
      'Unsupported image type. Allowed: PNG, JPG, JPEG, SVG and WEBP.';

  @override
  String get submitCardTitle => 'Submit request';

  @override
  String get submitCardDesc =>
      'Review the details above, then submit. The request is filed under the App ID.';

  @override
  String get submitRequest => 'Submit request';

  @override
  String get submitting => 'Submitting...';

  @override
  String get retry => 'Try again';

  @override
  String get requestSentTitle => 'Your request was submitted';

  @override
  String get requestSentBody =>
      'We received your request and our team will review it. We will contact you shortly to confirm the details.';

  @override
  String get requestReference => 'Request reference';

  @override
  String get backToStart => 'Back to start';

  @override
  String get submitErrNotConfigured =>
      'Submitting is not connected yet: the Firebase keys are not configured. Contact your administrator.';

  @override
  String get submitErrInvalidAppId =>
      'The App ID is not valid. Fix it in step 1 and try again.';

  @override
  String get submitErrPermission =>
      'You do not have permission to submit this request. Contact your administrator.';

  @override
  String get submitErrNetwork =>
      'Could not reach the server. Check your connection and try again. Your data is kept.';

  @override
  String get submitErrUnknown =>
      'Something went wrong while submitting. Try again; your data is kept.';

  @override
  String get nextStepsTitle => 'Next steps';

  @override
  String get stepReceived => 'Request received';

  @override
  String get stepReview => 'Our team reviews your request';

  @override
  String get stepContact => 'We contact you';

  @override
  String get stepContactVia => 'via';

  @override
  String get stateDone => 'Completed';

  @override
  String get stateInProgress => 'In progress';

  @override
  String get stateUpcoming => 'Upcoming';

  @override
  String get appIdCheckFailed => 'Couldn\'t check the App ID, try again';

  @override
  String get appIdSuggestions => 'Available suggestions:';

  @override
  String appIdJustTaken(String appId) {
    return 'The App ID \"$appId\" was just taken by another client. Your data is kept: choose a different ID and submit again.';
  }

  @override
  String get phBundleId => 'myapp';

  @override
  String packagePreview(String value) {
    return 'Package name: $value';
  }

  @override
  String get errReservedPackage =>
      'A Java reserved word such as class, new, int or package cannot be used';

  @override
  String get errPackageTooLong =>
      'The package name is too long (100 characters at most)';

  @override
  String get imageUrlNotCopyable =>
      'The image loads, but this site doesn\'t allow copying it. Upload the file instead.';

  @override
  String imageSizeMismatch(String required, String current) {
    return 'Unsuitable image size: required $required, current $current';
  }

  @override
  String get requiredLogoSize => 'at least 512×512';

  @override
  String get requiredIconSize => 'exactly 1024×1024';

  @override
  String bundlePreview(String value) {
    return 'Bundle ID: $value';
  }

  @override
  String get iosUnderscoreNote =>
      'Underscores \"_\" were converted to hyphens \"-\" because iOS does not allow them.';

  @override
  String get errBundleTooLong =>
      'The bundle ID is too long (155 characters at most)';
}
