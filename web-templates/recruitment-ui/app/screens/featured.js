/* Featured services: Home section, Home address line and the "view all" screen.
   Port of ui/featured.dart. */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { h, icon, page, selectTile, emptyState, sectionTitle, textButton } = R.ui;
  const W = (R.widgets = R.widgets || {});

  /** Opens a featured service; asks for a main address first when there is none. */
  async function startFeatured(ctx, f) {
    let address = ctx.session.mainAddress;
    if (!address) address = await W.showAddressSheet(ctx, { target: "main" });
    if (!address) return;
    ctx.session.startFeatured(f, address);
  }

  /** HomeAddressLine: the main address under the Home greeting. */
  W.homeAddressLine = function homeAddressLine(ctx) {
    const { x, session } = ctx;
    const main = session.mainAddress;
    const text = main ? `${ctx.t(main.city)} - ${ctx.t(main.district)}` : x("أضف عنوانك", "Add your address");
    return h("button", {
      class: "rui-header__sub rui-address-line", type: "button", key: "home-address",
      "aria-label": `${x("العنوان الرئيسي", "Main address")}: ${text}`,
      onClick: () => (main ? W.showAddressSheet(ctx, { target: "main" }) : W.showAddressForm(ctx, { offerMain: true, mainByDefault: true })),
    }, icon("location_on", { size: 14 }), h("span", null, text), icon("keyboard_arrow_down", { size: 16 }));
  };

  const mix = (hex, t) => RuiTheme.color.css(RuiTheme.color.lerp(RuiTheme.color.hex(hex), RuiTheme.color.hex("#000000"), t));

  function featuredCard(ctx, f) {
    return h("button", {
      class: "rui-featured", type: "button", key: `featured-${f.id}`, "aria-label": ctx.t(f.title),
      style: { "--f1": f.color, "--f2": mix(f.color, 0.5) }, onClick: () => startFeatured(ctx, f),
    }, icon(f.icon, { cls: "rui-featured__art" }), h("span", { class: "rui-featured__title" }, ctx.t(f.title)));
  }

  /** FeaturedSection on Home. */
  W.featuredSection = function featuredSection(ctx) {
    const items = ctx.session.featuredServices;
    if (!items.length) return null;
    return h("div", null,
      sectionTitle(ctx.x("الخدمات المميزة", "Featured services"),
        h("span", { class: "rui-link-btn" }, textButton({ key: "featured-view-all", label: ctx.x("عرض الكل", "View all"), onClick: () => ctx.nav.push(R.Routes.featured) }))),
      h("div", { class: "rui-featured-list", "data-scroll": "featured", key: "featured-list" }, items.map((f) => featuredCard(ctx, f))));
  };

  R.screens[R.Routes.featured] = function featuredScreen(ctx) {
    const items = ctx.session.featuredServices;
    return page(ctx, {
      title: ctx.x("الخدمات المميزة", "Featured services"),
      body: [
        items.length === 0 ? emptyState({ icon: "star", title: ctx.x("لا توجد خدمات مميزة", "No featured services") }) : null,
        items.map((f) => selectTile({
          key: `featured-all-${f.id}`, selected: false, onTap: () => startFeatured(ctx, f),
          leading: h("span", { class: "rui-avatar", style: { width: "40px", height: "40px", background: f.color, color: "#fff" } }, icon(f.icon, { size: 22 })),
          title: ctx.t(f.title),
          trailing: icon(ctx.isAr ? "chevron_left" : "chevron_right"),
        })),
      ],
    });
  };
})(window);
