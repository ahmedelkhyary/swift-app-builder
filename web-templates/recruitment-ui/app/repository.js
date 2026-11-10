/*
 * Mock data, pricing and discount rules of the prototype.
 * Port of packages/recruitment_ui/lib/src/demo/repository.dart. Nothing here
 * is production data or pricing; no network call, SMS or payment is made.
 */
(function (global) {
  "use strict";
  const R = (global.RuiApp = global.RuiApp || {});

  /** A bilingual text (models.dart `L`). */
  const L = (ar, en) => ({ ar, en: en === undefined ? ar : en });
  R.L = L;

  const MODULES = ["individuals", "hourly", "mediation"];
  R.MODULES = MODULES;

  // ---- Pricing (PricingRules) -------------------------------------------------

  const Pricing = {
    hourlyRate: 35,
    vatPercent: 15,
    nationalityFactor: (id) => ({ ph: 1.2, in: 1.05, id: 1.1, et: 0.95, ke: 1.0, lk: 1.08 })[id] ?? 1.0,
    professionFactor: (id) => ({ cook: 1.15, driver: 1.1, caregiver: 1.25 })[id] ?? 1.0,
    recruitmentPrice: (p, natId) => Math.round(p.basePrice * Pricing.nationalityFactor(natId)),
    mediationPrice: (p, natId, profId) =>
      Math.round(p.basePrice * Pricing.nationalityFactor(natId) * Pricing.professionFactor(profId)),
    hourlyPrice({ hoursPerVisit, visitsPerWeek, weeks }) {
      const base = hoursPerVisit * visitsPerWeek * weeks * Pricing.hourlyRate;
      const discountPercent = weeks >= 8 ? 10 : weeks >= 4 ? 5 : 0;
      return Math.round((base * (100 - discountPercent)) / 100);
    },
    vat: (amount) => Math.round((amount * Pricing.vatPercent) / 100),
  };
  R.Pricing = Pricing;

  // ---- Discounts (DiscountRules) ----------------------------------------------
  // status: "none" | "applied" | "invalid" | "expired" | "minimumNotMet"

  const Discounts = {
    codes: "DEMO10 (10%), SAVE50 (50 SAR, min 300), EXPIRED20",
    none: () => ({ status: "none", code: "", amount: 0, isApplied: false }),
    apply(rawCode, subtotal) {
      const code = String(rawCode || "").trim().toUpperCase();
      const r = (status, amount = 0) => ({ status, code, amount, isApplied: status === "applied" });
      switch (code) {
        case "DEMO10": return r("applied", Math.round(subtotal * 0.1));
        case "SAVE50": return subtotal < 300 ? r("minimumNotMet") : r("applied", 50);
        case "EXPIRED20": return r("expired");
        default: return r("invalid");
      }
    },
  };
  R.Discounts = Discounts;

  // ---- Phone / contract validation (session.dart) ------------------------------

  R.PhoneRules = {
    dialCodes: ["+966", "+971", "+965", "+973", "+968", "+974"],
    /** null when valid, else "required" | "digits" | "invalid". */
    validate(dial, number) {
      const n = String(number || "").trim();
      if (!n) return "required";
      if (!/^[0-9]+$/.test(n)) return "digits";
      if (dial === "+966") return /^5[0-9]{8}$/.test(n) ? null : "invalid";
      return n.length >= 8 && n.length <= 10 ? null : "invalid";
    },
  };

  R.ContractRules = {
    validNationalId: (v) => /^[12][0-9]{9}$/.test(String(v).trim()),
    validEmail: (v) => /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(String(v).trim()),
    validPhone: (v) => /^\+?[0-9]{8,14}$/.test(String(v).trim()),
    isComplete(c) {
      return c.fullName.trim().length >= 3 &&
        R.ContractRules.validNationalId(c.nationalId) &&
        R.ContractRules.validEmail(c.email) &&
        R.ContractRules.validPhone(c.phone) &&
        c.startDate != null &&
        c.acknowledged;
    },
  };

  R.emptyContract = (phone = "") => ({ fullName: "", nationalId: "", email: "", phone, startDate: null, acknowledged: false });

  // ---- Static data ---------------------------------------------------------------

  const nationalities = [
    { id: "ph", name: L("الفلبين", "Philippines"), flag: "🇵🇭" },
    { id: "in", name: L("الهند", "India"), flag: "🇮🇳" },
    { id: "id", name: L("إندونيسيا", "Indonesia"), flag: "🇮🇩" },
    { id: "et", name: L("إثيوبيا", "Ethiopia"), flag: "🇪🇹" },
    { id: "ke", name: L("كينيا", "Kenya"), flag: "🇰🇪" },
    { id: "lk", name: L("سريلانكا", "Sri Lanka"), flag: "🇱🇰" },
  ];

  const professions = [
    { id: "housemaid", name: L("عاملة منزلية", "Housemaid"), icon: "cleaning_services" },
    { id: "nanny", name: L("مربية أطفال", "Nanny"), icon: "child_care" },
    { id: "cook", name: L("طباخة", "Cook"), icon: "restaurant" },
    { id: "driver", name: L("سائق خاص", "Private driver"), icon: "directions_car" },
    { id: "caregiver", name: L("مرافقة رعاية", "Caregiver"), icon: "favorite" },
  ];

  const NAMES = {
    ph: [L("ماريا سانتوس", "Maria Santos"), L("جوزفين ريس", "Josephine Reyes"), L("ليزا كروز", "Liza Cruz"), L("آنا باوتيستا", "Ana Bautista"), L("روزا ماجنو", "Rosa Magno")],
    in: [L("أنيتا كوماري", "Anita Kumari"), L("ميرا ديفي", "Meera Devi"), L("بريا شارما", "Priya Sharma"), L("سونيتا راو", "Sunita Rao"), L("لاكشمي ناير", "Lakshmi Nair")],
    id: [L("ريتنو واتي", "Ratno Wati"), L("سيتي نور", "Siti Nur"), L("دوي ليستاري", "Dewi Lestari"), L("أوتامي", "Utami"), L("ياني سري", "Yani Sri")],
    et: [L("سلام تسفاي", "Selam Tesfaye"), L("ألم بيكيلي", "Alem Bekele"), L("هيرموني ديسالين", "Hirut Desalegn"), L("ماريتو", "Marito"), L("تيجست", "Tigist")],
    ke: [L("وانجيرو", "Wanjiru"), L("أكينيي", "Akinyi"), L("نيامبورا", "Nyambura"), L("وامبوي", "Wambui"), L("أتيينو", "Atieno")],
    lk: [L("كوماري ب.", "Kumari P."), L("نيلانثي", "Nilanthi"), L("شاميلا", "Shamila"), L("ديبيكا", "Dilrukshi"), L("ساندهيا", "Sandya")],
  };
  const SKILLS = {
    housemaid: [L("تنظيف المنزل", "House cleaning"), L("الكي والغسيل", "Laundry and ironing"), L("ترتيب", "Organizing")],
    nanny: [L("رعاية الأطفال", "Child care"), L("إسعافات أولية", "First aid"), L("مساعدة بالدراسة", "Homework help")],
    cook: [L("مطبخ عربي", "Arabic cuisine"), L("مطبخ عالمي", "International cuisine"), L("تحضير الوجبات", "Meal prep")],
    driver: [L("رخصة سارية", "Valid licence"), L("معرفة بالطرق", "Route knowledge"), L("قيادة آمنة", "Safe driving")],
    caregiver: [L("رعاية كبار السن", "Elder care"), L("مرافقة طبية", "Medical escort"), L("إعطاء الأدوية", "Medication reminders")],
  };
  const LANGUAGES = {
    ph: [L("الإنجليزية", "English"), L("التاغالوغية", "Tagalog")],
    in: [L("الإنجليزية", "English"), L("الهندية", "Hindi")],
    id: [L("الإندونيسية", "Indonesian")],
    et: [L("الأمهرية", "Amharic"), L("الإنجليزية", "English")],
    ke: [L("الإنجليزية", "English"), L("السواحيلية", "Swahili")],
    lk: [L("السنهالية", "Sinhala"), L("الإنجليزية", "English")],
  };
  const PROF_CODES = { housemaid: "HM", nanny: "NY", cook: "CK", driver: "DR", caregiver: "CG" };

  function buildWorkers() {
    const result = [];
    nationalities.forEach((nat, n) => {
      professions.forEach((prof, p) => {
        for (let k = 0; k < 3; k++) {
          result.push({
            id: `w_${nat.id}_${prof.id}_${k}`,
            code: `W-${nat.id.toUpperCase()}-${PROF_CODES[prof.id]}-${k + 1}`,
            name: NAMES[nat.id][(p + k) % 5],
            nationalityId: nat.id,
            professionId: prof.id,
            age: 25 + ((n * 7 + p * 3 + k * 5) % 15),
            years: 1 + ((n + p * 2 + k * 3) % 9),
            rating: 4.0 + ((n + p + k * 2) % 10) / 10,
            skills: SKILLS[prof.id],
            languages: LANGUAGES[nat.id],
            packageIds: new Set(k === 0 ? ["basic", "standard", "premium"] : k === 1 ? ["basic", "standard"] : ["standard", "premium"]),
            bio: L(
              `ملف تجريبي لعاملة من ${nat.name.ar} بخبرة في ${prof.name.ar}.`,
              `Demo profile: a ${prof.name.en.toLowerCase()} from ${nat.name.en}.`,
            ),
          });
        }
      });
    });
    return result;
  }

  /** Matches `L.matches` in models.dart. */
  R.matches = (l, query) => {
    const q = String(query || "").trim().toLowerCase();
    if (!q) return true;
    return l.ar.includes(q) || l.en.toLowerCase().includes(q);
  };

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  /** MockDemoRepository. One instance per mounted app. */
  R.createRepository = function createRepository({ latency = 700 } = {}) {
    let orderCounter = 1000;
    const repo = {
      latency,
      demoOtp: "123456",
      async sendOtp() { await sleep(latency); return true; },
      async verifyOtp(_phone, code) { await sleep(latency); return code === repo.demoOtp; },
      async biometricLogin() { await sleep(latency); return true; },

      banners: [
        { id: "b1", title: L("استقدام بثقة", "Recruit with confidence"), subtitle: L("عاملات مدربات ومعتمدات", "Trained, verified workers"), color: "#1565C0", target: "individuals" },
        { id: "b2", title: L("خدمة بالساعة", "Hourly cleaning"), subtitle: L("خصم 10% بكود DEMO10", "10% off with code DEMO10"), color: "#00897B", target: "hourly" },
        { id: "b3", title: L("خدمة الوساطة", "Mediation service"), subtitle: L("اختر العاملة بالاسم", "Pick your worker by name"), color: "#6A1B9A", target: "mediation" },
      ],
      reviews: [
        { author: L("أم محمد", "Um Mohammed"), rating: 5, text: L("خدمة ممتازة وسريعة، أنصح بها.", "Excellent, fast service. Recommended.") },
        { author: L("خالد العتيبي", "Khaled A."), rating: 4, text: L("الباقات واضحة والأسعار مناسبة.", "Clear packages and fair prices.") },
        { author: L("سارة", "Sara"), rating: 5, text: L("التعاقد سهل والدفع آمن.", "Easy contract and safe payment.") },
      ],
      partners: [
        { name: L("شركاء النجاح", "Success Partners") },
        { name: L("تأمين تجريبي", "Demo Insurance") },
        { name: L("بنك العينة", "Sample Bank") },
        { name: L("نقل المثال", "Example Transport") },
      ],
      contact: {
        phone: "+966 11 000 0000",
        email: "hello@demo.example",
        address: L("الرياض - حي العليا (عنوان تجريبي)", "Riyadh - Al Olaya (demo address)"),
        hours: L("السبت - الخميس، 9 ص - 6 م", "Sat - Thu, 9 AM - 6 PM"),
      },
      userName: L("أحمد", "Ahmed"),
      mainAddressId: null,
      featuredServices: [
        { id: "hourly-maid", module: "hourly", title: L("عاملة بنظام الساعات", "Hourly maid"), icon: "cleaning_services", color: "#2A6F97" },
        { id: "driver", module: "individuals", professionId: "driver", title: L("سائق خاص", "Private driver"), icon: "directions_car", color: "#6A4C93" },
        { id: "nanny", module: "individuals", professionId: "nanny", title: L("مربية أطفال", "Nanny"), icon: "child_care", color: "#C9184A" },
        { id: "housemaid", module: "individuals", professionId: "housemaid", title: L("عاملة منزلية", "Housemaid"), icon: "home_work", color: "#2D6A4F" },
      ],
      initialAddresses: [
        { id: "a1", label: L("المنزل", "Home"), city: L("الرياض", "Riyadh"), district: L("العليا", "Al Olaya"), street: L("شارع التحلية", "Tahlia St"), building: "12", notes: "" },
        { id: "a2", label: L("الفيلا", "Villa"), city: L("جدة", "Jeddah"), district: L("الروضة", "Al Rawdah"), street: L("شارع الأمير سلطان", "Prince Sultan St"), building: "7", notes: "" },
      ],
      cities: [L("الرياض", "Riyadh"), L("جدة", "Jeddah"), L("الدمام", "Dammam")],
      nationalities,
      professions,
      individualsPackages: [
        { id: "basic", name: L("الباقة الأساسية", "Basic"), description: L("استقدام عاملة مع ضمان لمدة 3 أشهر", "Recruitment with a 3-month guarantee"), basePrice: 8000, popular: false, includes: [L("رسوم الاستقدام", "Recruitment fees"), L("ضمان 3 أشهر", "3-month guarantee")] },
        { id: "standard", name: L("الباقة القياسية", "Standard"), description: L("تشمل التأمين الطبي وضمان 6 أشهر", "Includes medical insurance and a 6-month guarantee"), basePrice: 11000, popular: true, includes: [L("رسوم الاستقدام", "Recruitment fees"), L("تأمين طبي", "Medical insurance"), L("ضمان 6 أشهر", "6-month guarantee")] },
        { id: "premium", name: L("الباقة المميزة", "Premium"), description: L("خدمة كاملة مع استبدال مجاني", "Full service with free replacement"), basePrice: 15000, popular: false, includes: [L("رسوم الاستقدام", "Recruitment fees"), L("تأمين طبي", "Medical insurance"), L("ضمان 12 شهراً", "12-month guarantee"), L("استبدال مجاني", "Free replacement")] },
      ],
      mediationPackages: [
        { id: "m_basic", name: L("وساطة أساسية", "Basic mediation"), description: L("مطابقة العاملة وإنهاء الإجراءات", "Worker matching and paperwork"), basePrice: 3000, popular: false, includes: [L("مطابقة العاملة", "Worker matching"), L("متابعة الإجراءات", "Paperwork follow-up")] },
        { id: "m_plus", name: L("وساطة بلس", "Mediation Plus"), description: L("تشمل الفحص الطبي والتدريب", "Includes medical check and training"), basePrice: 4500, popular: true, includes: [L("مطابقة العاملة", "Worker matching"), L("فحص طبي", "Medical check"), L("تدريب أولي", "Initial training")] },
        { id: "m_full", name: L("وساطة شاملة", "Full mediation"), description: L("خدمة كاملة مع متابعة بعد الوصول", "End-to-end with post-arrival follow-up"), basePrice: 6500, popular: false, includes: [L("مطابقة العاملة", "Worker matching"), L("فحص طبي", "Medical check"), L("تدريب أولي", "Initial training"), L("متابعة بعد الوصول", "Post-arrival follow-up")] },
      ],
      hourlyPackages: [
        { id: "h_starter", name: L("باقة البداية", "Starter"), description: L("زيارة أسبوعية لمدة 4 ساعات", "One 4-hour visit per week"), hoursPerVisit: 4, visitsPerWeek: 1, weeks: 4 },
        { id: "h_family", name: L("باقة العائلة", "Family"), description: L("زيارتان أسبوعياً لمدة 4 ساعات", "Two 4-hour visits per week"), hoursPerVisit: 4, visitsPerWeek: 2, weeks: 4 },
        { id: "h_deep", name: L("تنظيف عميق", "Deep clean"), description: L("زيارتان أسبوعياً لمدة 6 ساعات لمدة شهرين", "Two 6-hour visits per week for 8 weeks"), hoursPerVisit: 6, visitsPerWeek: 2, weeks: 8 },
        { id: "h_daily", name: L("يومي", "Daily"), description: L("5 زيارات أسبوعياً لمدة 3 ساعات", "Five 3-hour visits per week"), hoursPerVisit: 3, visitsPerWeek: 5, weeks: 4 },
      ],
      paymentMethods: [
        { id: "card", name: L("بطاقة مدى / ائتمان", "Mada / Credit card"), icon: "credit_card" },
        { id: "wallet", name: L("المحفظة", "Wallet"), icon: "account_balance_wallet" },
        { id: "applepay", name: L("Apple Pay", "Apple Pay"), icon: "phone_iphone" },
        { id: "transfer", name: L("تحويل بنكي", "Bank transfer"), icon: "account_balance" },
      ],
      /** 1 = Monday ... 7 = Sunday; Friday (5) is off. */
      serviceWeekdays: new Set([1, 2, 3, 4, 6, 7]),
      workers: buildWorkers(),
      nationality: (id) => nationalities.find((n) => n.id === id),
      profession: (id) => professions.find((p) => p.id === id),

      async pay({ methodId, amount, simulateFailure }) {
        await sleep(latency);
        if (simulateFailure) return { isSuccess: false, failureReason: L("تم رفض العملية (محاكاة)", "Payment declined (simulated)") };
        if (methodId === "wallet" && amount > 5000) {
          return { isSuccess: false, failureReason: L("رصيد المحفظة غير كافٍ (محاكاة)", "Insufficient wallet balance (simulated)") };
        }
        return { isSuccess: true, failureReason: null };
      },
      nextOrderReference(module) {
        orderCounter++;
        const prefix = { individuals: "IND", hourly: "HRS", mediation: "MED" }[module];
        return `DEMO-${prefix}-${orderCounter}`;
      },
    };
    return repo;
  };
})(window);
