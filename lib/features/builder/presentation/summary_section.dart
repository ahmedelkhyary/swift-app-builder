import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../application/file_io.dart';
import '../application/providers.dart';
import '../domain/config.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'form_widgets.dart';
import 'l10n_ext.dart';

class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);

    if (DraftValidator.firstInvalid(d) != null) {
      return SectionCard(
        title: l10n.sectionSummary,
        child: Text(l10n.fixSectionsFirst),
      );
    }
    final prepared = ref.watch(preparedConfigProvider);
    return prepared.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (p) {
        if (p == null) {
          return SectionCard(
            title: l10n.sectionSummary,
            child: Text(l10n.fixSectionsFirst),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Review(draft: d, config: p.config),
            _ValidationReport(draft: d, errors: p.schemaErrors),
            SectionCard(
              title: l10n.summaryJson,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  p.config.toPrettyJson(),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            _Actions(prepared: p.config, valid: p.isValid),
            const _VersionHistory(),
          ],
        );
      },
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.draft, required this.config});
  final AppConfigDraft draft;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      (l10n.fieldAppId, config.appId),
      (l10n.fieldNameAr, config.appNameAr),
      (l10n.fieldNameEn, config.appNameEn),
      (
        l10n.labelClient,
        '${config.clientName} · ${config.clientEmail} · ${config.clientPhone}',
      ),
      if (config.supportEmails.isNotEmpty)
        (l10n.fieldSupportEmails, config.supportEmails.join(', ')),
      (l10n.labelAndroid, config.androidPackage),
      (l10n.labelIos, config.iosBundleId),
      (l10n.labelTemplate, l10n.templateName(config.templateId)),
      (
        l10n.labelColors,
        '${config.primaryColor} / ${config.secondaryColor} / ${config.splashBackgroundColor}',
      ),
      (l10n.fontFamily, config.fontFamily),
      (l10n.labelLogo, config.logoPath),
      (l10n.labelIcon, config.appIconPath),
      (
        l10n.labelLanguages,
        '${config.defaultLanguage} (${config.supportedLanguages.join(', ')})',
      ),
    ];
    return SectionCard(
      title: l10n.summaryReview,
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      r.$1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(r.$2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ValidationReport extends StatelessWidget {
  const _ValidationReport({required this.draft, required this.errors});
  final AppConfigDraft draft;
  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ok = errors.isEmpty;
    final ratio = contrastRatio(draft.primaryColor, const Color(0xFFFFFFFF));
    return SectionCard(
      title: l10n.summaryValidation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.error,
                color: ok ? Colors.green : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(ok ? l10n.validationPassed : l10n.validationFailed),
            ],
          ),
          for (final e in errors)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32, top: 4),
              child: Text(e, textDirection: TextDirection.ltr),
            ),
          if (ratio < 4.5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.contrastWarning(ratio.toStringAsFixed(1))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.prepared, required this.valid});
  final AppConfig prepared;
  final bool valid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> save() async {
      try {
        final saved = await ref
            .read(configServiceProvider)
            .save(
              ref.read(draftProvider),
              updatedBy: ref.read(currentUserProvider),
            );
        final c = ref.read(draftProvider.notifier);
        c.replace(ref.read(draftProvider).copyWith(existingApp: true));
        ref.invalidate(versionHistoryProvider);
        ref.invalidate(preparedConfigProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.saveSuccess(saved.configVersion))),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      }
    }

    void download() {
      try {
        downloadTextFile(
          '${prepared.appId}_v${prepared.configVersion}.json',
          prepared.toPrettyJson(),
        );
      } on UnsupportedError {
        messenger.showSnackBar(SnackBar(content: Text(l10n.downloadFailed)));
      }
    }

    return SectionCard(
      title: l10n.willSaveAsVersion(prepared.configVersion),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const ValueKey('save-config'),
            onPressed: valid ? save : null,
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
          ),
          OutlinedButton.icon(
            key: const ValueKey('download-json'),
            onPressed: download,
            icon: const Icon(Icons.download),
            label: Text(l10n.downloadJson),
          ),
        ],
      ),
    );
  }
}

class _VersionHistory extends ConsumerWidget {
  const _VersionHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final versions = ref.watch(versionHistoryProvider);
    return SectionCard(
      title: l10n.versionHistory,
      child: versions.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (list) {
          if (list.isEmpty) return Text(l10n.noVersions);
          return Column(
            children: [
              for (final v in list.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(l10n.versionLabel(v.configVersion)),
                  subtitle: Text(
                    '${v.updatedAt.toLocal().toString().split('.').first} · ${v.updatedBy}',
                  ),
                  trailing: TextButton(
                    key: ValueKey('restore-${v.configVersion}'),
                    onPressed: () async {
                      final draft = await ref
                          .read(configServiceProvider)
                          .draftFromStored(v);
                      ref.read(draftProvider.notifier).replace(draft);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.restored(v.configVersion))),
                      );
                      context.go('/builder/${WizardSection.info.name}');
                    },
                    child: Text(l10n.restoreAsDraft),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
