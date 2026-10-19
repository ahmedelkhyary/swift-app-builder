import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';

/// Validates config JSON against `assets/config.schema.json`.
class ConfigSchemaValidator {
  ConfigSchemaValidator(String schemaSource)
    : _schema = JsonSchema.create(schemaSource);

  static const assetPath = 'assets/config.schema.json';

  final JsonSchema _schema;

  static Future<ConfigSchemaValidator> fromAssets() async =>
      ConfigSchemaValidator(await rootBundle.loadString(assetPath));

  /// Human-readable errors; empty when [json] conforms to the schema AND
  /// passes the cross-field checks the schema cannot express.
  List<String> validate(Map<String, dynamic> json) {
    final results = _schema.validate(json);
    final errors = <String>[
      for (final e in results.errors) '${e.instancePath}: ${e.message}',
    ];
    final loc = json['localization'];
    if (loc is Map) {
      final supported = loc['supportedLanguages'];
      if (supported is List && !supported.contains(loc['defaultLanguage'])) {
        errors.add(
          '/localization: defaultLanguage must be in supportedLanguages',
        );
      }
    }
    return errors;
  }
}
