import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'App Builder'**
  String get appTitle;

  /// No description provided for @toggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get toggleLanguage;

  /// No description provided for @sectionInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get sectionInfo;

  /// No description provided for @sectionBranding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get sectionBranding;

  /// No description provided for @sectionLocalization.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get sectionLocalization;

  /// No description provided for @sectionTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get sectionTemplate;

  /// No description provided for @sectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get sectionSummary;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @loadExisting.
  ///
  /// In en, this message translates to:
  /// **'Load existing config'**
  String get loadExisting;

  /// No description provided for @loadByAppId.
  ///
  /// In en, this message translates to:
  /// **'Open by app ID'**
  String get loadByAppId;

  /// No description provided for @importJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Import JSON file'**
  String get importJsonFile;

  /// No description provided for @loadDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Load existing configuration'**
  String get loadDialogTitle;

  /// No description provided for @appNotFound.
  ///
  /// In en, this message translates to:
  /// **'No configuration found for this app ID'**
  String get appNotFound;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import file: {error}'**
  String importFailed(String error);

  /// No description provided for @loadedFromJsonNote.
  ///
  /// In en, this message translates to:
  /// **'Configuration loaded. Re-upload the logo and icon, which are not part of the JSON.'**
  String get loadedFromJsonNote;

  /// No description provided for @fieldNameAr.
  ///
  /// In en, this message translates to:
  /// **'App name (Arabic)'**
  String get fieldNameAr;

  /// No description provided for @fieldNameEn.
  ///
  /// In en, this message translates to:
  /// **'App name (English)'**
  String get fieldNameEn;

  /// No description provided for @fieldAndroidPackage.
  ///
  /// In en, this message translates to:
  /// **'Android package name'**
  String get fieldAndroidPackage;

  /// No description provided for @fieldIosBundleId.
  ///
  /// In en, this message translates to:
  /// **'iOS bundle ID'**
  String get fieldIosBundleId;

  /// No description provided for @fieldIosSame.
  ///
  /// In en, this message translates to:
  /// **'Same as Android'**
  String get fieldIosSame;

  /// No description provided for @fieldAppId.
  ///
  /// In en, this message translates to:
  /// **'App ID'**
  String get fieldAppId;

  /// No description provided for @fieldAppIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Generated from the English name; you can edit it manually.'**
  String get fieldAppIdHelper;

  /// No description provided for @fieldClientName.
  ///
  /// In en, this message translates to:
  /// **'Client / office name'**
  String get fieldClientName;

  /// No description provided for @fieldClientEmail.
  ///
  /// In en, this message translates to:
  /// **'Primary email'**
  String get fieldClientEmail;

  /// No description provided for @fieldClientPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get fieldClientPhone;

  /// No description provided for @appIdChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking availability…'**
  String get appIdChecking;

  /// No description provided for @appIdAvailable.
  ///
  /// In en, this message translates to:
  /// **'App ID is available'**
  String get appIdAvailable;

  /// No description provided for @errRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errRequired;

  /// No description provided for @errInvalidPackage.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters without spaces, for example com.excp.enaya'**
  String get errInvalidPackage;

  /// No description provided for @errInvalidBundleId.
  ///
  /// In en, this message translates to:
  /// **'Use reverse-DNS format without spaces, for example com.excp.enaya'**
  String get errInvalidBundleId;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address, for example name@company.com'**
  String get errInvalidEmail;

  /// No description provided for @errInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number with 8–15 digits, for example +966500000000'**
  String get errInvalidPhone;

  /// No description provided for @errInvalidHex.
  ///
  /// In en, this message translates to:
  /// **'Use a hex color like #1565C0'**
  String get errInvalidHex;

  /// No description provided for @errInvalidAppId.
  ///
  /// In en, this message translates to:
  /// **'Use 3–40 lowercase letters, digits or underscores, starting with a letter, e.g. khidma_recruitment'**
  String get errInvalidAppId;

  /// No description provided for @errAppIdTaken.
  ///
  /// In en, this message translates to:
  /// **'This app ID is already used'**
  String get errAppIdTaken;

  /// No description provided for @errDefaultNotSupported.
  ///
  /// In en, this message translates to:
  /// **'The default language must be among the supported languages'**
  String get errDefaultNotSupported;

  /// No description provided for @errAssetMissing.
  ///
  /// In en, this message translates to:
  /// **'This file is required'**
  String get errAssetMissing;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get secondaryColor;

  /// No description provided for @colorHex.
  ///
  /// In en, this message translates to:
  /// **'Hex value'**
  String get colorHex;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

  /// No description provided for @contrastWarning.
  ///
  /// In en, this message translates to:
  /// **'White text on this color has a contrast ratio of {ratio}:1, below the WCAG AA minimum of 4.5:1.'**
  String contrastWarning(String ratio);

  /// No description provided for @contrastOk.
  ///
  /// In en, this message translates to:
  /// **'Text contrast passes WCAG AA ({ratio}:1)'**
  String contrastOk(String ratio);

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoLabel;

  /// No description provided for @logoHint.
  ///
  /// In en, this message translates to:
  /// **'PNG or SVG, transparent background preferred, 1024×1024 (minimum 512)'**
  String get logoHint;

  /// No description provided for @appIconLabel.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get appIconLabel;

  /// No description provided for @appIconHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, exactly 1024×1024, no transparency'**
  String get appIconHint;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Splash screen'**
  String get splashTitle;

  /// No description provided for @splashBackground.
  ///
  /// In en, this message translates to:
  /// **'Splash background color'**
  String get splashBackground;

  /// No description provided for @splashLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Splash logo (optional)'**
  String get splashLogoLabel;

  /// No description provided for @splashLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Uses the main logo when empty'**
  String get splashLogoHint;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get fontFamily;

  /// No description provided for @noFile.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFile;

  /// No description provided for @issueWrongType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get issueWrongType;

  /// No description provided for @issueTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is larger than 2 MB'**
  String get issueTooLarge;

  /// No description provided for @issueUndecodable.
  ///
  /// In en, this message translates to:
  /// **'The image could not be read'**
  String get issueUndecodable;

  /// No description provided for @issueTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Image is smaller than 512×512'**
  String get issueTooSmall;

  /// No description provided for @issueWrongSize.
  ///
  /// In en, this message translates to:
  /// **'Image must be exactly 1024×1024'**
  String get issueWrongSize;

  /// No description provided for @issueHasTransparency.
  ///
  /// In en, this message translates to:
  /// **'Image has transparency; the app icon must be opaque'**
  String get issueHasTransparency;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get defaultLanguage;

  /// No description provided for @supportedLanguages.
  ///
  /// In en, this message translates to:
  /// **'Supported languages'**
  String get supportedLanguages;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @defaultAlwaysIncluded.
  ///
  /// In en, this message translates to:
  /// **'The default language is always included'**
  String get defaultAlwaysIncluded;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get chooseTemplate;

  /// No description provided for @templatePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get templatePremium;

  /// No description provided for @previewLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preview language'**
  String get previewLanguage;

  /// No description provided for @previewDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get previewDark;

  /// No description provided for @screenHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get screenHome;

  /// No description provided for @screenService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get screenService;

  /// No description provided for @screenAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get screenAddress;

  /// No description provided for @screenPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get screenPackage;

  /// No description provided for @screenWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get screenWorker;

  /// No description provided for @screenCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get screenCheckout;

  /// No description provided for @summaryReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get summaryReview;

  /// No description provided for @summaryJson.
  ///
  /// In en, this message translates to:
  /// **'Configuration JSON'**
  String get summaryJson;

  /// No description provided for @summaryValidation.
  ///
  /// In en, this message translates to:
  /// **'Validation report'**
  String get summaryValidation;

  /// No description provided for @validationPassed.
  ///
  /// In en, this message translates to:
  /// **'Configuration is valid against the schema'**
  String get validationPassed;

  /// No description provided for @validationFailed.
  ///
  /// In en, this message translates to:
  /// **'Schema validation failed'**
  String get validationFailed;

  /// No description provided for @fixSectionsFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete the earlier sections to see the summary.'**
  String get fixSectionsFirst;

  /// No description provided for @willSaveAsVersion.
  ///
  /// In en, this message translates to:
  /// **'Saving will create version {version}'**
  String willSaveAsVersion(int version);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save configuration'**
  String get save;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved as version {version}'**
  String saveSuccess(int version);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @downloadJson.
  ///
  /// In en, this message translates to:
  /// **'Download JSON'**
  String get downloadJson;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download is only available in the browser'**
  String get downloadFailed;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @noVersions.
  ///
  /// In en, this message translates to:
  /// **'No saved versions yet'**
  String get noVersions;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(int version);

  /// No description provided for @restoreAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Restore as new draft'**
  String get restoreAsDraft;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Version {version} restored as a new draft'**
  String restored(int version);

  /// No description provided for @valueNotSet.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get valueNotSet;

  /// No description provided for @labelTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get labelTemplate;

  /// No description provided for @labelColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get labelColors;

  /// No description provided for @labelLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get labelLogo;

  /// No description provided for @labelIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get labelIcon;

  /// No description provided for @labelLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get labelLanguages;

  /// No description provided for @labelClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get labelClient;

  /// No description provided for @labelAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get labelAndroid;

  /// No description provided for @labelIos.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get labelIos;

  /// No description provided for @modulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Service modules'**
  String get modulesTitle;

  /// No description provided for @moduleIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Individuals services'**
  String get moduleIndividuals;

  /// No description provided for @moduleHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly services'**
  String get moduleHourly;

  /// No description provided for @moduleMediation.
  ///
  /// In en, this message translates to:
  /// **'Mediation services'**
  String get moduleMediation;

  /// No description provided for @errNoModules.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one service module'**
  String get errNoModules;

  /// No description provided for @previewDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Interactive demo: mock data, no real payments, SMS or bookings.'**
  String get previewDemoNote;

  /// No description provided for @previewReset.
  ///
  /// In en, this message translates to:
  /// **'Reset demo'**
  String get previewReset;

  /// No description provided for @previewOpenFull.
  ///
  /// In en, this message translates to:
  /// **'Open full preview'**
  String get previewOpenFull;

  /// No description provided for @previewBackToGallery.
  ///
  /// In en, this message translates to:
  /// **'Back to template gallery'**
  String get previewBackToGallery;

  /// No description provided for @useThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get useThisTemplate;

  /// No description provided for @jumpTo.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get jumpTo;

  /// No description provided for @jumpLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get jumpLogin;

  /// No description provided for @jumpHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get jumpHome;

  /// No description provided for @jumpIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get jumpIndividuals;

  /// No description provided for @jumpHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get jumpHourly;

  /// No description provided for @jumpMediation.
  ///
  /// In en, this message translates to:
  /// **'Mediation'**
  String get jumpMediation;

  /// No description provided for @previewPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive preview'**
  String get previewPageTitle;

  /// No description provided for @previewTemplateSelected.
  ///
  /// In en, this message translates to:
  /// **'Template selected: {name}'**
  String previewTemplateSelected(String name);

  /// No description provided for @labelModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get labelModules;

  /// No description provided for @labelTemplateVersion.
  ///
  /// In en, this message translates to:
  /// **'Template version'**
  String get labelTemplateVersion;

  /// No description provided for @wizardStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String wizardStep(int n, int total);

  /// No description provided for @nextWithName.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String nextWithName(String name);

  /// No description provided for @autoBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoBadge;

  /// No description provided for @editAppId.
  ///
  /// In en, this message translates to:
  /// **'Edit app ID'**
  String get editAppId;

  /// No description provided for @resetAppId.
  ///
  /// In en, this message translates to:
  /// **'Generate again from the English name'**
  String get resetAppId;

  /// No description provided for @infoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Core app details and store identifiers. Fields marked * are required.'**
  String get infoSubtitle;

  /// No description provided for @brandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick any color you like from the picker, or type the color code directly.'**
  String get brandingSubtitle;

  /// No description provided for @localizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the default language and the languages the app supports.'**
  String get localizationSubtitle;

  /// No description provided for @templateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the service modules, then the look that suits your brand. You can change it later.'**
  String get templateSubtitle;

  /// No description provided for @summarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review everything, then save a new configuration version.'**
  String get summarySubtitle;

  /// No description provided for @cardNameIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Name & ID'**
  String get cardNameIdTitle;

  /// No description provided for @cardNameIdDesc.
  ///
  /// In en, this message translates to:
  /// **'How the app appears to users'**
  String get cardNameIdDesc;

  /// No description provided for @cardStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Android & iOS'**
  String get cardStoresTitle;

  /// No description provided for @cardStoresDesc.
  ///
  /// In en, this message translates to:
  /// **'Store publishing identifiers'**
  String get cardStoresDesc;

  /// No description provided for @cardClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get cardClientTitle;

  /// No description provided for @cardClientDesc.
  ///
  /// In en, this message translates to:
  /// **'The organization the app is built for'**
  String get cardClientDesc;

  /// No description provided for @phNameAr.
  ///
  /// In en, this message translates to:
  /// **'مثال: الخدمة للاستقدام'**
  String get phNameAr;

  /// No description provided for @phNameEn.
  ///
  /// In en, this message translates to:
  /// **'e.g. Al Khidma Recruitment'**
  String get phNameEn;

  /// No description provided for @phPackage.
  ///
  /// In en, this message translates to:
  /// **'com.excp.enaya'**
  String get phPackage;

  /// No description provided for @helperPackage.
  ///
  /// In en, this message translates to:
  /// **'Lowercase English letters and dots only. It cannot be changed after publishing.'**
  String get helperPackage;

  /// No description provided for @iosSameTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the same package for iOS'**
  String get iosSameTitle;

  /// No description provided for @iosSameDesc.
  ///
  /// In en, this message translates to:
  /// **'The Android identifier is copied to iOS automatically'**
  String get iosSameDesc;

  /// No description provided for @errNameArRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the Arabic app name, e.g. الخدمة للاستقدام'**
  String get errNameArRequired;

  /// No description provided for @errNameEnRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the English app name, e.g. Al Khidma Recruitment'**
  String get errNameEnRequired;

  /// No description provided for @errPackageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the Android package name, e.g. com.excp.enaya'**
  String get errPackageRequired;

  /// No description provided for @errBundleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the iOS bundle ID, e.g. com.excp.enaya'**
  String get errBundleRequired;

  /// No description provided for @errClientRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the client or office name'**
  String get errClientRequired;

  /// No description provided for @errAppIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an app ID, e.g. khidma_recruitment'**
  String get errAppIdRequired;

  /// No description provided for @templateHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose the app template'**
  String get templateHeading;

  /// No description provided for @modulesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more'**
  String get modulesHint;

  /// No description provided for @moduleIndividualsDesc.
  ///
  /// In en, this message translates to:
  /// **'Worker recruitment'**
  String get moduleIndividualsDesc;

  /// No description provided for @moduleHourlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Hourly booking'**
  String get moduleHourlyDesc;

  /// No description provided for @moduleMediationDesc.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship transfer'**
  String get moduleMediationDesc;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTitle;

  /// No description provided for @templatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} templates available'**
  String templatesAvailable(int count);

  /// No description provided for @templatePremiumDesc.
  ///
  /// In en, this message translates to:
  /// **'Most advanced: glass, gradients and smooth motion'**
  String get templatePremiumDesc;

  /// No description provided for @selectedPill.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedPill;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get livePreview;

  /// No description provided for @previewDemoShort.
  ///
  /// In en, this message translates to:
  /// **'Demo data, no real payments or bookings'**
  String get previewDemoShort;

  /// No description provided for @deviceIphone.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get deviceIphone;

  /// No description provided for @deviceAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get deviceAndroid;

  /// No description provided for @enableModuleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Enable “{name}” to view it'**
  String enableModuleTooltip(String name);

  /// No description provided for @selectedTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected template:'**
  String get selectedTemplateLabel;

  /// No description provided for @previewTemplateSwitcher.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get previewTemplateSwitcher;

  /// No description provided for @colorsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'App colors'**
  String get colorsCardTitle;

  /// No description provided for @extractColors.
  ///
  /// In en, this message translates to:
  /// **'Extract colors from logo'**
  String get extractColors;

  /// No description provided for @roleTabsLabel.
  ///
  /// In en, this message translates to:
  /// **'Color roles'**
  String get roleTabsLabel;

  /// No description provided for @rolePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get rolePrimary;

  /// No description provided for @roleSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get roleSecondary;

  /// No description provided for @roleSplash.
  ///
  /// In en, this message translates to:
  /// **'Splash background'**
  String get roleSplash;

  /// No description provided for @roleDescPrimary.
  ///
  /// In en, this message translates to:
  /// **'Buttons, banner, active elements'**
  String get roleDescPrimary;

  /// No description provided for @roleDescSecondary.
  ///
  /// In en, this message translates to:
  /// **'Accents, badges, secondary icons'**
  String get roleDescSecondary;

  /// No description provided for @roleDescSplash.
  ///
  /// In en, this message translates to:
  /// **'Background of the splash screen when the app opens'**
  String get roleDescSplash;

  /// No description provided for @pickerAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturation and brightness'**
  String get pickerAreaLabel;

  /// No description provided for @pickerAreaValue.
  ///
  /// In en, this message translates to:
  /// **'Saturation {s}%, brightness {v}%'**
  String pickerAreaValue(String s, String v);

  /// No description provided for @hueLabel.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hueLabel;

  /// No description provided for @hueValue.
  ///
  /// In en, this message translates to:
  /// **'{deg}°'**
  String hueValue(String deg);

  /// No description provided for @eyedropperLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick a color from the screen'**
  String get eyedropperLabel;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'HEX'**
  String get hexLabel;

  /// No description provided for @contrastOkWhite.
  ///
  /// In en, this message translates to:
  /// **'White text is clear on this color (contrast {ratio}:1)'**
  String contrastOkWhite(String ratio);

  /// No description provided for @contrastWarnWhite.
  ///
  /// In en, this message translates to:
  /// **'Text may not be clear on this color (contrast {ratio}:1)'**
  String contrastWarnWhite(String ratio);

  /// No description provided for @contrastOkBg.
  ///
  /// In en, this message translates to:
  /// **'The primary color is clear on this background (contrast {ratio}:1)'**
  String contrastOkBg(String ratio);

  /// No description provided for @contrastWarnBg.
  ///
  /// In en, this message translates to:
  /// **'The primary color may not be clear on this background (contrast {ratio}:1)'**
  String contrastWarnBg(String ratio);

  /// No description provided for @suggestedColors.
  ///
  /// In en, this message translates to:
  /// **'Suggested colors'**
  String get suggestedColors;

  /// No description provided for @fromLogo.
  ///
  /// In en, this message translates to:
  /// **'From logo'**
  String get fromLogo;

  /// No description provided for @colorSwatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Color {hex}'**
  String colorSwatchLabel(String hex);

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get changeLogo;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get uploadLogo;

  /// No description provided for @livePreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Colors update instantly as you choose'**
  String get livePreviewSubtitle;

  /// No description provided for @iconSplashCard.
  ///
  /// In en, this message translates to:
  /// **'App icon & splash screen'**
  String get iconSplashCard;

  /// No description provided for @colorsExtracted.
  ///
  /// In en, this message translates to:
  /// **'Colors extracted from the logo'**
  String get colorsExtracted;

  /// No description provided for @noColorsInLogo.
  ///
  /// In en, this message translates to:
  /// **'No distinct colors were found in the logo'**
  String get noColorsInLogo;

  /// No description provided for @fieldSupportEmails.
  ///
  /// In en, this message translates to:
  /// **'Support emails'**
  String get fieldSupportEmails;

  /// No description provided for @helperSupportEmails.
  ///
  /// In en, this message translates to:
  /// **'Add one or more emails. Press Enter or comma after each.'**
  String get helperSupportEmails;

  /// No description provided for @phSupportEmails.
  ///
  /// In en, this message translates to:
  /// **'support@example.com'**
  String get phSupportEmails;

  /// No description provided for @errSupportEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get errSupportEmailInvalid;

  /// No description provided for @hintSupportEmailDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This email is already added'**
  String get hintSupportEmailDuplicate;

  /// No description provided for @removeEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove {email}'**
  String removeEmailLabel(String email);

  /// No description provided for @templatesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No templates selected} =1{1 template selected} other{{count} templates selected}}'**
  String templatesSelectedCount(int count);

  /// No description provided for @pickAtLeastOneTemplate.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one template'**
  String get pickAtLeastOneTemplate;

  /// No description provided for @multipleTemplatesSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Several templates to compare'**
  String get multipleTemplatesSelectedLabel;

  /// No description provided for @compareTemplates.
  ///
  /// In en, this message translates to:
  /// **'Compare templates ({count})'**
  String compareTemplates(int count);

  /// No description provided for @compareHeading.
  ///
  /// In en, this message translates to:
  /// **'Compare and pick your template'**
  String get compareHeading;

  /// No description provided for @compareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one template for your app'**
  String get compareSubtitle;

  /// No description provided for @chooseThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose this template'**
  String get chooseThisTemplate;

  /// No description provided for @backToTemplates.
  ///
  /// In en, this message translates to:
  /// **'Back to templates'**
  String get backToTemplates;

  /// No description provided for @compareIndicator.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String compareIndicator(int current, int total);

  /// No description provided for @comparePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous template'**
  String get comparePrevious;

  /// No description provided for @compareNext.
  ///
  /// In en, this message translates to:
  /// **'Next template'**
  String get compareNext;

  /// No description provided for @compareScreenLabel.
  ///
  /// In en, this message translates to:
  /// **'Screen shown on every phone'**
  String get compareScreenLabel;

  /// No description provided for @templateSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get templateSimple;

  /// No description provided for @templateLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get templateLuxury;

  /// No description provided for @templateSimpleDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean, flat and lightweight with thin lines'**
  String get templateSimpleDesc;

  /// No description provided for @templateLuxuryDesc.
  ///
  /// In en, this message translates to:
  /// **'Dark tones, gold accents and elegant type'**
  String get templateLuxuryDesc;

  /// No description provided for @templateBadgeAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get templateBadgeAdvanced;

  /// No description provided for @templatePreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get templatePreviewAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
