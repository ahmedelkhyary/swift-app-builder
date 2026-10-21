import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'app_id_status.dart';
import 'chips_input.dart';
import 'form_widgets.dart';

/// Two fields side by side, stacked below the tablet breakpoint.
class FieldPair extends StatelessWidget {
  const FieldPair({super.key, required this.first, this.second});
  final Widget first;

  /// Null leaves the second column empty (stacked layouts skip it).
  final Widget? second;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 768) {
      return Column(
        children: [
          first,
          if (second != null) ...[const SizedBox(height: 20), second!],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 20),
        Expanded(child: second ?? const SizedBox.shrink()),
      ],
    );
  }
}

class InfoSection extends ConsumerStatefulWidget {
  const InfoSection({super.key});

  @override
  ConsumerState<InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends ConsumerState<InfoSection> {
  bool _editingAppId = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = ref.watch(draftProvider);
    final c = ref.read(draftProvider.notifier);
    final errors = DraftValidator.validateSection(d, WizardSection.info);

    // appId availability (only meaningful for new apps)
    FieldError? appIdError = errors[DraftField.appId];
    // Backend availability (debounced, latest answer only).
    var appIdTaken = false;
    if (appIdError == null && d.appId.isNotEmpty) {
      final availability = ref.watch(appIdAvailabilityProvider(d.appId));
      if (availability.valueOrNull == false) {
        appIdError = FieldError.appIdTaken;
        appIdTaken = true;
      }
    }

    final autoBadge = (!d.appIdEdited && !d.existingApp)
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.iconTile,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.autoBadge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          )
        : null;

