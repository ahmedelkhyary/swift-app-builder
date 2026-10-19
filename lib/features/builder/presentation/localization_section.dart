import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import 'form_widgets.dart';

class LocalizationSection extends ConsumerWidget {
  const LocalizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final c = ref.read(draftProvider.notifier);
    final names = {'ar': l10n.langArabic, 'en': l10n.langEnglish};

    return SectionCard(
      title: l10n.sectionLocalization,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.defaultLanguage,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              for (final e in names.entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {d.defaultLanguage},
            onSelectionChanged: (s) => c.setDefaultLanguage(s.first),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.supportedLanguages,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final e in names.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(e.value),
              subtitle: e.key == d.defaultLanguage
                  ? Text(l10n.defaultAlwaysIncluded)
                  : null,
              value: d.supportedLanguages.contains(e.key),
              onChanged: e.key == d.defaultLanguage
                  ? null
                  : (v) => c.toggleLanguage(e.key, v ?? false),
            ),
        ],
      ),
    );
  }
}
