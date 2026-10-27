import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../data/payment_backend.dart';
import '../domain/payment_gateways.dart';
import '../domain/payments.dart';
import '../domain/validators.dart';
import 'field_registry.dart';
import 'form_widgets.dart';

const _narrow = 700.0;

/// Step 5: the payment gateways the generated app offers. Two cards: pick the
/// gateways as tiles, then fill in each selected gateway's credentials in an
/// accordion. Everything is generated from [kPaymentGateways]; nothing here is
/// gateway-specific.
class PaymentsSection extends ConsumerStatefulWidget {
  const PaymentsSection({super.key});

  @override
  ConsumerState<PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends ConsumerState<PaymentsSection> {
  /// Rows the user opened or closed; null until they touch one (then the
  /// first incomplete row is the open one).
  Set<String>? _open;

  /// Selected gateways that have credentials, in selection order.
  final List<String> _order = [];

  bool _initialized = false;

  void _syncOrder(PaymentsDraft p) {
    _order.removeWhere((id) => !p.isEnabled(id));
    for (final id in p.enabledIds) {
      if (!_order.contains(id)) {
        _order.add(id);
        // A newly selected gateway opens so its fields are right there.
        if (_initialized) _open = {...?_open, id};
      }
    }
    _initialized = true;
  }

  Set<String> _openRows(PaymentsDraft p, Map<String, Set<String>> missing) {
    final open = _open;
    if (open != null) return open;
    for (final id in _order) {
      if (missing.containsKey(id)) return {id};
    }
    return const {};
  }

  void _toggleRow(String id, Set<String> current) => setState(() {
    _open = current.contains(id)
        ? ({...current}..remove(id))
        : {...current, id};
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payments = ref.watch(draftProvider.select((d) => d.payments));
    final attempted = ref.watch(submitAttemptProvider(WizardSection.payments));
    final errors = payments.validate();
    final c = ref.read(draftProvider.notifier);
    _syncOrder(payments);
    final rows = [
      for (final id in _order)
        if (paymentGatewayById(id)!.fields.isNotEmpty) id,
    ];
    final open = _openRows(payments, errors.missing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          icon: Icons.credit_card,
          title: l10n.paymentsChooseTitle,
          description: l10n.paymentsChooseDesc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TileGrid(
                payments: payments,
                onToggle: (id) =>
                    c.setGatewayEnabled(id, !payments.isEnabled(id)),
              ),
              if (attempted && errors.noneEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _InlineMessage(
                    key: const ValueKey('payments-none-enabled'),
                    text: l10n.errNoGatewayEnabled,
                    icon: Icons.error_outline,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          icon: Icons.link,
          title: l10n.paymentsDetailsTitle,
          description: l10n.paymentsDetailsDesc,
          trailing: _EnvironmentToggle(
            env: payments.env,
            onChanged: c.setPaymentEnv,
          ),
          child: rows.isEmpty
              ? Text(
                  l10n.paymentsDetailsEmpty,
                  key: const ValueKey('payments-details-empty'),
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                )
              : Column(
                  children: [
                    for (final id in rows)
                      _GatewayRow(
                        gateway: paymentGatewayById(id)!,
                        payments: payments,
                        missing: errors.missing[id] ?? const {},
                        expanded: open.contains(id),
                        onToggle: () => _toggleRow(id, open),
                      ),
                  ],
                ),
        ),
        _InlineMessage(
          key: const ValueKey('payments-secrets-note'),
          text: l10n.paymentsSecretsNote,
          icon: Icons.lock_outline,
          color: AppColors.muted,
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentToggle extends StatelessWidget {
  const _EnvironmentToggle({required this.env, required this.onChanged});
  final PaymentEnv env;
  final ValueChanged<PaymentEnv> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<PaymentEnv>(
      key: const ValueKey('payments-env'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: PaymentEnv.test,
          label: Text(l10n.paymentsEnvTest),
        ),
        ButtonSegment(
          value: PaymentEnv.live,
          label: Text(l10n.paymentsEnvLive),
        ),
      ],
      selected: {env},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.payments, required this.onToggle});
  final PaymentsDraft payments;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 760 ? 3 : (box.maxWidth >= 460 ? 2 : 1);
        final width = (box.maxWidth - 16 * (cols - 1)) / cols;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final g in kPaymentGateways)
              SizedBox(
                width: width,
                child: _GatewayTile(
                  gateway: g,
                  selected: payments.isEnabled(g.id),
                  onTap: () => onToggle(g.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GatewayTile extends StatelessWidget {
  const _GatewayTile({
    required this.gateway,
    required this.selected,
    required this.onTap,
  });
  final PaymentGateway gateway;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final g = gateway;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.gatewayEnable(g.name(lang)),
      child: Material(
        color: selected ? AppColors.iconTile : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('gateway-tile-${g.id}'),
          borderRadius: radius,
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Logo(gateway: g),
                      const SizedBox(height: 12),
                      Text(
                        g.name(lang),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RegionTags(gateway: g),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in g.supportedMethods.take(3))
                            _Chip(paymentMethodLabel(m, lang)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    key: ValueKey('gateway-check-${g.id}'),
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.iconTile,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.accent),
    ),
  );
}

const _successColor = Color(0xFF1E7B45);
const _warningColor = Color(0xFFB26A00);

class _GatewayRow extends ConsumerWidget {
  const _GatewayRow({
    required this.gateway,
    required this.payments,
    required this.missing,
    required this.expanded,
    required this.onToggle,
  });

  final PaymentGateway gateway;
  final PaymentsDraft payments;

  /// Required fields still empty in the current environment.
  final Set<String> missing;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final g = gateway;
    final isDefault = payments.defaultGateway == g.id;
    final complete = missing.isEmpty;
    final statusColor = complete ? _successColor : _warningColor;
    void setDefault() =>
        ref.read(draftProvider.notifier).setDefaultGateway(g.id);

    return Container(
      key: ValueKey('gateway-row-${g.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('gateway-row-header-${g.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: FittedBox(child: _Logo(gateway: g)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          g.name(lang),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          key: ValueKey('gateway-status-${g.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            complete
                                ? l10n.gatewayStatusComplete
                                : l10n.gatewayStatusMissing(missing.length),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width < 600)
                    IconButton(
                      key: ValueKey('gateway-star-${g.id}'),
                      tooltip: isDefault
                          ? l10n.gatewayIsDefault
                          : l10n.gatewaySetDefault,
                      onPressed: isDefault ? null : setDefault,
                      icon: Icon(
                        isDefault ? Icons.star : Icons.star_border,
                        color: isDefault ? _warningColor : AppColors.muted,
                      ),
                    )
                  else
                    TextButton.icon(
                      key: ValueKey('gateway-star-${g.id}'),
                      onPressed: isDefault ? null : setDefault,
                      icon: Icon(
                        isDefault ? Icons.star : Icons.star_border,
                        size: 20,
                        color: isDefault ? _warningColor : AppColors.muted,
                      ),
                      label: Text(
                        isDefault
                            ? l10n.gatewayIsDefault
                            : l10n.gatewaySetDefault,
                        style: TextStyle(
                          color: isDefault ? _warningColor : AppColors.accent,
                        ),
                      ),
                    ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  _Fields(gateway: g, payments: payments, missing: missing),
                  const SizedBox(height: 18),
                  _Actions(gateway: g, payments: payments),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.gateway, required this.payments});
  final PaymentGateway gateway;
  final PaymentsDraft payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final env = payments.env;
    final test = ref.watch(
      gatewayTestProvider.select(
        (m) => m['${gateway.id}/${env.name}'] ?? const GatewayTestState(),
      ),
    );

    void runTest() {
      if (payments.validate().missing.containsKey(gateway.id)) {
        // Shows the inline errors on the empty required fields.
        ref.read(submitAttemptProvider(WizardSection.payments).notifier).state =
            true;
        return;
      }
      ref.read(gatewayTestProvider.notifier).run(gateway.id, env);
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: ValueKey('gateway-test-${gateway.id}'),
          onPressed: test.running ? null : runTest,
          icon: test.running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(
            test.running ? l10n.gatewayTesting : l10n.gatewayTestConnection,
          ),
        ),
        if (test.result case final r?) _TestResult(result: r, id: gateway.id),
      ],
    );
  }
}

/// The gateway's official logo on a white 48x48 tile (white in dark mode too,
/// unless the gateway has a dark variant). The SVG is shown as it is: contained,
/// never recolored, cropped or stretched. A missing or broken file falls back to
/// the gateway's initials.
class _Logo extends StatelessWidget {
  const _Logo({required this.gateway});
  final PaymentGateway gateway;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = (dark ? gateway.logoDark : null) ?? gateway.logo;
    final initials = Center(
      child: Text(
        gateway.initials,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ),
      ),
    );
    return Container(
      key: ValueKey('gateway-logo-${gateway.id}'),
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // Stays white in dark mode: the logos are made for a light ground.
        color: dark && gateway.logoDark != null
            ? const Color(0xFF1A1F2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: asset == null
          ? initials
          : SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              // The alt text of the logo.
              semanticsLabel: gateway.name(lang),
              errorBuilder: (_, _, _) => initials,
            ),
    );
  }
}

/// Country tags of a gateway: a 16x12 flag plus the name; the Gulf gets a
/// neutral globe, with a tooltip naming the countries it covers.
class _RegionTags extends StatelessWidget {
  const _RegionTags({required this.gateway});
  final PaymentGateway gateway;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in gateway.regions)
          _RegionTag(region: r, gulfCountries: gateway.gulfCountries),
      ],
    );
  }
}

class _RegionTag extends StatefulWidget {
  const _RegionTag({required this.region, required this.gulfCountries});
  final GatewayRegion region;
  final List<String> gulfCountries;

