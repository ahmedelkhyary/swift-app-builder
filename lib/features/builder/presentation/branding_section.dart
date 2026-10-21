import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/asset.dart';
import '../domain/asset_validator.dart';
import '../domain/color_tools.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'color_picker.dart';
import 'field_registry.dart';
import 'form_widgets.dart';
import 'interactive_preview.dart';
import 'l10n_ext.dart';
import 'phone_preview.dart';

/// Signature of the file chooser, replaceable in tests.
typedef FilePick =
    Future<({String name, Uint8List bytes})?> Function(List<String> extensions);

Future<({String name, Uint8List bytes})?> defaultFilePick(
  List<String> extensions,
) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  if (result.isEmpty) return null;
  final f = result.first;
  return (name: f.name, bytes: await f.readAsBytes());
}

final filePickProvider = Provider<FilePick>((ref) => defaultFilePick);

/// The color roles the config really has (no background/text colors exist).
enum ColorRole { primary, secondary, splash }

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
    if (logo == null || logo.isSvg) {
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
      ColorRole.splash: (l10n.roleSplash, l10n.roleDescSplash),
    };
    final color = _colorOf(d, _role);
    final ContrastStatus contrast = switch (_role) {
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
              if (errors[DraftField.primaryColor] != null ||
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
          child: _AssetPicker(
            kind: AssetKind.logo,
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
              _AssetPicker(
                kind: AssetKind.appIcon,
                label: l10n.appIconLabel,
                hint: l10n.appIconHint,
                asset: d.appIcon,
                field: DraftField.appIcon,
                error: errors[DraftField.appIcon],
                pickLabel: l10n.upload,
                changeLabel: l10n.upload,
              ),
              const Divider(height: 32),
              _AssetPicker(
                kind: AssetKind.splashLogo,
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

class _AssetPicker extends ConsumerStatefulWidget {
  const _AssetPicker({
    required this.kind,
    required this.label,
    required this.hint,
    required this.asset,
    required this.pickLabel,
    required this.changeLabel,
    this.field,
    this.error,
  });
  final AssetKind kind;
  final String label;
  final String hint;
  final PickedAsset? asset;
  final String pickLabel;
  final String changeLabel;
  final DraftField? field;
  final FieldError? error;

  @override
  ConsumerState<_AssetPicker> createState() => _AssetPickerState();
}

class _AssetPickerState extends ConsumerState<_AssetPicker> {
  AssetIssue? _issue;
  final FocusNode _node = FocusNode();
  late final FieldRegistry _registry = ref.read(fieldRegistryProvider);

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    if (f != null) _registry.register(f, _node);
  }

  @override
  void dispose() {
    final f = widget.field;
    if (f != null) _registry.unregister(f, _node);
    _node.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final isIcon = widget.kind == AssetKind.appIcon;
    final picked = await ref.read(filePickProvider)(
      isIcon ? const ['png'] : const ['png', 'svg'],
    );
    if (picked == null) return;
    final check = isIcon
        ? AssetValidator.validateIcon(picked.name, picked.bytes)
        : AssetValidator.validateLogo(picked.name, picked.bytes);
    if (!mounted) return;
    setState(() => _issue = check.issue);
    if (check.asset != null) {
      ref.read(draftProvider.notifier).setAsset(widget.kind, check.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = widget.asset;
    final issueText = _issue == null ? null : l10n.assetIssue(_issue!);
    // A missing file is only reported once the user pressed Next.
    final attempted = ref.watch(submitAttemptProvider(WizardSection.branding));
    final errorText =
        issueText ??
        (widget.error != null && attempted
            ? l10n.fieldError(widget.error!)
            : null);

    return Focus(
      focusNode: _node,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText == null
                    ? AppColors.inputBorder
                    : AppColors.error,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.fieldFill,
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(6),
            child: a == null
                ? const Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: AppColors.muted,
                  )
                : RuiLogo(logo: BrandLogo(a.bytes, isSvg: a.isSvg), size: 60),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                if (a != null)
                  Text(
                    '${a.name}${a.width != null ? '  ${a.width}×${a.height}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      key: ValueKey('upload-${widget.kind.name}'),
                      onPressed: _pick,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        a == null ? widget.pickLabel : widget.changeLabel,
                      ),
                    ),
                    if (a != null)
                      TextButton(
                        key: ValueKey('remove-${widget.kind.name}'),
                        onPressed: () {
                          setState(() => _issue = null);
                          ref
                              .read(draftProvider.notifier)
                              .setAsset(widget.kind, null);
                        },
                        child: Text(l10n.remove),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
