/*
 * All state of one preview session, shared by every template.
 * Port of packages/recruitment_ui/lib/src/demo/session.dart: same fields,
 * same rules, same names (camelCase), so screens read like their Dart twins.
 *
 * Screens call the setters; every setter calls notify(), which re-renders the
 * visible screen. `session.nav` is the app's navigator (set by RuiApp.mount).
 */
(function (global) {
  "use strict";
  const R = (global.RuiApp = global.RuiApp || {});
  const { L, Pricing, Discounts } = R;

  /** Route names (DemoRoutes). */
  const Routes = {
    login: "/login",
    otp: "/otp",
    main: "/main",
    address: "/address", // arg: module
    indPackages: "/ind/packages",
    workers: "/workers", // arg: module
    worker: "/worker", // arg: module
    contract: "/contract", // arg: module
    payment: "/payment", // arg: module
    success: "/success", // arg: module
    hrPackages: "/hr/packages",
    hrDetails: "/hr/details",
    medCriteria: "/med/criteria",
    medPackages: "/med/packages",
    medMethod: "/med/method",
    medSearch: "/med/search",
    featured: "/featured",
  };
  R.Routes = Routes;

  const WEEKDAY_NAMES = {
    1: L("الإثنين", "Mon"), 2: L("الثلاثاء", "Tue"), 3: L("الأربعاء", "Wed"), 4: L("الخميس", "Thu"),
    5: L("الجمعة", "Fri"), 6: L("السبت", "Sat"), 7: L("الأحد", "Sun"),
  };
  R.weekdayNames = WEEKDAY_NAMES;

  /** `YYYY-MM-DD` (session.dart `_fmt`). */
  const fmtDate = (d) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  R.fmtDate = fmtDate;

  /** 1 = Monday ... 7 = Sunday (Dart DateTime.weekday). */
  R.isoWeekday = (d) => ((d.getDay() + 6) % 7) + 1;

  R.oneLine = (a, lang) => `${a.city[lang]} - ${a.district[lang]}, ${a.street[lang]}, ${a.building}`;

  R.createSession = function createSession({ repository, enabledModules } = {}) {
    const repo = repository || R.createRepository();
    const listeners = new Set();

    const s = {
      repo,
      nav: null,
      enabledModules: new Set(enabledModules || R.MODULES),

      subscribe(fn) { listeners.add(fn); return () => listeners.delete(fn); },
      notify() { listeners.forEach((fn) => fn()); },

      _init() {
        Object.assign(s, {
          dialCode: "+966",
          phone: "",
          isAuthenticated: false,
          mainTab: 0,
          addresses: repo.initialAddresses.slice(),
          selectedAddressId: null,
          indNationalityId: null,
          indPackageId: null,
          indWorkerId: null,
          indProfessionFilter: null,
          indContract: R.emptyContract(),
          hourlyCustom: false,
          hourlyPackageId: null,
          customHourly: { hoursPerVisit: 4, visitsPerWeek: 2, weeks: 4 },
          hourlyStartDate: null,
          hourlyDays: new Set(),
          appliedDiscountCode: "",
          medProfessionId: null,
          medNationalityId: null,
          medPackageId: null,
          medWorkerId: null,
          medQuery: "",
          medContract: R.emptyContract(),
          viewWorkerId: null,
          paymentMethodId: "card",
          simulateFailure: false,
          orders: [],
          lastOrder: null,
        });
      },

      /** Back to the initial state, on the login screen. */
      reset() {
        s._init();
        s.notify();
        s.nav && s.nav.replaceAll(Routes.login);
      },

      setEnabledModules(modules) {
        s.enabledModules = new Set(modules);
        s.notify();
      },

      // ---- auth ---------------------------------------------------------------
      setPhone(dial, number) { s.dialCode = dial; s.phone = number; s.notify(); },
      sendOtp: () => repo.sendOtp(s.dialCode, s.phone),
      async verifyOtp(code) {
        const ok = await repo.verifyOtp(s.phone, code);
        if (ok) s._signIn();
        return ok;
      },
      async biometricLogin() {
        const ok = await repo.biometricLogin();
        if (ok) s._signIn();
        return ok;
      },
      signInDemo() { s._signIn(); },
      _signIn() {
        s.isAuthenticated = true;
        if (!s.phone) s.phone = "500000000";
        s.indContract = { ...s.indContract, phone: `${s.dialCode}${s.phone}` };
        s.medContract = { ...s.medContract, phone: `${s.dialCode}${s.phone}` };
        s.notify();
      },
      logout() {
        s.isAuthenticated = false;
        s.notify();
        s.nav && s.nav.replaceAll(Routes.login);
      },
      setMainTab(i) { s.mainTab = i; s.notify(); },

      // ---- navigation helpers -------------------------------------------------
      entryRoute: (m) => (m === "mediation" ? Routes.medCriteria : Routes.address),
      openModule(m) { s.nav && s.nav.push(s.entryRoute(m), m); },
      /** "login" | "home" | "individuals" | "hourly" | "mediation" */
      jumpTo(entry) {
        const nav = s.nav;
        if (!nav) return;
        if (entry === "login") {
          s.isAuthenticated = false;
          s.notify();
          nav.replaceAll(Routes.login);
          return;
        }
        if (!s.isAuthenticated) s._signIn();
        s.mainTab = 0;
        nav.replaceAll(Routes.main);
        if (entry !== "home") s.openModule(entry);
      },

      // ---- addresses ----------------------------------------------------------
      get mainAddress() {
        return s.addresses.find((a) => a.id === repo.mainAddressId) || s.addresses[0] || null;
      },
      setMainAddress(id) { repo.mainAddressId = id; s.notify(); },
      get featuredServices() { return repo.featuredServices.filter((f) => s.enabledModules.has(f.module)); },
      /** Opens a featured service on its packages screen with `address`. */
      startFeatured(f, address) {
        s.selectedAddressId = address.id;
        if (f.module === "individuals") s.indProfessionFilter = f.professionId || null;
        s.notify();
        s.nav && s.nav.push(f.module === "hourly" ? Routes.hrPackages : Routes.indPackages, f.module);
      },
      get selectedAddress() { return s.addresses.find((a) => a.id === s.selectedAddressId) || null; },
      selectAddress(id) { s.selectedAddressId = id; s.notify(); },
      addAddress(a) { s.addresses = [...s.addresses, a]; s.selectedAddressId = a.id; s.notify(); },

      // ---- individuals --------------------------------------------------------
      get indPackage() { return repo.individualsPackages.find((p) => p.id === s.indPackageId) || null; },
      setIndNationality(id) {
        if (id === s.indNationalityId) return;
        s.indNationalityId = id;
        s._dropIndWorkerIfInvalid();
        s.notify();
      },
      setIndPackage(id) {
        if (id === s.indPackageId) return;
        s.indPackageId = id;
        s._dropIndWorkerIfInvalid();
        s.notify();
      },
      setIndProfessionFilter(id) { s.indProfessionFilter = id; s.notify(); },
      _dropIndWorkerIfInvalid() {
        if (s.indWorkerId != null && !s.individualsWorkers({ ignoreProfession: true }).some((w) => w.id === s.indWorkerId)) {
          s.indWorkerId = null;
        }
      },
      individualsWorkers({ ignoreProfession = false } = {}) {
        return repo.workers.filter((w) => {
          if (w.nationalityId !== s.indNationalityId) return false;
          if (s.indPackageId != null && !w.packageIds.has(s.indPackageId)) return false;
          if (!ignoreProfession && s.indProfessionFilter != null && w.professionId !== s.indProfessionFilter) return false;
          return true;
        });
      },
      selectIndWorker(id) { s.indWorkerId = id; s.notify(); },

      // ---- mediation ----------------------------------------------------------
      get medPackage() { return repo.mediationPackages.find((p) => p.id === s.medPackageId) || null; },
      setMedCriteria({ professionId, nationalityId } = {}) {
        if (professionId != null) s.medProfessionId = professionId;
        if (nationalityId != null) s.medNationalityId = nationalityId;
        if (s.medWorkerId != null && !s.mediationWorkers().some((w) => w.id === s.medWorkerId)) s.medWorkerId = null;
        s.notify();
      },
      setMedPackage(id) { s.medPackageId = id; s.notify(); },
      setMedQuery(q) { s.medQuery = q; s.notify(); },
      mediationWorkers({ query } = {}) {
        return repo.workers.filter((w) => {
          if (w.professionId !== s.medProfessionId) return false;
          if (w.nationalityId !== s.medNationalityId) return false;
          if (query != null && query.trim() !== "") {
            return R.matches(w.name, query) || w.code.toLowerCase().includes(query.trim().toLowerCase());
          }
          return true;
        });
      },
      selectMedWorker(id) { s.medWorkerId = id; s.notify(); },

      // ---- workers --------------------------------------------------------------
      workerById: (id) => (id == null ? null : repo.workers.find((w) => w.id === id) || null),
      viewWorker(id) { s.viewWorkerId = id; s.notify(); },

      // ---- contracts ------------------------------------------------------------
      contractFor: (m) => (m === "mediation" ? s.medContract : s.indContract),
      setContract(m, c) {
        if (m === "mediation") s.medContract = c; else s.indContract = c;
        s.notify();
      },

      // ---- hourly ---------------------------------------------------------------
      get hourlyPackage() { return repo.hourlyPackages.find((p) => p.id === s.hourlyPackageId) || null; },
      get hourlyHasSelection() { return s.hourlyCustom || s.hourlyPackage != null; },
      get hoursPerVisit() { return s.hourlyCustom ? s.customHourly.hoursPerVisit : s.hourlyPackage?.hoursPerVisit ?? 0; },
      get visitsPerWeek() { return s.hourlyCustom ? s.customHourly.visitsPerWeek : s.hourlyPackage?.visitsPerWeek ?? 0; },
      get weeks() { return s.hourlyCustom ? s.customHourly.weeks : s.hourlyPackage?.weeks ?? 0; },
      get totalVisits() { return s.visitsPerWeek * s.weeks; },
      get totalHours() { return s.hoursPerVisit * s.totalVisits; },
      priceFor: (hours, perWeek, weeks) => Pricing.hourlyPrice({ hoursPerVisit: hours, visitsPerWeek: perWeek, weeks }),
      get hourlySubtotal() {
        return s.hourlyHasSelection
          ? Pricing.hourlyPrice({ hoursPerVisit: s.hoursPerVisit, visitsPerWeek: s.visitsPerWeek, weeks: s.weeks })
          : 0;
      },
      selectHourlyPackage(id) { s.hourlyCustom = false; s.hourlyPackageId = id; s._trimDays(); s.notify(); },
      useFixedHourly() { s.hourlyCustom = false; s._trimDays(); s.notify(); },
      useCustomHourly() { s.hourlyCustom = true; s._trimDays(); s.notify(); },
      /** `c` is { hoursPerVisit, visitsPerWeek, weeks } (CustomHourly). */
      setCustomHourly(c) { s.customHourly = { ...c }; s._trimDays(); s.notify(); },
      _trimDays() { if (s.hourlyDays.size > s.visitsPerWeek) s.hourlyDays = new Set(); },
      setHourlyStart(d) { s.hourlyStartDate = d; s.notify(); },
      toggleHourlyDay(weekday) {
        const next = new Set(s.hourlyDays);
        if (!next.delete(weekday)) {
          if (next.size >= s.visitsPerWeek) return;
          next.add(weekday);
        }
        s.hourlyDays = next;
        s.notify();
      },
      applyDiscount(code) {
        const result = Discounts.apply(code, s.hourlySubtotal);
        s.appliedDiscountCode = result.isApplied ? result.code : "";
        s.notify();
        return result;
      },
      clearDiscount() { s.appliedDiscountCode = ""; s.notify(); },
      get hourlyDiscount() {
        return s.appliedDiscountCode ? Discounts.apply(s.appliedDiscountCode, s.hourlySubtotal) : Discounts.none();
      },
      get hourlyDetailsComplete() {
        return s.hourlyHasSelection && s.hourlyStartDate != null && s.hourlyDays.size === s.visitsPerWeek && s.selectedAddress != null;
      },

      // ---- payment & orders -----------------------------------------------------
      setPaymentMethod(id) { s.paymentMethodId = id; s.notify(); },
      setSimulateFailure(v) { s.simulateFailure = v; s.notify(); },

      /**
       * Totals for the payment screen: { module, title: L, details: [{label: L,
       * value: L}], prices: [{label: L, amount}], total }.
       */
      summary(module) {
        const dash = L("-");
        const addrLine = (a) => (a ? L(R.oneLine(a, "ar"), R.oneLine(a, "en")) : dash);
        const vatLabel = L("ضريبة القيمة المضافة 15%", "VAT 15%");
        if (module === "individuals") {
          const pkg = s.indPackage;
          const nat = s.indNationalityId ? repo.nationality(s.indNationalityId) : null;
          const worker = s.workerById(s.indWorkerId);
          const price = !pkg || !s.indNationalityId ? 0 : Pricing.recruitmentPrice(pkg, s.indNationalityId);
          const base = pkg?.basePrice ?? 0;
          const vat = Pricing.vat(price);
          return {
            module,
            title: L("خدمات الأفراد", "Individuals service"),
            details: [
              { label: L("الباقة", "Package"), value: pkg?.name ?? dash },
              { label: L("الجنسية", "Nationality"), value: nat?.name ?? dash },
              { label: L("العاملة", "Worker"), value: worker?.name ?? dash },
              { label: L("العنوان", "Address"), value: addrLine(s.selectedAddress) },
            ],
            prices: [
              { label: L("سعر الباقة", "Package price"), amount: base },
              { label: L("رسوم الجنسية", "Nationality fee"), amount: price - base },
              { label: vatLabel, amount: vat },
            ],
            total: price + vat,
          };
        }
        if (module === "hourly") {
          const subtotal = s.hourlySubtotal;
          const disc = s.hourlyDiscount;
          const discount = disc.isApplied ? disc.amount : 0;
          const vat = Pricing.vat(subtotal - discount);
          const start = s.hourlyStartDate;
          const days = [...s.hourlyDays].sort((a, b) => a - b).map((d) => WEEKDAY_NAMES[d]);
          const startText = start ? fmtDate(start) : "-";
          return {
            module,
            title: L("خدمة بالساعة", "Hourly service"),
            details: [
              { label: L("الباقة", "Package"), value: s.hourlyCustom ? L("باقة مخصصة", "Custom package") : s.hourlyPackage?.name ?? dash },
              { label: L("المدة", "Duration"), value: L(`${s.hoursPerVisit} ساعات × ${s.totalVisits} زيارة`, `${s.hoursPerVisit} h × ${s.totalVisits} visits`) },
              { label: L("الجدول", "Schedule"), value: L(`${startText} · ${days.map((d) => d.ar).join("، ")}`, `${startText} · ${days.map((d) => d.en).join(", ")}`) },
              { label: L("العنوان", "Address"), value: addrLine(s.selectedAddress) },
            ],
            prices: [
              { label: L("سعر الخدمة", "Service price"), amount: subtotal },
              ...(discount > 0 ? [{ label: L(`خصم (${disc.code})`, `Discount (${disc.code})`), amount: -discount }] : []),
              { label: vatLabel, amount: vat },
            ],
            total: subtotal - discount + vat,
          };
        }
        const pkg = s.medPackage;
        const nat = s.medNationalityId ? repo.nationality(s.medNationalityId) : null;
        const prof = s.medProfessionId ? repo.profession(s.medProfessionId) : null;
        const worker = s.workerById(s.medWorkerId);
        const price = !pkg || !s.medNationalityId || !s.medProfessionId
          ? 0
          : Pricing.mediationPrice(pkg, s.medNationalityId, s.medProfessionId);
        const vat = Pricing.vat(price);
        return {
          module,
          title: L("خدمة الوساطة", "Mediation service"),
          details: [
            { label: L("الباقة", "Package"), value: pkg?.name ?? dash },
            { label: L("المهنة", "Profession"), value: prof?.name ?? dash },
            { label: L("الجنسية", "Nationality"), value: nat?.name ?? dash },
            { label: L("العاملة", "Worker"), value: worker?.name ?? dash },
          ],
          prices: [
            { label: L("رسوم الوساطة", "Mediation fee"), amount: price },
            { label: vatLabel, amount: vat },
          ],
          total: price + vat,
        };
      },

      /** Simulated payment; an order is created only on success. */
      async pay(module) {
        const summary = s.summary(module);
        const result = await repo.pay({ methodId: s.paymentMethodId, amount: summary.total, simulateFailure: s.simulateFailure });
        if (result.isSuccess) {
          s.lastOrder = { reference: repo.nextOrderReference(module), summary, createdAt: new Date() };
          s.orders = [s.lastOrder, ...s.orders];
          s.notify();
        }
        return result;
      },

      /** Clears a finished flow; addresses and other modules are kept. */
      completeFlow(module) {
        if (module === "individuals") {
          Object.assign(s, { indNationalityId: null, indPackageId: null, indWorkerId: null, indProfessionFilter: null, indContract: R.emptyContract(s.indContract.phone) });
        } else if (module === "hourly") {
          Object.assign(s, { hourlyCustom: false, hourlyPackageId: null, customHourly: { hoursPerVisit: 4, visitsPerWeek: 2, weeks: 4 }, hourlyStartDate: null, hourlyDays: new Set(), appliedDiscountCode: "" });
        } else {
          Object.assign(s, { medProfessionId: null, medNationalityId: null, medPackageId: null, medWorkerId: null, medQuery: "", medContract: R.emptyContract(s.medContract.phone) });
        }
        s.mainTab = 0;
        s.notify();
      },
    };
    s._init();
    return s;
  };
})(window);
