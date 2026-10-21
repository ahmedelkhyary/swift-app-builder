import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/asset.dart';
import '../domain/color_tools.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'color_picker.dart';
import 'form_widgets.dart';
import 'interactive_preview.dart';
import 'image_source_input.dart';
import 'phone_preview.dart';

export 'image_source_input.dart'
    show FilePick, defaultFilePick, filePickProvider;

/// The color roles of the config. Background and text are optional: when
/// unset the template's own page / text colors apply.
enum ColorRole { primary, secondary, accent, background, text, splash }

/// Ready-made palettes: primary, secondary and accent together.
const _palettes = <(String, String, String, String)>[
  ('navy', '#213F80', '#29ABE2', '#2E9E5B'),
  ('teal', '#00695C', '#FFB300', '#2E7D32'),
  ('burgundy', '#7B1E3A', '#E0A526', '#2E7D32'),
  ('purple', '#4527A0', '#00B8D4', '#43A047'),
  ('charcoal', '#263238', '#FF7043', '#26A69A'),
];

const _defaultPageColor = Color(0xFFFFFFFF);
const _defaultTextColor = Color(0xFF1A1F2E);

/// Previous fixed presets, kept as "suggested colors".
const kPresetColors = <Color>[
  Color(0xFF1565C0),
  Color(0xFF0D47A1),
  Color(0xFF00897B),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFFFFB300),
  Color(0xFF455A64),
  Color(0xFF212121),
  Color(0xFFFFFFFF),
];

const _wideBreakpoint = 1100.0;
const _mobileBreakpoint = 768.0;

/// Step 2: colors (inline picker), logo, icon / splash, font + live preview.
class BrandingSection extends ConsumerStatefulWidget {
  const BrandingSection({super.key});

