/*
 * Address, Individuals packages, workers (list, search, details) and contract.
 * Port of ui/address_screen.dart, address_sheet.dart, individuals_screens.dart,
 * worker_screens.dart and contract_screen.dart. The shared pieces (address
 * sheets, nationality select, package card, worker card) live on RuiApp.widgets.
 */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { L } = R;
  const { h, icon, page, card, button, selectTile, notice, infoRow, sectionTitle, emptyState, input, select, chip, checkbox } = R.ui;
  const W = (R.widgets = R.widgets || {});

  // ---- Address sheets (address_sheet.dart) ---------------------------------------------

  /** New-address form in a sheet. Resolves the saved address, or undefined. */
  W.showAddressForm = function showAddressForm(ctx, { offerMain = false, mainByDefault = false } = {}) {
    const { x, session } = ctx;
    return ctx.sheet((close) => {
      const req = x("هذا الحقل مطلوب", "This field is required");
      const f = { label: "", city: "", district: "", street: "", building: "", notes: "" };
      let makeMain = mainByDefault;
      const errors = {};
      const box = h("div", { class: "rui-stack" });
      const draw = () => {
        const field = (key, label, extra = {}) => input({ key: `addr-${key}`, label, value: f[key], error: errors[key], onInput: (v) => { f[key] = v; }, ...extra });
        box.replaceChildren(
          h("h2", { class: "rui-subtitle" }, x("عنوان جديد", "New address")),
          field("label", x("اسم العنوان (مثل: المنزل)", "Label (e.g. Home)")),
          select({
            key: "addr-city", label: x("المدينة", "City"), value: f.city, placeholder: x("اختر المدينة", "Select a city"),
            options: ctx.repo.cities.map((c, i) => ({ value: String(i), label: ctx.t(c) })),
            onChange: (v) => { f.city = v; },
          }),
          errors.city ? h("span", { class: "rui-field__error" }, errors.city) : null,
          field("district", x("الحي", "District")),
          field("street", x("الشارع", "Street")),
          field("building", x("رقم المبنى", "Building no.")),
          field("notes", x("ملاحظات (اختياري)", "Notes (optional)")),
          offerMain ? checkbox({ key: "addr-main", checked: makeMain, label: x("تعيينه كعنواني الرئيسي", "Set as my main address"), onChange: (v) => { makeMain = v; } }) : null,
          button({ key: "addr-save", label: x("حفظ العنوان", "Save address"), icon: "save", onClick: save }));
      };
      function save() {
        for (const k of ["label", "district", "street", "building"]) errors[k] = f[k].trim() ? null : req;
        errors.city = f.city === "" ? x("اختر المدينة", "Select a city") : null;
        if (Object.values(errors).some(Boolean)) return draw();
        const same = (v) => L(v.trim());
        const address = {
          id: `a${Date.now()}`, label: same(f.label), city: ctx.repo.cities[+f.city],
          district: same(f.district), street: same(f.street), building: f.building.trim(), notes: f.notes.trim(),
        };
        session.addAddress(address);
        if (offerMain && makeMain) session.setMainAddress(address.id);
        close(address);
      }
      draw();
      return box;
    });
  };

  /** Pick the main address or the order address (target: "main" | "order"). */
  W.showAddressSheet = function showAddressSheet(ctx, { target }) {
    const { x, session } = ctx;
    const main = target === "main";
    return ctx.sheet((close) => {
      const selectedId = main ? session.mainAddress?.id : session.selectedAddressId;
      const pick = (a) => { if (main) session.setMainAddress(a.id); else session.selectAddress(a.id); close(a); };
      return h("div", { class: "rui-stack" },
        h("h2", { class: "rui-subtitle" }, main ? x("عنواني الرئيسي", "My main address") : x("عنوان الطلب", "Order address")),
        session.addresses.length === 0 ? emptyState({ icon: "location_off", title: x("لا توجد عناوين بعد", "No saved addresses yet") }) : null,
        session.addresses.map((a) => selectTile({
          key: `sheet-address-${a.id}`, selected: a.id === selectedId, onTap: () => pick(a),
          leading: icon("location_on"), title: ctx.t(a.label), subtitle: R.oneLine(a, ctx.lang),
        })),
        button({
          key: "sheet-address-add", label: x("إضافة عنوان جديد", "Add a new address"), icon: "add_location_alt", secondary: true,
          // Resolves with the new address once the form is saved (Dart pops `added`).
          onClick: () => close(W.showAddressForm(ctx, { offerMain: main, mainByDefault: main })),
        }));
    });
  };

  // ---- Address step (address_screen.dart) ------------------------------------------------

  R.screens[R.Routes.address] = function addressScreen(ctx) {
    const { x, session, state: st } = ctx;
    const module = ctx.args || "individuals";
    const next = () => {
      if (!session.selectedAddress) { st.showError = true; return ctx.refresh(); }
      ctx.nav.push(module === "hourly" ? R.Routes.hrPackages : R.Routes.indPackages, module);
    };
    return page(ctx, {
      title: x("اختر العنوان", "Choose address"),
      subtitle: x("الخطوة 1", "Step 1"),
      bottom: button({ key: "address-continue", label: x("متابعة", "Continue"), onClick: next }),
      body: [
        sectionTitle(x("عناويني المحفوظة", "Saved addresses")),
        session.addresses.length === 0 ? h("p", null, x("لا توجد عناوين بعد", "No saved addresses yet")) : null,
        session.addresses.map((a) => selectTile({
          key: `address-${a.id}`, selected: a.id === session.selectedAddressId,
          onTap: () => { st.showError = false; session.selectAddress(a.id); },
          leading: icon("location_on"), title: ctx.t(a.label), subtitle: R.oneLine(a, ctx.lang),
        })),
        st.showError ? notice(x("اختر عنواناً للمتابعة", "Select an address to continue"), { kind: "error" }) : null,
        h("div", { style: { height: "8px" } }),
        button({ key: "address-add", label: x("إضافة عنوان جديد", "Add a new address"), icon: "add_location_alt", secondary: true, onClick: () => W.showAddressForm(ctx) }),
      ],
    });
  };

  // ---- Shared: nationality select + package card (individuals_screens.dart) -------------

  W.nationalitySelect = (ctx, { value, onChange, error }) => h("div", { class: "rui-stack", style: { gap: "4px" } },
    select({
      key: "nationality-select", label: ctx.x("الجنسية", "Nationality"), value: value || "",
      placeholder: ctx.x("اختر الجنسية", "Select a nationality"),
      options: ctx.repo.nationalities.map((n) => ({ value: n.id, label: `${n.flag}  ${ctx.t(n.name)}` })),
      onChange,
    }),
    error ? h("span", { class: "rui-field__error" }, error) : null);

  W.packageCard = (ctx, { pkg, price, selected, onTap, key }) => selectTile({
    key, selected, onTap,
    title: ctx.t(pkg.name), subtitle: ctx.t(pkg.description),
    trailing: h("div", { style: { textAlign: "end", display: "grid", justifyItems: "end" } },
      pkg.popular ? h("span", { class: "rui-badge", style: { marginBottom: "4px" } }, ctx.x("الأكثر طلباً", "Popular")) : null,
      h("span", { class: "rui-price rui-title", style: { fontFamily: "var(--rui-font)" } }, String(price)),
      h("span", { class: "rui-body-sm" }, ctx.x("ر.س", "SAR"))),
    child: h("div", { class: "rui-chips", style: { marginTop: "8px", gap: "6px" } },
      pkg.includes.map((inc) => h("span", { class: "rui-tag" }, icon("check", { size: 14 }), ctx.t(inc)))),
  });

  R.screens[R.Routes.indPackages] = function indPackages(ctx) {
    const { x, session, state: st } = ctx;
    const natError = st.submitted && session.indNationalityId == null ? x("اختر الجنسية", "Select a nationality") : null;
    const pkgError = st.submitted && session.indPackageId == null ? x("اختر باقة", "Select a package") : null;
    const next = () => {
      if (session.indNationalityId == null || session.indPackageId == null) { st.submitted = true; return ctx.refresh(); }
      ctx.nav.push(R.Routes.workers, "individuals");
    };
    return page(ctx, {
      title: x("الباقات والجنسية", "Packages & nationality"),
      subtitle: x("الخطوة 2", "Step 2"),
      bottom: button({ key: "ind-packages-continue", label: x("عرض العاملات", "View workers"), onClick: next }),
      body: [
        W.nationalitySelect(ctx, { value: session.indNationalityId, error: natError, onChange: (v) => session.setIndNationality(v) }),
        sectionTitle(x("الباقات المتاحة", "Available packages")),
        ctx.repo.individualsPackages.map((p) => W.packageCard(ctx, {
          key: `ind-package-${p.id}`, pkg: p, price: R.Pricing.recruitmentPrice(p, session.indNationalityId || ""),
          selected: p.id === session.indPackageId, onTap: () => session.setIndPackage(p.id),
        })),
        session.indNationalityId == null ? h("p", { class: "rui-body-sm" }, x("اختر الجنسية لعرض الأسعار النهائية.", "Select a nationality to see final prices.")) : null,
        pkgError ? notice(pkgError, { kind: "error" }) : null,
      ],
    });
  };

  // ---- Workers (worker_screens.dart) ------------------------------------------------------

  const selectedWorkerId = (s, m) => (m === "mediation" ? s.medWorkerId : s.indWorkerId);
  const selectWorker = (s, m, id) => (m === "mediation" ? s.selectMedWorker(id) : s.selectIndWorker(id));
  const avatar = (ic, size) => h("span", { class: "rui-avatar", style: { width: `${size}px`, height: `${size}px` } }, icon(ic, { size: size * 0.45 }));

  W.workerCard = function workerCard(ctx, worker, module) {
    const { x, session } = ctx;
    const selected = selectedWorkerId(session, module) === worker.id;
    const nat = ctx.repo.nationality(worker.nationalityId);
    const prof = ctx.repo.profession(worker.professionId);
    return selectTile({
      key: `worker-${worker.id}`, selected, onTap: () => selectWorker(session, module, worker.id),
      leading: avatar(prof.icon, 52),
      title: ctx.t(worker.name),
      subtitle: `${worker.code} · ${ctx.t(prof.name)}`,
      trailing: h("div", { style: { display: "grid", justifyItems: "center", gap: "2px" } },
        h("span", { class: "rui-row rui-body-sm", style: { gap: "2px" } }, icon("star", { size: 16, fill: true, color: "var(--rui-secondary)" }), String(worker.rating)),
        icon(selected ? "check_circle" : "radio_button_unchecked", { fill: selected, cls: selected ? "rui-select-tile__mark is-on" : "rui-select-tile__mark" })),
      child: h("div", { style: { marginTop: "8px" } },
        h("div", { class: "rui-body-sm" }, `${nat.flag} ${ctx.t(nat.name)} · ${worker.years} ${x("سنوات خبرة", "yrs experience")} · ${worker.age} ${x("سنة", "y/o")}`),
        h("div", { class: "rui-row", style: { marginTop: "8px" } },
          h("div", { class: "rui-grow" }, button({
            key: `worker-details-${worker.id}`, label: x("عرض التفاصيل", "View details"), secondary: true, cls: "rui-btn--small",
            onClick: (e) => { e.stopPropagation(); session.viewWorker(worker.id); ctx.nav.push(R.Routes.worker, module); },
          })),
          h("div", { class: "rui-grow" }, button({
            key: `worker-select-${worker.id}`, label: selected ? x("تم الاختيار", "Selected") : x("اختيار", "Select"), cls: "rui-btn--small",
            onClick: (e) => { e.stopPropagation(); selectWorker(session, module, worker.id); },
          })))),
    });
  };

  function continueToWorker(ctx, module) {
    const id = selectedWorkerId(ctx.session, module);
    if (id == null) { ctx.state.showError = true; return ctx.refresh(); }
    ctx.session.viewWorker(id);
    ctx.nav.push(R.Routes.worker, module);
  }

  R.screens[R.Routes.workers] = function workersScreen(ctx) {
    const { x, session, state: st } = ctx;
    const module = ctx.args || "individuals";
    const isInd = module === "individuals";
    const workers = isInd ? session.individualsWorkers() : session.mediationWorkers();
    return page(ctx, {
      title: x("اختر العاملة", "Choose a worker"),
      subtitle: isInd ? x("الخطوة 3", "Step 3") : x("تصفح العاملات", "Browse workers"),
      bottom: button({ key: "workers-continue", label: x("متابعة", "Continue"), onClick: () => continueToWorker(ctx, module) }),
      body: [
        isInd ? h("div", { class: "rui-chips rui-chips--scroll", "data-scroll": "filters" },
          chip({ key: "filter-all", label: x("الكل", "All"), selected: session.indProfessionFilter == null, onTap: () => session.setIndProfessionFilter(null) }),
          ctx.repo.professions.map((p) => chip({ key: `filter-${p.id}`, label: ctx.t(p.name), selected: session.indProfessionFilter === p.id, onTap: () => session.setIndProfessionFilter(p.id) }))) : null,
        sectionTitle(x(`${workers.length} عاملة متاحة`, `${workers.length} workers available`)),
        workers.length === 0 ? notice(x("لا توجد عاملات مطابقة. غيّر الفلتر أو الباقة.", "No workers match. Change the filter or package."), { kind: "warning" }) : null,
        workers.map((w) => W.workerCard(ctx, w, module)),
        st.showError ? notice(x("اختر عاملة للمتابعة", "Select a worker to continue"), { kind: "error" }) : null,
      ],
    });
  };

  R.screens[R.Routes.medSearch] = function workerSearch(ctx) {
    const { x, session, state: st } = ctx;
    const query = session.medQuery.trim();
    const results = session.mediationWorkers({ query });
    const total = session.mediationWorkers().length;
    return page(ctx, {
      title: x("البحث بالاسم", "Search by name"),
      subtitle: x("الوساطة", "Mediation"),
      bottom: button({ key: "search-continue", label: x("متابعة", "Continue"), onClick: () => continueToWorker(ctx, "mediation") }),
      body: [
        h("div", { class: "rui-search" },
          input({ key: "worker-search", label: x("اسم العاملة", "Worker name"), value: session.medQuery, prefixIcon: "search", onInput: (v) => { st.showError = false; session.setMedQuery(v); } }),
          query ? h("button", { class: "rui-icon-btn rui-search__clear", type: "button", "aria-label": x("مسح", "Clear"), onClick: () => session.setMedQuery("") }, icon("close")) : null),
        h("p", { class: "rui-body-sm", style: { margin: "4px 0 8px" } }, x(`البحث ضمن ${total} عاملة تطابق مهنتك وجنسيتك.`, `Searching among ${total} workers matching your profession and nationality.`)),
        results.length === 0 ? notice(x(`لا توجد نتائج لـ "${query}". جرّب اسماً آخر.`, `No results for "${query}". Try another name.`), { kind: "warning", icon: "search_off" }) : null,
        results.map((w) => W.workerCard(ctx, w, "mediation")),
        st.showError ? notice(x("اختر عاملة للمتابعة", "Select a worker to continue"), { kind: "error" }) : null,
      ],
    });
  };

  R.screens[R.Routes.worker] = function workerDetails(ctx) {
    const { x, session, state: st } = ctx;
    const module = ctx.args || "individuals";
    const worker = session.workerById(session.viewWorkerId);
    if (!worker) return page(ctx, { title: x("التفاصيل", "Details"), body: h("p", null, x("لم يتم اختيار عاملة", "No worker selected")) });
    const nat = ctx.repo.nationality(worker.nationalityId);
    const prof = ctx.repo.profession(worker.professionId);
    const summary = session.summary(module);
    st.tab = st.tab || 0;
    const tabs = [x("الملف", "Profile"), x("المهارات", "Skills"), x("الباقة", "Package")];
    const panels = [
      () => [
        infoRow(x("الرمز", "Code"), worker.code),
        infoRow(x("الجنسية", "Nationality"), `${nat.flag} ${ctx.t(nat.name)}`),
        infoRow(x("المهنة", "Profession"), ctx.t(prof.name)),
        infoRow(x("العمر", "Age"), String(worker.age)),
        infoRow(x("الخبرة", "Experience"), `${worker.years} ${x("سنوات", "years")}`),
        infoRow(x("اللغات", "Languages"), worker.languages.map((l) => ctx.t(l)).join(", ")),
        h("p", { class: "rui-body-sm" }, ctx.t(worker.bio)),
      ],
      () => h("div", { class: "rui-chips" }, worker.skills.map((k) => h("span", { class: "rui-chip", style: { cursor: "default" } }, icon("check_circle", { size: 16 }), ctx.t(k)))),
      () => [
        infoRow(x("الخدمة", "Service"), ctx.t(summary.title)),
        summary.details.slice(0, 3).map((l) => infoRow(ctx.t(l.label), ctx.t(l.value))),
        h("hr", { class: "rui-divider" }),
        infoRow(x("الإجمالي", "Total"), ctx.money(summary.total), { bold: true }),
      ],
    ];
    return page(ctx, {
      title: ctx.t(worker.name),
      subtitle: worker.code,
      bottom: button({
        key: "worker-confirm", label: x("اختيار العاملة ومتابعة", "Select worker & continue"),
        onClick: () => { selectWorker(session, module, worker.id); ctx.nav.push(R.Routes.contract, module); },
      }),
      body: h("div", { class: "rui-stack", style: { justifyItems: "center" } },
        avatar(prof.icon, 88),
        h("span", { class: "rui-row", style: { gap: "4px" } }, icon("star", { size: 18, fill: true, color: "var(--rui-secondary)" }), String(worker.rating)),
        h("div", { class: "rui-tabs", role: "tablist", key: "worker-tabs" }, tabs.map((t, i) => h("button", {
          class: "rui-tab", type: "button", role: "tab", "aria-selected": String(i === st.tab), key: `worker-tab-${i}`,
          onClick: () => { st.tab = i; ctx.refresh(); },
        }, t))),
        h("div", { class: "rui-tabpanel", role: "tabpanel" }, panels[st.tab]())),
    });
  };

  // ---- Contract (contract_screen.dart) -------------------------------------------------------

  const parseDate = (v) => { const [y, m, d] = v.split("-").map(Number); return v ? new Date(y, m - 1, d) : null; };
  const addDays = (n) => { const d = new Date(); d.setDate(d.getDate() + n); return d; };

  R.screens[R.Routes.contract] = function contractScreen(ctx) {
    const { x, session, state: st } = ctx;
    const module = ctx.args || "individuals";
    const summary = session.summary(module);
    const c = session.contractFor(module);
    const save = (patch) => session.setContract(module, { ...session.contractFor(module), ...patch });
    const v = R.ContractRules;
    const err = st.submitted ? {
      name: c.fullName.trim().length < 3 ? x("أدخل الاسم الكامل (3 أحرف على الأقل)", "Enter your full name (min 3 characters)") : null,
      nid: v.validNationalId(c.nationalId) ? null : x("10 أرقام تبدأ بـ 1 أو 2", "10 digits starting with 1 or 2"),
      email: v.validEmail(c.email) ? null : x("بريد إلكتروني غير صحيح", "Invalid email address"),
      phone: v.validPhone(c.phone) ? null : x("رقم جوال غير صحيح", "Invalid phone number"),
      date: c.startDate ? null : x("هذا الحقل مطلوب", "This field is required"),
    } : {};
    const next = () => {
      st.submitted = true;
      if (!R.ContractRules.isComplete(session.contractFor(module))) return ctx.refresh();
      ctx.nav.push(R.Routes.payment, module);
    };
    return page(ctx, {
      title: x("نموذج العقد", "Contract form"),
      subtitle: ctx.t(summary.title),
      bottom: button({ key: "contract-continue", label: x("المتابعة للدفع", "Continue to payment"), onClick: next }),
      body: h("div", { class: "rui-stack" },
        notice(x("عقد تجريبي للعرض فقط وليس ملزماً قانونياً. لا يتم إرسال أي بيانات.", "Demo contract for preview only — not legally binding. No data is submitted."), { kind: "warning" }),
        sectionTitle(x("مراجعة الطلب", "Review order")),
        card({ pad: 14 }, summary.details.map((l) => infoRow(ctx.t(l.label), ctx.t(l.value)))),
        sectionTitle(x("بيانات العميل", "Customer details")),
        input({ key: "contract-name", label: x("الاسم الكامل", "Full name"), value: c.fullName, error: err.name, onInput: (val) => save({ fullName: val }) }),
        input({
          key: "contract-nid", label: x("رقم الهوية", "National ID"), value: c.nationalId, inputmode: "numeric", dir: "ltr", maxlength: 10, error: err.nid,
          onInput: (val, e) => { const d = val.replace(/\D/g, "").slice(0, 10); e.target.value = d; save({ nationalId: d }); },
        }),
        input({ key: "contract-email", label: x("البريد الإلكتروني", "Email"), value: c.email, type: "email", dir: "ltr", error: err.email, onInput: (val) => save({ email: val }) }),
        input({ key: "contract-phone", label: x("رقم الجوال", "Phone"), value: c.phone, type: "tel", dir: "ltr", error: err.phone, onInput: (val) => save({ phone: val }) }),
        input({
          key: "contract-date", label: x("تاريخ بدء العقد", "Contract start date"), type: "date", dir: "ltr",
          value: c.startDate ? R.fmtDate(c.startDate) : "", min: R.fmtDate(addDays(1)), max: R.fmtDate(addDays(180)), error: err.date,
          onInput: (val) => save({ startDate: parseDate(val) }),
        }),
        checkbox({ key: "contract-ack", checked: c.acknowledged, label: x("أقرّ بأنني اطلعت على العقد التجريبي", "I acknowledge this demo contract"), onChange: (val) => save({ acknowledged: val }) }),
        st.submitted && !c.acknowledged ? notice(x("يجب الإقرار للمتابعة", "Acknowledgement is required"), { kind: "error" }) : null),
    });
  };
})(window);
