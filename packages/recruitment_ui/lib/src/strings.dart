/// Minimal string table for the recruitment flow (ar / en).
class RuiStrings {
  const RuiStrings(this.languageCode);
  final String languageCode;

  bool get isAr => languageCode == 'ar';

  /// Picks the Arabic or English variant of an inline UI string.
  String x(String ar, String en) => isAr ? ar : en;

  String _t(String key) => (_table[key] ?? const {})[languageCode] ?? key;

  String get home => _t('home');
  String get orders => _t('orders');
  String get account => _t('account');
  String get welcome => _t('welcome');
  String get heroTitle => _t('heroTitle');
  String get heroBody => _t('heroBody');
  String get startNow => _t('startNow');
  String get ourServices => _t('ourServices');
  String get howItWorks => _t('howItWorks');
  String get chooseService => _t('chooseService');
  String get chooseAddress => _t('chooseAddress');
  String get choosePackage => _t('choosePackage');
  String get chooseWorker => _t('chooseWorker');
  String get checkout => _t('checkout');
  String get city => _t('city');
  String get district => _t('district');
  String get pinOnMap => _t('pinOnMap');
  String get next => _t('next');
  String get select => _t('select');
  String get selected => _t('selected');
  String get currency => _t('currency');
  String get experience => _t('experience');
  String get years => _t('years');
  String get orderSummary => _t('orderSummary');
  String get paymentMethod => _t('paymentMethod');
  String get card => _t('card');
  String get applePay => _t('applePay');
  String get total => _t('total');
  String get payNow => _t('payNow');
  String get service => _t('service');
  String get package => _t('package');
  String get worker => _t('worker');
  String get address => _t('address');
  String stepOf(int n, int total) =>
      isAr ? 'الخطوة $n من $total' : 'Step $n of $total';

  String step(int i) => _t('step$i');

  static const _table = <String, Map<String, String>>{
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'orders': {'ar': 'طلباتي', 'en': 'Orders'},
    'account': {'ar': 'حسابي', 'en': 'Account'},
    'welcome': {'ar': 'مرحباً بك', 'en': 'Welcome'},
    'heroTitle': {
      'ar': 'استقدم عاملتك بسهولة',
      'en': 'Hire your helper easily',
    },
    'heroBody': {
      'ar': 'اختر الخدمة والباقة والعاملة المناسبة في دقائق',
      'en': 'Pick the service, package and worker in minutes',
    },
    'startNow': {'ar': 'ابدأ الآن', 'en': 'Start now'},
    'ourServices': {'ar': 'خدماتنا', 'en': 'Our services'},
    'howItWorks': {'ar': 'كيف يعمل التطبيق', 'en': 'How it works'},
    'chooseService': {'ar': 'اختر الخدمة', 'en': 'Choose a service'},
    'chooseAddress': {'ar': 'اختر العنوان', 'en': 'Choose address'},
    'choosePackage': {'ar': 'اختر الباقة', 'en': 'Choose a package'},
    'chooseWorker': {'ar': 'اختر العاملة', 'en': 'Choose a worker'},
    'checkout': {'ar': 'الدفع', 'en': 'Checkout'},
    'city': {'ar': 'المدينة', 'en': 'City'},
    'district': {'ar': 'الحي', 'en': 'District'},
    'pinOnMap': {'ar': 'حدد الموقع على الخريطة', 'en': 'Pin your location'},
    'next': {'ar': 'التالي', 'en': 'Next'},
    'select': {'ar': 'اختيار', 'en': 'Select'},
    'selected': {'ar': 'تم الاختيار', 'en': 'Selected'},
    'currency': {'ar': 'ر.س', 'en': 'SAR'},
    'experience': {'ar': 'الخبرة', 'en': 'Experience'},
    'years': {'ar': 'سنوات', 'en': 'years'},
    'orderSummary': {'ar': 'ملخص الطلب', 'en': 'Order summary'},
    'paymentMethod': {'ar': 'طريقة الدفع', 'en': 'Payment method'},
    'card': {'ar': 'بطاقة مدى / ائتمان', 'en': 'Mada / Credit card'},
    'applePay': {'ar': 'Apple Pay', 'en': 'Apple Pay'},
    'total': {'ar': 'الإجمالي', 'en': 'Total'},
    'payNow': {'ar': 'ادفع الآن', 'en': 'Pay now'},
    'service': {'ar': 'الخدمة', 'en': 'Service'},
    'package': {'ar': 'الباقة', 'en': 'Package'},
    'worker': {'ar': 'العاملة', 'en': 'Worker'},
    'address': {'ar': 'العنوان', 'en': 'Address'},
    'step1': {'ar': 'اختر الخدمة', 'en': 'Choose service'},
    'step2': {'ar': 'حدد العنوان', 'en': 'Set address'},
    'step3': {'ar': 'اختر الباقة', 'en': 'Pick package'},
    'step4': {'ar': 'اختر العاملة', 'en': 'Pick worker'},
    'step5': {'ar': 'ادفع أونلاين', 'en': 'Pay online'},
  };
}
