import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../data/request_submitter.dart';
import '../domain/config.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'form_widgets.dart';
import 'l10n_ext.dart';
import 'field_registry.dart';
import 'submit_success.dart';
import 'wizard_reset.dart';

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
            _SubmitPanel(appId: p.config.appId, valid: p.isValid),
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
        [
          '${config.primaryColor} / ${config.secondaryColor} / ${config.accentColor}',
          if (config.backgroundColor != null) config.backgroundColor!,
          if (config.textColor != null) config.textColor!,
          config.splashBackgroundColor,
        ].join(' · '),
      ),
      (l10n.fontFamily, config.fontFamily),
      (l10n.labelLogo, config.logoPath),
      (l10n.labelIcon, config.appIconPath),
      if (draft.splashLogo != null)
        (l10n.splashLogoLabel, config.splashLogoPath),
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

/// "Submit request": sends the wizard to the backend with loading, error +
/// retry, an overwrite confirmation and a success dialog.
class _SubmitPanel extends ConsumerWidget {
  const _SubmitPanel({required this.appId, required this.valid});
  final String appId;
  final bool valid;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(submitProvider.notifier);
    final result = await controller.submit();
    if (result == null || !context.mounted) return;
    if (result == SubmitResult.taken) {
      // Someone else got this ID first: nothing was written. Keep every
      // answer, mark the ID as taken and take the user back to Step 1.
      ref.read(appIdTakenProvider.notifier).update((ids) => {...ids, appId});
      ref.read(submitAttemptProvider(WizardSection.info).notifier).state = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('app-id-just-taken'),
          content: Text(l10n.appIdJustTaken(appId)),
          duration: const Duration(seconds: 8),
        ),
      );
      context.go('/builder/${WizardSection.info.name}');
      return;
    }
    if (!context.mounted) return;
    final draft = ref.read(draftProvider);
    await showSubmitSuccess(
      context,
      appId: appId,
      email: draft.clientEmail.trim(),
      primary: draft.primaryColor,
    );
    // Back to the beginning: every step and any draft data is cleared.
    if (!context.mounted) return;
    resetWizard(ref);
    context.go('/builder/${WizardSection.info.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(submitProvider);
    final error = state.error;
    return SectionCard(
      title: l10n.submitCardTitle,
      description: l10n.submitCardDesc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  key: const ValueKey('submit-error'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEFEA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB4441C)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFB4441C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.submitError(error))),
                    ],
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('submit-request'),
                onPressed: valid && !state.submitting
                    ? () => _submit(context, ref)
                    : null,
                icon: state.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(error == null ? Icons.send : Icons.refresh),
                label: Text(
                  state.submitting
                      ? l10n.submitting
                      : (error == null ? l10n.submitRequest : l10n.retry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
