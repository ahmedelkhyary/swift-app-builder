import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/builder/application/providers.dart';
import 'features/builder/application/schema_validator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final schema = await ConfigSchemaValidator.fromAssets();
  runApp(
    ProviderScope(
      overrides: [schemaValidatorProvider.overrideWithValue(schema)],
      child: const BuilderApp(),
    ),
  );
}
