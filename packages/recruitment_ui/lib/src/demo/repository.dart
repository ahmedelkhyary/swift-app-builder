import 'package:flutter/material.dart';

import 'models.dart';

/// All mock pricing in one place so it can later be replaced by a real
/// pricing service. Nothing here is production pricing.
class PricingRules {
  const PricingRules._();

  static const hourlyRate = 35; // SAR per hour (demo)
  static const vatPercent = 15;

  /// Demo surcharge per nationality for recruitment packages.
  static double nationalityFactor(String nationalityId) =>
      switch (nationalityId) {
        'ph' => 1.20,
        'in' => 1.05,
        'id' => 1.10,
        'et' => 0.95,
        'ke' => 1.00,
        'lk' => 1.08,
        _ => 1.0,
      };

  static double professionFactor(String professionId) => switch (professionId) {
    'cook' => 1.15,
    'driver' => 1.10,
    'caregiver' => 1.25,
    _ => 1.0,
  };

  static int recruitmentPrice(RecruitPackage p, String nationalityId) =>
      (p.basePrice * nationalityFactor(nationalityId)).round();

  static int mediationPrice(
    RecruitPackage p,
    String nationalityId,
    String professionId,
  ) =>
      (p.basePrice *
              nationalityFactor(nationalityId) *
              professionFactor(professionId))
          .round();

  static int hourlyPrice({
    required int hoursPerVisit,
    required int visitsPerWeek,
    required int weeks,
  }) {
    final base = hoursPerVisit * visitsPerWeek * weeks * hourlyRate;
    final discountPercent = weeks >= 8 ? 10 : (weeks >= 4 ? 5 : 0);
    return (base * (100 - discountPercent) / 100).round();
  }

  static int vat(int amount) => (amount * vatPercent / 100).round();
}

/// Local, deterministic discount rules (demo only).
class DiscountRules {
  const DiscountRules._();

  static const codes = 'DEMO10 (10%), SAVE50 (50 SAR, min 300), EXPIRED20';

  static DiscountResult apply(String rawCode, int subtotal) {
    final code = rawCode.trim().toUpperCase();
    switch (code) {
      case 'DEMO10':
        return DiscountResult(
          DiscountStatus.applied,
          code: code,
          amount: (subtotal * 0.10).round(),
        );
      case 'SAVE50':
        if (subtotal < 300) {
          return DiscountResult(DiscountStatus.minimumNotMet, code: code);
        }
        return DiscountResult(DiscountStatus.applied, code: code, amount: 50);
      case 'EXPIRED20':
        return DiscountResult(DiscountStatus.expired, code: code);
      default:
        return DiscountResult(DiscountStatus.invalid, code: code);
    }
  }
}

/// Backend-facing surface of the demo. Production apps replace this with real
/// services; the preview only ever uses [MockDemoRepository].
abstract class DemoRepository {
  /// Documented demo rule: the verification code is always this value.
  String get demoOtp;

  Duration get latency;

  Future<bool> sendOtp(String dialCode, String phone);
  Future<bool> verifyOtp(String phone, String code);
  Future<bool> biometricLogin();

  List<PromoBanner> get banners;
  List<Review> get reviews;
  List<Partner> get partners;
  ContactInfo get contact;
  List<DemoAddress> get initialAddresses;

  /// The signed-in customer's display name (greeting on Home).
  L get userName;

  /// Services highlighted on Home, already in display order.
  List<FeaturedService> get featuredServices;

  /// The customer's main (default) address id. Kept by the repository, not the
  /// session, so it survives logout and demo resets like a saved preference.
  String? get mainAddressId;
  set mainAddressId(String? id);
  List<L> get cities;
  List<Nationality> get nationalities;
  List<Profession> get professions;
  List<RecruitPackage> get individualsPackages;
  List<RecruitPackage> get mediationPackages;
  List<HourlyPackage> get hourlyPackages;
  List<PaymentMethodInfo> get paymentMethods;
  List<DemoWorker> get workers;

  Nationality nationality(String id);
  Profession profession(String id);

  /// Days of the week (1 = Monday ... 7 = Sunday) on which service is offered.
  Set<int> get serviceWeekdays;

  Future<PaymentResult> pay({
    required String methodId,
    required int amount,
    required bool simulateFailure,
  });

  String nextOrderReference(ServiceModule module);
}