  @override
  ConsumerState<BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends ConsumerState<BrandingSection> {
  ColorRole _role = ColorRole.primary;
  Uint8List? _logoBytes;
  List<Color> _logoColors = const [];

  List<Color> _colorsFor(PickedAsset? logo) {
    if (logo == null || logo.isSvg || logo.isRemote) {
      _logoBytes = null;
      return _logoColors = const [];
    }
    if (!identical(_logoBytes, logo.bytes)) {
      _logoBytes = logo.bytes;
      _logoColors = dominantColors(logo.bytes);
    }
    return _logoColors;
  }

  Color _colorOf(AppConfigDraft d, ColorRole r) => switch (r) {
    ColorRole.primary => d.primaryColor,
    ColorRole.secondary => d.secondaryColor,
    ColorRole.accent => d.accentColor,
    ColorRole.background => d.backgroundColor ?? _defaultPageColor,
    ColorRole.text => d.textColor ?? _defaultTextColor,
    ColorRole.splash => parseHexColor(d.splashHex) ?? Colors.white,
  };

  void _set(ColorRole r, Color c) {
    final n = ref.read(draftProvider.notifier);
    final hex = hexOf(c);
    switch (r) {
      case ColorRole.primary:
        n.setPrimary(hex);
      case ColorRole.secondary:
        n.setSecondary(hex);
      case ColorRole.accent:
        n.setAccent(hex);
      case ColorRole.background:
        n.setBackground(hex);
      case ColorRole.text:
        n.setText(hex);
      case ColorRole.splash:
        n.setSplashColor(hex);
    }
  }

  void _extract(AppLocalizations l10n, PickedAsset logo) {
    final colors = dominantColors(logo.bytes);
    final messenger = ScaffoldMessenger.of(context);
    if (colors.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noColorsInLogo)));
      return;
    }
    _set(ColorRole.primary, colors[0]);
    if (colors.length > 1) _set(ColorRole.secondary, colors[1]);
    setState(() => _role = ColorRole.primary);
    messenger.showSnackBar(SnackBar(content: Text(l10n.colorsExtracted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final errors = DraftValidator.validateSection(d, WizardSection.branding);
    final width = MediaQuery.sizeOf(context).width;
    final logoColors = _colorsFor(d.logo);
    final mobile = width < _mobileBreakpoint;

    final roleInfo = {
      ColorRole.primary: (l10n.rolePrimary, l10n.roleDescPrimary),
      ColorRole.secondary: (l10n.roleSecondary, l10n.roleDescSecondary),
      ColorRole.accent: (l10n.roleAccent, l10n.roleDescAccent),
      ColorRole.background: (l10n.roleBackground, l10n.roleDescBackground),
      ColorRole.text: (l10n.roleText, l10n.roleDescText),
      ColorRole.splash: (l10n.roleSplash, l10n.roleDescSplash),
    };
    final color = _colorOf(d, _role);
    final pageColor = d.backgroundColor ?? _defaultPageColor;
    final textColor = d.textColor ?? _defaultTextColor;
    final ContrastStatus contrast = switch (_role) {
      ColorRole.accent => () {
        final r = contrastRatio(color, pageColor);
        final s = r.toStringAsFixed(1);
        return ContrastStatus(
          ratio: r,
          okMessage: l10n.contrastOkAccent(s),
          warnMessage: l10n.contrastWarnAccent(s),
        );
      }(),
      ColorRole.background || ColorRole.text => () {
        final r = contrastRatio(textColor, pageColor);
        final s = r.toStringAsFixed(1);
        return ContrastStatus(
          ratio: r,
          okMessage: l10n.contrastOkText(s),
          warnMessage: l10n.contrastWarnText(s),
        );
      }(),
      ColorRole.splash => () {
        final r = contrastRatio(d.primaryColor, color);
        final s = r.toStringAsFixed(1);
        return ContrastStatus(
          ratio: r,
          okMessage: l10n.contrastOkBg(s),
          warnMessage: l10n.contrastWarnBg(s),
        );
      }(),
      _ => () {
        final r = contrastRatio(color, Colors.white);
        final s = r.toStringAsFixed(1);
        return ContrastStatus(
          ratio: r,
          okMessage: l10n.contrastOkWhite(s),
          warnMessage: l10n.contrastWarnWhite(s),
        );
      }(),
    };

    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.sectionBranding,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.brandingSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        // ---- colors ----
        SectionCard(
          title: l10n.colorsCardTitle,
          trailing: (d.logo != null && !d.logo!.isSvg)
              ? OutlinedButton.icon(
                  key: const ValueKey('extract-colors'),
                  onPressed: () => _extract(l10n, d.logo!),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(l10n.extractColors),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: l10n.roleTabsLabel,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cols = mobile ? 2 : 3;
                    final w = (box.maxWidth - 12 * (cols - 1)) / cols;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final r in ColorRole.values)
                          SizedBox(
                            width: w,
                            child: _RoleTab(
                              key: ValueKey('role-${r.name}'),
                              name: roleInfo[r]!.$1,
                              color: _colorOf(d, r),
                              selected: r == _role,
                              onTap: () => setState(() => _role = r),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // ---- ready-made palettes + reset ----
              Text(
                l10n.palettesTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _palettes)
                    _PaletteChip(
                      key: ValueKey('palette-${p.$1}'),
                      label: switch (p.$1) {
                        'navy' => l10n.paletteNavy,
                        'teal' => l10n.paletteTeal,
                        'burgundy' => l10n.paletteBurgundy,
                        'purple' => l10n.palettePurple,
                        _ => l10n.paletteCharcoal,
                      },
                      colors: [
                        for (final h in [p.$2, p.$3, p.$4]) parseHexColor(h)!,
                      ],
                      selected:
                          d.primaryHex.toUpperCase() == p.$2 &&
                          d.secondaryHex.toUpperCase() == p.$3 &&
                          d.accentHex.toUpperCase() == p.$4,
                      onTap: () => ref
                          .read(draftProvider.notifier)
                          .setPalette(p.$2, p.$3, p.$4),
                    ),
                  TextButton.icon(
                    key: const ValueKey('reset-colors'),
                    onPressed: ref.read(draftProvider.notifier).resetColors,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text(l10n.resetColors),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ColorPickerPanel(
                key: ValueKey('picker-${_role.name}'),
                color: color,
                onChanged: (c) => _set(_role, c),
                roleName: roleInfo[_role]!.$1,
                roleDescription: roleInfo[_role]!.$2,
                presets: kPresetColors,
                logoColors: logoColors,
                contrast: contrast,
              ),
              if ((_role == ColorRole.background &&
                      d.backgroundHex.isNotEmpty) ||
                  (_role == ColorRole.text && d.textHex.isNotEmpty))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const ValueKey('role-clear'),
                    onPressed: () {
                      final n = ref.read(draftProvider.notifier);
                      _role == ColorRole.background
                          ? n.setBackground('')
                          : n.setText('');
                    },
                    child: Text(l10n.useTemplateDefault),
                  ),
                ),
              if (errors[DraftField.primaryColor] != null ||
                  errors[DraftField.accentColor] != null ||
                  errors[DraftField.backgroundColor] != null ||
                  errors[DraftField.textColor] != null ||
                  errors[DraftField.secondaryColor] != null ||
                  errors[DraftField.splashColor] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.errInvalidHex,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
        // ---- logo ----
        SectionCard(
          title: l10n.logoLabel,
          child: ImageSourceInput(
            kind: AssetKind.logo,
            allowUrl: true,
            label: l10n.logoLabel,
            hint: l10n.logoHint,
            asset: d.logo,
            field: DraftField.logo,
            error: errors[DraftField.logo],
            pickLabel: l10n.uploadLogo,
            changeLabel: l10n.changeLogo,
          ),
        ),
        // ---- icon + splash ----
        SectionCard(
          title: l10n.iconSplashCard,
          child: Column(
            children: [
              ImageSourceInput(
                kind: AssetKind.appIcon,
                allowUrl: true,
                label: l10n.appIconLabel,
                hint: l10n.appIconHint,
                asset: d.appIcon,
                field: DraftField.appIcon,
                error: errors[DraftField.appIcon],
                pickLabel: l10n.upload,
                changeLabel: l10n.upload,
              ),
              const Divider(height: 32),
              ImageSourceInput(
                kind: AssetKind.splashLogo,
                allowUrl: true,
                label: l10n.splashLogoLabel,
                hint: l10n.splashLogoHint,
                asset: d.splashLogo,
                pickLabel: l10n.upload,
                changeLabel: l10n.upload,
              ),
            ],
          ),
        ),
        // ---- font ----
        SectionCard(
          title: l10n.fontFamily,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('font-family'),
            initialValue: d.fontFamily,
            decoration: InputDecoration(
              labelText: l10n.fontFamily,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: [
              for (final f in kFontFamilies)
                DropdownMenuItem(value: f, child: Text(f)),
            ],
            onChanged: (v) =>
                v == null ? null : ref.read(draftProvider.notifier).setFont(v),
          ),
        ),
      ],
    );

    const preview = BrandingPreviewPanel();
    if (width >= _wideBreakpoint) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: settings),
          const SizedBox(width: 32),
          const SizedBox(width: 400, child: preview),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [settings, const SizedBox(height: 8), preview],
    );
  }
}

