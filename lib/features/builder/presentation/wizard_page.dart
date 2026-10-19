import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/validators.dart';
import 'branding_section.dart';
import 'info_section.dart';
import 'localization_section.dart';
import 'summary_section.dart';
import 'template_section.dart';
import 'wizard_shell.dart';

/// One step of the wizard: the shared [WizardShell] around the step content.
class WizardPage extends ConsumerWidget {
  const WizardPage({super.key, required this.section});
  final WizardSection section;

  Widget _content() => switch (section) {
    WizardSection.info => const InfoSection(),
    WizardSection.branding => const BrandingSection(),
    WizardSection.localization => const LocalizationSection(),
    WizardSection.template => const TemplateSection(),
    WizardSection.summary => const SummarySection(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep every section's validity (incl. the async app-ID check) alive so the
    // router guard and the Next button can rely on it.
    for (final s in WizardSection.values) {
      ref.watch(sectionEnabledProvider(s));
    }
    return WizardShell(section: section, child: _content());
  }
}