class MockDemoRepository implements DemoRepository {
  MockDemoRepository({this.latency = const Duration(milliseconds: 700)});

  @override
  final Duration latency;

  int _orderCounter = 1000;

  @override
  String get demoOtp => '123456';

  @override
  Future<bool> sendOtp(String dialCode, String phone) async {
    await Future<void>.delayed(latency);
    return true; // nothing is sent; no SMS provider is involved
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(latency);
    return code == demoOtp;
  }

  @override
  Future<bool> biometricLogin() async {
    await Future<void>.delayed(latency);
    return true; // simulated; no device biometric API is called
  }

  @override
  final banners = const [
    PromoBanner(
      id: 'b1',
      title: L('استقدام بثقة', 'Recruit with confidence'),
      subtitle: L('عاملات مدربات ومعتمدات', 'Trained, verified workers'),
      color: Color(0xFF1565C0),
      target: ServiceModule.individuals,
    ),
    PromoBanner(
      id: 'b2',
      title: L('خدمة بالساعة', 'Hourly cleaning'),
      subtitle: L('خصم 10% بكود DEMO10', '10% off with code DEMO10'),
      color: Color(0xFF00897B),
      target: ServiceModule.hourly,
    ),
    PromoBanner(
      id: 'b3',
      title: L('خدمة الوساطة', 'Mediation service'),
      subtitle: L('اختر العاملة بالاسم', 'Pick your worker by name'),
      color: Color(0xFF6A1B9A),
      target: ServiceModule.mediation,
    ),
  ];

  @override
  final reviews = const [
    Review(
      L('أم محمد', 'Um Mohammed'),
      5,
      L(
        'خدمة ممتازة وسريعة، أنصح بها.',
        'Excellent, fast service. Recommended.',
      ),
    ),
    Review(
      L('خالد العتيبي', 'Khaled A.'),
      4,
      L('الباقات واضحة والأسعار مناسبة.', 'Clear packages and fair prices.'),
    ),
    Review(
      L('سارة', 'Sara'),
      5,
      L('التعاقد سهل والدفع آمن.', 'Easy contract and safe payment.'),
    ),
  ];

  @override
  final partners = const [
    Partner(L('شركاء النجاح', 'Success Partners')),
    Partner(L('تأمين تجريبي', 'Demo Insurance')),
    Partner(L('بنك العينة', 'Sample Bank')),
    Partner(L('نقل المثال', 'Example Transport')),
  ];

  @override
  final contact = const ContactInfo(
    phone: '+966 11 000 0000',
    email: 'hello@demo.example',
    address: L(
      'الرياض - حي العليا (عنوان تجريبي)',
      'Riyadh - Al Olaya (demo address)',
    ),
    hours: L('السبت - الخميس، 9 ص - 6 م', 'Sat - Thu, 9 AM - 6 PM'),
  );

  @override
  final userName = const L('أحمد', 'Ahmed');

  @override
  String? mainAddressId;

  @override
  final featuredServices = const [
    FeaturedService(
      id: 'hourly-maid',
      module: ServiceModule.hourly,
      title: L('عاملة بنظام الساعات', 'Hourly maid'),
      icon: Icons.cleaning_services,
      color: Color(0xFF2A6F97),
    ),
    FeaturedService(
      id: 'driver',
      module: ServiceModule.individuals,
      professionId: 'driver',
      title: L('سائق خاص', 'Private driver'),
      icon: Icons.directions_car,
      color: Color(0xFF6A4C93),
    ),
    FeaturedService(
      id: 'nanny',
      module: ServiceModule.individuals,
      professionId: 'nanny',
      title: L('مربية أطفال', 'Nanny'),
      icon: Icons.child_care,
      color: Color(0xFFC9184A),
    ),
    FeaturedService(
      id: 'housemaid',
      module: ServiceModule.individuals,
      professionId: 'housemaid',
      title: L('عاملة منزلية', 'Housemaid'),
      icon: Icons.home_work,
      color: Color(0xFF2D6A4F),
    ),
  ];

  @override
  final initialAddresses = const [
    DemoAddress(
      id: 'a1',
      label: L('المنزل', 'Home'),
      city: L('الرياض', 'Riyadh'),
      district: L('العليا', 'Al Olaya'),
      street: L('شارع التحلية', 'Tahlia St'),
      building: '12',
    ),
    DemoAddress(
      id: 'a2',
      label: L('الفيلا', 'Villa'),
      city: L('جدة', 'Jeddah'),
      district: L('الروضة', 'Al Rawdah'),
      street: L('شارع الأمير سلطان', 'Prince Sultan St'),
      building: '7',
    ),
  ];

