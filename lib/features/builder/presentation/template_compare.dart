import 'dart:ui' show PointerDeviceKind;

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

const _phoneWidth = 306.0; // PhoneFrame body + side buttons at scale 1
const _slot = 340.0; // phone + gutter in the scrolling row
const _mobileBreakpoint = 768.0;

/// Step 4 sub-view: the ticked templates side by side, all showing the same
/// screen, each with its own "Choose this template" button.
class TemplateCompare extends ConsumerStatefulWidget {
  const TemplateCompare({super.key});

  @override
  ConsumerState<TemplateCompare> createState() => _TemplateCompareState();
}

class _TemplateCompareState extends ConsumerState<TemplateCompare> {
  late final List<String> _ids = List.of(
    ref.read(templatePickProvider).selected,
  );
  late final Map<String, DemoSession> _sessions;
  final ScrollController _scroll = ScrollController();
  DemoEntry _entry = DemoEntry.home;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(demoRepositoryProvider);
    final modules = {
      for (final m in ServiceModule.values)
        if (ref.read(draftProvider).enabledModules.contains(m.name)) m,
    };
    // One independent session per phone, so each keeps its own navigation.
    _sessions = {
      for (final id in _ids)
        id: DemoSession(repository: repo, enabledModules: modules),
    };
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  double _extent = _slot;

  void _onScroll() {
    final page = (_scroll.offset / _extent).round().clamp(0, _ids.length - 1);
    if (page != _page) setState(() => _page = page);
  }

  void _goTo(int page) {
    final target = page.clamp(0, _ids.length - 1);
    _scroll.animateTo(
      (target * _extent).clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showEverywhere(DemoEntry entry) {
    setState(() => _entry = entry);
    for (final s in _sessions.values) {
      s.jumpTo(entry);
    }
  }

  void _choose(String id) {
    ref.read(draftProvider.notifier).setTemplate(id);
    // The step after the template: payments, or Summary when the template has
    // no payments.
    final sections = ref.read(activeSectionsProvider);
    final next = sections[sections.indexOf(WizardSection.template) + 1];
    context.go('/builder/${next.name}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final lang = ref.watch(previewLanguageProvider) ?? d.defaultLanguage;
    final dark = ref.watch(previewDarkProvider);
    final device = ref.watch(previewDeviceProvider);
    final mobile = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    Widget phoneColumn(String id, double scale) {
      final name = l10n.templateName(id);
      return Semantics(
        container: true,
        label: name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhonePreview(
              key: ValueKey('compare-phone-$id'),
              session: _sessions[id]!,
              template: AppTemplate.byId(id),
              branding: d.branding,
              languageCode: lang,
              dark: dark,
              device: device,
              scale: scale,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: ValueKey('compare-choose-$id'),
              onPressed: () => _choose(id),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 44)),
              child: Text(l10n.chooseThisTemplate),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.compareHeading,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.compareSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: l10n.compareScreenLabel,
          child: Center(
            child: ScreenSwitcher(
              active: _entry,
              enabledModules: d.enabledModules,
              onSelect: _showEverywhere,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final n = _ids.length;
              if (!mobile && n <= 3) {
                // One row: shrink the phones if the row would not fit.
                final scale =
                    ((box.maxWidth - 32 * (n - 1)) / (n * _phoneWidth)).clamp(
                      0.6,
                      1.0,
                    );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) const SizedBox(width: 32),
                      phoneColumn(_ids[i], scale.toDouble()),
                    ],
                  ],
                );
              }
              // Scrolling row that snaps phone by phone (4+ templates, or one
              // phone at a time on mobile).
              _extent = mobile ? box.maxWidth : _slot;
              final scale = mobile
                  ? (box.maxWidth / _phoneWidth).clamp(0.6, 1.0).toDouble()
                  : 1.0;
              return Column(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                      scrollbars: false,
                    ),
                    child: SingleChildScrollView(
                      key: const ValueKey('compare-scroller'),
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: _SnapPhysics(itemExtent: _extent),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final id in _ids)
                            SizedBox(
                              width: _extent,
                              child: Center(child: phoneColumn(id, scale)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ArrowButton(
                        key: const ValueKey('compare-prev'),
                        label: l10n.comparePrevious,
                        icon: Icons.chevron_left,
                        onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                      ),
                      if (mobile)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.compareIndicator(_page + 1, n),
                            key: const ValueKey('compare-indicator'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 12),
                      _ArrowButton(
                        key: const ValueKey('compare-next'),
                        label: l10n.compareNext,
                        icon: Icons.chevron_right,
                        onPressed: _page < n - 1
                            ? () => _goTo(_page + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chevron that points "backwards"/"forwards" along the reading direction.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final flipped = rtl
        ? (icon == Icons.chevron_left
              ? Icons.chevron_right
              : Icons.chevron_left)
        : icon;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(flipped),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }
}

/// Settles on the nearest multiple of [itemExtent] (scroll snap).
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _target(ScrollMetrics m, double velocity) {
    var page = m.pixels / itemExtent;
    if (velocity < -toleranceFor(m).velocity) {
      page -= 0.5;
    } else if (velocity > toleranceFor(m).velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * itemExtent).clamp(
      m.minScrollExtent,
      m.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _target(position, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
