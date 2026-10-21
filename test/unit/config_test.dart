import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swiftappbuilder/features/builder/application/config_service.dart';
import 'package:swiftappbuilder/features/builder/data/config_repository.dart';
import 'package:swiftappbuilder/features/builder/data/in_memory_config_repository.dart';
import 'package:swiftappbuilder/features/builder/domain/asset.dart';
import 'package:swiftappbuilder/features/builder/domain/config.dart';
import 'package:swiftappbuilder/features/builder/domain/draft.dart';

import '../helpers.dart';

ConfigService makeService(
  InMemoryConfigRepository repo, {
  DateTime Function()? now,
}) => ConfigService(repo, loadSchema(), now: now);

void main() {
  final fixedNow = DateTime.utc(2026, 1, 1, 12);

  group('JSON', () {
    test('has exactly the documented shape', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final p = await service.prepare(validDraft(), updatedBy: 'tester');
      final json = p.config.toJson();
      expect(json.keys, [
        'schemaVersion',
        'appId',
        'configVersion',
        'client',
        'appName',
        'android',
        'ios',
        'templateId',
        'templateVersion',
        'modules',
        'branding',
        'localization',
        'meta',
      ]);
      expect(json['schemaVersion'], 2);
      expect(json['templateVersion'], 2);
      expect(json['modules'], ['individuals', 'hourly', 'mediation']);
      expect(json['configVersion'], 1);
      expect((json['branding'] as Map)['logo'], 'apps/swift_maids/v1/logo.png');
      expect(
        ((json['branding'] as Map)['splash'] as Map)['logo'],
        'apps/swift_maids/v1/logo.png',
      );
      expect((json['meta'] as Map)['updatedBy'], 'tester');
    });

    test('serialization round-trip', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final config = (await service.prepare(
        validDraft(),
        updatedBy: 'tester',
      )).config;
      final decoded = AppConfig.fromJsonString(config.toPrettyJson());
      expect(decoded, config);
      expect(jsonEncode(decoded.toJson()), jsonEncode(config.toJson()));
    });

    test('support emails are saved, loaded and default to empty', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final draft = validDraft().copyWith(
        supportEmails: ['a@example.com', 'b@example.com'],
      );
      final config = (await service.prepare(draft, updatedBy: 'x')).config;
      expect((config.toJson()['client'] as Map)['supportEmails'], [
        'a@example.com',
        'b@example.com',
      ]);
      expect(AppConfig.fromJsonString(config.toPrettyJson()), config);
      expect(AppConfigDraft.fromConfig(config).supportEmails, [
        'a@example.com',
        'b@example.com',
      ]);

      // Older documents without the field still load.
      final json = config.toJson();
      (json['client'] as Map).remove('supportEmails');
      expect(AppConfig.fromJson(json).supportEmails, isEmpty);
      expect(loadSchema().validate(json), isEmpty);
    });

    test('schema rejects bad or duplicate support emails', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final config = (await service.prepare(
        validDraft(),
        updatedBy: 'x',
      )).config;
      for (final bad in [
        ['nope'],
        ['a@example.com', 'a@example.com'],
      ]) {
        final json = config.toJson();
        (json['client'] as Map)['supportEmails'] = bad;
        expect(loadSchema().validate(json), isNotEmpty, reason: '$bad');
      }
    });

    test('schema accepts only the current templates', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final config = (await service.prepare(
        validDraft(),
        updatedBy: 'x',
      )).config;
      for (final id in ['simple', 'luxury', 'premium']) {
        final json = config.toJson()..['templateId'] = id;
        expect(loadSchema().validate(json), isEmpty, reason: id);
      }
      final old = config.toJson()..['templateId'] = 'classic';
      expect(loadSchema().validate(old), isNotEmpty);
    });

    test('accent, background and text colors are saved and loaded', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final draft = validDraft().copyWith(
        accentHex: '#e91e63',
        backgroundHex: '#faf3e0',
        textHex: '#222222',
      );
      final config = (await service.prepare(draft, updatedBy: 'x')).config;
      final branding = config.toJson()['branding'] as Map;
      expect(branding['accentColor'], '#E91E63');
      expect(branding['backgroundColor'], '#FAF3E0');
      expect(branding['textColor'], '#222222');
      expect(loadSchema().validate(config.toJson()), isEmpty);
      final back = AppConfigDraft.fromConfig(
        AppConfig.fromJsonString(config.toPrettyJson()),
      );
      expect(back.accentHex, '#E91E63');
      expect(back.backgroundHex, '#FAF3E0');
      expect(back.textHex, '#222222');

      // Unset background/text are not written; old configs without an accent
      // load with the default one.
      final plain = (await service.prepare(
        validDraft(),
        updatedBy: 'x',
      )).config;
      final pb = plain.toJson()['branding'] as Map;
      expect(pb.containsKey('backgroundColor'), isFalse);
      expect(pb.containsKey('textColor'), isFalse);
      pb.remove('accentColor');
      expect(AppConfig.fromJson(plain.toJson()).accentColor, '#2E9E5B');
    });

    test('image source links are kept as references', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final base = validDraft();
      final draft = base.copyWith(
        logo: PickedAsset(
          name: 'logo.png',
          bytes: base.logo!.bytes,
          extension: 'png',
          sourceUrl: 'https://cdn.example.com/logo.png',
        ),
      );
      final config = (await service.prepare(draft, updatedBy: 'x')).config;
      final branding = config.toJson()['branding'] as Map;
      expect(branding['logoSourceUrl'], 'https://cdn.example.com/logo.png');
      expect(branding.containsKey('appIconSourceUrl'), isFalse);
      expect(loadSchema().validate(config.toJson()), isEmpty);
      expect(AppConfig.fromJsonString(config.toPrettyJson()), config);
    });

    test(
      'iOS bundle ID is saved with its sync flag and rebuilt when missing',
      () async {
        final service = makeService(
          InMemoryConfigRepository(),
          now: () => fixedNow,
        );
        final mirrored = validDraft().copyWith(
          androidPackage: 'com.excp.my_app',
        );
        final c1 = (await service.prepare(mirrored, updatedBy: 'x')).config;
        final ios = c1.toJson()['ios'] as Map;
        expect(ios['bundleId'], 'com.excp.my-app');
        expect(ios.containsKey('sameAsAndroid'), isFalse);
        expect(loadSchema().validate(c1.toJson()), isEmpty);

        final own = validDraft().copyWith(
          iosSameAsAndroid: false,
          iosBundleId: 'com.excp.other',
        );
        final c2 = (await service.prepare(own, updatedBy: 'x')).config;
        final back2 = AppConfigDraft.fromConfig(
          AppConfig.fromJsonString(c2.toPrettyJson()),
        );
        expect(back2.iosSameAsAndroid, isFalse);
        expect(back2.effectiveIosBundleId, 'com.excp.other');

        // Data from before the fixed prefix: another prefix is replaced and an
        // empty iOS value is generated from Android with syncing on.
        final json = c1.toJson();
        (json['android'] as Map)['packageName'] = 'com.example.my_app';
        (json['ios'] as Map)
          ..['bundleId'] = ''
          ..remove('sameAsAndroid');
        final old = AppConfigDraft.fromConfig(AppConfig.fromJson(json));
        expect(old.androidPackage, 'com.excp.my_app');
        expect(old.iosSameAsAndroid, isTrue);
        expect(old.effectiveIosBundleId, 'com.excp.my-app');
      },
    );

    test('rejects malformed structure', () {
      expect(() => AppConfig.fromJsonString('[]'), throwsFormatException);
      expect(
        () => AppConfig.fromJsonString('{"appId":"x"}'),
        throwsFormatException,
      );
    });

    test('draft <-> config round trip keeps form values', () async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      final draft = validDraft().copyWith(templateId: 'luxury');
      final config = (await service.prepare(draft, updatedBy: 'x')).config;
      final back = AppConfigDraft.fromConfig(config);
      expect(back.nameAr, draft.nameAr);
      expect(back.androidPackage, normalizePackage(draft.androidPackage));
      expect(back.templateId, 'luxury');
      expect(back.existingApp, isTrue);
      expect(back.iosSameAsAndroid, isTrue);
    });
  });

  group('JSON schema', () {
    Future<Map<String, dynamic>> validJson() async {
      final service = makeService(
        InMemoryConfigRepository(),
        now: () => fixedNow,
      );
      return (await service.prepare(
        validDraft(),
        updatedBy: 'x',
      )).config.toJson();
    }

    test('valid config passes', () async {
      expect(loadSchema().validate(await validJson()), isEmpty);
    });

    test('bad color, package and template are reported', () async {
      final j = await validJson();
      (j['branding'] as Map)['primaryColor'] = 'blue';
      (j['android'] as Map)['packageName'] = 'Bad';
      j['templateId'] = 'fancy';
      final errors = loadSchema().validate(j);
      expect(errors.length, greaterThanOrEqualTo(3));
    });

    test('unknown properties such as secrets are rejected', () async {
      final j = await validJson();
      j['paymentApiKey'] = 'sk_live_123';
      (j['branding'] as Map)['signingKey'] = 'abc';
      expect(loadSchema().validate(j), hasLength(2));
    });

    test('schema v2 requires templateVersion and modules', () async {
      final j = await validJson();
      j.remove('templateVersion');
      j.remove('modules');
      expect(loadSchema().validate(j), isNotEmpty);
    });

    test(
      'legacy schema v1 documents remain valid and load with defaults',
      () async {
        final j = await validJson();
        j['schemaVersion'] = 1;
        j.remove('templateVersion');
        j.remove('modules');
        expect(loadSchema().validate(j), isEmpty);
        final config = AppConfig.fromJson(j);
        expect(config.templateVersion, 1);
        expect(config.modules, AppConfig.defaultModules);
      },
    );

    test('unknown module is rejected', () async {
      final j = await validJson();
      j['modules'] = ['individuals', 'payroll'];
      expect(loadSchema().validate(j), isNotEmpty);
    });

    test('default language must be supported', () async {
      final j = await validJson();
      (j['localization'] as Map)['supportedLanguages'] = ['en'];
      expect(loadSchema().validate(j), isNotEmpty);
    });

    test('storage path must be under apps/{appId}/v{n}/', () async {
      final j = await validJson();
      (j['branding'] as Map)['logo'] = '../etc/passwd';
      expect(loadSchema().validate(j), isNotEmpty);
    });
  });

  group('modules in config', () {
    test('only enabled modules are written, in canonical order', () async {
      final service = makeService(InMemoryConfigRepository());
      final draft = validDraft().copyWith(
        enabledModules: ['mediation', 'individuals'],
      );
      final config = (await service.prepare(draft, updatedBy: 'x')).config;
      expect(config.modules, ['individuals', 'mediation']);
      expect(AppConfigDraft.fromConfig(config).enabledModules, [
        'individuals',
        'mediation',
      ]);
    });
  });

  group('versioning', () {
    test(
      'each save appends version N+1 and never mutates older versions',
      () async {
        final repo = InMemoryConfigRepository();
        final service = makeService(repo, now: () => fixedNow);

        expect(await service.nextVersion('swift_maids'), 1);
        final v1 = await service.save(validDraft(), updatedBy: 'a');
        expect(v1.configVersion, 1);

        final changed = validDraft().copyWith(templateId: 'luxury');
        final v2 = await service.save(changed, updatedBy: 'b');
        expect(v2.configVersion, 2);
        expect(await service.nextVersion('swift_maids'), 3);

        final list = await repo.listVersions('swift_maids');
        expect(list.map((c) => c.configVersion), [1, 2]);
        expect((await repo.getVersion('swift_maids', 1))!.templateId, 'simple');
        expect((await repo.getLatest('swift_maids'))!.templateId, 'luxury');
        expect(v2.createdAt, v1.createdAt);
        expect(await repo.getVersion('swift_maids', 3), isNull);
      },
    );

    test('assets are stored per version under apps/{appId}/v{n}/', () async {
      final repo = InMemoryConfigRepository();
      final service = makeService(repo);
      await service.save(validDraft(), updatedBy: 'a');
      await service.save(validDraft(), updatedBy: 'a');
      expect(await repo.getAsset('apps/swift_maids/v1/logo.png'), isNotNull);
      expect(
        await repo.getAsset('apps/swift_maids/v2/app_icon.png'),
        isNotNull,
      );
      expect(await repo.getAsset('apps/swift_maids/v3/logo.png'), isNull);
    });

    test('repository refuses non-sequential versions', () async {
      final repo = InMemoryConfigRepository();
      final service = makeService(repo);
      final p = await service.prepare(validDraft(), updatedBy: 'a');
      final skipped = AppConfig.fromJson({
        ...p.config.toJson(),
        'configVersion': 5,
      });
      expect(
        () => repo.save(skipped, p.assets),
        throwsA(isA<VersionConflictException>()),
      );
    });

    test('appId availability flips after first save', () async {
      final repo = InMemoryConfigRepository();
      final service = makeService(repo);
      expect(await repo.isAppIdAvailable('swift_maids'), isTrue);
      await service.save(validDraft(), updatedBy: 'a');
      expect(await repo.isAppIdAvailable('swift_maids'), isFalse);
    });

    test('save refuses schema-invalid drafts', () async {
      final service = makeService(InMemoryConfigRepository());
      final bad = validDraft().copyWith(primaryHex: 'nope');
      expect(() => service.save(bad, updatedBy: 'a'), throwsStateError);
    });

    test('restore loads assets back into a draft', () async {
      final repo = InMemoryConfigRepository();
      final service = makeService(repo);
      final v1 = await service.save(validDraft(), updatedBy: 'a');
      final draft = await service.draftFromStored(v1);
      expect(draft.logo, isNotNull);
      expect(draft.appIcon, isNotNull);
      expect(draft.splashLogo, isNull);
      expect(draft.existingApp, isTrue);
    });
  });
}
