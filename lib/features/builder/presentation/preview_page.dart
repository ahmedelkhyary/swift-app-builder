import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/validators.dart';
import 'interactive_preview.dart';
import 'l10n_ext.dart';

/// Full-page interactive preview: switch templates in place (the demo
/// session is kept), reset, and return to the gallery.
class PreviewPage extends ConsumerWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final c = ref.read(draftProvider.notifier);
    // Keep the wizard's validity providers alive so the router guard can still
    // evaluate them when returning to the gallery.
    for (final s in WizardSection.values) {
      ref.watch(sectionEnabledProvider(s));
    }
    final name = l10n.templateName(d.templateId);
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('preview-back'),
          tooltip: l10n.previewBackToGallery,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/builder/template'),
        ),
        title: Text('${l10n.previewPageTitle} · $name'),
        actions: [
          FilledButton.icon(
            key: const ValueKey('preview-use-template'),
            onPressed: () {
              context.go('/builder/template');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.previewTemplateSelected(name))),
              );
            },
            icon: const Icon(Icons.check),
            label: Text(l10n.useThisTemplate),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in AppTemplate.all)
                  ChoiceChip(
                    key: ValueKey('preview-template-${t.id}'),
                    label: Text(l10n.templateName(t.id)),
                    selected: d.templateId == t.id,
                    onSelected: (_) => c.setTemplate(t.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: InteractivePreview(
                phoneScale: wide ? 1.15 : 1,
                showOpenFull: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
