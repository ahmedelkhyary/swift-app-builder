/* Mediation flow: criteria, packages, worker method. Port of ui/mediation_screens.dart.
   The search and browse screens are shared with Individuals (individuals.js). */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { h, icon, page, card, button, selectTile, notice, sectionTitle } = R.ui;
  const W = R.widgets;

  R.screens[R.Routes.medCriteria] = function medCriteria(ctx) {
    const { x, session, state: st } = ctx;
    const next = () => {
      if (session.medProfessionId == null || session.medNationalityId == null) { st.submitted = true; return ctx.refresh(); }
      ctx.nav.push(R.Routes.medPackages);
    };
    return page(ctx, {
      title: x("المهنة والجنسية", "Profession & nationality"),
      subtitle: x("الخطوة 1", "Step 1"),
      bottom: button({ key: "med-criteria-continue", label: x("عرض الباقات", "View packages"), onClick: next }),
      body: [
        sectionTitle(x("اختر المهنة", "Choose a profession")),
        ctx.repo.professions.map((p) => selectTile({
          key: `profession-${p.id}`, selected: session.medProfessionId === p.id,
          onTap: () => session.setMedCriteria({ professionId: p.id }),
          leading: icon(p.icon), title: ctx.t(p.name),
        })),
        st.submitted && session.medProfessionId == null ? notice(x("اختر المهنة", "Select a profession"), { kind: "error" }) : null,
        h("div", { style: { height: "8px" } }),
        W.nationalitySelect(ctx, {
          value: session.medNationalityId,
          error: st.submitted && session.medNationalityId == null ? x("اختر الجنسية", "Select a nationality") : null,
          onChange: (v) => session.setMedCriteria({ nationalityId: v }),
        }),
      ],
    });
  };

  R.screens[R.Routes.medPackages] = function medPackages(ctx) {
    const { x, session, state: st } = ctx;
    const prof = ctx.repo.profession(session.medProfessionId || "housemaid");
    const nat = ctx.repo.nationality(session.medNationalityId || "ph");
    return page(ctx, {
      title: x("باقات الوساطة", "Mediation packages"),
      subtitle: `${ctx.t(prof.name)} · ${ctx.t(nat.name)}`,
      bottom: button({
        key: "med-packages-continue", label: x("متابعة", "Continue"),
        onClick: () => { if (session.medPackageId == null) { st.showError = true; return ctx.refresh(); } ctx.nav.push(R.Routes.medMethod); },
      }),
      body: [
        ctx.repo.mediationPackages.map((p) => W.packageCard(ctx, {
          key: `med-package-${p.id}`, pkg: p,
          price: R.Pricing.mediationPrice(p, session.medNationalityId || "ph", session.medProfessionId || "housemaid"),
          selected: p.id === session.medPackageId,
          onTap: () => { st.showError = false; session.setMedPackage(p.id); },
        })),
        st.showError ? notice(x("اختر باقة للمتابعة", "Select a package to continue"), { kind: "error" }) : null,
      ],
    });
  };

  R.screens[R.Routes.medMethod] = function workerMethod(ctx) {
    const { x } = ctx;
    const option = (key, ic, title, body, onTap) => card({ key, onTap, pad: 18, cls: "rui-method", label: title },
      h("div", { class: "rui-row", style: { gap: "14px" } },
        h("span", { class: "rui-avatar", style: { width: "52px", height: "52px" } }, icon(ic)),
        h("div", { class: "rui-grow" }, h("div", { class: "rui-select-tile__title" }, title), h("div", { class: "rui-body-sm" }, body)),
        icon(ctx.isAr ? "chevron_left" : "chevron_right")));
    return page(ctx, {
      title: x("طريقة اختيار العاملة", "How to choose the worker"),
      subtitle: x("الوساطة", "Mediation"),
      body: h("div", { class: "rui-stack" },
        option("method-browse", "grid_view", x("تصفح العاملات", "Browse workers"), x("استعرض العاملات المتاحات واطلع على التفاصيل", "See available workers and their details"),
          () => ctx.nav.push(R.Routes.workers, "mediation")),
        option("method-search", "search", x("البحث بالاسم", "Search by name"), x("ابحث عن عاملة محددة باسمها", "Find a specific worker by name"),
          () => ctx.nav.push(R.Routes.medSearch))),
    });
  };
})(window);
