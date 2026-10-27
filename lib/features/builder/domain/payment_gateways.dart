/// The payment gateways the wizard can configure. The form of every gateway is
/// generated from its entry here (labels included, so no l10n entries are
/// needed): to add a gateway (Tap, Moyasar, ...) add one [PaymentGateway] to
/// [kPaymentGateways]. Also mirror its non-secret field keys in
/// `assets/config.schema.json` (a unit test checks they match) and its
/// secrets / connection test in `functions/src/paymentGateways.ts`.
library;

enum GatewayFieldType {
  /// Plain value, stored in the request and the exported settings file.
  text,

  /// Never leaves the browser except through the secrets backend call and the
  /// connection test; never part of the request, the config or the export.
  secret,

  /// One of [GatewayField.options].
  select,
}

class GatewayField {
  const GatewayField({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    this.type = GatewayFieldType.text,
    this.required = false,
    this.placeholder,
    this.helpAr,
    this.helpEn,
    this.options = const [],
    this.defaultValue,
  });

  final String key;
  final String labelAr;
  final String labelEn;
  final GatewayFieldType type;
  final bool required;
  final String? placeholder;
  final String? helpAr;
  final String? helpEn;

  /// Allowed values of a [GatewayFieldType.select].
  final List<String> options;
  final String? defaultValue;

  bool get isSecret => type == GatewayFieldType.secret;

  String label(String lang) => lang == 'ar' ? labelAr : labelEn;
  String? help(String lang) => lang == 'ar' ? helpAr : helpEn;
}

/// A region a gateway serves; shown as a tag with a flag (or a globe for
/// [gulf]).
enum GatewayRegion {
  /// Egypt (flag code `eg`).
  eg,

  /// Saudi Arabia (flag code `sa`).
  sa,

  /// The Gulf countries, see [PaymentGateway.gulfCountries].
  gulf,
}

/// Gulf Cooperation Council countries other than Saudi Arabia (ISO codes).
const kGulfCountries = ['ae', 'kw', 'qa', 'bh', 'om'];

