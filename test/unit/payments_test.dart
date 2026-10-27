import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/features/builder/application/config_service.dart';
import 'package:swiftappbuilder/features/builder/data/in_memory_config_repository.dart';
import 'package:swiftappbuilder/features/builder/data/payment_backend.dart';
import 'package:swiftappbuilder/features/builder/domain/config.dart';
import 'package:swiftappbuilder/features/builder/domain/draft.dart';
import 'package:swiftappbuilder/features/builder/domain/payment_gateways.dart';
import 'package:swiftappbuilder/features/builder/domain/payments.dart';
import 'package:swiftappbuilder/features/builder/domain/request_document.dart';
import 'package:swiftappbuilder/features/builder/domain/validators.dart';

import '../helpers.dart';

const _secretValues = [
  'tok-SECRET-1234567890',
  'api-SECRET-1234567890',
  'sk-SECRET-1234567890',
  'hmac-SECRET-1234567890',
  'ac-SECRET-1234567890',
  'req-SECRET-1234567890',
  'res-SECRET-1234567890',
];

/// Every field of every gateway filled in, test and live.
PaymentsDraft _filled() {
  var p = const PaymentsDraft();
  for (final g in kPaymentGateways) {
    p = p.withEnabled(g.id, true);
    for (final env in PaymentEnv.values) {
      var n = 0;
      for (final f in g.fields) {
        if (f.type == GatewayFieldType.select) continue;
        final v = f.isSecret
            ? _secretValues[(n++ + g.id.length) % _secretValues.length]
            : '${g.id}-${f.key}-${env.name}';
        p = p.withValue(g.id, env, f.key, v);
      }
    }
  }
  return p;
}

