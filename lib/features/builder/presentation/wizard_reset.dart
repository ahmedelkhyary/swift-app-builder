import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'field_registry.dart';
import 'interactive_preview.dart';

/// Clears every step and all UI state so the wizard starts empty again.
void resetWizard(WidgetRef ref) {
  ref.read(draftProvider.notifier).reset();
  ref.invalidate(submitProvider);
  ref.invalidate(submitAttemptProvider);
  ref.invalidate(assetSourceProvider);
  ref.invalidate(previewTemplateProvider);
  ref.invalidate(previewLanguageProvider);
  ref.invalidate(previewDarkProvider);
  ref.invalidate(previewDeviceProvider);
  ref.invalidate(demoSessionProvider);
}
