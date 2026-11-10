/* Hourly flow: packages (fixed or custom) and service details. Port of ui/hourly_screens.dart. */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { h, icon, page, card, button, selectTile, notice, infoRow, sectionTitle, input, select, chip } = R.ui;
  const W = R.widgets;

  function segmented(ctx, { value, options, onChange, key }) {
    return h("div", { class: "rui-segmented", role: "radiogroup", key },
      options.map((o) => h("button", {
        type: "button", role: "radio", "aria-checked": String(o.value === value), class: o.value === value ? "is-on" : "",
        onClick: () => { if (o.value !== value) onChange(o.value); },
      }, o.value === value ? icon("check", { size: 18 }) : null, o.label)));
  }

  function stepper(ctx, { key, label, value, min, max, onChange, suffix = "" }) {
    return h("div", { class: "rui-stepper" },
      h("span", { class: "rui-grow" }, label),
      h("button", { class: "rui-stepper__btn", type: "button", key: `${key}-minus`, "aria-label": ctx.x("إنقاص", "Decrease"), disabled: value <= min, onClick: () => onChange(value - 1) }, icon("remove")),
      h("strong", { class: "rui-stepper__value", key, "aria-live": "polite" }, `${value}${suffix}`),
      h("button", { class: "rui-stepper__btn", type: "button", key: `${key}-plus`, "aria-label": ctx.x("زيادة", "Increase"), disabled: value >= max, onClick: () => onChange(value + 1) }, icon("add")));
  }

  function customBuilder(ctx) {
    const { x, session } = ctx;
    const c = session.customHourly;
    const set = (patch) => session.setCustomHourly({ ...c, ...patch });
    const price = session.priceFor(c.hoursPerVisit, c.visitsPerWeek, c.weeks);
    const visits = c.visitsPerWeek * c.weeks;
    return card({ selected: true, pad: 14 },
      stepper(ctx, { key: "custom-hours", label: x("ساعات الزيارة", "Hours per visit"), value: c.hoursPerVisit, min: 2, max: 8, suffix: x(" س", " h"), onChange: (v) => set({ hoursPerVisit: v }) }),
      stepper(ctx, { key: "custom-visits", label: x("زيارات أسبوعياً", "Visits per week"), value: c.visitsPerWeek, min: 1, max: 5, onChange: (v) => set({ visitsPerWeek: v }) }),
      h("div", { style: { padding: "6px 0" } }, select({
        key: "custom-weeks", label: x("المدة (أسابيع)", "Duration (weeks)"), value: String(c.weeks),
        options: [1, 2, 4, 8, 12].map((w) => ({ value: String(w), label: `${w} ${x("أسبوع", "weeks")}` })),
        onChange: (v) => set({ weeks: +v }),
      })),
      h("hr", { class: "rui-divider" }),
      infoRow(x("إجمالي الزيارات", "Total visits"), String(visits)),
      infoRow(x("إجمالي الساعات", "Total hours"), String(visits * c.hoursPerVisit)),
      infoRow(x("السعر التقديري", "Estimated price"), ctx.money(price), { bold: true }),
      h("p", { class: "rui-body-sm", style: { color: "var(--rui-outline)", margin: "4px 0 0" } },
        x(`تسعير تجريبي: ${R.Pricing.hourlyRate} ر.س/ساعة مع خصم للمدد الطويلة.`, `Demo pricing: ${R.Pricing.hourlyRate} SAR/hour with a discount for longer terms.`)));
  }

  R.screens[R.Routes.hrPackages] = function hourlyPackages(ctx) {
    const { x, session, state: st } = ctx;
    return page(ctx, {
      title: x("اختر الباقة", "Choose a package"),
      subtitle: x("الخطوة 2", "Step 2"),
      bottom: button({
        key: "hr-packages-continue", label: x("متابعة", "Continue"),
        onClick: () => { if (!session.hourlyHasSelection) { st.showError = true; return ctx.refresh(); } ctx.nav.push(R.Routes.hrDetails); },
      }),
      body: [
        segmented(ctx, {
          key: "hr-mode", value: session.hourlyCustom,
          options: [{ value: false, label: x("باقات جاهزة", "Fixed packages") }, { value: true, label: x("صمّم باقتك", "Design your own") }],
          onChange: (v) => { st.showError = false; if (v) session.useCustomHourly(); else session.useFixedHourly(); },
        }),
        h("div", { style: { height: "12px" } }),
        session.hourlyCustom ? customBuilder(ctx) : ctx.repo.hourlyPackages.map((p) => selectTile({
          key: `hr-package-${p.id}`, selected: session.hourlyPackageId === p.id,
          onTap: () => { st.showError = false; session.selectHourlyPackage(p.id); },
          title: ctx.t(p.name), subtitle: ctx.t(p.description),
          trailing: h("div", { style: { display: "grid", justifyItems: "end" } },
            h("span", { class: "rui-price rui-title", style: { fontFamily: "var(--rui-font)" } }, String(session.priceFor(p.hoursPerVisit, p.visitsPerWeek, p.weeks))),
            h("span", { class: "rui-body-sm" }, x("ر.س", "SAR"))),
          child: h("div", { class: "rui-chips", style: { marginTop: "8px", gap: "6px" } },
            h("span", { class: "rui-tag" }, `${p.hoursPerVisit * p.visitsPerWeek * p.weeks} ${x("ساعة", "hours")}`),
            h("span", { class: "rui-tag" }, `${p.visitsPerWeek * p.weeks} ${x("زيارة", "visits")}`),
            h("span", { class: "rui-tag" }, `${p.visitsPerWeek}/${x("أسبوع", "wk")}`)),
        })),
        st.showError ? notice(x("اختر باقة للمتابعة", "Select a package to continue"), { kind: "error" }) : null,
      ],
    });
  };

  const addDays = (d, n) => { const r = new Date(d); r.setDate(r.getDate() + n); return r; };
  const parseDate = (v) => { if (!v) return null; const [y, m, d] = v.split("-").map(Number); return new Date(y, m - 1, d); };

  function discountMessage(ctx, r) {
    const { x } = ctx;
    switch (r.status) {
      case "applied": return x(`تم تطبيق الكود ${r.code}: خصم ${r.amount} ر.س`, `Code ${r.code} applied: -${r.amount} SAR`);
      case "invalid": return x("كود الخصم غير صحيح", "Invalid discount code");
      case "expired": return x("انتهت صلاحية الكود", "This code has expired");
      case "minimumNotMet": return x("الحد الأدنى للطلب 300 ر.س لهذا الكود", "Minimum order of 300 SAR for this code");
      default: return "";
    }
  }

  R.screens[R.Routes.hrDetails] = function hourlyDetails(ctx) {
    const { x, session, state: st } = ctx;
    if (st.code == null) st.code = "";
    const summary = session.summary("hourly");
    const addr = session.selectedAddress;
    const need = session.visitsPerWeek;
    const start = session.hourlyStartDate;
    const days = ctx.repo.serviceWeekdays;
    // First selectable day: tomorrow, skipping days without service.
    let first = addDays(new Date(), 1);
    while (!days.has(R.isoWeekday(first))) first = addDays(first, 1);

    const apply = () => {
      if (!st.code.trim()) return;
      st.lastResult = session.applyDiscount(st.code);
      ctx.refresh(); // applyDiscount already re-rendered, before lastResult was set
    };
    const next = () => {
      if (!session.hourlyDetailsComplete) { st.submitted = true; return ctx.refresh(); }
      ctx.nav.push(R.Routes.payment, "hourly");
    };
    const dateError = st.dateError || (st.submitted && !start ? x("اختر تاريخ البدء", "Select a start date") : null);

    return page(ctx, {
      title: x("تفاصيل الخدمة", "Service details"),
      subtitle: x("الخطوة 3", "Step 3"),
      bottom: button({ key: "hr-details-continue", label: x("المتابعة للدفع", "Continue to payment"), onClick: next }),
      body: [
        card({ pad: 14 },
          infoRow(x("العنوان", "Address"), addr ? R.oneLine(addr, ctx.lang) : "-"),
          infoRow(x("الباقة", "Package"), ctx.t(summary.details[0].value)),
          infoRow(x("المدة", "Duration"), ctx.t(summary.details[1].value))),
        sectionTitle(x("تاريخ البدء", "Start date")),
        input({
          key: "hr-start-date", type: "date", dir: "ltr", label: x("اختر تاريخ أول زيارة", "Pick the first visit date"),
          value: start ? R.fmtDate(start) : "", min: R.fmtDate(first), max: R.fmtDate(addDays(new Date(), 90)), error: dateError,
          onInput: (v) => {
            const d = parseDate(v);
            // selectableDayPredicate: only days with service can be picked.
            if (d && !days.has(R.isoWeekday(d))) { st.dateError = x("لا توجد خدمة يوم الجمعة. اختر يوماً آخر.", "No service on Fridays. Pick another day."); return ctx.refresh(); }
            st.dateError = null;
            if (d) session.setHourlyStart(d); else ctx.refresh();
          },
        }),
        sectionTitle(x(`أيام الخدمة (${need} أيام أسبوعياً)`, `Service days (${need} per week)`)),
        h("div", { class: "rui-chips" }, Object.entries(R.weekdayNames).map(([k, name]) => {
          const day = +k;
          return chip({ key: `day-${day}`, label: ctx.t(name), selected: session.hourlyDays.has(day), disabled: !days.has(day), onTap: () => session.toggleHourlyDay(day) });
        })),
        h("p", { class: "rui-body-sm", style: { margin: "6px 0 0" } }, x("الجمعة غير متاحة.", "Friday is unavailable.")),
        st.submitted && session.hourlyDays.size !== need ? notice(x(`اختر ${need} أيام بالضبط`, `Select exactly ${need} days`), { kind: "error" }) : null,
        sectionTitle(x("كود الخصم", "Discount code")),
        h("div", { class: "rui-discount" },
          h("div", { class: "rui-grow" }, input({
            key: "discount-field", label: x("أدخل الكود", "Enter code"), value: st.code, dir: "ltr", hint: "DEMO10 · SAVE50 · EXPIRED20",
            onInput: (v, e) => { const u = v.toUpperCase(); if (u !== v) { const p = e.target.selectionStart; e.target.value = u; e.target.setSelectionRange(p, p); } st.code = u; },
            onEnter: apply,
          })),
          button({ key: "discount-apply", label: x("تطبيق", "Apply"), cls: "rui-btn--compact", onClick: apply })),
        st.lastResult && st.lastResult.status !== "none"
          ? notice(discountMessage(ctx, st.lastResult), { kind: st.lastResult.isApplied ? "success" : "error" }) : null,
        sectionTitle(x("ملخص السعر", "Price summary")),
        W.orderSummaryCard(ctx, summary, { canChangeAddress: true }),
      ],
    });
  };
})(window);
