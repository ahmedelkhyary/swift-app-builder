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
  String get fieldAndroidPackage => 'اسم الحزمة لـ Android (Package Name)';

  @override
  String get fieldIosBundleId => 'معرف الحزمة لـ iOS (Bundle ID)';

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
  String get fieldClientEmail => 'البريد الإلكتروني الأساسي';

  @override
  String get fieldClientPhone => 'هاتف الدعم';

  @override
  String get appIdChecking => 'جارٍ التحقق...';

  @override
  String get appIdAvailable => 'معرف التطبيق متاح';

  @override
  String get errRequired => 'هذا الحقل مطلوب';

  @override
  String get errInvalidPackage =>
      'اسم الحزمة يجب أن يحتوي على أحرف إنجليزية صغيرة وأرقام فقط ويبدأ بحرف';

  @override
  String get errInvalidBundleId =>
      'معرف الحزمة يجب أن يحتوي على أحرف إنجليزية وأرقام وشرطة (-) فقط';

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
      'من 3 إلى 30 حرفًا: أحرف إنجليزية صغيرة وأرقام وشرطات، ويبدأ بحرف، مثل khidma-recruitment';

  @override
  String get errAppIdTaken => 'معرف التطبيق مستخدم من قبل، اختر معرفًا آخر';

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
  String get templatePremium => 'بريميوم';

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
  String get summaryValidation => 'تقرير التحقق';

  @override
  String get validationPassed => 'الإعدادات صالحة وفق المخطط';

  @override
  String get validationFailed => 'فشل التحقق من المخطط';

  @override
  String get fixSectionsFirst => 'أكمل الأقسام السابقة لعرض الملخص.';

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
  String get phNameAr => 'مثال: الخدمة للاستقدام';

  @override
  String get phNameEn => 'e.g. Al Khidma Recruitment';

  @override
  String get phPackage => 'myapp';

  @override
  String get helperPackage =>
      'أحرف إنجليزية صغيرة ونقاط فقط، ولا يمكن تغييره بعد النشر.';

  @override
  String get iosSameTitle => 'نفس اسم حزمة Android';

  @override
  String get errNameArRequired =>
      'أدخل اسم التطبيق بالعربية، مثل: الخدمة للاستقدام';

  @override
  String get errNameEnRequired =>
      'أدخل اسم التطبيق بالإنجليزية، مثل: Al Khidma Recruitment';

  @override
  String get errPackageRequired => 'هذا الحقل مطلوب';

  @override
  String get errBundleRequired => 'هذا الحقل مطلوب';

  @override
  String get errClientRequired => 'أدخل اسم العميل أو المكتب';

  @override
  String get errAppIdRequired => 'أدخل معرّف التطبيق، مثل khidma_recruitment';

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
  String get templatePremiumDesc =>
      'الأكثر تطورًا: أسطح زجاجية وتدرجات وحركة سلسة';

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

  @override
  String get fieldSupportEmails => 'بريد الدعم';

  @override
  String get helperSupportEmails =>
      'أضف بريدًا أو أكثر. اضغط Enter أو فاصلة بعد كل بريد.';

  @override
  String get phSupportEmails => 'support@example.com';

  @override
  String get errSupportEmailInvalid => 'صيغة البريد غير صحيحة';

  @override
  String get hintSupportEmailDuplicate => 'هذا البريد مضاف بالفعل';

  @override
  String removeEmailLabel(String email) {
    return 'إزالة $email';
  }

  @override
  String templatesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار $count قالبًا',
      few: 'تم اختيار $count قوالب',
      two: 'تم اختيار قالبين',
      one: 'تم اختيار قالب واحد',
      zero: 'لم يتم اختيار أي قالب',
    );
    return '$_temp0';
  }

  @override
  String get pickAtLeastOneTemplate => 'اختر قالبًا واحدًا على الأقل';

  @override
  String get multipleTemplatesSelectedLabel => 'عدة قوالب قيد المقارنة';

  @override
  String compareTemplates(int count) {
    return 'قارن القوالب ($count)';
  }

  @override
  String get compareHeading => 'قارن واختر قالبك';

  @override
  String get compareSubtitle => 'اختر قالبًا واحدًا لتطبيقك';

  @override
  String get chooseThisTemplate => 'اختيار هذا القالب';

  @override
  String get backToTemplates => 'رجوع للقوالب';

  @override
  String compareIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get comparePrevious => 'القالب السابق';

  @override
  String get compareNext => 'القالب التالي';

  @override
  String get compareScreenLabel => 'الشاشة المعروضة في كل الهواتف';

  @override
  String get templateSimple => 'البسيط';

  @override
  String get templateLuxury => 'فاخر';

  @override
  String get templateSimpleDesc => 'تصميم نظيف وخفيف بمساحات بيضاء وخطوط رفيعة';

  @override
  String get templateLuxuryDesc =>
      'فخامة هادئة بدرجات داكنة ولمسات ذهبية وخطوط أنيقة';

  @override
  String get templateBadgeAdvanced => 'متقدم';

  @override
  String get templatePreviewAction => 'معاينة';

  @override
  String get roleAccent => 'اللون المميز';

  @override
  String get roleBackground => 'الخلفية';

  @override
  String get roleText => 'لون النص';

  @override
  String get roleDescAccent =>
      'الروابط مثل «عرض الكل»، وحالات النجاح، والعناصر المحددة';

  @override
  String get roleDescBackground =>
      'خلفية الشاشات (اختياري، وإلا يُستخدم لون القالب)';

  @override
  String get roleDescText => 'لون النصوص (اختياري، وإلا يُستخدم لون القالب)';

  @override
  String contrastOkAccent(String ratio) {
    return 'الرابط واضح على الخلفية (التباين $ratio:1)';
  }

  @override
  String contrastWarnAccent(String ratio) {
    return 'قد لا يكون الرابط واضحًا على الخلفية (التباين $ratio:1)';
  }

  @override
  String contrastOkText(String ratio) {
    return 'النص مقروء على الخلفية (التباين $ratio:1)';
  }

  @override
  String contrastWarnText(String ratio) {
    return 'قد لا يكون النص مقروءًا على الخلفية (التباين $ratio:1)';
  }

  @override
  String get palettesTitle => 'ألوان جاهزة';

  @override
  String get paletteNavy => 'كحلي';

  @override
  String get paletteTeal => 'أخضر مزرق';

  @override
  String get paletteBurgundy => 'عنابي';

  @override
  String get palettePurple => 'بنفسجي';

  @override
  String get paletteCharcoal => 'فحمي';

  @override
  String get resetColors => 'إعادة إلى ألوان القالب الافتراضية';

  @override
  String get useTemplateDefault => 'استخدام لون القالب الافتراضي';

  @override
  String get assetSourceLabel => 'مصدر الصورة';

  @override
  String get assetSourceFile => 'رفع ملف';

  @override
  String get assetSourceUrl => 'رابط صورة';

  @override
  String get imageUrlPlaceholder => 'https://example.com/logo.png';

  @override
  String get imageUrlLoad => 'تحميل';

  @override
  String get imageUrlChange => 'تغيير';

  @override
  String get imageUrlLoading => 'جارٍ التحقق من الصورة…';

  @override
  String get imageUrlInvalid => 'الرابط غير صالح';

  @override
  String get imageUrlLoadFailed =>
      'تعذّر تحميل الصورة من هذا الرابط. تأكد أن الرابط عام ويشير مباشرة إلى صورة.';

  @override
  String get imageUrlUnsupported =>
      'نوع الصورة غير مدعوم. المسموح: PNG وJPG وJPEG وSVG وWEBP.';

  @override
  String get submitCardTitle => 'إرسال الطلب';

  @override
  String get submitCardDesc =>
      'راجع البيانات أعلاه ثم أرسل الطلب. سيتم تسجيله برقم معرّف التطبيق.';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get submitting => 'جاري الإرسال...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get requestSentTitle => 'تم إرسال طلبك بنجاح';

  @override
  String get requestSentBody =>
      'استلمنا طلبك وسيقوم فريقنا بمراجعته، وسنتواصل معك في أقرب وقت لتأكيد التفاصيل.';

  @override
  String get requestReference => 'رقم الطلب';

  @override
  String get backToStart => 'العودة للبداية';

  @override
  String get submitErrNotConfigured =>
      'لم يتم ربط الإرسال بعد: مفاتيح Firebase غير مضبوطة. تواصل مع مسؤول النظام.';

  @override
  String get submitErrInvalidAppId =>
      'معرّف التطبيق غير صحيح. عدّله في الخطوة الأولى ثم أعد المحاولة.';

  @override
  String get submitErrPermission =>
      'لا توجد صلاحية لإرسال الطلب. تواصل مع مسؤول النظام.';

  @override
  String get submitErrNetwork =>
      'تعذّر الاتصال بالخادم. تحقق من الإنترنت ثم أعد المحاولة. بياناتك محفوظة.';

  @override
  String get submitErrUnknown =>
      'حدث خطأ أثناء إرسال الطلب. أعد المحاولة؛ بياناتك محفوظة.';

  @override
  String get nextStepsTitle => 'الخطوات القادمة';

  @override
  String get stepReceived => 'تم استلام الطلب';

  @override
  String get stepReview => 'مراجعة الطلب من فريقنا';

  @override
  String get stepContact => 'التواصل معك';

  @override
  String get stepContactVia => 'عبر';

  @override
  String get stateDone => 'مكتمل';

  @override
  String get stateInProgress => 'جارٍ الآن';

  @override
  String get stateUpcoming => 'قادم';

  @override
  String get appIdCheckFailed => 'تعذّر التحقق من المعرف، حاول مرة أخرى';

  @override
  String get appIdSuggestions => 'معرفات متاحة مقترحة:';

  @override
  String appIdJustTaken(String appId) {
    return 'تم استخدام معرف التطبيق «$appId» للتو من عميل آخر. بياناتك محفوظة، اختر معرفًا آخر ثم أعد الإرسال.';
  }

  @override
  String get phBundleId => 'myapp';

  @override
  String packagePreview(String value) {
    return 'اسم الحزمة: $value';
  }

  @override
  String get errReservedPackage =>
      'لا يمكن استخدام كلمة محجوزة في Java مثل class أو new أو int أو package';

  @override
  String get errPackageTooLong => 'اسم الحزمة طويل جدًا (الحد الأقصى 100 حرف)';

  @override
  String get imageUrlNotCopyable =>
      'تم تحميل الصورة لكن هذا الموقع لا يسمح بنسخها. ارفع الملف بدلًا من ذلك.';

  @override
  String imageSizeMismatch(String required, String current) {
    return 'أبعاد الصورة غير مناسبة: المطلوب $required والحالية $current';
  }

  @override
  String get requiredLogoSize => '512×512 على الأقل';

  @override
  String get requiredIconSize => '1024×1024 بالضبط';

  @override
  String bundlePreview(String value) {
    return 'معرف الحزمة: $value';
  }

  @override
  String get iosUnderscoreNote =>
      'تم تحويل «_» إلى «-» لأن iOS لا يدعم الشرطة السفلية.';

  @override
  String get errBundleTooLong =>
      'معرف الحزمة طويل جدًا (الحد الأقصى 155 حرفًا)';

  @override
  String get sectionPayments => 'طرق الدفع';

  @override
  String get paymentsSubtitle =>
      'فعّل بوابات الدفع اللي هتظهر في التطبيق، وحدّد البوابة الافتراضية.';

  @override
  String get paymentsEnvTest => 'تجريبي';

  @override
  String get paymentsEnvLive => 'فعلي';

  @override
  String gatewayEnable(String name) {
    return 'تفعيل $name';
  }

  @override
  String get gatewaySetDefault => 'اجعلها الافتراضية';

  @override
  String get gatewayTestConnection => 'اختبار الاتصال';

  @override
  String get gatewayTesting => 'جارٍ الاختبار...';

  @override
  String get gatewayTestOk => 'الاتصال شغّال';

  @override
  String get gatewayTestInvalid => 'البوابة رفضت البيانات دي';

  @override
  String get gatewayTestNotImplemented =>
      'اختبار الاتصال لسه مش متاح للبوابة دي';

  @override
  String get gatewayTestUnreachable =>
      'مقدرناش نوصل لخدمة الاختبار. جرّب تاني.';

  @override
  String get gatewayTestError => 'البوابة رجّعت خطأ';

  @override
  String get gatewayShowSecret => 'إظهار';

  @override
  String get gatewayHideSecret => 'إخفاء';

  @override
  String get paymentsConfigureLater => 'أضبطها لاحقًا';

  @override
  String get paymentsSecretsNote =>
      'المفاتيح السرية بتتخزّن على السيرفر فقط ومش بتتحط جوّه ملف التطبيق.';

  @override
  String get errNoGatewayEnabled =>
      'فعّل بوابة واحدة على الأقل أو اختار أضبطها لاحقًا';

  @override
  String get errGatewayFieldsMissing =>
      'املأ بيانات الاعتماد المطلوبة للبوابات المفعّلة';

  @override
  String get labelPayments => 'طرق الدفع';

  @override
  String get paymentsConfiguredLater => 'أضبطها لاحقًا';

  @override
  String paymentsDefaultSuffix(String name) {
    return '$name (افتراضي)';
  }

  @override
  String get paymentsSecretsNotSaved =>
      'اتبعت طلبك، بس مقدرناش نحفظ مفاتيح الدفع. تواصل مع الدعم عشان نستلمها منك.';

  @override
  String get paymentsChooseTitle => 'اختر بوابات الدفع';

  @override
  String get paymentsChooseDesc => 'اختار كل بوابة عايز التطبيق يقدّمها.';

  @override
  String get paymentsDetailsTitle => 'بيانات الربط';

  @override
  String get paymentsDetailsDesc =>
      'أدخل بيانات البوابات المختارة للبيئة المحددة.';

  @override
  String get paymentsDetailsEmpty => 'اختار بوابة من فوق عشان تدخل بياناتها.';

  @override
  String get gatewayStatusComplete => 'مكتمل';

  @override
  String gatewayStatusMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ناقص $count حقول',
      two: 'ناقص حقلين',
      one: 'ناقص حقل واحد',
    );
    return '$_temp0';
  }

  @override
  String get gatewayIsDefault => 'افتراضية';

  @override
  String get regionEg => 'مصر';

  @override
  String get regionSa => 'السعودية';

  @override
  String get regionGulf => 'الخليج';

  @override
  String get countryAe => 'الإمارات';

  @override
  String get countryKw => 'الكويت';

  @override
  String get countryQa => 'قطر';

  @override
  String get countryBh => 'البحرين';

  @override
  String get countryOm => 'عُمان';
}