  @override
  final cities = const [
    L('الرياض', 'Riyadh'),
    L('جدة', 'Jeddah'),
    L('الدمام', 'Dammam'),
  ];

  @override
  final nationalities = const [
    Nationality('ph', L('الفلبين', 'Philippines'), '🇵🇭'),
    Nationality('in', L('الهند', 'India'), '🇮🇳'),
    Nationality('id', L('إندونيسيا', 'Indonesia'), '🇮🇩'),
    Nationality('et', L('إثيوبيا', 'Ethiopia'), '🇪🇹'),
    Nationality('ke', L('كينيا', 'Kenya'), '🇰🇪'),
    Nationality('lk', L('سريلانكا', 'Sri Lanka'), '🇱🇰'),
  ];

  @override
  final professions = const [
    Profession(
      'housemaid',
      L('عاملة منزلية', 'Housemaid'),
      Icons.cleaning_services,
    ),
    Profession('nanny', L('مربية أطفال', 'Nanny'), Icons.child_care),
    Profession('cook', L('طباخة', 'Cook'), Icons.restaurant),
    Profession('driver', L('سائق خاص', 'Private driver'), Icons.directions_car),
    Profession('caregiver', L('مرافقة رعاية', 'Caregiver'), Icons.favorite),
  ];

  @override
  final individualsPackages = const [
    RecruitPackage(
      id: 'basic',
      name: L('الباقة الأساسية', 'Basic'),
      description: L(
        'استقدام عاملة مع ضمان لمدة 3 أشهر',
        'Recruitment with a 3-month guarantee',
      ),
      basePrice: 8000,
      includes: [
        L('رسوم الاستقدام', 'Recruitment fees'),
        L('ضمان 3 أشهر', '3-month guarantee'),
      ],
    ),
    RecruitPackage(
      id: 'standard',
      name: L('الباقة القياسية', 'Standard'),
      description: L(
        'تشمل التأمين الطبي وضمان 6 أشهر',
        'Includes medical insurance and a 6-month guarantee',
      ),
      basePrice: 11000,
      popular: true,
      includes: [
        L('رسوم الاستقدام', 'Recruitment fees'),
        L('تأمين طبي', 'Medical insurance'),
        L('ضمان 6 أشهر', '6-month guarantee'),
      ],
    ),
    RecruitPackage(
      id: 'premium',
      name: L('الباقة المميزة', 'Premium'),
      description: L(
        'خدمة كاملة مع استبدال مجاني',
        'Full service with free replacement',
      ),
      basePrice: 15000,
      includes: [
        L('رسوم الاستقدام', 'Recruitment fees'),
        L('تأمين طبي', 'Medical insurance'),
        L('ضمان 12 شهراً', '12-month guarantee'),
        L('استبدال مجاني', 'Free replacement'),
      ],
    ),
  ];

  @override
  final mediationPackages = const [
    RecruitPackage(
      id: 'm_basic',
      name: L('وساطة أساسية', 'Basic mediation'),
      description: L(
        'مطابقة العاملة وإنهاء الإجراءات',
        'Worker matching and paperwork',
      ),
      basePrice: 3000,
      includes: [
        L('مطابقة العاملة', 'Worker matching'),
        L('متابعة الإجراءات', 'Paperwork follow-up'),
      ],
    ),
    RecruitPackage(
      id: 'm_plus',
      name: L('وساطة بلس', 'Mediation Plus'),
      description: L(
        'تشمل الفحص الطبي والتدريب',
        'Includes medical check and training',
      ),
      basePrice: 4500,
      popular: true,
      includes: [
        L('مطابقة العاملة', 'Worker matching'),
        L('فحص طبي', 'Medical check'),
        L('تدريب أولي', 'Initial training'),
      ],
    ),
    RecruitPackage(
      id: 'm_full',
      name: L('وساطة شاملة', 'Full mediation'),
      description: L(
        'خدمة كاملة مع متابعة بعد الوصول',
        'End-to-end with post-arrival follow-up',
      ),
      basePrice: 6500,
      includes: [
        L('مطابقة العاملة', 'Worker matching'),
        L('فحص طبي', 'Medical check'),
        L('تدريب أولي', 'Initial training'),
        L('متابعة بعد الوصول', 'Post-arrival follow-up'),
      ],
    ),
  ];