  @override
  State<_RegionTag> createState() => _RegionTagState();
}

class _RegionTagState extends State<_RegionTag> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final r = widget.region;
    final name = switch (r) {
      GatewayRegion.eg => l10n.regionEg,
      GatewayRegion.sa => l10n.regionSa,
      GatewayRegion.gulf => l10n.regionGulf,
    };
    final tag = Container(
      key: ValueKey('region-${r.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (r) {
            // Real SVG flags (flag-icons): emoji flags do not render on Windows.
            GatewayRegion.eg => CountryFlags.flag(
              'eg',
              width: 16,
              height: 12,
              borderRadius: 2,
            ),
            GatewayRegion.sa => CountryFlags.flag(
              'sa',
              width: 16,
              height: 12,
              borderRadius: 2,
            ),
            GatewayRegion.gulf => const Icon(
              Icons.public,
              size: 14,
              color: AppColors.muted,
            ),
          },
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: AppColors.text),
          ),
        ],
      ),
    );
    if (r != GatewayRegion.gulf) return tag;
    final countries = [
      for (final c in widget.gulfCountries) _countryName(l10n, c),
    ].join(lang == 'ar' ? '، ' : ', ');
    // Hover shows the tooltip; so does keyboard focus.
    return Focus(
      onFocusChange: (focused) {
        if (focused) _tooltip.currentState?.ensureTooltipVisible();
      },
      child: Tooltip(key: _tooltip, message: countries, child: tag),
    );
  }
}

