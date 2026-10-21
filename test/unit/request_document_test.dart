import 'package:flutter_test/flutter_test.dart';
import 'package:swiftappbuilder/features/builder/domain/request_document.dart';

import '../helpers.dart';

void main() {
  test('request document holds the wizard data and image URLs only', () {
    final d = validDraft().copyWith(
      supportEmails: ['help@example.com'],
      backgroundHex: '#faf3e0',
    );
    final doc = requestFields(
      d,
      logoUrl: 'https://storage.example/logo.png',
      appIconUrl: 'https://storage.example/icon.png',
    );
    expect(doc['appId'], 'swift_maids');
    expect((doc['client'] as Map)['supportEmails'], ['help@example.com']);
    expect((doc['client'] as Map)['name'], 'مكتب سويفت');
    final branding = doc['branding'] as Map;
    expect(branding['logoUrl'], 'https://storage.example/logo.png');
    expect(branding['appIconUrl'], 'https://storage.example/icon.png');
    expect(branding['backgroundColor'], '#FAF3E0');
    expect(branding.containsKey('textColor'), isFalse);
    expect(branding.containsKey('splashLogoUrl'), isFalse);
    // No raw image data may be stored in the document.
    expect(doc.toString().contains('Uint8List'), isFalse);
    expect(doc['templateId'], d.templateId);
    expect(doc['modules'], d.enabledModules);
    // status and timestamps are added by the backend.
    expect(doc.containsKey('status'), isFalse);
    expect(doc.containsKey('createdAt'), isFalse);
  });
}
