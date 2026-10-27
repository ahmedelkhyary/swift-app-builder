import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:swiftappbuilder/features/builder/application/schema_validator.dart';
import 'package:swiftappbuilder/features/builder/domain/asset.dart';
import 'package:swiftappbuilder/features/builder/domain/draft.dart';
import 'package:swiftappbuilder/features/builder/domain/payments.dart';

ConfigSchemaValidator loadSchema() =>
    ConfigSchemaValidator(File('assets/config.schema.json').readAsStringSync());

Uint8List pngBytes(int w, int h, {bool alpha = false}) {
  final image = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
  img.fill(image, color: img.ColorRgba8(21, 101, 192, alpha ? 128 : 255));
  return Uint8List.fromList(img.encodePng(image));
}

PickedAsset fakeAsset(String name) => PickedAsset(
  name: name,
  bytes: pngBytes(16, 16),
  extension: 'png',
  width: 16,
  height: 16,
);

AppConfigDraft validDraft({String appId = 'swift_maids'}) => AppConfigDraft(
  appId: appId,
  appIdEdited: true,
  nameAr: 'سويفت للعمالة',
  nameEn: 'Swift Maids',
  androidPackage: 'com.excp.swift',
  iosSameAsAndroid: true,
  iosBundleId: 'com.excp.swift',
  clientName: 'مكتب سويفت',
  clientEmail: 'info@swift.example',
  clientPhone: '+966500000000',
  logo: fakeAsset('logo.png'),
  appIcon: fakeAsset('icon.png'),
  // The payments step is optional: "configure later" keeps it valid.
  payments: const PaymentsDraft(configureLater: true),
);
