// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'منشئ التطبيقات';

  @override
  String get toggleLanguage => 'English';

  @override
  String get sectionInfo => 'معلومات التطبيق';

  @override
  String get sectionBranding => 'الهوية البصرية';

  @override
  String get sectionLocalization => 'اللغات';

  @override
  String get sectionTemplate => 'القالب';

  @override
  String get sectionSummary => 'الملخص';

  @override
  String get next => 'التالي';

  @override
  String get back => 'السابق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get load => 'تحميل';

  @override
  String get upload => 'رفع ملف';

  @override
  String get remove => 'إزالة';

  @override
  String get loadExisting => 'تحميل إعدادات موجودة';

  @override
  String get loadByAppId => 'فتح بمعرّف التطبيق';

  @override
  String get importJsonFile => 'استيراد ملف JSON';

  @override
  String get loadDialogTitle => 'تحميل إعدادات موجودة';

  @override
  String get appNotFound => 'لا توجد إعدادات لهذا المعرّف';

  @override
  String importFailed(String error) {
    return 'تعذر استيراد الملف: $error';
  }

  @override
  String get loadedFromJsonNote =>
      'تم تحميل الإعدادات. أعد رفع الشعار والأيقونة لأنهما ليسا جزءاً من ملف JSON.';

  @override
  String get fieldNameAr => 'اسم التطبيق (عربي)';

  @override
  String get fieldNameEn => 'اسم التطبيق (إنجليزي)';

  @override
  String get fieldAndroidPackage => 'اسم حزمة أندرويد';

  @override
  String get fieldIosBundleId => 'معرّف حزمة iOS';

  @override
  String get fieldIosSame => 'نفس حزمة أندرويد';

  @override
  String get fieldAppId => 'معرّف التطبيق';

  @override
  String get fieldAppIdHelper =>
      'يُولَّد من الاسم الإنجليزي، ويمكنك تعديله يدويًا.';

  @override
  String get fieldClientName => 'اسم العميل / المكتب';

  @override
  String get fieldClientEmail => 'البريد الإلكتروني';

  @override
  String get fieldClientPhone => 'هاتف الدعم';

  @override
  String get appIdChecking => 'جارٍ التحقق من التوفر…';

  @override
  String get appIdAvailable => 'المعرّف متاح';

  @override
  String get errRequired => 'هذا الحقل مطلوب';

  @override
  String get errInvalidPackage =>
      'استخدم أحرفًا صغيرة بدون مسافات، مثل com.rose.store';

  @override
  String get errInvalidBundleId =>
      'استخدم صيغة النطاق العكسي بدون مسافات، مثل com.rose.store';

  @override
  String get errInvalidEmail =>
      'أدخل بريدًا إلكترونيًا صحيحًا، مثل name@company.com';

  @override
  String get errInvalidPhone =>
      'أدخل رقم هاتف من 8 إلى 15 رقمًا، مثل +966500000000';

  @override
  String get errInvalidHex => 'استخدم لوناً بصيغة hex مثل #1565C0';

  @override
  String get errInvalidAppId =>
      'من 3 إلى 40 حرفًا إنجليزيًا صغيرًا أو أرقامًا أو شرطة سفلية، ويبدأ بحرف، مثل rose_store';

  @override
  String get errAppIdTaken => 'هذا المعرّف مستخدم بالفعل';

  @override
  String get errDefaultNotSupported =>
      'يجب أن تكون اللغة الافتراضية ضمن اللغات المدعومة';

  @override
  String get errAssetMissing => 'هذا الملف مطلوب';

  @override
  String get primaryColor => 'اللون الأساسي';

  @override
  String get secondaryColor => 'اللون الثانوي';

  @override
  String get colorHex => 'قيمة hex';

  @override
  String get pickColor => 'اختر لوناً';

  @override
  String contrastWarning(String ratio) {
    return 'نسبة التباين للنص الأبيض على هذا اللون $ratio:1، وهي أقل من الحد الأدنى 4.5:1 حسب WCAG AA.';
  }

  @override
  String contrastOk(String ratio) {
    return 'تباين النص يحقق WCAG AA ($ratio:1)';
  }

  @override
  String get logoLabel => 'الشعار';

  @override
  String get logoHint =>
      'PNG أو SVG، يفضّل خلفية شفافة و 1024×1024 (الحد الأدنى 512)';

  @override
  String get appIconLabel => 'أيقونة التطبيق';

  @override
  String get appIconHint => 'PNG بحجم 1024×1024 بالضبط وبدون شفافية';

  @override
  String get splashTitle => 'شاشة البداية';

  @override
  String get splashBackground => 'لون خلفية شاشة البداية';

  @override
  String get splashLogoLabel => 'شعار شاشة البداية (اختياري)';

  @override
  String get splashLogoHint => 'يُستخدم الشعار الرئيسي عند تركه فارغاً';

  @override
  String get fontFamily => 'نوع الخط';

  @override
  String get noFile => 'لم يتم اختيار ملف';

  @override
  String get issueWrongType => 'نوع الملف غير مدعوم';

  @override
  String get issueTooLarge => 'حجم الملف أكبر من 2 ميجابايت';

  @override
  String get issueUndecodable => 'تعذرت قراءة الصورة';

  @override
  String get issueTooSmall => 'الصورة أصغر من 512×512';

  @override
  String get issueWrongSize => 'يجب أن تكون الصورة 1024×1024 بالضبط';

  @override
  String get issueHasTransparency =>
      'الصورة تحتوي على شفافية، ويجب أن تكون الأيقونة معتمة';

  @override
  String get defaultLanguage => 'اللغة الافتراضية';

  @override
  String get supportedLanguages => 'اللغات المدعومة';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'الإنجليزية';

  @override
  String get defaultAlwaysIncluded => 'اللغة الافتراضية مضمّنة دائماً';

  @override
  String get chooseTemplate => 'اختر قالباً';

  @override
  String get templateClassic => 'كلاسيكي';

  @override
  String get templateModern => 'عصري';

  @override
  String get templateMinimal => 'بسيط';

  @override
  String get templatePremium => 'فاخر';

  @override
  String get previewLanguage => 'لغة المعاينة';

  @override
  String get previewDark => 'الوضع الداكن';

  @override
  String get screenHome => 'الرئيسية';

  @override
  String get screenService => 'الخدمة';

  @override
  String get screenAddress => 'العنوان';

  @override
  String get screenPackage => 'الباقة';

  @override
  String get screenWorker => 'العاملة';

  @override
  String get screenCheckout => 'الدفع';

  @override
  String get summaryReview => 'المراجعة';

  @override
  String get summaryJson => 'ملف الإعدادات JSON';

  @override
  String get summaryValidation => 'تقرير التحقق';

  @override
  String get validationPassed => 'الإعدادات صالحة وفق المخطط';

  @override
  String get validationFailed => 'فشل التحقق من المخطط';

  @override
  String get fixSectionsFirst => 'أكمل الأقسام السابقة لعرض الملخص.';

  @override
  String willSaveAsVersion(int version) {
    return 'سيتم الحفظ كإصدار $version';
  }

  @override
  String get save => 'حفظ الإعدادات';

  @override
  String saveSuccess(int version) {
    return 'تم الحفظ كإصدار $version';
  }

  @override
  String saveFailed(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String get downloadJson => 'تنزيل JSON';

  @override
  String get downloadFailed => 'التنزيل متاح في المتصفح فقط';

  @override
  String get versionHistory => 'سجل الإصدارات';

  @override
  String get noVersions => 'لا توجد إصدارات محفوظة بعد';

  @override
  String versionLabel(int version) {
    return 'الإصدار $version';
  }

  @override
  String get restoreAsDraft => 'استعادة كمسودة جديدة';

  @override
  String restored(int version) {
    return 'تمت استعادة الإصدار $version كمسودة جديدة';
  }

  @override
  String get valueNotSet => '—';

  @override
  String get labelTemplate => 'القالب';

  @override
  String get labelColors => 'الألوان';

  @override
  String get labelLogo => 'الشعار';

  @override
  String get labelIcon => 'أيقونة التطبيق';

  @override
  String get labelLanguages => 'اللغات';

  @override
  String get labelClient => 'العميل';

  @override
  String get labelAndroid => 'أندرويد';

  @override
  String get labelIos => 'iOS';

  @override
  String get modulesTitle => 'وحدات الخدمة';

  @override
  String get moduleIndividuals => 'خدمات الأفراد';

  @override
  String get moduleHourly => 'الخدمات بالساعة';

  @override
  String get moduleMediation => 'خدمات الوساطة';

  @override
  String get errNoModules => 'فعّل وحدة خدمة واحدة على الأقل';

  @override
  String get previewDemoNote =>
      'عرض تفاعلي: بيانات وهمية، بدون مدفوعات أو رسائل أو حجوزات حقيقية.';

  @override
  String get previewReset => 'إعادة ضبط العرض';

  @override
  String get previewOpenFull => 'فتح المعاينة الكاملة';

  @override
  String get previewBackToGallery => 'العودة إلى معرض القوالب';

  @override
  String get useThisTemplate => 'استخدام هذا القالب';

  @override
  String get jumpTo => 'انتقال إلى';

  @override
  String get jumpLogin => 'تسجيل الدخول';

  @override
  String get jumpHome => 'الرئيسية';

  @override
  String get jumpIndividuals => 'الأفراد';

  @override
  String get jumpHourly => 'بالساعة';

  @override
  String get jumpMediation => 'الوساطة';

  @override
  String get previewPageTitle => 'المعاينة التفاعلية';

  @override
  String previewTemplateSelected(String name) {
    return 'تم اختيار القالب: $name';
  }

  @override
  String get labelModules => 'الوحدات';

  @override
  String get labelTemplateVersion => 'إصدار القالب';

  @override
  String wizardStep(int n, int total) {
    return 'الخطوة $n من $total';
  }

  @override
  String nextWithName(String name) {
    return 'التالي: $name';
  }

  @override
  String get autoBadge => 'تلقائي';

  @override
  String get editAppId => 'تعديل المعرّف';

  @override
  String get resetAppId => 'توليد المعرّف من الاسم الإنجليزي مجددًا';

  @override
  String get infoSubtitle =>
      'البيانات الأساسية للتطبيق ومعرّفات المتاجر. الحقول المعلّمة بـ * مطلوبة.';

  @override
  String get brandingSubtitle =>
      'اختر أي لون تحبه من المنتقي، أو اكتب كود اللون مباشرة.';

  @override
  String get localizationSubtitle =>
      'اختر اللغة الافتراضية واللغات التي يدعمها التطبيق.';

  @override
  String get templateSubtitle =>
      'حدّد وحدات الخدمة، ثم اختر الشكل اللي يناسب علامتك. تقدر تغيّره لاحقًا.';

  @override
  String get summarySubtitle =>
      'راجع كل شيء ثم احفظ إصدارًا جديدًا من الإعدادات.';

  @override
  String get cardNameIdTitle => 'الاسم والمعرّف';

  @override
  String get cardNameIdDesc => 'كيف سيظهر التطبيق للمستخدمين';

  @override
  String get cardStoresTitle => 'أندرويد و iOS';

  @override
  String get cardStoresDesc => 'معرّفات النشر على المتاجر';

  @override
  String get cardClientTitle => 'العميل';

  @override
  String get cardClientDesc => 'الجهة التي يُبنى لها التطبيق';

  @override
  String get phNameAr => 'مثال: متجر الورد';

  @override
  String get phNameEn => 'e.g. Rose Store';

  @override
  String get phPackage => 'com.company.app';

  @override
  String get helperPackage =>
      'أحرف إنجليزية صغيرة ونقاط فقط، ولا يمكن تغييره بعد النشر.';

  @override
  String get iosSameTitle => 'استخدام نفس الحزمة لـ iOS';

  @override
  String get iosSameDesc => 'سيُنسخ معرّف أندرويد تلقائيًا إلى iOS';

  @override
  String get errNameArRequired => 'أدخل اسم التطبيق بالعربية، مثل: متجر الورد';

  @override
  String get errNameEnRequired =>
      'أدخل اسم التطبيق بالإنجليزية، مثل: Rose Store';

  @override
  String get errPackageRequired => 'أدخل اسم حزمة أندرويد، مثل com.rose.store';

  @override
  String get errBundleRequired => 'أدخل معرّف حزمة iOS، مثل com.rose.store';

  @override
  String get errClientRequired => 'أدخل اسم العميل أو المكتب';

  @override
  String get errAppIdRequired => 'أدخل معرّف التطبيق، مثل rose_store';

  @override
  String get templateHeading => 'اختر قالب التطبيق';

  @override
  String get modulesHint => 'اختر وحدة أو أكثر';

  @override
  String get moduleIndividualsDesc => 'استقدام عاملات';

  @override
  String get moduleHourlyDesc => 'حجز بالساعة';

  @override
  String get moduleMediationDesc => 'نقل كفالة';

  @override
  String get templatesTitle => 'القوالب';

  @override
  String templatesAvailable(int count) {
    return '$count قوالب متاحة';
  }

  @override
  String get templateClassicDesc => 'تخطيط متوازن وبطاقات واضحة';

  @override
  String get templateModernDesc => 'حواف مدوّرة وطابع هادئ';

  @override
  String get templateMinimalDesc => 'خطوط نظيفة وقوائم بسيطة';

  @override
  String get templatePremiumDesc => 'تدرجات جريئة وعمق بصري';

  @override
  String get selectedPill => 'مُختار';

  @override
  String get livePreview => 'معاينة حيّة';

  @override
  String get previewDemoShort =>
      'بيانات تجريبية، بدون مدفوعات أو حجوزات حقيقية';

  @override
  String get deviceIphone => 'iPhone';

  @override
  String get deviceAndroid => 'Android';

  @override
  String enableModuleTooltip(String name) {
    return 'فعّل «$name» لعرضها';
  }

  @override
  String get selectedTemplateLabel => 'القالب المختار:';

  @override
  String get previewTemplateSwitcher => 'القالب';

  @override
  String get colorsCardTitle => 'ألوان التطبيق';

  @override
  String get extractColors => 'استخراج الألوان من الشعار';

  @override
  String get roleTabsLabel => 'أدوار الألوان';

  @override
  String get rolePrimary => 'الأساسي';

  @override
  String get roleSecondary => 'الثانوي';

  @override
  String get roleSplash => 'خلفية شاشة البداية';

  @override
  String get roleDescPrimary => 'الأزرار، البانر، العناصر النشطة';

  @override
  String get roleDescSecondary => 'التمييز، الشارات، الأيقونات الثانوية';

  @override
  String get roleDescSplash => 'خلفية شاشة البداية عند فتح التطبيق';

  @override
  String get pickerAreaLabel => 'التشبع والسطوع';

  @override
  String pickerAreaValue(String s, String v) {
    return 'التشبع $s%، السطوع $v%';
  }

  @override
  String get hueLabel => 'درجة اللون';

  @override
  String hueValue(String deg) {
    return '$deg°';
  }

  @override
  String get eyedropperLabel => 'أداة التقاط اللون';

  @override
  String get hexLabel => 'HEX';

  @override
  String contrastOkWhite(String ratio) {
    return 'النص الأبيض واضح على هذا اللون (تباين $ratio:1)';
  }

  @override
  String contrastWarnWhite(String ratio) {
    return 'النص قد لا يكون واضحًا على هذا اللون (تباين $ratio:1)';
  }

  @override
  String contrastOkBg(String ratio) {
    return 'اللون الأساسي واضح على هذه الخلفية (تباين $ratio:1)';
  }

  @override
  String contrastWarnBg(String ratio) {
    return 'اللون الأساسي قد لا يكون واضحًا على هذه الخلفية (تباين $ratio:1)';
  }

  @override
  String get suggestedColors => 'ألوان مقترحة';

  @override
  String get fromLogo => 'من الشعار';

  @override
  String colorSwatchLabel(String hex) {
    return 'اللون $hex';
  }

  @override
  String get changeLogo => 'تغيير الشعار';

  @override
  String get uploadLogo => 'رفع الشعار';

  @override
  String get livePreviewSubtitle => 'الألوان تتحدّث فورًا وأنت تختار';

  @override
  String get iconSplashCard => 'أيقونة التطبيق وشاشة البداية';

  @override
  String get colorsExtracted => 'تم استخراج الألوان من الشعار';

  @override
  String get noColorsInLogo => 'لم يتم العثور على ألوان مميزة في الشعار';
}
