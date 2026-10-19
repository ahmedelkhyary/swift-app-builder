import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/asset.dart';
import '../domain/asset_validator.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'form_widgets.dart';
import 'l10n_ext.dart';

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

class BrandingSection extends ConsumerWidget {
  const BrandingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final c = ref.read(draftProvider.notifier);
    final errors = DraftValidator.validateSection(d, WizardSection.branding);
    final ratio = contrastRatio(d.primaryColor, const Color(0xFFFFFFFF));
    final passes = ratio >= 4.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: l10n.sectionBranding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColorField(
                label: l10n.primaryColor,
                hex: d.primaryHex,
                field: DraftField.primaryColor,
                error: errors[DraftField.primaryColor],
                onChanged: c.setPrimary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    passes ? Icons.check_circle_outline : Icons.warning_amber,
                    size: 18,
                    color: passes ? Colors.green : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      passes
                          ? l10n.contrastOk(ratio.toStringAsFixed(1))
                          : l10n.contrastWarning(ratio.toStringAsFixed(1)),
                      key: const ValueKey('contrast-message'),
                      style: TextStyle(
                        color: passes ? null : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ColorField(
                label: l10n.secondaryColor,
                hex: d.secondaryHex,
                field: DraftField.secondaryColor,
                error: errors[DraftField.secondaryColor],
                onChanged: c.setSecondary,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: d.fontFamily,
                decoration: InputDecoration(
                  labelText: l10n.fontFamily,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final f in kFontFamilies)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => v == null ? null : c.setFont(v),
              ),
            ],
          ),
        ),
        SectionCard(
          title: '${l10n.logoLabel} / ${l10n.appIconLabel}',
          child: Column(
            children: [
              _AssetPicker(
                kind: AssetKind.logo,
                label: l10n.logoLabel,
                hint: l10n.logoHint,
                asset: d.logo,
                field: DraftField.logo,
                error: errors[DraftField.logo],
              ),
              const Divider(height: 32),
              _AssetPicker(
                kind: AssetKind.appIcon,
                label: l10n.appIconLabel,
                hint: l10n.appIconHint,
                asset: d.appIcon,
                field: DraftField.appIcon,
                error: errors[DraftField.appIcon],
              ),
            ],
          ),
        ),
        SectionCard(
          title: l10n.splashTitle,
          child: Column(
            children: [
              ColorField(
                label: l10n.splashBackground,
                hex: d.splashHex,
                field: DraftField.splashColor,
                error: errors[DraftField.splashColor],
                onChanged: c.setSplashColor,
              ),
              const SizedBox(height: 16),
              _AssetPicker(
                kind: AssetKind.splashLogo,
                label: l10n.splashLogoLabel,
                hint: l10n.splashLogoHint,
                asset: d.splashLogo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetPicker extends ConsumerStatefulWidget {
  const _AssetPicker({
    required this.kind,
    required this.label,
    required this.hint,
    required this.asset,
    this.field,
    this.error,
  });
  final AssetKind kind;
  final String label;
  final String hint;
  final PickedAsset? asset;
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
    final theme = Theme.of(context);
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText == null
                    ? theme.colorScheme.outline
                    : theme.colorScheme.error,
              ),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(4),
            child: a == null
                ? const Icon(Icons.image_outlined, size: 32)
                : RuiLogo(logo: BrandLogo(a.bytes, isSvg: a.isSvg), size: 80),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: theme.textTheme.titleSmall),
                Text(widget.hint, style: theme.textTheme.bodySmall),
                if (a != null)
                  Text(
                    '${a.name}${a.width != null ? '  ${a.width}×${a.height}' : ''}',
                    style: theme.textTheme.bodySmall,
                    textDirection: TextDirection.ltr,
                  ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      errorText,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.upload_file),
                      label: Text(l10n.upload),
                    ),
                    if (a != null)
                      TextButton(
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
