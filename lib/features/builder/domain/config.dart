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
    required this.appNameAr,
    required this.appNameEn,
    required this.androidPackage,
    required this.iosBundleId,
    required this.templateId,
    this.templateVersion = 1,
    this.modules = defaultModules,
    required this.primaryColor,
    required this.secondaryColor,
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
  final String appNameAr;
  final String appNameEn;
  final String androidPackage;
  final String iosBundleId;
  final String templateId;

  /// Version of the template implementation the generator must use.
  final int templateVersion;

  /// Enabled service modules (individuals, hourly, mediation).
  final List<String> modules;
  final String primaryColor;
  final String secondaryColor;
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
    'client': {'name': clientName, 'email': clientEmail, 'phone': clientPhone},
    'appName': {'ar': appNameAr, 'en': appNameEn},
    'android': {'packageName': androidPackage},
    'ios': {'bundleId': iosBundleId},
    'templateId': templateId,
    'templateVersion': templateVersion,
    'modules': modules,
    'branding': {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'fontFamily': fontFamily,
      'logo': logoPath,
      'appIcon': appIconPath,
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
        appNameAr: name['ar'] as String,
        appNameEn: name['en'] as String,
        androidPackage:
            (j['android'] as Map<String, dynamic>)['packageName'] as String,
        iosBundleId: (j['ios'] as Map<String, dynamic>)['bundleId'] as String,
        templateId: j['templateId'] as String,
        templateVersion: (j['templateVersion'] as int?) ?? 1,
        modules: j['modules'] == null
            ? defaultModules
            : List<String>.from(j['modules'] as List),
        primaryColor: branding['primaryColor'] as String,
        secondaryColor: branding['secondaryColor'] as String,
        fontFamily: branding['fontFamily'] as String,
        logoPath: branding['logo'] as String,
        appIconPath: branding['appIcon'] as String,
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