  @override
  final hourlyPackages = const [
    HourlyPackage(
      id: 'h_starter',
      name: L('باقة البداية', 'Starter'),
      description: L('زيارة أسبوعية لمدة 4 ساعات', 'One 4-hour visit per week'),
      hoursPerVisit: 4,
      visitsPerWeek: 1,
      weeks: 4,
    ),
    HourlyPackage(
      id: 'h_family',
      name: L('باقة العائلة', 'Family'),
      description: L(
        'زيارتان أسبوعياً لمدة 4 ساعات',
        'Two 4-hour visits per week',
      ),
      hoursPerVisit: 4,
      visitsPerWeek: 2,
      weeks: 4,
    ),
    HourlyPackage(
      id: 'h_deep',
      name: L('تنظيف عميق', 'Deep clean'),
      description: L(
        'زيارتان أسبوعياً لمدة 6 ساعات لمدة شهرين',
        'Two 6-hour visits per week for 8 weeks',
      ),
      hoursPerVisit: 6,
      visitsPerWeek: 2,
      weeks: 8,
    ),
    HourlyPackage(
      id: 'h_daily',
      name: L('يومي', 'Daily'),
      description: L(
        '5 زيارات أسبوعياً لمدة 3 ساعات',
        'Five 3-hour visits per week',
      ),
      hoursPerVisit: 3,
      visitsPerWeek: 5,
      weeks: 4,
    ),
  ];

  @override
  final paymentMethods = const [
    PaymentMethodInfo(
      'card',
      L('بطاقة مدى / ائتمان', 'Mada / Credit card'),
      Icons.credit_card,
    ),
    PaymentMethodInfo(
      'wallet',
      L('المحفظة', 'Wallet'),
      Icons.account_balance_wallet,
    ),
    PaymentMethodInfo('applepay', L('Apple Pay', 'Apple Pay'), Icons.apple),
    PaymentMethodInfo(
      'transfer',
      L('تحويل بنكي', 'Bank transfer'),
      Icons.account_balance,
    ),
  ];

  @override
  Set<int> get serviceWeekdays => {1, 2, 3, 4, 6, 7}; // Friday (5) is off

  @override
  Nationality nationality(String id) =>
      nationalities.firstWhere((n) => n.id == id);

  @override
  Profession profession(String id) => professions.firstWhere((p) => p.id == id);

  @override
  Future<PaymentResult> pay({
    required String methodId,
    required int amount,
    required bool simulateFailure,
  }) async {
    await Future<void>.delayed(latency);
    if (simulateFailure) {
      return const PaymentResult.failure(
        L('تم رفض العملية (محاكاة)', 'Payment declined (simulated)'),
      );
    }
    if (methodId == 'wallet' && amount > 5000) {
      return const PaymentResult.failure(
        L(
          'رصيد المحفظة غير كافٍ (محاكاة)',
          'Insufficient wallet balance (simulated)',
        ),
      );
    }
    return const PaymentResult.success();
  }

  @override
  String nextOrderReference(ServiceModule module) {
    _orderCounter++;
    final prefix = switch (module) {
      ServiceModule.individuals => 'IND',
      ServiceModule.hourly => 'HRS',
      ServiceModule.mediation => 'MED',
    };
    return 'DEMO-$prefix-$_orderCounter';
  }

  // ---- workers (generated deterministically) -------------------------------

