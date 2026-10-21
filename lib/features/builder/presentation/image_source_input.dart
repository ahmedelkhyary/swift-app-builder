import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/image_url_loader.dart';
import '../application/providers.dart';
import '../domain/asset.dart';
import '../domain/asset_validator.dart';
import '../domain/draft.dart';
import '../domain/image_source.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'interactive_preview.dart' show Segmented;
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

/// One image input of the wizard: "Upload file" or "Image URL", with its own
/// mode, URL, loading state, error and preview. Used for the logo, the app icon
/// and the splash logo (any other image field should use it too).
///
/// - [label] / [hint]: title and description (formats, minimum or exact size,
///   transparency rules, and whether it is optional).
/// - [asset]: the current value; changes go through the draft controller.
/// - [allowUrl]: offer "Image URL" next to "Upload file".
class ImageSourceInput extends ConsumerStatefulWidget {
  const ImageSourceInput({
    super.key,
    required this.kind,
    required this.label,
    required this.hint,
    required this.asset,
    required this.pickLabel,
    required this.changeLabel,
    this.field,
    this.error,
    this.allowUrl = false,
  });

  /// Offers "Image URL" next to "Upload file" (logo and app icon).
  final bool allowUrl;
  final AssetKind kind;
  final String label;
  final String hint;
  final PickedAsset? asset;
  final String pickLabel;
  final String changeLabel;
  final DraftField? field;
  final FieldError? error;

  @override
  ConsumerState<ImageSourceInput> createState() => ImageSourceInputState();
}

class ImageSourceInputState extends ConsumerState<ImageSourceInput> {
  AssetIssue? _issue;
  UrlFailure? _failure;
  UrlImageResult? _sized;
  bool _loading = false;
  late final TextEditingController _url = TextEditingController(
    text: widget.asset?.sourceUrl ?? '',
  );
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
    _url.dispose();
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

  /// The remembered source; defaults to the URL when the image came from one.
  AssetSource get _source =>
      ref.watch(assetSourceProvider(widget.kind)) ??
      (widget.asset?.sourceUrl != null ? AssetSource.url : AssetSource.file);

  /// Loads the typed link. The current image is only replaced once the new
  /// one passed the same checks as an uploaded file.
  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _issue = null;
      _failure = null;
    });
    final result = await loadImageFromUrl(
      _url.text,
      widget.kind,
      ref.read(imageFetchProvider),
      probe: ref.read(imageProbeProvider),
      ownBuckets: ref.read(ownStorageBucketsProvider),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = result.failure;
      _issue = result.issue;
      _sized = result.width == null ? null : result;
    });
    if (result.asset != null) {
      ref.read(draftProvider.notifier).setAsset(widget.kind, result.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = widget.asset;
    final urlMode = widget.allowUrl && _source == AssetSource.url;
    final failureText = switch (_failure) {
      UrlFailure.invalid => l10n.imageUrlInvalid,
      UrlFailure.unreachable => l10n.imageUrlLoadFailed,
      UrlFailure.unsupported => l10n.imageUrlUnsupported,
      UrlFailure.notCopyable => l10n.imageUrlNotCopyable,
      null => null,
    };
    final sized = _sized;
    final issueText =
        failureText ??
        (sized != null && _issue != null
            ? l10n.imageSizeMismatch(
                widget.kind == AssetKind.appIcon
                    ? l10n.requiredIconSize
                    : l10n.requiredLogoSize,
                '${sized.width}×${sized.height}',
              )
            : (_issue == null ? null : l10n.assetIssue(_issue!)));
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
                : RuiLogo(logo: brandLogoOf(a), size: 60),
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

                if (widget.allowUrl) ...[
                  Semantics(
                    container: true,

                    label: l10n.assetSourceLabel,

                    child: Segmented<AssetSource>(
                      key: ValueKey('source-${widget.kind.name}'),

                      value: urlMode ? AssetSource.url : AssetSource.file,

                      options: {
                        AssetSource.file: l10n.assetSourceFile,

                        AssetSource.url: l10n.assetSourceUrl,
                      },

                      onChanged: (v) {
                        // Only the mode changes; the current image stays until a new one

                        // has been confirmed.

                        setState(() {
                          _issue = null;

                          _failure = null;
                        });

                        ref
                                .read(assetSourceProvider(widget.kind).notifier)
                                .state =
                            v;
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],

                if (urlMode) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: TextField(
                          key: ValueKey('url-${widget.kind.name}'),

                          controller: _url,

                          keyboardType: TextInputType.url,

                          textDirection: TextDirection.ltr,

                          textAlign: TextAlign.left,

                          enabled: !_loading,

                          onSubmitted: (_) => _load(),

                          decoration: InputDecoration(
                            hintText: l10n.imageUrlPlaceholder,

                            isDense: true,

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      FilledButton(
                        key: ValueKey('load-${widget.kind.name}'),

                        onPressed: _loading ? null : _load,

                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 44),
                        ),

                        child: _loading
                            ? const SizedBox(
                                width: 18,

                                height: 18,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                a == null
                                    ? l10n.imageUrlLoad
                                    : l10n.imageUrlChange,
                              ),
                      ),
                    ],
                  ),

                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),

                      child: Semantics(
                        liveRegion: true,

                        child: Text(
                          l10n.imageUrlLoading,

                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 6),
                ],

                Wrap(
                  spacing: 8,

                  runSpacing: 4,
                  children: [
                    if (!urlMode)
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
                          setState(() {
                            _issue = null;
                            _failure = null;
                            _url.clear();
                          });
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
