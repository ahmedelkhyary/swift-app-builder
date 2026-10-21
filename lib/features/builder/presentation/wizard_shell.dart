import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale_provider.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'l10n_ext.dart';
import 'load_dialog.dart';

const _sections = WizardSection.values;
const double _narrow = 768;

String _subtitle(AppLocalizations l10n, WizardSection s) => switch (s) {
  WizardSection.info => l10n.infoSubtitle,
  WizardSection.branding => l10n.brandingSubtitle,
  WizardSection.localization => l10n.localizationSubtitle,
  WizardSection.template => l10n.templateSubtitle,
  WizardSection.summary => l10n.summarySubtitle,
};

/// Layout shared by all five wizard steps: header, horizontal stepper,
/// scrollable content and a sticky footer.
class WizardShell extends ConsumerWidget {
  const WizardShell({super.key, required this.section, required this.child});

  final WizardSection section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final index = _sections.indexOf(section);
    final wide =
        section == WizardSection.template || section == WizardSection.branding;
    final narrow = MediaQuery.sizeOf(context).width < _narrow;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const _Header(),
          _Stepper(current: index),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 16 : 24,
                vertical: narrow ? 20 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1280 : 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!wide) ...[
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.sectionTitle(section),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _subtitle(l10n, section),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted, fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                      ],
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Footer(section: section),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < _narrow;
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.apps_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.appTitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          if (narrow)
            IconButton.outlined(
              key: const ValueKey('load-existing'),
              tooltip: l10n.loadExisting,
              onPressed: () => showLoadDialog(context, ref),
              icon: const Icon(Icons.folder_open),
            )
          else
            OutlinedButton.icon(
              key: const ValueKey('load-existing'),
              onPressed: () => showLoadDialog(context, ref),
              icon: const Icon(Icons.folder_open, size: 20),
              label: Text(l10n.loadExisting),
            ),
          const SizedBox(width: 8),
          TextButton(
            key: const ValueKey('toggle-language'),
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            child: Text(l10n.toggleLanguage),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends ConsumerWidget {
  const _Stepper({required this.current});
  final int current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < _narrow;
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 12 : 24,
              vertical: narrow ? 12 : 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Row(
                  children: [
                    for (var i = 0; i < _sections.length; i++)
                      Expanded(
                        flex: narrow && i != current ? 1 : 2,
                        child: _StepItem(
                          index: i,
                          current: current,
                          title: l10n.sectionTitle(_sections[i]),
                          showTitle: !narrow || i == current,
                          onTap: i < current
                              ? () =>
                                    context.go('/builder/${_sections[i].name}')
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 4,
            child: Row(
              children: [
                Expanded(
                  flex: current + 1,
                  child: Container(
                    key: const ValueKey('progress-fill'),
                    color: AppColors.accent,
                  ),
                ),
                Expanded(
                  flex: _sections.length - current - 1,
                  child: Container(color: AppColors.progressTrack),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.current,
    required this.title,
    required this.showTitle,
    required this.onTap,
  });

  final int index;
  final int current;
  final String title;
  final bool showTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == current;
    final done = index < current;
    final circle = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? AppColors.accent
            : (done ? AppColors.iconTile : Colors.transparent),
        border: (isCurrent || done)
            ? null
            : Border.all(color: AppColors.stepBorder, width: 1.5),
      ),
      child: done
          ? const Icon(Icons.check, size: 18, color: AppColors.accent)
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isCurrent ? Colors.white : AppColors.muted,
              ),
            ),
    );
    return Semantics(
      button: done,
      selected: isCurrent,
      label: title,
      child: InkWell(
        key: ValueKey('step-$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              circle,
              if (showTitle) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.section});
  final WizardSection section;

  void _next(BuildContext context, WidgetRef ref, {VoidCallback? onValid}) {
    final index = _sections.indexOf(section);
    if (ref.read(sectionValidProvider(section))) {
      if (onValid != null) {
        onValid();
      } else {
        context.go('/builder/${_sections[index + 1].name}');
      }
      return;
    }
    // Reveal every error, then take the user to the first invalid field.
    ref.read(submitAttemptProvider(section).notifier).state = true;
    final errors = DraftValidator.validateSection(
      ref.read(draftProvider),
      section,
    ).keys;
    final registry = ref.read(fieldRegistryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // With no synchronous error the blocker is the async app-ID check.
      registry.focusFirstInvalid(
        errors.isEmpty ? const [DraftField.appId] : errors,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final index = _sections.indexOf(section);
    final isLast = index == _sections.length - 1;
    final narrow = MediaQuery.sizeOf(context).width < _narrow;
    final nextName = isLast ? '' : l10n.sectionTitle(_sections[index + 1]);
    final isTemplate = section == WizardSection.template;
    final pick = isTemplate ? ref.watch(templatePickProvider) : null;
    final picked = pick?.selected.length ?? 1;
    final comparing = pick?.comparing ?? false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (comparing) ...[
              OutlinedButton(
                key: const ValueKey('compare-back'),
                onPressed: ref.read(templatePickProvider.notifier).closeCompare,
                child: Text(l10n.backToTemplates),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                  children: [
                    TextSpan(
                      text: l10n.wizardStep(index + 1, _sections.length),
                    ),
                    if (isTemplate && !comparing) ...[
                      const TextSpan(text: ' · '),
                      if (picked == 0)
                        TextSpan(
                          text: l10n.pickAtLeastOneTemplate,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (picked == 1) ...[
                        TextSpan(text: '${l10n.selectedTemplateLabel} '),
                        TextSpan(
                          text: l10n.templateName(
                            ref.watch(
                              draftProvider.select((d) => d.templateId),
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        TextSpan(
                          text: l10n.templatesSelectedCount(picked),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ],
                ),
                key: const ValueKey('step-counter'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!comparing)
              OutlinedButton(
                key: const ValueKey('wizard-back'),
                onPressed: index == 0
                    ? null
                    : () => context.go('/builder/${_sections[index - 1].name}'),
                child: Text(l10n.back),
              ),
            if (!isLast && !comparing) ...[
              const SizedBox(width: 12),
              Flexible(
                flex: 6,
                child: FilledButton(
                  key: const ValueKey('wizard-next'),
                  onPressed: picked == 0
                      ? null
                      : (picked >= 2
                            ? () => _next(
                                context,
                                ref,
                                onValid: ref
                                    .read(templatePickProvider.notifier)
                                    .openCompare,
                              )
                            : () => _next(context, ref)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          picked >= 2
                              ? l10n.compareTemplates(picked)
                              : (narrow
                                    ? l10n.next
                                    : l10n.nextWithName(nextName)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mirrors automatically in RTL.
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