  static const _names = <String, List<L>>{
    'ph': [
      L('ماريا سانتوس', 'Maria Santos'),
      L('جوزفين ريس', 'Josephine Reyes'),
      L('ليزا كروز', 'Liza Cruz'),
      L('آنا باوتيستا', 'Ana Bautista'),
      L('روزا ماجنو', 'Rosa Magno'),
    ],
    'in': [
      L('أنيتا كوماري', 'Anita Kumari'),
      L('ميرا ديفي', 'Meera Devi'),
      L('بريا شارما', 'Priya Sharma'),
      L('سونيتا راو', 'Sunita Rao'),
      L('لاكشمي ناير', 'Lakshmi Nair'),
    ],
    'id': [
      L('ريتنو واتي', 'Ratno Wati'),
      L('سيتي نور', 'Siti Nur'),
      L('دوي ليستاري', 'Dewi Lestari'),
      L('أوتامي', 'Utami'),
      L('ياني سري', 'Yani Sri'),
    ],
    'et': [
      L('سلام تسفاي', 'Selam Tesfaye'),
      L('ألم بيكيلي', 'Alem Bekele'),
      L('هيرموني ديسالين', 'Hirut Desalegn'),
      L('ماريتو', 'Marito'),
      L('تيجست', 'Tigist'),
    ],
    'ke': [
      L('وانجيرو', 'Wanjiru'),
      L('أكينيي', 'Akinyi'),
      L('نيامبورا', 'Nyambura'),
      L('وامبوي', 'Wambui'),
      L('أتيينو', 'Atieno'),
    ],
    'lk': [
      L('كوماري ب.', 'Kumari P.'),
      L('نيلانثي', 'Nilanthi'),
      L('شاميلا', 'Shamila'),
      L('ديبيكا', 'Dilrukshi'),
      L('ساندهيا', 'Sandya'),
    ],
  };

  static const _skills = <String, List<L>>{
    'housemaid': [
      L('تنظيف المنزل', 'House cleaning'),
      L('الكي والغسيل', 'Laundry and ironing'),
      L('ترتيب', 'Organizing'),
    ],
    'nanny': [
      L('رعاية الأطفال', 'Child care'),
      L('إسعافات أولية', 'First aid'),
      L('مساعدة بالدراسة', 'Homework help'),
    ],
    'cook': [
      L('مطبخ عربي', 'Arabic cuisine'),
      L('مطبخ عالمي', 'International cuisine'),
      L('تحضير الوجبات', 'Meal prep'),
    ],
    'driver': [
      L('رخصة سارية', 'Valid licence'),
      L('معرفة بالطرق', 'Route knowledge'),
      L('قيادة آمنة', 'Safe driving'),
    ],
    'caregiver': [
      L('رعاية كبار السن', 'Elder care'),
      L('مرافقة طبية', 'Medical escort'),
      L('إعطاء الأدوية', 'Medication reminders'),
    ],
  };

  static const _languages = <String, List<L>>{
    'ph': [L('الإنجليزية', 'English'), L('التاغالوغية', 'Tagalog')],
    'in': [L('الإنجليزية', 'English'), L('الهندية', 'Hindi')],
    'id': [L('الإندونيسية', 'Indonesian')],
    'et': [L('الأمهرية', 'Amharic'), L('الإنجليزية', 'English')],
    'ke': [L('الإنجليزية', 'English'), L('السواحيلية', 'Swahili')],
    'lk': [L('السنهالية', 'Sinhala'), L('الإنجليزية', 'English')],
  };

  static const _profCodes = {
    'housemaid': 'HM',
    'nanny': 'NY',
    'cook': 'CK',
    'driver': 'DR',
    'caregiver': 'CG',
  };

  @override
  late final List<DemoWorker> workers = _buildWorkers();

  List<DemoWorker> _buildWorkers() {
    final result = <DemoWorker>[];
    for (var n = 0; n < nationalities.length; n++) {
      final nat = nationalities[n];
      for (var p = 0; p < professions.length; p++) {
        final prof = professions[p];
        for (var k = 0; k < 3; k++) {
          result.add(
            DemoWorker(
              id: 'w_${nat.id}_${prof.id}_$k',
              code: 'W-${nat.id.toUpperCase()}-${_profCodes[prof.id]}-${k + 1}',
              name: _names[nat.id]![(p + k) % 5],
              nationalityId: nat.id,
              professionId: prof.id,
              age: 25 + ((n * 7 + p * 3 + k * 5) % 15),
              years: 1 + ((n + p * 2 + k * 3) % 9),
              rating: 4.0 + ((n + p + k * 2) % 10) / 10,
              skills: _skills[prof.id]!,
              languages: _languages[nat.id]!,
              packageIds: switch (k) {
                0 => {'basic', 'standard', 'premium'},
                1 => {'basic', 'standard'},
                _ => {'standard', 'premium'},
              },
              bio: L(
                'ملف تجريبي لعاملة من ${nat.name.ar} بخبرة في ${prof.name.ar}.',
                'Demo profile: a ${prof.name.en.toLowerCase()} from ${nat.name.en}.',
              ),
            ),
          );
        }
      }
    }
    return result;
  }
}
