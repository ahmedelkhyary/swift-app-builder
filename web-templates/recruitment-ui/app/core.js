/*
 * RuiApp core: DOM builder, shared widgets, navigator and mount().
 *
 * Counterpart of RecruitmentApp (ui/app.dart) + widgets.dart. A screen is a
 * function registered in RuiApp.screens[route]: (ctx) => Element. It is
 * rendered again whenever the session changes or it calls ctx.refresh();
 * ctx.state survives those re-renders (it is the screen's State object).
 */
(function (global) {
  "use strict";
  const R = (global.RuiApp = global.RuiApp || {});
  R.screens = R.screens || {};

  // ---- DOM builder ---------------------------------------------------------------

  /**
   * h("div", { class, style, key, onClick, ...attrs }, ...children)
   * `key` becomes data-key (used to keep focus across re-renders). Children
   * may be nodes, strings, numbers, arrays, or null/false (skipped).
   */
  function h(tag, props, ...children) {
    const el = document.createElement(tag);
    if (props) {
      for (const [k, v] of Object.entries(props)) {
        if (v == null || v === false) continue;
        if (k === "class") el.className = v;
        else if (k === "style" && typeof v === "object") Object.assign(el.style, v);
        else if (k === "key") el.dataset.key = v;
        else if (k.startsWith("on") && typeof v === "function") el.addEventListener(k.slice(2).toLowerCase(), v);
        else if (k === "value" && "value" in el) el.value = v;
        else if (k === "checked" || k === "disabled" || k === "selected") el[k] = !!v;
        else if (k === "html") el.innerHTML = v;
        else el.setAttribute(k, v === true ? "" : v);
      }
    }
    append(el, children);
    return el;
  }
  function append(el, children) {
    for (const c of children) {
      if (c == null || c === false) continue;
      if (Array.isArray(c)) append(el, c);
      else el.appendChild(c instanceof Node ? c : document.createTextNode(String(c)));
    }
  }

  const icon = (name, { size, fill, color, cls } = {}) =>
    h("span", {
      class: "rui-icon" + (fill ? " rui-icon--fill" : "") + (cls ? " " + cls : ""),
      "aria-hidden": "true",
      style: { fontSize: size ? `${size}px` : null, color: color || null },
    }, name);

  // ---- Widgets (widgets.dart) ------------------------------------------------------

  /** RuiHeader. `onBack` shows the back arrow; `large` = Home's tall hero. */
  function header(ctx, { title, subtitle, subtitleNode, avatar, onBack, trailing, large } = {}) {
    const style = ctx.template.header;
    const hero = style === "hero";
    return h("header", { class: "rui-header" + (large ? " rui-header--large" : "") + (style === "solid" && !avatar ? " rui-header--center" : "") },
      onBack
        ? h("button", { class: "rui-icon-btn", type: "button", "aria-label": ctx.x("رجوع", "Back"), key: "header-back", onClick: onBack },
          icon(ctx.isAr ? "arrow_forward" : "arrow_back"))
        : null,
      avatar ? h("span", { class: "rui-header__logo", "aria-hidden": "true" }, icon("person")) : null,
      h("div", { class: "rui-header__text" },
        subtitle && large && hero ? h("div", { class: "rui-header__sub" }, subtitle) : null,
        h("h1", { class: "rui-title" }, title),
        subtitleNode || (subtitle && !(large && hero) ? h("div", { class: "rui-header__sub" }, subtitle) : null)),
      trailing || (style === "solid" && !avatar && onBack ? h("span", { class: "rui-header__balance" }) : null));
  }

  /**
   * RuiPage: header + scrolling body + optional bottom action.
   * `back`: true (pop), a function, or false.
   */
  function page(ctx, { title, subtitle, back = true, trailing, body, bottom, scroll = true, cls } = {}) {
    const onBack = back === false ? null : typeof back === "function" ? back : () => ctx.nav.pop();
    return h("section", { class: "rui-page" + (cls ? " " + cls : "") },
      header(ctx, { title, subtitle, onBack, trailing }),
      h("div", { class: "rui-page__body" + (scroll ? "" : " rui-page__body--fixed"), "data-scroll": "body" }, body),
      bottom ? h("div", { class: "rui-page__bottom" }, bottom) : null);
  }

  /** RuiCard. Pass `onTap` to make it interactive (rendered as a button-like div). */
  function card({ selected, onTap, pad, cls, style, key, label } = {}, ...children) {
    const tap = typeof onTap === "function";
    return h("div", {
      class: "rui-card" + (tap ? " rui-card--tap" : "") + (selected ? " rui-card--selected" : "") + (cls ? " " + cls : ""),
      style: { ...(pad != null ? { "--pad": `${pad}px` } : {}), ...(style || {}) },
      key,
      role: tap ? "button" : null,
      tabindex: tap ? "0" : null,
      "aria-pressed": tap && selected != null ? String(!!selected) : null,
      "aria-label": label || null,
      onClick: tap ? onTap : null,
      onKeydown: tap ? (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onTap(e); } } : null,
    }, children);
  }

  /**
   * RuiButton. `secondary` = the Dart `outlined: true` (filled secondary in
   * Simple, outlined in Luxury / Premium). `loading` shows a spinner.
   */
  function button({ label, icon: ic, onClick, disabled, loading, secondary, key, cls, type = "button" } = {}) {
    return h("button", {
      class: "rui-btn" + (secondary ? " rui-btn--secondary" : "") + (cls ? " " + cls : ""),
      type, key,
      disabled: disabled || loading,
      "aria-busy": loading ? "true" : null,
      onClick: onClick || null,
    }, loading ? h("span", { class: "rui-spinner", "aria-hidden": "true" }) : [ic ? icon(ic) : null, h("span", null, label)]);
  }

  /** Flutter TextButton. */
  const textButton = ({ label, icon: ic, onClick, key, disabled } = {}) =>
    h("button", { class: "rui-text-btn", type: "button", key, disabled, onClick }, ic ? icon(ic, { size: 18 }) : null, label);

  /** RuiSelectTile: a selectable card row with a radio mark (or `trailing`). */
  function selectTile({ selected, onTap, title, subtitle, leading, trailing, child, key, disabled } = {}) {
    return card({ selected, onTap: disabled ? null : onTap, pad: 14, cls: "rui-select-tile" + (disabled ? " is-disabled" : ""), key },
      h("div", { class: "rui-select-tile__row" },
        leading ? h("div", { class: "rui-select-tile__leading" }, leading) : null,
        h("div", { class: "rui-select-tile__text" },
          h("div", { class: "rui-select-tile__title" }, title),
          subtitle ? h("div", { class: "rui-body-sm" }, subtitle) : null),
        trailing != null ? trailing : icon(selected ? "check_circle" : "radio_button_unchecked", { fill: selected, cls: selected ? "rui-select-tile__mark is-on" : "rui-select-tile__mark" })),
      child || null);
  }

  /** RuiNotice. kind: "info" | "success" | "error" | "warning". */
  function notice(message, { kind = "info", icon: ic, key } = {}) {
    const def = { info: "info", success: "check_circle", error: "error", warning: "warning" }[kind];
    return h("div", { class: `rui-notice rui-notice--${kind}`, role: kind === "error" ? "alert" : null, key },
      icon(ic || def, { size: 20 }), h("div", null, message));
  }

  /** RuiInfoRow: label / value row of a summary. */
  const infoRow = (label, value, { bold } = {}) =>
    h("div", { class: "rui-info-row" + (bold ? " is-bold" : "") }, h("span", null, label), h("span", null, value));

  /** RuiSectionTitle. */
  const sectionTitle = (text, trailing) =>
    h("div", { class: "rui-section-title" }, h("h2", { class: "rui-subtitle" }, text), h("span", { class: "rui-spacer" }), trailing || null);

  /** RuiEmptyState. */
  const emptyState = ({ icon: ic, title, subtitle, key } = {}) =>
    h("div", { class: "rui-empty" },
      h("div", { class: "rui-empty__disc" }, icon(ic, { size: 44 })),
      h("strong", { class: "rui-subtitle", key }, title),
      subtitle ? h("span", { class: "rui-muted" }, subtitle) : null);

  /** RuiSkeleton. */
  const skeleton = ({ h: height = 16, w, r = 12 } = {}) =>
    h("div", { class: "rui-skeleton", style: { height: `${height}px`, width: w ? `${w}px` : null, borderRadius: `${r}px` } });

  /**
   * A labelled text field. `onInput(value)`; `error` shows below the field
   * and marks it invalid; `prefixIcon` adds an icon inside.
   */
  function input({ label, value = "", onInput, onEnter, type = "text", placeholder, key, dir, inputmode, maxlength, error, hint, prefixIcon, autofocus, disabled, min, max, readonly } = {}) {
    const field = h("input", {
      class: "rui-input" + (prefixIcon ? " rui-input--prefixed" : ""),
      type, value, placeholder, key, dir, inputmode, maxlength, disabled, min, max, readonly,
      "aria-invalid": error ? "true" : null,
      "aria-label": label || placeholder || null,
      autofocus: autofocus || null,
      onInput: onInput ? (e) => onInput(e.target.value, e) : null,
      onKeydown: onEnter ? (e) => { if (e.key === "Enter") onEnter(e); } : null,
    });
    return h("label", { class: "rui-field" },
      label ? h("span", { class: "rui-field__label" }, label) : null,
      prefixIcon ? h("span", { class: "rui-field__control" }, icon(prefixIcon, { size: 20, cls: "rui-field__prefix" }), field) : field,
      error ? h("span", { class: "rui-field__error" }, error) : hint ? h("span", { class: "rui-field__hint" }, hint) : null);
  }

  /** A labelled <select>. options: [{ value, label }]. */
  function select({ label, value, options, onChange, key, placeholder, dir } = {}) {
    const el = h("select", { class: "rui-input rui-select", key, dir, "aria-label": label || null, onChange: (e) => onChange && onChange(e.target.value) },
      placeholder ? h("option", { value: "", disabled: true, selected: value == null || value === "" }, placeholder) : null,
      options.map((o) => h("option", { value: o.value, selected: o.value === value }, o.label)));
    return h("label", { class: "rui-field" }, label ? h("span", { class: "rui-field__label" }, label) : null, el);
  }

  /** Choice chip (filters, weekdays). */
  const chip = ({ label, selected, onTap, icon: ic, key, disabled } = {}) =>
    h("button", { class: "rui-chip" + (selected ? " is-selected" : ""), type: "button", key, disabled, "aria-pressed": String(!!selected), onClick: onTap },
      selected ? icon("check", { size: 16 }) : ic ? icon(ic, { size: 16 }) : null, label);

  /** Checkbox row (e.g. "I agree"). */
  const checkbox = ({ checked, onChange, label, key } = {}) =>
    h("label", { class: "rui-check" },
      h("input", { type: "checkbox", checked, key, onChange: (e) => onChange && onChange(e.target.checked) }),
      h("span", null, label));

  /** On/off switch row. */
  const toggle = ({ checked, onChange, label, key } = {}) =>
    h("label", { class: "rui-toggle" },
      h("span", null, label),
      h("input", { type: "checkbox", role: "switch", checked, key, onChange: (e) => onChange && onChange(e.target.checked) }),
      h("span", { class: "rui-toggle__track", "aria-hidden": "true" }));

  /** Price helpers. */
  const money = (ctx, amount) => `${amount} ${ctx.x("ر.س", "SAR")}`;

  R.ui = { h, icon, header, page, card, button, textButton, selectTile, notice, infoRow, sectionTitle, emptyState, skeleton, input, select, chip, checkbox, toggle, money };

  // ---- Navigator + app ---------------------------------------------------------------

  /**
   * Mounts the prototype into `root`. Options: templateId, branding, dark,
   * lang, enabledModules, initialRoute, showDemoBanner (default true).
   * Returns a controller: { session, update(opts), nav, destroy() }.
   */
  R.mount = function mount(root, options = {}) {
    let opts = { showDemoBanner: true, ...options };
    const session = opts.session || R.createSession({ enabledModules: opts.enabledModules });
    const stack = []; // { name, args, state, el, disposers }
    let template;

    root.replaceChildren();
    root.classList.add("rui-viewport");
    const banner = h("div", { class: "rui-demo-banner" });
    const stage = h("div", { class: "rui-stage" });
    const overlays = h("div", { class: "rui-overlays" });
    root.append(banner, stage, overlays);

    function theme() {
      template = RuiTheme.apply(root, {
        templateId: opts.templateId, branding: opts.branding, dark: opts.dark, lang: opts.lang, loadFonts: opts.loadFonts,
      }).template;
      banner.hidden = !opts.showDemoBanner;
      banner.textContent = (opts.lang === "en")
        ? "DEMO PREVIEW — mock data, no real payments"
        : "عرض تجريبي — بيانات وهمية، لا مدفوعات حقيقية";
    }

    function context(entry) {
      const lang = opts.lang === "en" ? "en" : "ar";
      const ctx = {
        app: controller, session, repo: session.repo, template, lang,
        isAr: lang === "ar",
        branding: opts.branding || {},
        appName() {
          const b = opts.branding || {};
          const pref = lang === "ar" ? b.appNameAr : b.appNameEn;
          const fb = lang === "ar" ? b.appNameEn : b.appNameAr;
          return (pref && pref.trim()) || (fb && fb.trim()) || (lang === "ar" ? "اسم التطبيق" : "App name");
        },
        x: (ar, en) => (lang === "ar" ? ar : en),
        t: (l) => (l == null ? "" : typeof l === "string" ? l : l[lang]),
        money: (n) => money(ctx, n),
        nav, args: entry.args, state: entry.state,
        refresh: () => { if (stack[stack.length - 1] === entry) render(entry); },
        onDispose: (fn) => entry.disposers.push(fn),
        snack, dialog, sheet, busy,
        reducedMotion: () => global.matchMedia && global.matchMedia("(prefers-reduced-motion: reduce)").matches,
      };
      return ctx;
    }

    /** Renders `entry`, keeping scroll positions and the focused field. */
    function render(entry, { animate = false } = {}) {
      const build = R.screens[entry.name] || R.screens[R.Routes.login];
      const old = entry.el;
      const scrolls = {};
      let focus = null;
      if (old) {
        old.querySelectorAll("[data-scroll]").forEach((el) => { scrolls[el.dataset.scroll] = [el.scrollTop, el.scrollLeft]; });
        const a = document.activeElement;
        if (a && old.contains(a) && a.dataset.key) {
          focus = { key: a.dataset.key, start: a.selectionStart, end: a.selectionEnd };
        }
      }
      const el = build(context(entry));
      el.classList.add("rui-route");
      if (animate) el.classList.add("rui-route--enter");
      if (old && old.parentNode) old.replaceWith(el); else stage.appendChild(el);
      entry.el = el;
      el.querySelectorAll("[data-scroll]").forEach((s) => {
        const v = scrolls[s.dataset.scroll];
        if (v) { s.scrollTop = v[0]; s.scrollLeft = v[1]; }
      });
      if (focus) {
        const f = el.querySelector(`[data-key="${CSS.escape(focus.key)}"]`);
        if (f) {
          f.focus({ preventScroll: true });
          try { if (focus.start != null) f.setSelectionRange(focus.start, focus.end); } catch (_) { /* not a text field */ }
        }
      }
      if (animate) RuiTheme.reveal(el);
    }

    function dispose(entry) {
      entry.disposers.forEach((fn) => { try { fn(); } catch (_) { /* ignore */ } });
      entry.disposers = [];
      if (entry.el) entry.el.remove();
      entry.el = null;
    }

    function show(entry, animate) {
      stage.querySelectorAll(".rui-route").forEach((el) => { if (el !== entry.el) el.remove(); });
      render(entry, { animate });
      closeOverlays();
    }

    const nav = {
      push(name, args) {
        const top = stack[stack.length - 1];
        if (top && top.el) top.el.remove();
        if (top) top.el = null;
        const entry = { name, args, state: {}, el: null, disposers: [] };
        stack.push(entry);
        show(entry, true);
      },
      pop() {
        if (stack.length <= 1) return false;
        dispose(stack.pop());
        show(stack[stack.length - 1], false);
        return true;
      },
      /** pushNamedAndRemoveUntil(name, (_) => false) */
      replaceAll(name, args) {
        while (stack.length) dispose(stack.pop());
        nav.push(name, args);
      },
      /** popUntil(route) */
      popUntil(name) {
        while (stack.length > 1 && stack[stack.length - 1].name !== name) dispose(stack.pop());
        show(stack[stack.length - 1], false);
      },
      get current() { return stack[stack.length - 1]?.name; },
      get depth() { return stack.length; },
    };
    session.nav = nav;

    // ---- overlays: snack, dialog, sheet, busy ---------------------------------------

    let snackTimer;
    function snack(message) {
      overlays.querySelectorAll(".rui-snack").forEach((n) => n.remove());
      const el = h("div", { class: "rui-snack", role: "status" }, message);
      overlays.appendChild(el);
      clearTimeout(snackTimer);
      snackTimer = setTimeout(() => el.remove(), 3000);
    }

    function modal(build, cls) {
      return new Promise((resolve) => {
        const prevFocus = document.activeElement;
        const scrim = h("div", { class: `rui-scrim ${cls}` });
        const close = (value) => {
          scrim.remove();
          document.removeEventListener("keydown", onKey, true);
          if (prevFocus && prevFocus.isConnected) prevFocus.focus({ preventScroll: true });
          resolve(value);
        };
        const onKey = (e) => { if (e.key === "Escape") { e.stopPropagation(); close(undefined); } };
        scrim.addEventListener("click", (e) => { if (e.target === scrim) close(undefined); });
        scrim.appendChild(build(close));
        overlays.appendChild(scrim);
        document.addEventListener("keydown", onKey, true);
        const first = scrim.querySelector("button, [href], input, select, textarea, [tabindex]");
        if (first) first.focus({ preventScroll: true });
      });
    }

    /** AlertDialog. actions: [{ label, value, primary, key }]. Resolves the value. */
    function dialog({ icon: ic, title, content, actions = [] } = {}) {
      return modal((close) => h("div", { class: "rui-dialog", role: "dialog", "aria-modal": "true", "aria-label": title || null },
        ic ? icon(ic, { size: 40, cls: "rui-dialog__icon" }) : null,
        title ? h("h2", { class: "rui-subtitle" }, title) : null,
        content ? h("div", { class: "rui-dialog__content" }, content) : null,
        h("div", { class: "rui-dialog__actions" },
          actions.map((a) => a.primary
            ? h("button", { class: "rui-btn rui-btn--compact", type: "button", key: a.key, onClick: () => close(a.value) }, a.label)
            : h("button", { class: "rui-text-btn", type: "button", key: a.key, onClick: () => close(a.value) }, a.label)))), "rui-scrim--center");
    }

    /** Bottom sheet. `build(close)` returns its content. */
    function sheet(build) {
      return modal((close) => h("div", { class: "rui-sheet", role: "dialog", "aria-modal": "true" },
        h("span", { class: "rui-sheet__handle", "aria-hidden": "true" }), build(close)), "rui-scrim--bottom");
    }

    let busyEl = null;
    function busy(on) {
      if (on && !busyEl) {
        busyEl = h("div", { class: "rui-busy", "aria-live": "polite", "aria-busy": "true" }, h("span", { class: "rui-spinner rui-spinner--lg" }));
        overlays.appendChild(busyEl);
      } else if (!on && busyEl) {
        busyEl.remove();
        busyEl = null;
      }
    }

    function closeOverlays() {
      overlays.querySelectorAll(".rui-scrim, .rui-busy").forEach((n) => n.remove());
      busyEl = null;
    }

    // ---- lifecycle ----------------------------------------------------------------------

    const unsubscribe = session.subscribe(() => {
      const top = stack[stack.length - 1];
      if (top) render(top);
    });

    const controller = {
      session,
      nav,
      /** Re-themes and re-renders (template, colors, dark, language...). */
      update(next) {
        opts = { ...opts, ...next };
        if (next.enabledModules) session.setEnabledModules(next.enabledModules);
        theme();
        const top = stack[stack.length - 1];
        if (top) render(top);
      },
      destroy() {
        unsubscribe();
        while (stack.length) dispose(stack.pop());
        root.replaceChildren();
      },
    };

    theme();
    const start = opts.initialRoute || (session.isAuthenticated ? R.Routes.main : R.Routes.login);
    nav.push(start);
    return controller;
  };
})(window);