    Widget? appIdSuffix;
    if (!d.existingApp) {
      appIdSuffix = d.appIdEdited
          ? IconButton(
              key: const ValueKey('app-id-reset'),
              tooltip: l10n.resetAppId,
              icon: const Icon(Icons.auto_fix_high, size: 20),
              onPressed: () {
                setState(() => _editingAppId = false);
                c.regenerateAppId();
              },
            )
          : IconButton(
              key: const ValueKey('app-id-edit'),
              tooltip: l10n.editAppId,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                setState(() => _editingAppId = true);
                ref.read(fieldRegistryProvider).focus(DraftField.appId);
              },
            );
    }
    final appIdReadOnly = !d.existingApp && !d.appIdEdited && !_editingAppId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          icon: Icons.badge_outlined,
          title: l10n.cardNameIdTitle,
          description: l10n.cardNameIdDesc,
          child: Column(
            children: [
              FieldPair(
                first: DraftTextField(
                  fieldKey: const ValueKey('name-ar'),
                  field: DraftField.nameAr,
                  label: l10n.fieldNameAr,
                  required: true,
                  hint: l10n.phNameAr,
                  value: d.nameAr,
                  error: errors[DraftField.nameAr],
                  messages: {FieldError.required: l10n.errNameArRequired},
                  onChanged: c.setNameAr,
                ),
                second: DraftTextField(
                  fieldKey: const ValueKey('name-en'),
                  field: DraftField.nameEn,
                  label: l10n.fieldNameEn,
                  required: true,
                  hint: l10n.phNameEn,
                  value: d.nameEn,
                  ltr: true,
                  error: errors[DraftField.nameEn],
                  messages: {FieldError.required: l10n.errNameEnRequired},
                  onChanged: c.setNameEn,
                ),
              ),
              const SizedBox(height: 20),
              DraftTextField(
                fieldKey: const ValueKey('app-id'),
                field: DraftField.appId,
                label: l10n.fieldAppId,
                badge: autoBadge,
                value: d.appId,
                ltr: true,
                mono: true,
                fillColor: AppColors.fieldFill,
                readOnly: appIdReadOnly,
                helper: l10n.fieldAppIdHelper,
                error: appIdError,
                alwaysShowError: appIdTaken,
                messages: {FieldError.required: l10n.errAppIdRequired},
                suffix: appIdSuffix,
                onChanged: c.setAppId,
              ),
              AppIdStatus(appId: d.appId),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.phone_android,
          title: l10n.cardStoresTitle,
          description: l10n.cardStoresDesc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Android and iOS side by side (stacked on small screens).
              FieldPair(
                first: DraftTextField(
                  fieldKey: const ValueKey('android-package'),
                  field: DraftField.androidPackage,
                  label: l10n.fieldAndroidPackage,
                  required: true,
                  hint: l10n.phPackage,
                  helper: l10n.packagePreview(d.androidPackage),
                  // Only the part after the fixed prefix is editable.
                  fixedPrefix: kPackagePrefix,
                  value: packageSuffix(d.androidPackage),
                  inputFormatters: [PackageSuffixFormatter()],
                  ltr: true,
                  mono: true,
                  error: errors[DraftField.androidPackage],
                  messages: {FieldError.required: l10n.errPackageRequired},
                  onChanged: (suffix) =>
                      c.setAndroidPackage(kPackagePrefix + suffix),
                ),
                second: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DraftTextField(
                      fieldKey: const ValueKey('ios-bundle'),
                      field: DraftField.iosBundleId,
                      label: l10n.fieldIosBundleId,
                      required: true,
                      hint: l10n.phBundleId,
                      helper: l10n.bundlePreview(d.effectiveIosBundleId),
                      fixedPrefix: kPackagePrefix,
                      value: packageSuffix(d.effectiveIosBundleId),
                      inputFormatters: [BundleSuffixFormatter()],
                      ltr: true,
                      mono: true,
                      // Read-only while it follows the Android value.
                      readOnly: d.iosSameAsAndroid,
                      fillColor: d.iosSameAsAndroid
                          ? AppColors.fieldFill
                          : null,
                      error: errors[DraftField.iosBundleId],
                      messages: {FieldError.required: l10n.errBundleRequired},
                      onChanged: (suffix) =>
                          c.setIosBundleId(kPackagePrefix + suffix),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('ios-same'),
                      value: d.iosSameAsAndroid,
                      onChanged: (v) => c.setIosSameAsAndroid(v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.iosSameTitle,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (d.iosMirrorConverted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          key: const ValueKey('ios-converted-note'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.iosUnderscoreNote,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.business_outlined,
          title: l10n.cardClientTitle,
          description: l10n.cardClientDesc,
          child: Column(
            children: [
              DraftTextField(
                fieldKey: const ValueKey('client-name'),
                field: DraftField.clientName,
                label: l10n.fieldClientName,
                required: true,
                value: d.clientName,
                error: errors[DraftField.clientName],
                messages: {FieldError.required: l10n.errClientRequired},
                onChanged: c.setClientName,
              ),
              const SizedBox(height: 20),
              FieldPair(
                first: DraftTextField(
                  fieldKey: const ValueKey('client-email'),
                  field: DraftField.clientEmail,
                  label: l10n.fieldClientEmail,
                  required: true,
                  value: d.clientEmail,
                  ltr: true,
                  keyboardType: TextInputType.emailAddress,
                  error: errors[DraftField.clientEmail],
                  onChanged: c.setClientEmail,
                ),
                second: DraftTextField(
                  fieldKey: const ValueKey('client-phone'),
                  field: DraftField.clientPhone,
                  label: l10n.fieldClientPhone,
                  required: true,
                  value: d.clientPhone,
                  ltr: true,
                  keyboardType: TextInputType.phone,
                  error: errors[DraftField.clientPhone],
                  onChanged: c.setClientPhone,
                ),
              ),
              const SizedBox(height: 20),
              // Same two-column grid as the row above: aligned under the
              // primary email, second column left empty.
              FieldPair(
                first: EmailChipsInput(
                  fieldKey: const ValueKey('support-emails'),
                  label: l10n.fieldSupportEmails,
                  helper: l10n.helperSupportEmails,
                  hint: l10n.phSupportEmails,
                  emails: d.supportEmails,
                  onChanged: c.setSupportEmails,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
