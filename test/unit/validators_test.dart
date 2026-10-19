import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/features/builder/domain/asset_validator.dart';
import 'package:swiftappbuilder/features/builder/domain/draft.dart';
import 'package:swiftappbuilder/features/builder/domain/validators.dart';

import '../helpers.dart';

void main() {
  group('Validators', () {
    test('android package', () {
      expect(Validators.androidPackage('com.example.app'), isNull);
      expect(Validators.androidPackage('com.my_app.v2'), isNull);
      expect(Validators.androidPackage(''), FieldError.required);
      expect(Validators.androidPackage('app'), FieldError.invalidPackage);
      expect(
        Validators.androidPackage('Com.Example.app'),
        FieldError.invalidPackage,
      );
      expect(
        Validators.androidPackage('com.1example.app'),
        FieldError.invalidPackage,
      );
      expect(Validators.androidPackage('com..app'), FieldError.invalidPackage);
    });

    test('ios bundle id', () {
      expect(Validators.iosBundleId('com.Example.my-app'), isNull);
      expect(Validators.iosBundleId('single'), FieldError.invalidBundleId);
      expect(
        Validators.iosBundleId('com.exa mple'),
        FieldError.invalidBundleId,
      );
    });

    test('app id', () {
      expect(Validators.appId('client_app_001'), isNull);
      expect(Validators.appId('ab'), FieldError.invalidAppId);
      expect(Validators.appId('1client'), FieldError.invalidAppId);
      expect(Validators.appId('Client'), FieldError.invalidAppId);
    });

    test('email, phone, hex', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('a@b'), FieldError.invalidEmail);
      expect(Validators.phone('+966 500 000 000'), isNull);
      expect(Validators.phone('12'), FieldError.invalidPhone);
      expect(Validators.hexColor('#1565C0'), isNull);
      expect(Validators.hexColor('1565C0'), FieldError.invalidHex);
      expect(Validators.hexColor('#12345'), FieldError.invalidHex);
    });

    test('slugify', () {
      expect(slugifyAppId('Swift Maids'), 'swift_maids');
      expect(slugifyAppId('  123 Office!! '), 'office');
      expect(slugifyAppId('مكتب'), '');
    });
  });

  group('DraftValidator', () {
    test(
      'empty draft is invalid in info, valid draft passes every section',
      () {
        expect(
          DraftValidator.isSectionValid(
            const AppConfigDraft(),
            WizardSection.info,
          ),
          isFalse,
        );
        final d = validDraft();
        for (final s in WizardSection.values) {
          expect(DraftValidator.validateSection(d, s), isEmpty, reason: s.name);
        }
      },
    );

    test('branding requires logo and icon', () {
      final d = validDraft().copyWith(clearLogo: true);
      expect(DraftValidator.validateSection(d, WizardSection.branding), {
        DraftField.logo: FieldError.assetMissing,
      });
    });

    test('default language must be supported', () {
      final d = validDraft().copyWith(supportedLanguages: ['en']);
      expect(
        DraftValidator.validateSection(d, WizardSection.localization),
        isNotEmpty,
      );
    });

    test('at least one service module is required', () {
      final d = validDraft().copyWith(enabledModules: const []);
      expect(DraftValidator.validateSection(d, WizardSection.template), {
        DraftField.modules: FieldError.noModules,
      });
    });

    test('ios same-as-android uses the android package', () {
      final d = validDraft().copyWith(iosBundleId: 'ignored.value');
      expect(d.effectiveIosBundleId, 'com.example.swift');
    });
  });

  group('contrast', () {
    test('white on dark blue passes, white on yellow fails', () {
      expect(whiteTextPassesAa(parseHexColor('#1565C0')!), isTrue);
      expect(whiteTextPassesAa(parseHexColor('#FFB300')!), isFalse);
    });
  });

  group('AssetValidator', () {
    test('logo size rules', () {
      expect(
        AssetValidator.validateLogo('a.png', pngBytes(512, 512)).isOk,
        isTrue,
      );
      expect(
        AssetValidator.validateLogo('a.png', pngBytes(100, 100)).issue,
        AssetIssue.tooSmall,
      );
      expect(
        AssetValidator.validateLogo('a.jpg', pngBytes(512, 512)).issue,
        AssetIssue.wrongType,
      );
      expect(
        AssetValidator.validateLogo(
          'a.png',
          pngBytes(10, 10).sublist(0, 20),
        ).issue,
        AssetIssue.undecodable,
      );
    });

    test('svg logo', () {
      final ok = '<svg width="600" height="600" xmlns="x"></svg>'.codeUnits;
      final small = '<svg viewBox="0 0 24 24"></svg>'.codeUnits;
      expect(
        AssetValidator.validateLogo('a.svg', Uint8List.fromList(ok)).isOk,
        isTrue,
      );
      expect(
        AssetValidator.validateLogo('a.svg', Uint8List.fromList(small)).issue,
        AssetIssue.tooSmall,
      );
    });

    test('icon must be 1024 and opaque', () {
      expect(
        AssetValidator.validateIcon('i.png', pngBytes(1024, 1024)).isOk,
        isTrue,
      );
      expect(
        AssetValidator.validateIcon('i.png', pngBytes(512, 512)).issue,
        AssetIssue.wrongSize,
      );
      expect(
        AssetValidator.validateIcon(
          'i.png',
          pngBytes(1024, 1024, alpha: true),
        ).issue,
        AssetIssue.hasTransparency,
      );
    });
  });
}