void main() {
  group('registry', () {
    test('has the three gateways, in order', () {
      expect(kPaymentGateways.map((g) => g.id), [
        'hyperpay',
        'paymob',
        'payfort',
      ]);
      expect(paymentGatewayById('cod'), isNull);
    });

    test('field keys and required flags follow the spec', () {
      List<String> keys(String id, bool Function(GatewayField) test) => [
        for (final f in paymentGatewayById(id)!.fields)
          if (test(f)) f.key,
      ];
      expect(keys('hyperpay', (f) => f.required), [
        'accessToken',
        'entityIdCards',
        'entityIdMada',
      ]);
      expect(keys('hyperpay', (f) => f.isSecret), ['accessToken']);
      expect(keys('paymob', (f) => f.required), [
        'apiKey',
        'secretKey',
        'publicKey',
        'cardIntegrationId',
        'hmacSecret',
      ]);
      expect(keys('paymob', (f) => f.isSecret), [
        'apiKey',
        'secretKey',
        'hmacSecret',
      ]);
      expect(keys('payfort', (f) => f.required), [
        'merchantIdentifier',
        'accessCode',
        'shaRequestPhrase',
        'shaResponsePhrase',
      ]);
      final sha = paymentGatewayById('payfort')!.field('shaType')!;
      expect(sha.type, GatewayFieldType.select);
      expect(sha.options, ['SHA-256', 'SHA-512']);
      expect(sha.defaultValue, 'SHA-256');
    });

    test('the JSON schema allows exactly the non-secret fields', () {
      final schema =
          jsonDecode(File('assets/config.schema.json').readAsStringSync())
              as Map<String, dynamic>;
      final defs = schema['definitions'] as Map<String, dynamic>;
      const defOf = {
        'hyperpay': 'gatewayHyperpay',
        'paymob': 'gatewayPaymob',
        'payfort': 'gatewayPayfort',
      };
      for (final g in kPaymentGateways) {
        final gw = defs[defOf[g.id]] as Map<String, dynamic>;
        final env =
            (gw['properties'] as Map<String, dynamic>)['test']
                as Map<String, dynamic>;
        expect(
          (env['properties'] as Map<String, dynamic>).keys.toSet(),
          g.publicFields.map((f) => f.key).toSet(),
          reason: g.id,
        );
      }
    });
  });

  group('default gateway', () {
    test('the first enabled gateway becomes the default', () {
      final p = const PaymentsDraft().withEnabled('paymob', true);
      expect(p.defaultGateway, 'paymob');
      final both = p.withEnabled('hyperpay', true);
      expect(both.defaultGateway, 'paymob'); // never changes by itself
    });

    test('disabling the default reassigns it; none left clears it', () {
      var p = const PaymentsDraft()
          .withEnabled('hyperpay', true)
          .withEnabled('payfort', true);
      expect(p.defaultGateway, 'hyperpay');
      p = p.withEnabled('hyperpay', false);
      expect(p.defaultGateway, 'payfort');
      p = p.withEnabled('payfort', false);
      expect(p.defaultGateway, isNull);
    });

    test('only an enabled gateway can be set as the default', () {
      var p = const PaymentsDraft().withEnabled('hyperpay', true);
      p = p.withDefault('paymob'); // not enabled
      expect(p.defaultGateway, 'hyperpay');
      p = p.withEnabled('payfort', true).withDefault('payfort');
      expect(p.defaultGateway, 'payfort');
    });

    test('enabling a gateway cancels "configure later"', () {
      final p = const PaymentsDraft(
        configureLater: true,
      ).withEnabled('hyperpay', true);
      expect(p.configureLater, isFalse);
    });
  });

  group('validation', () {
    test('nothing enabled needs "configure later"', () {
      expect(const PaymentsDraft().validate().noneEnabled, isTrue);
      expect(
        const PaymentsDraft(configureLater: true).validate().isEmpty,
        isTrue,
      );
    });

    test('only enabled gateways are validated, for the current env only', () {
      var p = const PaymentsDraft().withEnabled('hyperpay', true);
      expect(p.validate().missing['hyperpay'], {
        'accessToken',
        'entityIdCards',
        'entityIdMada',
      });
      expect(p.validate().missing.containsKey('paymob'), isFalse);

      // Filling the test environment satisfies it; live stays empty.
      for (final k in ['accessToken', 'entityIdCards', 'entityIdMada']) {
        p = p.withValue('hyperpay', PaymentEnv.test, k, 'x');
      }
      expect(p.validate().isEmpty, isTrue);
      expect(
        p.copyWith(env: PaymentEnv.live).validate().missing['hyperpay'],
        isNotEmpty,
      );

      // A disabled gateway keeps its values and is not validated.
      final off = p
          .withEnabled('hyperpay', false)
          .copyWith(configureLater: true);
      expect(off.validate().isEmpty, isTrue);
      expect(
        off
            .gateway('hyperpay')
            .valueOf(
              paymentGatewayById('hyperpay')!,
              PaymentEnv.test,
              'accessToken',
            ),
        'x',
      );
    });

    test('whitespace does not satisfy a required field', () {
      final p = const PaymentsDraft()
          .withEnabled('payfort', true)
          .withValue('payfort', PaymentEnv.test, 'merchantIdentifier', '   ');
      expect(p.validate().missing['payfort'], contains('merchantIdentifier'));
    });

    test('shaType defaults to SHA-256 and is never "missing"', () {
      final p = const PaymentsDraft().withEnabled('payfort', true);
      expect(p.validate().missing['payfort'], isNot(contains('shaType')));
      expect(
        p
            .gateway('payfort')
            .valueOf(
              paymentGatewayById('payfort')!,
              PaymentEnv.live,
              'shaType',
            ),
        'SHA-256',
      );
    });

    test(
      'the payments step is validated per template and wired into steps',
      () {
        final d = validDraft().copyWith(payments: const PaymentsDraft());
        expect(DraftValidator.validateSection(d, WizardSection.payments), {
          DraftField.paymentGateways: FieldError.noGatewayEnabled,
        });
        final incomplete = d.copyWith(
          payments: const PaymentsDraft().withEnabled('hyperpay', true),
        );
        expect(
          DraftValidator.validateSection(incomplete, WizardSection.payments),
          {DraftField.paymentFields: FieldError.gatewayFieldsMissing},
        );
        expect(DraftValidator.firstInvalid(d), WizardSection.payments);
        expect(activeSections(d), contains(WizardSection.payments));
        expect(activeSections(d).last, WizardSection.summary);
      },
    );
  });

  test('a template without payments skips the step', () {
    const noPayments = AppTemplate(
      id: 'simple',
      nameAr: 'x',
      nameEn: 'x',
      cornerRadius: 12,
      cardStyle: CardStyle.outlined,
      elevation: 0,
      typographyScale: 1,
      headerStyle: HeaderStyle.solid,
      buttonStyle: RuiButtonStyle.flat,
      serviceGrid: ServiceGridVariant.list,
      navStyle: NavStyle.line,
      inputStyle: InputStyleKind.outlined,
      transition: PageTransitionKind.fade,
      palette: PaletteKind.neutral,
      motion: MotionLevel.none,
      supportsPayments: false,
    );
    expect(activeSections(validDraft(), byId: (_) => noPayments), [
      WizardSection.info,
      WizardSection.branding,
      WizardSection.localization,
      WizardSection.template,
      WizardSection.summary,
    ]);
    expect(
      templateSupportsPayments('simple', byId: (_) => noPayments),
      isFalse,
    );
    // The shipped templates all include payments.
    for (final t in AppTemplate.all) {
      expect(templateSupportsPayments(t.id), isTrue, reason: t.id);
    }
  });

  group('secrets', () {
    test('toJson holds ids, flags, default and non-secret fields only', () {
      final p = _filled();
      final json = jsonEncode(p.toJson());
      for (final s in _secretValues) {
        expect(json, isNot(contains(s)));
      }
      for (final k in [
        'accessToken',
        'apiKey',
        'secretKey',
        'hmacSecret',
        'accessCode',
        'shaRequestPhrase',
        'shaResponsePhrase',
      ]) {
        expect(json, isNot(contains(k)), reason: k);
      }
      final out = p.toJson();
      expect(out['environment'], 'test');
      expect(out['defaultGateway'], 'hyperpay');
      final gws = out['gateways'] as Map;
      expect((gws['hyperpay'] as Map)['enabled'], isTrue);
      expect(
        ((gws['hyperpay'] as Map)['test'] as Map)['entityIdCards'],
        'hyperpay-entityIdCards-test',
      );
      expect(
        ((gws['hyperpay'] as Map)['live'] as Map)['entityIdCards'],
        'hyperpay-entityIdCards-live',
      );
      // The select default is written explicitly for an enabled gateway.
      expect(((gws['payfort'] as Map)['test'] as Map)['shaType'], 'SHA-256');
    });

    test(
      'secrets() returns them per environment, for the backend call only',
      () {
        final s = _filled().secrets();
        expect(s.keys, containsAll(['test', 'live']));
        expect(s['test']!['hyperpay']!.keys, ['accessToken']);
        expect(s['live']!['paymob']!.keys.toSet(), {
          'apiKey',
          'secretKey',
          'hmacSecret',
        });
        // A disabled gateway's secrets are not sent.
        expect(
          _filled().withEnabled('hyperpay', false).secrets()['test']!.keys,
          isNot(contains('hyperpay')),
        );
      },
    );

    test('the request document and the config carry no secret', () {
      final d = validDraft().copyWith(payments: _filled());
      final doc = requestFields(
        d,
        logoUrl: 'https://s/logo.png',
        appIconUrl: 'https://s/icon.png',
        secretsTokenHash: 'abc',
      );
      final text = jsonEncode(doc);
      for (final s in _secretValues) {
        expect(text, isNot(contains(s)));
      }
      final payments = doc['payments'] as Map;
      expect(payments['secretsTokenHash'], 'abc');
      expect(payments['defaultGateway'], 'hyperpay');

      final schema = loadSchema();
      final config = {
        ...(jsonDecode(jsonEncode(_configJson())) as Map<String, dynamic>),
        'payments': d.payments.toJson(),
      };
      expect(schema.validate(config), isEmpty);
    });

    test('the schema rejects a secret smuggled into the settings file', () {
      final schema = loadSchema();
      final p = const PaymentsDraft().withEnabled('hyperpay', true).toJson();
      final base = _configJson();
      expect(schema.validate({...base, 'payments': p}), isEmpty);
      final bad = jsonDecode(jsonEncode(p)) as Map<String, dynamic>;
      ((bad['gateways'] as Map)['hyperpay'] as Map)['test'] = {
        'entityIdCards': 'x',
        'accessToken': 'tok-SECRET',
      };
      expect(schema.validate({...base, 'payments': bad}), isNotEmpty);
    });

    test(
      'fromJson ignores secret and unknown fields and repairs the default',
      () {
        final p = PaymentsDraft.fromJson({
          'environment': 'live',
          'defaultGateway': 'paymob', // not enabled
          'gateways': {
            'hyperpay': {
              'enabled': true,
              'live': {'entityIdCards': 'e1', 'accessToken': 'tok-SECRET'},
            },
            'unknown': {'enabled': true},
          },
        });
        expect(p.env, PaymentEnv.live);
        expect(p.enabledIds, ['hyperpay']);
        expect(p.defaultGateway, 'hyperpay');
        expect(jsonEncode(p.secrets()), '{}');
        expect(p.gateway('hyperpay').values[PaymentEnv.live], {
          'entityIdCards': 'e1',
        });
      },
    );

    test('round trip through toJson / fromJson keeps the non-secret state', () {
      final p = _filled().withDefault('payfort');
      final again = PaymentsDraft.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(again.enabledIds, p.enabledIds);
      expect(again.defaultGateway, 'payfort');
      expect(again.toJson(), p.toJson());
      expect(again.hasSecrets, isFalse);
    });

    test(
      '"Load existing settings" restores gateways but never secrets',
      () async {
        final service = ConfigService(InMemoryConfigRepository(), loadSchema());
        final prepared = await service.prepare(
          validDraft().copyWith(payments: _filled().withDefault('payfort')),
          updatedBy: 'tester',
        );
        expect(
          prepared.isValid,
          isTrue,
          reason: prepared.schemaErrors.join('\n'),
        );
        final file = prepared.config.toPrettyJson();
        for (final s in _secretValues) {
          expect(file, isNot(contains(s)));
        }

        final loaded = AppConfigDraft.fromConfig(
          AppConfig.fromJsonString(file),
        ).payments;
        expect(loaded.enabledIds, ['hyperpay', 'paymob', 'payfort']);
        expect(loaded.defaultGateway, 'payfort');
        expect(loaded.hasSecrets, isFalse);
        // So the required secrets must be entered again before continuing.
        expect(loaded.validate().missing['hyperpay'], {'accessToken'});
      },
    );

    test('the secrets token is random and only its hash is stored', () {
      final a = SecretsToken.generate();
      final b = SecretsToken.generate();
      expect(a.value, isNot(b.value));
      expect(a.value.length, greaterThanOrEqualTo(40));
      expect(a.hash, SecretsToken.hashOf(a.value));
      expect(a.hash, hasLength(64));
      expect(a.hash, isNot(contains(a.value)));
    });
  });
}

Map<String, dynamic> _configJson() => {
  'schemaVersion': 2,
  'appId': 'swift_maids',
  'configVersion': 1,
  'client': {
    'name': 'x',
    'email': 'info@swift.example',
    'phone': '+966500000000',
  },
  'appName': {'ar': 'س', 'en': 'S'},
  'android': {'packageName': 'com.excp.swift'},
  'ios': {'bundleId': 'com.excp.swift'},
  'templateId': 'simple',
  'templateVersion': 2,
  'modules': ['individuals'],
  'branding': {
    'primaryColor': '#213F80',
    'secondaryColor': '#29ABE2',
    'fontFamily': 'Cairo',
    'logo': 'apps/swift_maids/v1/logo.png',
    'appIcon': 'apps/swift_maids/v1/app_icon.png',
    'splash': {
      'backgroundColor': '#FFFFFF',
      'logo': 'apps/swift_maids/v1/logo.png',
    },
  },
  'localization': {
    'defaultLanguage': 'ar',
    'supportedLanguages': ['ar'],
  },
  'meta': {'createdAt': 'x', 'updatedAt': 'x', 'updatedBy': 'x'},
};