class PaymentGateway {
  const PaymentGateway({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.initials,
    required this.regions,
    required this.supportedMethods,
    this.fields = const [],
    this.gulfCountries = kGulfCountries,
    this.logo,
    this.logoDark,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  /// Where the gateway operates, shown as country tags on its tile.
  final List<GatewayRegion> regions;

  /// The countries behind [GatewayRegion.gulf] (ISO codes), listed in its
  /// tooltip.
  final List<String> gulfCountries;

  /// Shown in the logo tile when the logo is missing or fails to load.
  final String initials;

  /// Official logo (SVG asset), shown as it is: never recolored or cropped.
  final String? logo;

  /// Optional variant for dark backgrounds; [logo] is used when absent.
  final String? logoDark;

  /// Payment method ids (see [kPaymentMethodLabels]).
  final List<String> supportedMethods;
  final List<GatewayField> fields;

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;

  Iterable<GatewayField> get secretFields => fields.where((f) => f.isSecret);
  Iterable<GatewayField> get publicFields => fields.where((f) => !f.isSecret);

  GatewayField? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// Display names (Arabic, English) of the payment methods gateways support.
const kPaymentMethodLabels = <String, (String, String)>{
  'mada': ('مدى', 'mada'),
  'visa': ('فيزا', 'Visa'),
  'mastercard': ('ماستركارد', 'Mastercard'),
  'applepay': ('أبل باي', 'Apple Pay'),
  'stcpay': ('STC Pay', 'STC Pay'),
  'cards': ('البطاقات', 'Cards'),
  'wallets': ('المحافظ', 'Wallets'),
  'fawry': ('فوري', 'Fawry'),
  'valu': ('valU', 'valU'),
};

String paymentMethodLabel(String id, String lang) {
  final l = kPaymentMethodLabels[id];
  if (l == null) return id;
  return lang == 'ar' ? l.$1 : l.$2;
}

const kPaymentGateways = <PaymentGateway>[
  PaymentGateway(
    id: 'hyperpay',
    nameAr: 'هايبر باي',
    nameEn: 'HyperPay',
    initials: 'HP',
    regions: [GatewayRegion.sa, GatewayRegion.gulf],
    logo: 'assets/payment-gateways/hyperpay.png',
    supportedMethods: ['mada', 'visa', 'mastercard', 'applepay', 'stcpay'],
    fields: [
      GatewayField(
        key: 'accessToken',
        labelAr: 'رمز الوصول (Access Token)',
        labelEn: 'Access token',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'entityIdCards',
        labelAr: 'Entity ID للبطاقات',
        labelEn: 'Entity ID (cards)',
        required: true,
        placeholder: '8ac7a4c8…',
      ),
      GatewayField(
        key: 'entityIdMada',
        labelAr: 'Entity ID لمدى',
        labelEn: 'Entity ID (mada)',
        required: true,
        placeholder: '8ac7a4c8…',
      ),
      GatewayField(
        key: 'entityIdApplePay',
        labelAr: 'Entity ID لأبل باي',
        labelEn: 'Entity ID (Apple Pay)',
        placeholder: '8ac7a4c8…',
        helpAr: 'اختياري. اتركه فاضي لو مش هتفعّل أبل باي.',
        helpEn: 'Optional. Leave empty if you do not offer Apple Pay.',
      ),
      GatewayField(
        key: 'entityIdStcPay',
        labelAr: 'Entity ID لـ STC Pay',
        labelEn: 'Entity ID (STC Pay)',
        placeholder: '8ac7a4c8…',
        helpAr: 'اختياري. اتركه فاضي لو مش هتفعّل STC Pay.',
        helpEn: 'Optional. Leave empty if you do not offer STC Pay.',
      ),
    ],
  ),
  PaymentGateway(
    id: 'paymob',
    nameAr: 'باي موب',
    nameEn: 'Paymob',
    initials: 'PM',
    regions: [GatewayRegion.eg, GatewayRegion.sa, GatewayRegion.gulf],
    logo: 'assets/payment-gateways/paymob.png',
    supportedMethods: ['cards', 'wallets', 'fawry', 'valu'],
    fields: [
      GatewayField(
        key: 'apiKey',
        labelAr: 'مفتاح الـ API',
        labelEn: 'API key',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'secretKey',
        labelAr: 'المفتاح السري',
        labelEn: 'Secret key',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'publicKey',
        labelAr: 'المفتاح العام',
        labelEn: 'Public key',
        required: true,
      ),
      GatewayField(
        key: 'cardIntegrationId',
        labelAr: 'Integration ID للبطاقات',
        labelEn: 'Card integration ID',
        required: true,
        placeholder: '1234567',
      ),
      GatewayField(
        key: 'walletIntegrationId',
        labelAr: 'Integration ID للمحافظ',
        labelEn: 'Wallet integration ID',
        placeholder: '1234567',
        helpAr: 'اختياري. للمحافظ الإلكترونية فقط.',
        helpEn: 'Optional. Only for mobile wallets.',
      ),
      GatewayField(
        key: 'hmacSecret',
        labelAr: 'مفتاح HMAC',
        labelEn: 'HMAC secret',
        type: GatewayFieldType.secret,
        required: true,
      ),
    ],
  ),
  PaymentGateway(
    id: 'payfort',
    nameAr: 'أمازون للدفع (PayFort)',
    nameEn: 'Amazon Payment Services (PayFort)',
    initials: 'APS',
    regions: [GatewayRegion.eg, GatewayRegion.sa, GatewayRegion.gulf],
    logo: 'assets/payment-gateways/aps.png',
    supportedMethods: ['mada', 'visa', 'mastercard', 'applepay'],
    fields: [
      GatewayField(
        key: 'merchantIdentifier',
        labelAr: 'معرّف التاجر (Merchant Identifier)',
        labelEn: 'Merchant identifier',
        required: true,
      ),
      GatewayField(
        key: 'accessCode',
        labelAr: 'رمز الوصول (Access Code)',
        labelEn: 'Access code',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'shaRequestPhrase',
        labelAr: 'SHA Request Phrase',
        labelEn: 'SHA request phrase',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'shaResponsePhrase',
        labelAr: 'SHA Response Phrase',
        labelEn: 'SHA response phrase',
        type: GatewayFieldType.secret,
        required: true,
      ),
      GatewayField(
        key: 'shaType',
        labelAr: 'نوع التشفير (SHA Type)',
        labelEn: 'SHA type',
        type: GatewayFieldType.select,
        options: ['SHA-256', 'SHA-512'],
        defaultValue: 'SHA-256',
      ),
    ],
  ),
];

PaymentGateway? paymentGatewayById(String id) {
  for (final g in kPaymentGateways) {
    if (g.id == id) return g;
  }
  return null;
}
