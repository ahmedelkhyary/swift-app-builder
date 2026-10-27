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
  DraftField.paymentGateways,
  DraftField.paymentFields,
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
  DraftField.paymentGateways ||
  DraftField.paymentFields => WizardSection.payments,
};

/// Lets the wizard scroll to and focus the first invalid field.
class FieldRegistry {
  /// Keyed by a [DraftField], or by a string for fields that are generated
  /// (the payment credential fields, see [paymentFieldKey]). Insertion order is
  /// build order, i.e. top to bottom.
  final Map<Object, FocusNode> _nodes = {};

  void register(Object field, FocusNode node) => _nodes[field] = node;

  void unregister(Object field, FocusNode node) {
    if (_nodes[field] == node) _nodes.remove(field);
  }

  /// Moves keyboard focus to [field] if it is currently mounted.
  void focus(DraftField field) => _nodes[field]?.requestFocus();

  /// Focuses the first on-screen field of [keys] (generated fields), in the
  /// order they were built.
  bool focusFirstOf(Set<Object> keys) {
    for (final e in _nodes.entries) {
      final ctx = e.value.context;
      if (!keys.contains(e.key) || ctx == null) continue;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 250),
      );
      e.value.requestFocus();
      return true;
    }
    return false;
  }

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

/// Registry key of the credential field [key] of gateway [gatewayId].
String paymentFieldKey(String gatewayId, String key) => 'pay:$gatewayId:$key';
