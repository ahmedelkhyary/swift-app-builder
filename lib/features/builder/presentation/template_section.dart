import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/validators.dart';
import 'interactive_preview.dart';
import 'l10n_ext.dart';
import 'phone_preview.dart';
import 'template_compare.dart';

const _breakpointTwoColumns = 1100.0;
const _breakpointMobile = 768.0;

/// Step 4: service modules + template gallery (start side) and the live
/// preview (end side). Below ~1100px the preview wraps underneath.
class TemplateSection extends ConsumerWidget {
  const TemplateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final pick = ref.watch(templatePickProvider);
    if (pick.comparing) return const TemplateCompare();
    const selection = _SelectionColumn();
    final preview = InteractivePreview(templateId: pick.preview);
    if (width >= _breakpointTwoColumns) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: selection),
          const SizedBox(width: 32),
          SizedBox(width: 440, child: preview),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [selection, const SizedBox(height: 32), preview],
    );
  }
}

class _SelectionColumn extends ConsumerWidget {
  const _SelectionColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final c = ref.read(draftProvider.notifier);
    final pick = ref.watch(templatePickProvider);
    final pickC = ref.read(templatePickProvider.notifier);
    final lang = ref.watch(previewLanguageProvider) ?? d.defaultLanguage;
    final modules = {
      for (final m in ServiceModule.values)
        if (d.enabledModules.contains(m.name)) m,
    };
    final errors = DraftValidator.validateSection(d, WizardSection.template);
    final mobile = MediaQuery.sizeOf(context).width < _breakpointMobile;

    final units = <(String, String, String, IconData)>[
      (
        'individuals',
        l10n.moduleIndividuals,
        l10n.moduleIndividualsDesc,
        Icons.people_alt_outlined,
      ),
      ('hourly', l10n.moduleHourly, l10n.moduleHourlyDesc, Icons.schedule),
      (
        'mediation',
        l10n.moduleMediation,
        l10n.moduleMediationDesc,
        Icons.swap_horiz,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.templateHeading,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.templateSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        // ---- service units ----
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.modulesTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.modulesHint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, box) {
                  final cols = mobile ? 1 : 3;
                  final w = (box.maxWidth - 12 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final u in units)
                        SizedBox(
                          width: w,
                          child: _UnitCard(
                            key: ValueKey('module-${u.$1}'),
                            name: u.$2,
                            description: u.$3,
                            icon: u.$4,
                            selected: d.enabledModules.contains(u.$1),
                            onTap: () => c.setModule(
                              u.$1,
                              !d.enabledModules.contains(u.$1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (errors[DraftField.modules] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.fieldError(errors[DraftField.modules]!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ---- templates ----
        Row(
          children: [
            Text(
              l10n.templatesTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.templatesSelectedCount(pick.selected.length),
                  key: const ValueKey('templates-selected-count'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pick.selected.isEmpty
                        ? AppColors.error
                        : AppColors.accent,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (!mobile)
              Text(
                l10n.templatesAvailable(AppTemplate.all.length),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final cols = mobile ? 1 : 3;
            final w = (box.maxWidth - 16 * (cols - 1)) / cols;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final t in AppTemplate.all)
                  SizedBox(
                    width: w,
                    child: TemplateCard(
                      template: t,
                      branding: d.branding,
                      lang: lang,
                      modules: modules,
                      selected: pick.selected.contains(t.id),
                      onTap: () => pickC.toggle(t.id),
                      onPreview: () {
                        ref.read(previewTemplateProvider.notifier).state = t.id;
                        context.go('/preview');
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Selectable service-unit card (a real button; `toggled` = aria-pressed).
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFF3F6FC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.accent : const Color(0xFFDCE0EA),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.iconTile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Template card: mini phone with the real Home rendering, name, description.
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.branding,
    required this.lang,
    required this.modules,
    required this.selected,
    required this.onTap,
    this.onPreview,
  });

  final AppTemplate template;
  final BrandingConfig branding;
  final String lang;
  final Set<ServiceModule> modules;
  final bool selected;
  final VoidCallback onTap;

  /// Opens the full-size preview of this template (without selecting it).
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.templateName(template.id);
    final desc = switch (template.id) {
      'simple' => l10n.templateSimpleDesc,
      'luxury' => l10n.templateLuxuryDesc,
      _ => l10n.templatePremiumDesc,
    };
    return Semantics(
      button: true,
      toggled: selected,
      label: name,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('template-${template.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0xFFDCE4F5), spreadRadius: 4)]
              : null,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.accent : const Color(0xFFDCE0EA),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 236,
                    color: selected
                        ? const Color(0xFFEEF1F7)
                        : AppColors.pageBackground,
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: _MiniPhone(
                            template: template,
                            branding: branding,
                            lang: lang,
                            modules: modules,
                          ),
                        ),
                        PositionedDirectional(
                          top: 10,
                          start: 10,
                          child: Tooltip(
                            message: l10n.selectedPill,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : const Color(0xFFB9BFCE),
                                  width: 1.5,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (template.id == 'premium') ...[
                              const SizedBox(width: 8),
                              Container(
                                key: const ValueKey('badge-premium'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2F4B8A),
                                      Color(0xFF7A4FD0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.templateBadgeAdvanced,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                        if (onPreview != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: ValueKey('preview-card-${template.id}'),
                              onPressed: onPreview,
                              icon: const Icon(Icons.open_in_full, size: 16),
                              label: Text(l10n.templatePreviewAction),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 132×200 phone with a 5px bezel, rounded top and cut off at the bottom,
/// showing the template's real Home screen in the client's brand colors.
class _MiniPhone extends StatelessWidget {
  const _MiniPhone({
    required this.template,
    required this.branding,
    required this.lang,
    required this.modules,
  });

  final AppTemplate template;
  final BrandingConfig branding;
  final String lang;
  final Set<ServiceModule> modules;

  @override
  Widget build(BuildContext context) {
    const bezel = 5.0;
    const width = 132.0;
    const height = 200.0;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(bezel, bezel, bezel, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF14171D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        child: TemplateThumbnail(
          template: template,
          branding: branding,
          languageCode: lang,
          modules: modules,
          aspectRatio: (width - 2 * bezel) / (height - bezel),
        ),
      ),
    );
  }
}
