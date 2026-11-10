/* Main shell: Home, Orders, Account tabs. Port of ui/main_shell.dart. */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { L } = R;
  const { h, icon, header, card, button, selectTile, notice, infoRow, sectionTitle, emptyState, skeleton } = R.ui;
  R.widgets = R.widgets || {};

  /** ModuleInfo: title, subtitle and icon of each service module. */
  R.ModuleInfo = {
    individuals: { title: L("خدمات الأفراد", "Individuals"), subtitle: L("استقدام عاملة منزلية بعقد دائم", "Recruit a domestic worker"), icon: "groups" },
    hourly: { title: L("الخدمة بالساعة", "Hourly services"), subtitle: L("تنظيف بالساعة حسب جدولك", "Cleaning on your schedule"), icon: "schedule" },
    mediation: { title: L("الوساطة", "Mediation"), subtitle: L("اختر العاملة بنفسك وتولّ الإجراءات", "Pick your worker, we handle paperwork"), icon: "handshake" },
  };

  const SKELETON_MS = 650; // AppTemplate.skeletonDuration

  // ---- Colors for the banner gradients (Color.lerp in sRGB) ------------------------

  const mixCss = (a, b, t) => RuiTheme.color.css(RuiTheme.color.lerp(a, b, t));
  function bannerVars(ctx, hex) {
    const C = RuiTheme.color;
    const c = C.hex(hex);
    const black = C.hex("#000000");
    const k = RuiTheme.resolveTokens(ctx.template, RuiTheme.parseBranding(ctx.branding), ctx.dark);
    switch (ctx.template.card) {
      case "luxe": return { "--b1": mixCss(c, k.chrome, 0.55), "--b2": mixCss(c, black, 0.6) };
      case "glass": return { "--b1": hex, "--b2": mixCss(c, k.primary, 0.5), "--b3": mixCss(c, black, 0.45), "--bs": C.css({ ...c, a: 0.4 }) };
      default: return { "--b1": mixCss(c, black, 0.12) };
    }
  }

  function bannerSlider(ctx) {
    const { session, state: st } = ctx;
    const banners = ctx.repo.banners.filter((b) => session.enabledModules.has(b.target));
    if (!banners.length) return null;
    st.bannerPage = Math.min(st.bannerPage || 0, banners.length - 1);
    const dots = h("div", { class: "rui-dots", "aria-hidden": "true" }, banners.map((_, i) => h("span", { class: i === st.bannerPage ? "is-on" : "" })));
    const rich = ctx.template.motion === "rich";
    const track = h("div", { class: "rui-banners", "data-scroll": "banners", key: "banner-slider" },
      banners.map((b, i) => h("button", {
        class: "rui-banner", type: "button", key: `banner-${i}`, style: bannerVars(ctx, b.color),
        "aria-label": ctx.t(b.title), onClick: () => session.openModule(b.target),
      },
      h("span", { class: "rui-banner__title" }, ctx.t(b.title)),
      h("span", { class: "rui-banner__sub" }, ctx.t(b.subtitle)),
      h("span", { class: "rui-banner__cta" }, ctx.x("اكتشف", "Explore")))));
    // Page indicator + the peeking carousel's scale effect.
    track.addEventListener("scroll", () => {
      const items = [...track.children];
      const mid = track.getBoundingClientRect().left + track.clientWidth / 2;
      let best = 0, bestD = Infinity;
      items.forEach((el, i) => {
        const r = el.getBoundingClientRect();
        const d = Math.abs(r.left + r.width / 2 - mid);
        if (d < bestD) { bestD = d; best = i; }
        if (rich) el.style.transform = `scale(${Math.max(0.9, 1 - (d / r.width) * 0.07).toFixed(3)})`;
      });
      if (best !== st.bannerPage) {
        st.bannerPage = best;
        [...dots.children].forEach((d, i) => d.classList.toggle("is-on", i === best));
      }
    }, { passive: true });
    if (rich) requestAnimationFrame(() => track.dispatchEvent(new Event("scroll")));
    return h("div", null, track, dots);
  }

  function categories(ctx) {
    const mods = R.MODULES.filter((m) => ctx.session.enabledModules.has(m));
    if (!mods.length) return null;
    const horizontal = ctx.template.grid === "list";
    return h("div", { class: "rui-services", style: { "--rest": Math.max(1, mods.length - 1) } },
      mods.map((m) => {
        const info = R.ModuleInfo[m];
        return card({ cls: "rui-service", key: `category-${m}`, onTap: () => ctx.session.openModule(m), label: ctx.t(info.title) },
          icon(info.icon, { size: horizontal ? 28 : 30 }),
          h("span", { class: "rui-service__label" }, ctx.t(info.title)));
      }));
  }

  function reviewCard(ctx, r) {
    return card({ cls: "rui-review" },
      h("div", { class: "rui-review__stars", "aria-label": `${r.rating}/5` },
        Array.from({ length: 5 }, (_, i) => icon("star", { size: 16, fill: i < r.rating }))),
      h("div", { class: "rui-review__text" }, ctx.t(r.text)),
      h("strong", { class: "rui-body-sm" }, ctx.t(r.author)));
  }

  function contactCard(ctx) {
    const { x } = ctx;
    const c = ctx.repo.contact;
    const row = (key, ic, title, value, onTap) =>
      h("button", { class: "rui-list-row", type: "button", key, onClick: onTap },
        icon(ic), h("span", { class: "rui-grow" }, title, h("small", { dir: "ltr", style: { textAlign: ctx.isAr ? "right" : "left" } }, value)));
    return card({ pad: 6, style: { paddingInline: "14px" } },
      row("contact-phone", "call", x("اتصل بنا", "Call us"), c.phone, () => ctx.dialog({
        icon: "phone_in_talk",
        title: x("اتصال تجريبي", "Demo call"),
        content: x(`في التطبيق الحقيقي سيتم الاتصال بالرقم ${c.phone}. لم يتم إجراء أي اتصال.`, `In the real app this would dial ${c.phone}. No call was placed.`),
        actions: [{ label: x("حسناً", "OK"), primary: true }],
      })),
      row("contact-email", "mail", x("البريد", "Email"), c.email, () => ctx.snack(x("تجريبي: كان سيفتح تطبيق البريد", "Demo: would open the email app"))),
      row("contact-address", "location_on", x("العنوان", "Address"), ctx.t(c.address), () => ctx.sheet(() => h("div", null,
        h("h2", { class: "rui-subtitle", style: { marginBottom: "12px" } }, x("معلومات التواصل", "Contact details")),
        infoRow(x("العنوان", "Address"), ctx.t(c.address)),
        infoRow(x("ساعات العمل", "Hours"), ctx.t(c.hours)),
        infoRow(x("الهاتف", "Phone"), c.phone)))));
  }

  function homeSkeleton() {
    return h("div", { class: "rui-stack", key: "home-skeleton" },
      skeleton({ h: 170, r: 22 }),
      h("div", { style: { height: "8px" } }), skeleton({ h: 18, w: 140 }),
      h("div", { class: "rui-row" }, h("div", { class: "rui-grow" }, skeleton({ h: 110, r: 22 })), h("div", { class: "rui-grow" }, skeleton({ h: 110, r: 22 }))),
      h("div", { style: { height: "8px" } }), skeleton({ h: 18, w: 110 }),
      skeleton({ h: 70, r: 22 }), skeleton({ h: 70, r: 22 }));
  }

  function homeTab(ctx) {
    const { session, state: st, x } = ctx;
    const rich = ctx.template.motion === "rich";
    // Rich-motion templates show skeletons while "loading", once per visit.
    if (st.homeLoaded == null) {
      st.homeLoaded = !(rich && !ctx.reducedMotion());
      if (!st.homeLoaded) {
        const t = setTimeout(() => { st.homeLoaded = true; st.revealHome = true; ctx.refresh(); }, SKELETON_MS);
        ctx.onDispose(() => clearTimeout(t));
      }
    }
    const subtitleNode = R.widgets.homeAddressLine ? R.widgets.homeAddressLine(ctx) : null;
    const reveal = (node) => (node ? h("div", { "data-rui-reveal": "" }, node) : null);
    const sections = st.homeLoaded ? [
      bannerSlider(ctx),
      R.widgets.featuredSection ? R.widgets.featuredSection(ctx) : null,
      sectionTitle(x("الأقسام الرئيسية", "Main categories")),
      categories(ctx),
      sectionTitle(x("آراء العملاء", "Customer reviews")),
      h("div", { class: "rui-reviews", "data-scroll": "reviews" }, ctx.repo.reviews.map((r) => reviewCard(ctx, r))),
      sectionTitle(x("شركاؤنا", "Our partners")),
      h("div", { class: "rui-partners" }, ctx.repo.partners.map((p) => {
        const name = ctx.t(p.name);
        return h("div", { class: "rui-partner" }, h("span", { class: "rui-partner__disc" }, [...name][0]), h("span", null, name));
      })),
      sectionTitle(x("تواصل معنا", "Contact us")),
      contactCard(ctx),
    ].map(reveal) : null;

    const body = h("div", { class: "rui-page__body", "data-scroll": "home", key: "home-list" }, st.homeLoaded ? sections : homeSkeleton());
    if (st.revealHome) { st.revealHome = false; setTimeout(() => body.isConnected && RuiTheme.reveal(body), 0); }

    const first = R.MODULES.find((m) => session.enabledModules.has(m));
    return [
      header(ctx, {
        title: x(`مرحباً ${ctx.repo.userName.ar}`, `Hello ${ctx.repo.userName.en}`),
        avatar: true, large: true, subtitleNode,
        trailing: h("button", {
          class: "rui-icon-btn", type: "button", key: "home-bell", "aria-label": x("الإشعارات", "Notifications"),
          onClick: () => ctx.sheet(() => h("div", { style: { minHeight: "280px", display: "grid" } },
            emptyState({ icon: "notifications_off", title: x("لا توجد إشعارات", "No notifications"), subtitle: x("ستظهر إشعاراتك هنا", "Your notifications will appear here") }))),
        }, icon("notifications")),
      }),
      body,
      rich && first ? h("button", { class: "rui-fab", type: "button", key: "quick-order", onClick: () => session.openModule(first) }, icon("bolt"), x("اطلب الآن", "Order now")) : null,
    ];
  }

  function ordersTab(ctx) {
    const { x } = ctx;
    const orders = ctx.session.orders;
    return [
      header(ctx, { title: x("طلباتي", "My orders") }),
      orders.length === 0
        ? h("div", { class: "rui-page__body rui-page__body--fixed" }, emptyState({ icon: "receipt_long", title: x("لا توجد طلبات بعد", "No orders yet"), key: "orders-empty" }))
        : h("div", { class: "rui-page__body", "data-scroll": "orders" }, orders.map((o) => selectTile({
          title: ctx.t(o.summary.title),
          subtitle: o.reference,
          leading: icon(R.ModuleInfo[o.summary.module].icon),
          trailing: h("strong", null, ctx.money(o.summary.total)),
        }))),
    ];
  }

  function accountTab(ctx) {
    const { x, session } = ctx;
    return [
      header(ctx, { title: x("حسابي", "My account") }),
      h("div", { class: "rui-page__body rui-stack", "data-scroll": "account", style: { alignContent: "start" } },
        card({ pad: 14 },
          infoRow(x("الجوال", "Phone"), h("span", { dir: "ltr" }, `${session.dialCode} ${session.phone}`)),
          infoRow(x("القالب", "Template"), ctx.isAr ? ctx.template.nameAr : ctx.template.nameEn),
          infoRow(x("العناوين المحفوظة", "Saved addresses"), String(session.addresses.length))),
        notice(x("هذا عرض تجريبي ببيانات وهمية. لا يتم حفظ أي بيانات حقيقية.", "This is a demo with mock data. No real data is stored.")),
        button({ label: x("إعادة ضبط العرض", "Reset demo"), icon: "restart_alt", secondary: true, key: "account-reset", onClick: () => session.reset() }),
        button({ label: x("تسجيل الخروج", "Log out"), icon: "logout", key: "account-logout", onClick: () => session.logout() })),
    ];
  }

  R.screens[R.Routes.main] = function mainShell(ctx) {
    const { session, x } = ctx;
    const tab = session.mainTab;
    const items = [
      ["home", x("الرئيسية", "Home")],
      ["receipt_long", x("طلباتي", "Orders")],
      ["person", x("حسابي", "Account")],
    ];
    if (tab !== 0) ctx.state.homeLoaded = ctx.state.homeLoaded ?? true;
    const content = tab === 1 ? ordersTab(ctx) : tab === 2 ? accountTab(ctx) : homeTab(ctx);
    return h("section", { class: "rui-shell" },
      h("div", { class: "rui-shell__body", key: `tab-${tab}` }, content),
      h("nav", { class: "rui-nav", "aria-label": x("التنقل", "Navigation") },
        h("div", { class: "rui-nav__list" }, items.map(([ic, label], i) =>
          h("button", {
            class: "rui-nav__item", type: "button", key: `nav-${i}`,
            "aria-current": i === tab ? "page" : null, "aria-label": label,
            onClick: () => { if (i !== tab) session.setMainTab(i); },
          }, icon(ic, { fill: i === tab && ctx.template.nav !== "line" }), h("span", { class: "rui-nav__label" }, label))))));
  };
})(window);
