import 'dart:convert';

/// The persisted, versioned app configuration (matches `config.schema.json`).
///
/// Never holds secrets: payment keys, signing keys and tokens do not belong
/// here (the schema forbids unknown properties).
class AppConfig {
  const AppConfig({
    this.schemaVersion = currentSchemaVersion,
    required this.appId,
    required this.configVersion,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    this.supportEmails = const [],
    required this.appNameAr,
    required this.appNameEn,
    required this.androidPackage,
    required this.iosBundleId,
    this.iosSameAsAndroid,
    required this.templateId,
    this.templateVersion = 1,
    this.modules = defaultModules,
    this.payments,
    required this.primaryColor,
    required this.secondaryColor,
    this.accentColor = '#2E9E5B',
    this.logoSourceUrl,
    this.appIconSourceUrl,
    this.backgroundColor,
    this.textColor,
    required this.fontFamily,
    required this.logoPath,
    required this.appIconPath,
    required this.splashBackgroundColor,
    required this.splashLogoPath,
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// 2 adds [templateVersion] and [modules]; version 1 files are still read.
  static const currentSchemaVersion = 2;
  static const defaultModules = ['individuals', 'hourly', 'mediation'];

  final int schemaVersion;
  final String appId;
  final int configVersion;
  final String clientName;
  final String clientEmail;
  final String clientPhone;

  /// Optional extra addresses for support notifications.
  final List<String> supportEmails;
  final String appNameAr;
  final String appNameEn;
  final String androidPackage;
  final String iosBundleId;

  /// Whether the iOS bundle ID follows the Android package (null in older
  /// configs: derived from the values).
  final bool? iosSameAsAndroid;
  final String templateId;

  /// Version of the template implementation the generator must use.
  final int templateVersion;

  /// Enabled service modules (individuals, hourly, mediation).
  final List<String> modules;

  /// Payment settings without any secret (see `PaymentsDraft.toJson`); null
  /// when the template has no payments or the config predates the step.
  final Map<String, dynamic>? payments;
  final String primaryColor;
  final String secondaryColor;

  /// Links, success states and selected items (older configs: green).
  final String accentColor;

  /// Optional page / text color overrides (null = the template's default).
  final String? backgroundColor;
  final String? textColor;

  /// Original links when the logo / icon were added from a URL.
  final String? logoSourceUrl;
  final String? appIconSourceUrl;
  final String fontFamily;
  final String logoPath;
  final String appIconPath;
  final String splashBackgroundColor;
  final String splashLogoPath;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'appId': appId,
    'configVersion': configVersion,
    'client': {
      'name': clientName,
      'email': clientEmail,
      'phone': clientPhone,
      'supportEmails': supportEmails,
    },
    'appName': {'ar': appNameAr, 'en': appNameEn},
    'android': {'packageName': androidPackage},
    // The sync flag is not written here (a stale copy of the schema would
    // reject it); it is derived on load and stored in the request document.
    'ios': {'bundleId': iosBundleId},
    'templateId': templateId,
    'templateVersion': templateVersion,
    'modules': modules,
    if (payments != null) 'payments': payments,
    'branding': {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
      'fontFamily': fontFamily,
      'logo': logoPath,
      'appIcon': appIconPath,
      if (logoSourceUrl != null) 'logoSourceUrl': logoSourceUrl,
      if (appIconSourceUrl != null) 'appIconSourceUrl': appIconSourceUrl,
      'splash': {
        'backgroundColor': splashBackgroundColor,
        'logo': splashLogoPath,
      },
    },
    'localization': {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
    },
    'meta': {
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'updatedBy': updatedBy,
    },
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Throws [FormatException] when the structure is not as expected.
  factory AppConfig.fromJson(Map<String, dynamic> j) {
    try {
      final client = j['client'] as Map<String, dynamic>;
      final name = j['appName'] as Map<String, dynamic>;
      final branding = j['branding'] as Map<String, dynamic>;
      final splash = branding['splash'] as Map<String, dynamic>;
      final loc = j['localization'] as Map<String, dynamic>;
      final meta = j['meta'] as Map<String, dynamic>;
      return AppConfig(
        schemaVersion: j['schemaVersion'] as int,
        appId: j['appId'] as String,
        configVersion: j['configVersion'] as int,
        clientName: client['name'] as String,
        clientEmail: client['email'] as String,
        clientPhone: client['phone'] as String,
        supportEmails: [
          for (final e
              in (client['supportEmails'] as List<dynamic>? ?? const []))
            e as String,
        ],
        appNameAr: name['ar'] as String,
        appNameEn: name['en'] as String,
        androidPackage:
            (j['android'] as Map<String, dynamic>)['packageName'] as String,
        iosBundleId: (j['ios'] as Map<String, dynamic>)['bundleId'] as String,
        iosSameAsAndroid:
            (j['ios'] as Map<String, dynamic>)['sameAsAndroid'] as bool?,
        templateId: j['templateId'] as String,
        templateVersion: (j['templateVersion'] as int?) ?? 1,
        modules: j['modules'] == null
            ? defaultModules
            : List<String>.from(j['modules'] as List),
        payments: j['payments'] as Map<String, dynamic>?,
        primaryColor: branding['primaryColor'] as String,
        secondaryColor: branding['secondaryColor'] as String,
        accentColor: (branding['accentColor'] as String?) ?? '#2E9E5B',
        backgroundColor: branding['backgroundColor'] as String?,
        textColor: branding['textColor'] as String?,
        fontFamily: branding['fontFamily'] as String,
        logoPath: branding['logo'] as String,
        appIconPath: branding['appIcon'] as String,
        logoSourceUrl: branding['logoSourceUrl'] as String?,
        appIconSourceUrl: branding['appIconSourceUrl'] as String?,
        splashBackgroundColor: splash['backgroundColor'] as String,
        splashLogoPath: splash['logo'] as String,
        defaultLanguage: loc['defaultLanguage'] as String,
        supportedLanguages: List<String>.from(
          loc['supportedLanguages'] as List,
        ),
        createdAt: DateTime.parse(meta['createdAt'] as String),
        updatedAt: DateTime.parse(meta['updatedAt'] as String),
        updatedBy: meta['updatedBy'] as String,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid config structure: $e');
    }
  }

  factory AppConfig.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Config root must be a JSON object');
    }
    return AppConfig.fromJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      other is AppConfig && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}