/// A color role tab: swatch, role name and HEX code.
class _RoleTab extends StatelessWidget {
  const _RoleTab({
    super.key,
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hex = hexOf(color);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$name $hex',
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFF3F6FC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1F000000)),
                  ),
                ),
                const SizedBox(width: 10),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hex,
                        textDirection: TextDirection.ltr,
                        style: monoStyle(
                          size: 12,
                        ).copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Live preview" card for this step: the Simple template's home screen
/// with the current colors and logo, updating as the user picks.
class BrandingPreviewPanel extends ConsumerStatefulWidget {
  const BrandingPreviewPanel({super.key});

  @override
  ConsumerState<BrandingPreviewPanel> createState() =>
      _BrandingPreviewPanelState();
}

class _BrandingPreviewPanelState extends ConsumerState<BrandingPreviewPanel> {
  late final DemoSession _session = DemoSession(
    repository: MockDemoRepository(latency: Duration.zero),
  )..signInDemo();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final lang = ref.watch(previewLanguageProvider) ?? d.defaultLanguage;
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
          Text(
            l10n.livePreview,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.livePreviewSubtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
              session: _session,
              template: AppTemplate.simple,
              branding: d.branding,
              languageCode: lang,
              device: device,
            ),
          ),
        ],
      ),
    );
  }
}

/// A ready-made palette: three color dots and a name.
class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    super.key,
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.inputBorder,
              width: selected ? 2 : 1,
            ),
            color: selected ? AppColors.iconTile : AppColors.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in colors)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsetsDirectional.only(end: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
