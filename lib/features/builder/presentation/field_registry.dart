import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/validators.dart';

/// Whether the user pressed Next on a section (errors are then shown on every
/// invalid field, not only on blurred ones).
final submitAttemptProvider = StateProvider.family<bool, WizardSection>(
  (ref, section) => false,
);

/// Visual top-to-bottom order of fields, used to find the first invalid one.
const _visualOrder = [
  DraftField.nameAr,
  DraftField.nameEn,
  DraftField.appId,
  DraftField.androidPackage,
  DraftField.iosBundleId,
  DraftField.clientName,
  DraftField.clientEmail,
  DraftField.clientPhone,
  DraftField.primaryColor,
  DraftField.secondaryColor,
  DraftField.accentColor,
  DraftField.backgroundColor,
  DraftField.textColor,
  DraftField.logo,
  DraftField.appIcon,
  DraftField.splashColor,
  DraftField.supportedLanguages,
  DraftField.modules,
];

WizardSection sectionOfField(DraftField f) => switch (f) {
  DraftField.nameAr ||
  DraftField.nameEn ||
  DraftField.appId ||
  DraftField.androidPackage ||
  DraftField.iosBundleId ||
  DraftField.clientName ||
  DraftField.clientEmail ||
  DraftField.clientPhone => WizardSection.info,
  DraftField.primaryColor ||
  DraftField.secondaryColor ||
  DraftField.accentColor ||
  DraftField.backgroundColor ||
  DraftField.textColor ||
  DraftField.splashColor ||
  DraftField.logo ||
  DraftField.appIcon => WizardSection.branding,
  DraftField.supportedLanguages => WizardSection.localization,
  DraftField.modules => WizardSection.template,
};

/// Lets the wizard scroll to and focus the first invalid field.
class FieldRegistry {
  final Map<DraftField, FocusNode> _nodes = {};

  void register(DraftField field, FocusNode node) => _nodes[field] = node;

  void unregister(DraftField field, FocusNode node) {
    if (_nodes[field] == node) _nodes.remove(field);
  }

  /// Moves keyboard focus to [field] if it is currently mounted.
  void focus(DraftField field) => _nodes[field]?.requestFocus();

  /// Focuses the first field of [errors] (in visual order) that is on screen.
  /// Returns true if a field was focused.
  bool focusFirstInvalid(Iterable<DraftField> errors) {
    final invalid = errors.toSet();
    for (final f in _visualOrder) {
      if (!invalid.contains(f)) continue;
      final node = _nodes[f];
      final ctx = node?.context;
      if (node == null || ctx == null) continue;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 250),
      );
      node.requestFocus();
      return true;
    }
    return false;
  }
}

final fieldRegistryProvider = Provider<FieldRegistry>((ref) => FieldRegistry());
