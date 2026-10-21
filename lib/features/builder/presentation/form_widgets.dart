import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'l10n_ext.dart';

/// Labelled text field bound to an external value (the draft).
///
/// The label always sits above the input. Errors appear only after the field
/// lost focus once, or after the user pressed Next on its section, so a fresh
/// form is not shown in red.
class DraftTextField extends ConsumerStatefulWidget {
  const DraftTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.field,
    this.fieldKey,
    this.error,
    this.messages = const {},
    this.helper,
    this.hint,
    this.required = false,
    this.ltr = false,
    this.mono = false,
    this.enabled = true,
    this.readOnly = false,
    this.dashed = false,
    this.alwaysShowError = false,
    this.fixedPrefix,
    this.fillColor,
    this.badge,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  /// Registers the field so Next can scroll to / focus it when invalid.
  final DraftField? field;

  /// Key applied to the underlying [TextField] (used by tests).
  final Key? fieldKey;
  final FieldError? error;

  /// Field-specific replacements for the generic error texts.
  final Map<FieldError, String> messages;
  final String? helper;
  final String? hint;
  final bool required;

  /// Force left-to-right input (package names, emails, hex, ids).
  final bool ltr;
  final bool mono;
  final bool enabled;
  final bool readOnly;

  /// Show the error as soon as it exists (async checks), not only after the
  /// field was left or Next was pressed.
  final bool alwaysShowError;

  /// A read-only addon shown inside the field before the editable text (for
  /// example `com.excp.`). It is not part of [value] and cannot be edited,
  /// selected, typed over or pasted away. The field itself is laid out
  /// left-to-right; label, helper and errors keep the page direction.
  final String? fixedPrefix;

  /// Dashed outline, used for fields that mirror another value.
  final bool dashed;
  final Color? fillColor;

  /// Small widget shown next to the label (e.g. the "Auto" pill).
  final Widget? badge;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  ConsumerState<DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends ConsumerState<DraftTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();
  late final FieldRegistry _registry = ref.read(fieldRegistryProvider);
  bool _blurred = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _blurred = true;
      setState(() {});
    });
    final f = widget.field;
    if (f != null) _registry.register(f, _focus);
  }

  @override
  void didUpdateWidget(DraftTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    final f = widget.field;
    if (f != null) _registry.unregister(f, _focus);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.field;
    final attempted =
        f != null && ref.watch(submitAttemptProvider(sectionOfField(f)));
    final err = widget.error;
    final showError =
        err != null && (widget.alwaysShowError || _blurred || attempted);
    final errorText = err == null
        ? null
        : (widget.messages[err] ?? l10n.fieldError(err));
    final focused = _focus.hasFocus;
    final radius = BorderRadius.circular(10);
    final textStyle = widget.mono
        ? monoStyle()
        : Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c, width: w),
    );
    final borderColor = showError
        ? AppColors.error
        : (focused ? AppColors.accent : AppColors.inputBorder);

    final bare = widget.fixedPrefix != null;
    Widget input = TextField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.ltr ? TextDirection.ltr : null,
      textAlign: widget.ltr ? TextAlign.left : TextAlign.start,
      style: textStyle,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isDense: false,
        hintText: widget.hint,
        hintStyle: textStyle?.copyWith(
          color: AppColors.muted.withValues(alpha: 0.75),
        ),
        hintTextDirection: widget.ltr ? TextDirection.ltr : null,
        filled: !bare,
        fillColor: widget.enabled
            ? (widget.fillColor ?? AppColors.surface)
            : AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        border: widget.dashed || bare ? InputBorder.none : border(borderColor),
        enabledBorder: widget.dashed || bare
            ? InputBorder.none
            : border(borderColor),
        disabledBorder: widget.dashed || bare
            ? InputBorder.none
            : border(AppColors.inputBorder),
        focusedBorder: widget.dashed || bare
            ? InputBorder.none
            : border(showError ? AppColors.error : AppColors.accent, 1.5),
        suffixIcon: widget.suffix,
      ),
    );

    if (bare) {
      final prefix = widget.fixedPrefix!;
      input = Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: BoxDecoration(
            color: widget.fillColor ?? AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Read-only addon: not focusable, selectable or editable.
                ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('fixed-prefix'),
                    color: AppColors.pageBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Text(
                      prefix,
                      textDirection: TextDirection.ltr,
                      style: (textStyle ?? const TextStyle()).copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: input),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.dashed) {
      input = CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: AppColors.stepBorder,
          radius: 10,
        ),
        child: input,
      );
    } else {
      input = AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: (showError ? AppColors.error : AppColors.accent)
                        .withValues(alpha: 0.18),
                    spreadRadius: 3,
                  ),
                ]
              : const [],
        ),
        child: input,
      );
    }

    final helperStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: AppColors.muted,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: widget.label),
                    if (widget.required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.badge != null) ...[
              const SizedBox(width: 8),
              widget.badge!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          textField: true,
          label: widget.label,
          // aria-invalid equivalent: exposed through the error text below.
          child: input,
        ),
        if (showError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
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
                      style: helperStyle?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(widget.helper!, style: helperStyle),
          ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// White card with an optional icon + description header, used by every
/// wizard section.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final IconData? icon;

  /// Optional widget at the end of the header (e.g. an action button).
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
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
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.iconTile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Keeps the editable part of a package name well-formed while typing:
/// lowercases, drops spaces and every character except letters, digits,
/// underscores and dots, and ignores a pasted copy of the fixed prefix.
class PackageSuffixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.toLowerCase();
    if (text.startsWith(kPackagePrefix)) {
      text = text.substring(kPackagePrefix.length);
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Keeps the editable part of an iOS bundle ID well-formed while typing:
/// lowercases, turns pasted underscores into hyphens, drops spaces and every
/// other character except letters, digits, hyphens and dots, and ignores a
/// pasted copy of the fixed prefix.
class BundleSuffixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.toLowerCase().replaceAll('_', '-');
    if (text.startsWith(kPackagePrefix)) {
      text = text.substring(kPackagePrefix.length);
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9.-]'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
