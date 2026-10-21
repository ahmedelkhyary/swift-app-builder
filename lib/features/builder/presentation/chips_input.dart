import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/validators.dart';

/// Tags input for e-mail addresses.
///
/// Enter, comma, Tab or leaving the field turns the typed text into a chip.
/// Pasting several addresses (comma, space or new-line separated) creates one
/// chip each. Invalid text stays in the input with an error below; duplicates
/// (case-insensitive) are dropped with a short hint.
class EmailChipsInput extends StatefulWidget {
  const EmailChipsInput({
    super.key,
    required this.label,
    required this.emails,
    required this.onChanged,
    this.helper,
    this.hint,
    this.fieldKey,
  });

  final String label;
  final List<String> emails;
  final ValueChanged<List<String>> onChanged;
  final String? helper;
  final String? hint;

  /// Key applied to the inner [TextField] (used by tests).
  final Key? fieldKey;

  @override
  State<EmailChipsInput> createState() => _EmailChipsInputState();
}

class _EmailChipsInputState extends State<EmailChipsInput> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);
  bool _invalid = false;
  bool _duplicate = false;
  Timer? _duplicateTimer;

  static final _separators = RegExp(r'[,;\s]+');
  static final _newLinesToSpaces = TextInputFormatter.withFunction(
    (old, value) => value.text.contains('\n')
        ? value.copyWith(text: value.text.replaceAll(RegExp(r'\r?\n'), ' '))
        : value,
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text.trim().isNotEmpty) {
        _commit(_controller.text, last: true);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _duplicateTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final text = _controller.text;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        text.isEmpty &&
        widget.emails.isNotEmpty) {
      widget.onChanged([...widget.emails]..removeLast());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab && text.trim().isNotEmpty) {
      // A valid address becomes a chip and Tab moves on; an invalid one stays
      // put so the error is not skipped.
      final ok = _commit(text, last: true);
      return ok ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Converts [raw] into chips. With [last] false the trailing token (no
  /// separator after it yet) stays in the input. Returns true when nothing
  /// invalid is left behind.
  bool _commit(String raw, {required bool last}) {
    final parts = raw.split(_separators);
    final pending = last ? '' : parts.removeLast();
    final emails = [...widget.emails];
    final seen = {for (final e in emails) e.toLowerCase()};
    final rejected = <String>[];
    var duplicate = false;
    for (final token in parts) {
      final email = token.trim();
      if (email.isEmpty) continue;
      if (Validators.email(email) != null) {
        rejected.add(email);
      } else if (!seen.add(email.toLowerCase())) {
        duplicate = true;
      } else {
        emails.add(email);
      }
    }
    final remaining = [...rejected, if (pending.isNotEmpty) pending].join(' ');
    if (emails.length != widget.emails.length) widget.onChanged(emails);
    _controller.value = TextEditingValue(
      text: remaining,
      selection: TextSelection.collapsed(offset: remaining.length),
    );
    setState(() => _invalid = rejected.isNotEmpty);
    if (duplicate) _flashDuplicate();
    return rejected.isEmpty;
  }

  void _flashDuplicate() {
    _duplicateTimer?.cancel();
    setState(() => _duplicate = true);
    _duplicateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _duplicate = false);
    });
  }

  void _onTextChanged(String text) {
    if (_invalid) setState(() => _invalid = false);
    // A separator was typed or pasted: everything before it is complete.
    if (text.contains(_separators)) _commit(text, last: false);
  }

  void _remove(String email) =>
      widget.onChanged([...widget.emails]..remove(email));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final focused = _focus.hasFocus;
    final borderColor = _invalid
        ? AppColors.error
        : (focused ? AppColors.accent : AppColors.inputBorder);
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 15);
    final helperStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: AppColors.muted,
      height: 1.4,
    );

    Widget message(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text, style: helperStyle?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          container: true,
          label: widget.label,
          // aria-invalid: the error text below is announced as a live region.
          hint: _invalid ? l10n.errSupportEmailInvalid : widget.helper,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focus.requestFocus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: focused ? 1.5 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: (_invalid ? AppColors.error : AppColors.accent)
                              .withValues(alpha: 0.18),
                          spreadRadius: 3,
                        ),
                      ]
                    : const [],
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final maxW = box.maxWidth;
                  return ConstrainedBox(
                    // The field grows in height only; after about four lines
                    // of chips it scrolls inside instead.
                    constraints: const BoxConstraints(maxHeight: 156),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final e in widget.emails)
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxW),
                              child: _EmailChip(
                                email: e,
                                removeLabel: l10n.removeEmailLabel(e),
                                onRemove: () => _remove(e),
                              ),
                            ),
                          SizedBox(
                            // Alone it spans the whole row; after chips it takes at
                            // least 160px and wraps to the next line when out of room.
                            width: widget.emails.isEmpty
                                ? maxW
                                : (maxW < 180 ? maxW : 180),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextField(
                                key: widget.fieldKey,
                                controller: _controller,
                                focusNode: _focus,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                textAlign:
                                    Directionality.of(context) ==
                                        TextDirection.rtl
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: textStyle,
                                // Pasted new lines become separators instead of being
                                // dropped by the single-line field.
                                inputFormatters: [_newLinesToSpaces],
                                onChanged: _onTextChanged,
                                onSubmitted: (v) {
                                  _commit(v, last: true);
                                  _focus.requestFocus();
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintText: widget.emails.isEmpty
                                      ? widget.hint
                                      : null,
                                  hintTextDirection: TextDirection.ltr,
                                  hintStyle: textStyle?.copyWith(
                                    color: AppColors.muted.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_invalid)
          message(
            Icons.error_outline,
            l10n.errSupportEmailInvalid,
            AppColors.error,
          )
        else if (_duplicate)
          message(
            Icons.info_outline,
            l10n.hintSupportEmailDuplicate,
            AppColors.muted,
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

class _EmailChip extends StatelessWidget {
  const _EmailChip({
    required this.email,
    required this.removeLabel,
    required this.onRemove,
  });

  final String email;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsetsDirectional.only(start: 10, end: 2),
      decoration: BoxDecoration(
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: monoStyle().copyWith(
                  fontSize: 13,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: removeLabel,
            excludeSemantics: true,
            child: Tooltip(
              message: removeLabel,
              child: InkResponse(
                onTap: onRemove,
                radius: 16,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.close, size: 16, color: AppColors.accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