String _countryName(AppLocalizations l10n, String code) => switch (code) {
  'ae' => l10n.countryAe,
  'kw' => l10n.countryKw,
  'qa' => l10n.countryQa,
  'bh' => l10n.countryBh,
  'om' => l10n.countryOm,
  _ => code.toUpperCase(),
};

class _Fields extends ConsumerWidget {
  const _Fields({
    required this.gateway,
    required this.payments,
    required this.missing,
  });
  final PaymentGateway gateway;
  final PaymentsDraft payments;
  final Set<String> missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final c = ref.read(draftProvider.notifier);
    final env = payments.env;
    final draft = payments.gateway(gateway.id);

    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth < _narrow ? 1 : 2;
        final width = (box.maxWidth - 20 * (cols - 1)) / cols;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final f in gateway.fields)
              SizedBox(
                width: width,
                child: switch (f.type) {
                  GatewayFieldType.select => _SelectField(
                    // A new key per environment resets the shown value.
                    key: ValueKey('${gateway.id}-${f.key}-${env.name}'),
                    label: f.label(lang),
                    options: f.options,
                    value: draft.valueOf(gateway, env, f.key),
                    onChanged: (v) => c.setGatewayValue(gateway.id, f.key, v),
                  ),
                  _ => _CredentialField(
                    key: ValueKey('${gateway.id}-${f.key}-${env.name}'),
                    gatewayId: gateway.id,
                    field: f,
                    label: f.label(lang),
                    help: f.help(lang),
                    value: draft.valueOf(gateway, env, f.key),
                    error: missing.contains(f.key) ? FieldError.required : null,
                    onChanged: (v) => c.setGatewayValue(gateway.id, f.key, v),
                  ),
                },
              ),
          ],
        );
      },
    );
  }
}

class _CredentialField extends StatefulWidget {
  const _CredentialField({
    super.key,
    required this.gatewayId,
    required this.field,
    required this.label,
    required this.help,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String gatewayId;
  final GatewayField field;
  final String label;
  final String? help;
  final String value;
  final FieldError? error;
  final ValueChanged<String> onChanged;

  @override
  State<_CredentialField> createState() => _CredentialFieldState();
}

class _CredentialFieldState extends State<_CredentialField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.field;
    return DraftTextField(
      label: widget.label,
      value: widget.value,
      onChanged: widget.onChanged,
      registryKey: paymentFieldKey(widget.gatewayId, f.key),
      section: WizardSection.payments,
      fieldKey: ValueKey('field-${widget.gatewayId}-${f.key}'),
      error: widget.error,
      required: f.required,
      hint: f.placeholder,
      helper: widget.help,
      ltr: true,
      mono: true,
      obscure: f.isSecret && !_revealed,
      suffix: f.isSecret
          ? IconButton(
              key: ValueKey('secret-toggle-${widget.gatewayId}-${f.key}'),
              tooltip: _revealed
                  ? l10n.gatewayHideSecret
                  : l10n.gatewayShowSecret,
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            )
          : null,
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o,
                child: Text(o, textDirection: TextDirection.ltr),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: border(AppColors.inputBorder),
            enabledBorder: border(AppColors.inputBorder),
            focusedBorder: border(AppColors.accent, 1.5),
          ),
        ),
      ],
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({required this.result, required this.id});
  final GatewayTestResult result;
  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ok = result.isOk;
    final text = switch (result.code) {
      GatewayTestResult.ok => l10n.gatewayTestOk,
      GatewayTestResult.invalidCredentials => l10n.gatewayTestInvalid,
      GatewayTestResult.notImplemented => l10n.gatewayTestNotImplemented,
      GatewayTestResult.unreachable => l10n.gatewayTestUnreachable,
      _ => l10n.gatewayTestError,
    };
    final color = ok ? const Color(0xFF1E7B45) : AppColors.error;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(
        key: ValueKey('gateway-test-result-$id'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: Text(
                result.detail == null || ok ? text : '$text (${result.detail})',
                style: TextStyle(fontSize: 13, color: color, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
