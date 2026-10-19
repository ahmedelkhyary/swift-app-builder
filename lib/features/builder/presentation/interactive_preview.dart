import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import 'form_widgets.dart' show DashedBorderPainter;
import 'phone_frame.dart';
import 'phone_preview.dart';

/// Preview-only state (not part of the saved config).
final previewLanguageProvider = StateProvider<String?>((ref) => null);
final previewDarkProvider = StateProvider<bool>((ref) => false);
final previewDeviceProvider = StateProvider<PhoneDevice>(
  (ref) => PhoneDevice.iphone,
);

/// The "live preview" card: header, controls, device stage, screen pills.
class InteractivePreview extends ConsumerWidget {
  const InteractivePreview({
    super.key,
    this.phoneScale = 1,
    this.showOpenFull = true,
  });

  final double phoneScale;
  final bool showOpenFull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final session = ref.watch(demoSessionProvider);
    final lang = ref.watch(previewLanguageProvider) ?? d.defaultLanguage;
    final dark = ref.watch(previewDarkProvider);
    final device = ref.watch(previewDeviceProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.livePreview,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.previewDemoShort,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                key: const ValueKey('preview-reset'),
                label: l10n.previewReset,
                icon: Icons.restart_alt,
                onPressed: session.reset,
              ),
              if (showOpenFull) ...[
                const SizedBox(width: 8),
                _IconBtn(
                  key: const ValueKey('preview-open-full'),
                  label: l10n.previewOpenFull,
                  icon: Icons.open_in_full,
                  onPressed: () => context.go('/preview'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Segmented<String>(
                key: const ValueKey('preview-lang'),
                value: lang,
                options: const {'ar': 'AR', 'en': 'EN'},
                onChanged: (v) =>
                    ref.read(previewLanguageProvider.notifier).state = v,
              ),
              Segmented<PhoneDevice>(
                key: const ValueKey('preview-device'),
                value: device,
                options: {
                  PhoneDevice.iphone: l10n.deviceIphone,
                  PhoneDevice.android: l10n.deviceAndroid,
                },
                onChanged: (v) =>
                    ref.read(previewDeviceProvider.notifier).state = v,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    key: const ValueKey('preview-dark'),
                    value: dark,
                    onChanged: (v) =>
                        ref.read(previewDarkProvider.notifier).state = v,
                  ),
                  Text(l10n.previewDark, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1F7),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: PhonePreview(
              session: session,
              template: AppTemplate.byId(d.templateId),
              branding: d.branding,
              languageCode: lang,
              dark: dark,
              device: device,
              scale: phoneScale,
            ),
          ),
          const SizedBox(height: 14),
          _ScreenPills(session: session, enabledModules: d.enabledModules),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 40,
          height: 40,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Segmented control: #F0F2F7 track, white active segment.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in options.entries)
            Semantics(
              button: true,
              selected: e.key == value,
              child: InkWell(
                key: ValueKey('seg-${e.key}'),
                onTap: () => onChanged(e.key),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 38,
                    minWidth: 52,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e.key == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: e.key == value
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: e.key == value
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: e.key == value ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScreenPills extends StatelessWidget {
  const _ScreenPills({required this.session, required this.enabledModules});
  final DemoSession session;
  final List<String> enabledModules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(DemoEntry, String, String?)>[
      (DemoEntry.home, l10n.jumpHome, null),
      (DemoEntry.login, l10n.jumpLogin, null),
      (DemoEntry.individuals, l10n.jumpIndividuals, 'individuals'),
      (DemoEntry.hourly, l10n.jumpHourly, 'hourly'),
      (DemoEntry.mediation, l10n.jumpMediation, 'mediation'),
    ];
    final moduleNames = {
      'individuals': l10n.moduleIndividuals,
      'hourly': l10n.moduleHourly,
      'mediation': l10n.moduleMediation,
    };
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final active = session.currentEntry;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 0,
          children: [
            for (final it in items)
              _Pill(
                key: ValueKey('jump-${it.$1.name}'),
                label: it.$2,
                active: active == it.$1,
                enabled: it.$3 == null || enabledModules.contains(it.$3),
                disabledTooltip: it.$3 == null
                    ? null
                    : l10n.enableModuleTooltip(moduleNames[it.$3]!),
                onTap: () => session.jumpTo(it.$1),
              ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.disabledTooltip,
  });

  final String label;
  final bool active;
  final bool enabled;
  final String? disabledTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.text
            : (enabled ? Colors.white : Colors.transparent),
        borderRadius: BorderRadius.circular(999),
        border: (active || !enabled)
            ? null
            : Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active
              ? Colors.white
              : (enabled ? AppColors.text : AppColors.muted),
        ),
      ),
    );
    Widget child = pill;
    if (!enabled) {
      child = CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: AppColors.stepBorder,
          radius: 18,
        ),
        child: pill,
      );
    }
    // 44px-high hit target around the 36px pill.
    final target = Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(height: 44, child: Center(child: child)),
      ),
    );
    return !enabled && disabledTooltip != null
        ? Tooltip(message: disabledTooltip!, child: target)
        : target;
  }
}
