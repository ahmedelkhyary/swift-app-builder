import 'payment_gateways.dart';

enum PaymentEnv {
  test,
  live;

  static PaymentEnv? parse(Object? v) {
    for (final e in values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// What the user entered for one gateway.
///
/// [values] holds every field of the gateway per environment, secrets
/// included. Secrets only ever leave this object through [PaymentsDraft
/// .secrets]; [PaymentsDraft.toJson] and everything built on it leaves them
/// out.
class GatewayDraft {
  const GatewayDraft({this.enabled = false, this.values = const {}});

  final bool enabled;
  final Map<PaymentEnv, Map<String, String>> values;

  /// The entered value, or the field's default (select fields), or ''.
  String valueOf(PaymentGateway g, PaymentEnv env, String key) {
    final v = values[env]?[key];
    if (v != null && v.isNotEmpty) return v;
    return g.field(key)?.defaultValue ?? '';
  }

  GatewayDraft copyWith({bool? enabled}) =>
      GatewayDraft(enabled: enabled ?? this.enabled, values: values);

  GatewayDraft withValue(PaymentEnv env, String key, String value) {
    final envValues = {...?values[env], key: value};
    return GatewayDraft(
      enabled: enabled,
      values: {...values, env: Map.unmodifiable(envValues)},
    );
  }
}

/// Outcome of [PaymentsDraft.validate].
class PaymentErrors {
  const PaymentErrors({this.noneEnabled = false, this.missing = const {}});

  /// Nothing is enabled and "Configure later" was not chosen.
  final bool noneEnabled;

  /// `gatewayId` -> keys of the required fields that are empty (for the
  /// current environment).
  final Map<String, Set<String>> missing;

  bool get isEmpty => !noneEnabled && missing.isEmpty;
}

/// The "Payment methods" step.
class PaymentsDraft {
  const PaymentsDraft({
    this.env = PaymentEnv.test,
    this.gateways = const {},
    this.defaultGateway,
    this.configureLater = false,
  });

  /// The environment shown in the step. Test and live credentials are kept
  /// separately; only the selected one is validated.
  final PaymentEnv env;
  final Map<String, GatewayDraft> gateways;

  /// One of the enabled gateways, or null when there is none.
  final String? defaultGateway;

  /// The user chose to continue without enabling a gateway.
  final bool configureLater;

  GatewayDraft gateway(String id) => gateways[id] ?? const GatewayDraft();

  bool isEnabled(String id) => gateway(id).enabled;

  /// Enabled gateways in registry order.
  List<String> get enabledIds => [
    for (final g in kPaymentGateways)
      if (isEnabled(g.id)) g.id,
  ];

  PaymentsDraft copyWith({
    PaymentEnv? env,
    Map<String, GatewayDraft>? gateways,
    String? defaultGateway,
    bool clearDefault = false,
    bool? configureLater,
  }) => PaymentsDraft(
    env: env ?? this.env,
    gateways: gateways ?? this.gateways,
    defaultGateway: clearDefault
        ? null
        : (defaultGateway ?? this.defaultGateway),
    configureLater: configureLater ?? this.configureLater,
  );

  /// Keeps the default consistent: the first enabled gateway becomes
  /// the default when there is none, or when the default was disabled.
  PaymentsDraft _withValidDefault() {
    final online = enabledIds;
    if (online.isEmpty) return copyWith(clearDefault: true);
    if (online.contains(defaultGateway)) return this;
    return copyWith(defaultGateway: online.first);
  }

  PaymentsDraft withEnabled(String id, bool enabled) {
    if (paymentGatewayById(id) == null) return this;
    final next = copyWith(
      gateways: {
        ...gateways,
        id: gateway(id).copyWith(enabled: enabled),
      },
      // Enabling a gateway means the user is not postponing the setup.
      configureLater: enabled ? false : null,
    );
    return next._withValidDefault();
  }

  /// "Configure later": unselects every gateway (their values are kept) and
  /// postpones the setup.
  PaymentsDraft withConfigureLater() => PaymentsDraft(
    env: env,
    gateways: {
      for (final e in gateways.entries) e.key: e.value.copyWith(enabled: false),
    },
    configureLater: true,
  );

  /// Makes [id] the default. Only an enabled gateway can be.
  PaymentsDraft withDefault(String id) {
    if (!enabledIds.contains(id)) return this;
    return copyWith(defaultGateway: id);
  }

  PaymentsDraft withValue(String id, PaymentEnv env, String key, String value) {
    final g = paymentGatewayById(id);
    if (g == null || g.field(key) == null) return this;
    return copyWith(
      gateways: {...gateways, id: gateway(id).withValue(env, key, value)},
    );
  }

  /// Required fields that are empty, for enabled gateways in [env] only.
  PaymentErrors validate() {
    final missing = <String, Set<String>>{};
    for (final id in enabledIds) {
      final g = paymentGatewayById(id)!;
      final keys = {
        for (final f in g.fields)
          if (f.required && gateway(id).valueOf(g, env, f.key).trim().isEmpty)
            f.key,
      };
      if (keys.isNotEmpty) missing[id] = keys;
    }
    return PaymentErrors(
      noneEnabled: enabledIds.isEmpty && !configureLater,
      missing: missing,
    );
  }

  /// The settings written to the request and the exported settings file:
  /// gateway ids, enabled flags, the default gateway and the non-secret
  /// fields. Secrets are never included.
  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    final gws = <String, dynamic>{};
    for (final g in kPaymentGateways) {
      final d = gateway(g.id);
      final byEnv = <String, dynamic>{};
      for (final env in PaymentEnv.values) {
        final fields = <String, String>{};
        for (final f in g.publicFields) {
          final v = d.enabled
              ? d.valueOf(g, env, f.key)
              : (d.values[env]?[f.key] ?? '');
          if (v.trim().isNotEmpty) fields[f.key] = v.trim();
        }
        if (fields.isNotEmpty) byEnv[env.name] = fields;
      }
      if (d.enabled || byEnv.isNotEmpty) {
        gws[g.id] = {'enabled': d.enabled, ...byEnv};
      }
    }
    if (enabledIds.isEmpty) out['configureLater'] = configureLater;
    out['environment'] = env.name;
    if (defaultGateway != null) out['defaultGateway'] = defaultGateway;
    out['gateways'] = gws;
    return out;
  }

  /// The secrets of the enabled gateways, `env -> gatewayId -> key -> value`,
  /// for the secrets backend call only. Never put this in the request, the
  /// config or the exported file.
  Map<String, Map<String, Map<String, String>>> secrets() {
    final out = <String, Map<String, Map<String, String>>>{};
    for (final id in enabledIds) {
      final g = paymentGatewayById(id)!;
      for (final env in PaymentEnv.values) {
        final entered = {
          for (final f in g.secretFields)
            if ((gateway(id).values[env]?[f.key] ?? '').trim().isNotEmpty)
              f.key: gateway(id).values[env]![f.key]!.trim(),
        };
        if (entered.isNotEmpty) {
          out.putIfAbsent(env.name, () => {})[id] = entered;
        }
      }
    }
    return out;
  }

  bool get hasSecrets => secrets().isNotEmpty;

  /// Reads the settings written by [toJson]. Unknown gateways and fields are
  /// ignored, secret fields are never read, and the default is repaired.
  factory PaymentsDraft.fromJson(Map<String, dynamic> j) {
    final gateways = <String, GatewayDraft>{};
    final raw = j['gateways'];
    if (raw is Map) {
      for (final g in kPaymentGateways) {
        final e = raw[g.id];
        if (e is! Map) continue;
        final values = <PaymentEnv, Map<String, String>>{};
        for (final env in PaymentEnv.values) {
          final fields = e[env.name];
          if (fields is! Map) continue;
          final kept = {
            for (final f in g.publicFields)
              if (fields[f.key] is String) f.key: fields[f.key] as String,
          };
          if (kept.isNotEmpty) values[env] = Map.unmodifiable(kept);
        }
        gateways[g.id] = GatewayDraft(
          enabled: e['enabled'] == true,
          values: Map.unmodifiable(values),
        );
      }
    }
    final draft = PaymentsDraft(
      env: PaymentEnv.parse(j['environment']) ?? PaymentEnv.test,
      gateways: Map.unmodifiable(gateways),
      defaultGateway: j['defaultGateway'] as String?,
      configureLater: j['configureLater'] == true,
    );
    return draft._withValidDefault();
  }
}
