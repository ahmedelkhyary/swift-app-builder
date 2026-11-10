/*
 * rui-theme.js: the recruitment_ui templates for plain HTML/CSS/JS.
 *
 * A direct port of `packages/recruitment_ui/lib/src/app_template.dart`
 * (AppTemplate + RuiTokens.resolve) and `color_utils.dart`. Keep the numbers
 * here in sync with those files: a template is the same set of design tokens
 * on every platform, only the rendering differs.
 *
 * Usage:
 *   RuiTheme.apply(document.documentElement, {
 *     templateId: "luxury",
 *     branding: { primaryColor: "#1B4D89", secondaryColor: "#C9A227",
 *                 accentColor: "#2E9E5B", fontFamily: "Cairo" },
 *     dark: false,
 *     lang: "ar",
 *   });
 * `branding` has the same shape as the builder's saved config.
 */
(function (global) {
  "use strict";

  /** Mirrors AppTemplate.simple / .luxury / .premium. */
  const TEMPLATES = {
    simple: {
      id: "simple", nameAr: "البسيط", nameEn: "Simple",
      cornerRadius: 12, typographyScale: 1.0, spacing: 1,
      card: "outlined", header: "solid", button: "flat", grid: "list",
      nav: "line", input: "outlined", transition: "fade",
      palette: "neutral", motion: "none", displayFont: false,
    },
    luxury: {
      id: "luxury", nameAr: "فاخر", nameEn: "Luxury",
      cornerRadius: 20, typographyScale: 1.04, spacing: 1.25,
      card: "luxe", header: "luxe", button: "luxe", grid: "grid2",
      nav: "luxe", input: "luxe", transition: "rise",
      palette: "luxe", motion: "soft", displayFont: true,
    },
    premium: {
      id: "premium", nameAr: "بريميوم", nameEn: "Premium",
      cornerRadius: 22, typographyScale: 1.06, spacing: 1.1,
      card: "glass", header: "hero", button: "gradient", grid: "featured",
      nav: "floating", input: "soft", transition: "scale",
      palette: "vivid", motion: "rich", displayFont: false,
    },
  };
  const TEMPLATE_VERSION = 2; // AppTemplate.version

  // ---- Colors: {r,g,b} in 0..255, a in 0..1 -------------------------------

  const WHITE = { r: 255, g: 255, b: 255, a: 1 };
  const BLACK = { r: 0, g: 0, b: 0, a: 1 };

  function hex(input) {
    const s = String(input || "").trim().replace(/^#/, "");
    if (!/^[0-9a-fA-F]{6}$/.test(s)) return null;
    const n = parseInt(s, 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, a: 1 };
  }

  /** Flutter's Color.lerp: straight (non-premultiplied) component lerp. */
  function lerp(x, y, t) {
    return {
      r: x.r + (y.r - x.r) * t,
      g: x.g + (y.g - x.g) * t,
      b: x.b + (y.b - x.b) * t,
      a: x.a + (y.a - x.a) * t,
    };
  }

  const alpha = (c, a) => ({ ...c, a });

  function css(c) {
    const r = Math.round(c.r), g = Math.round(c.g), b = Math.round(c.b);
    return c.a >= 1 ? `rgb(${r} ${g} ${b})` : `rgb(${r} ${g} ${b} / ${+c.a.toFixed(3)})`;
  }

  /** Color.computeLuminance (WCAG relative luminance). */
  function luminance(c) {
    const ch = (v) => {
      v /= 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  function contrastRatio(a, b) {
    const la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }

  /** Black or white, whichever reads best on `bg` (color_utils.onColorFor). */
  const onColorFor = (bg) =>
    contrastRatio(bg, WHITE) >= contrastRatio(bg, BLACK) ? WHITE : BLACK;

  // ---- Tokens: port of RuiTokens._resolveBase ------------------------------

  const CHAMPAGNE = hex("#E8CE8A");

  function resolveTokens(t, b, dark) {
    const link = dark ? lerp(b.accent, WHITE, 0.2) : b.accent;
    const primary = dark ? lerp(b.primary, WHITE, 0.25) : b.primary;
    const secondary = b.secondary;
    let k;
    switch (t.palette) {
      case "luxe": {
        const ink = lerp(b.primary, BLACK, dark ? 0.92 : 0.84);
        const gold = lerp(secondary, CHAMPAGNE, 0.55);
        k = {
          page: dark ? lerp(b.primary, BLACK, 0.9) : lerp(hex("#FBF8F1"), b.primary, 0.03),
          text: dark ? hex("#F4EEE0") : hex("#1C1710"),
          cardFill: dark ? lerp(b.primary, BLACK, 0.8) : hex("#FFFDF8"),
          cardBorder: alpha(gold, dark ? 0.35 : 0.5),
          chrome: ink,
          onChrome: hex("#F7F1E3"),
          accent: gold,
          focus: alpha(gold, 0.3),
          heroGradient: [ink, lerp(ink, b.primary, 0.45)],
        };
        break;
      }
      case "vivid": {
        const mid = lerp(primary, secondary, 0.55);
        k = {
          page: dark ? lerp(hex("#0D0E13"), primary, 0.08) : lerp(WHITE, primary, 0.06),
          text: dark ? hex("#F1F2F6") : hex("#14161F"),
          cardFill: alpha(WHITE, dark ? 0.07 : 0.72),
          cardBorder: alpha(WHITE, dark ? 0.14 : 0.9),
          chrome: primary,
          onChrome: onColorFor(primary),
          accent: secondary,
          focus: alpha(primary, 0.28),
          heroGradient: [primary, mid, lerp(primary, BLACK, dark ? 0.55 : 0.35)],
        };
        break;
      }
      default: {
        const chrome = dark ? lerp(b.primary, BLACK, 0.45) : b.primary;
        k = {
          page: dark ? hex("#121316") : WHITE,
          text: dark ? hex("#ECEDF0") : hex("#1A1F2E"),
          cardFill: dark ? hex("#1A1B1F") : WHITE,
          cardBorder: dark ? hex("#30323A") : hex("#E6E9F0"),
          chrome,
          onChrome: onColorFor(chrome),
          accent: secondary,
          focus: alpha(primary, 0.18),
          heroGradient: [chrome, lerp(chrome, BLACK, 0.22)],
        };
      }
    }
    k.link = link;
    k.primary = primary;
    k.secondary = secondary;
    // The client's own page / text colors always win (RuiTokens.resolve).
    if (b.background) k.page = b.background;
    if (b.text) k.text = b.text;
    return k;
  }

  function parseBranding(raw) {
    const r = raw || {};
    return {
      primary: hex(r.primaryColor) || hex("#1B4D89"),
      secondary: hex(r.secondaryColor) || hex("#F2A541"),
      accent: hex(r.accentColor) || hex("#2E9E5B"),
      background: hex(r.backgroundColor),
      text: hex(r.textColor),
      fontFamily: (r.fontFamily || "Cairo").trim(),
    };
  }

  // ---- Fonts -----------------------------------------------------------------

  function ensureFonts(families) {
    const id = "rui-fonts";
    const query = families
      .map((f) => `family=${encodeURIComponent(f).replace(/%20/g, "+")}:wght@400;600;700`)
      .join("&");
    const href = `https://fonts.googleapis.com/css2?${query}&display=swap`;
    let link = document.getElementById(id);
    if (link && link.href === href) return;
    if (!link) {
      link = document.createElement("link");
      link.id = id;
      link.rel = "stylesheet";
      document.head.appendChild(link);
    }
    link.href = href;
  }

  // ---- Apply -------------------------------------------------------------------

  /**
   * Writes every token as a CSS custom property on `root` and the template's
   * component variants as data attributes, which `rui.css` styles.
   */
  function apply(root, options) {
    const opts = options || {};
    const t = TEMPLATES[opts.templateId] || TEMPLATES.simple;
    const b = parseBranding(opts.branding);
    const dark = !!opts.dark;
    const lang = opts.lang === "en" ? "en" : "ar";
    const k = resolveTokens(t, b, dark);

    const vars = {
      "--rui-page": css(k.page),
      "--rui-text": css(k.text),
      "--rui-text-muted": css(alpha(k.text, 0.6)),
      "--rui-card-fill": css(k.cardFill),
      "--rui-card-fill-soft": css(alpha(k.cardFill, k.cardFill.a * 0.55)),
      "--rui-card-border": css(k.cardBorder),
      "--rui-chrome": css(k.chrome),
      "--rui-on-chrome": css(k.onChrome),
      "--rui-on-chrome-solid": css(onColorFor(k.chrome)),
      "--rui-accent": css(k.accent),
      "--rui-focus": css(k.focus),
      "--rui-link": css(k.link),
      "--rui-on-link": css(onColorFor(k.link)),
      "--rui-primary": css(k.primary),
      "--rui-on-primary": css(onColorFor(k.primary)),
      "--rui-primary-a07": css(alpha(k.primary, 0.07)),
      "--rui-primary-a10": css(alpha(k.primary, 0.1)),
      "--rui-primary-a16": css(alpha(k.primary, 0.16)),
      "--rui-primary-a22": css(alpha(k.primary, dark ? 0.35 : 0.22)),
      "--rui-primary-a28": css(alpha(k.primary, 0.28)),
      "--rui-primary-a32": css(alpha(k.primary, 0.32)),
      "--rui-primary-a50": css(alpha(k.primary, 0.5)),
      "--rui-secondary": css(k.secondary),
      "--rui-on-secondary": css(onColorFor(k.secondary)),
      "--rui-hero": `linear-gradient(135deg, ${k.heroGradient.map(css).join(", ")})`,
      "--rui-hero-v": `linear-gradient(180deg, ${k.heroGradient.map(css).join(", ")})`,
      "--rui-hero-v-rev": `linear-gradient(180deg, ${k.heroGradient.slice().reverse().map(css).join(", ")})`,
      "--rui-hero-h": `linear-gradient(90deg, ${k.heroGradient.map(css).join(", ")})`,
      "--rui-on-hero": css(onColorFor(k.heroGradient[0])),
      "--rui-card-luxe-end": css(lerp(k.cardFill, k.accent, dark ? 0.06 : 0.1)),
      "--rui-input-fill-outlined": css(lerp(k.cardFill, k.text, dark ? 0.08 : 0.035)),
      "--rui-input-fill-soft": css(dark ? alpha(WHITE, 0.07) : alpha(k.primary, 0.07)),
      "--rui-nav-floating-fill": css(alpha(WHITE, dark ? 0.1 : 0.78)),
      "--rui-shadow-a": dark ? "0.45" : "0.08",
      "--rui-radius": `${t.cornerRadius}px`,
      "--rui-space": String(t.spacing),
      "--rui-type": String(t.typographyScale),
      "--rui-font": `"${b.fontFamily}", system-ui, sans-serif`,
      "--rui-font-display": t.displayFont
        ? `"${lang === "ar" ? "Amiri" : "Playfair Display"}", serif`
        : "var(--rui-font)",
    };
    for (const [name, value] of Object.entries(vars)) root.style.setProperty(name, value);

    const ds = root.dataset;
    ds.ruiTemplate = t.id;
    ds.ruiCard = t.card;
    ds.ruiHeader = t.header;
    ds.ruiButton = t.button;
    ds.ruiGrid = t.grid;
    ds.ruiNav = t.nav;
    ds.ruiInput = t.input;
    ds.ruiTransition = t.transition;
    ds.ruiMotion = t.motion;
    ds.ruiTheme = dark ? "dark" : "light";
    // Any element can be the themed root (the whole page, or a phone-frame
    // preview inside a larger page): it gets its own language and direction.
    root.lang = lang;
    root.dir = lang === "ar" ? "rtl" : "ltr";

    const fonts = [b.fontFamily];
    if (t.displayFont) fonts.push(lang === "ar" ? "Amiri" : "Playfair Display");
    if (opts.loadFonts !== false) ensureFonts(fonts);
    return { template: t, tokens: k };
  }

  // ---- Motion (MotionLevel.rich: staggered reveal, RuiReveal) ----------------

  /** Fades and slides in `[data-rui-reveal]` children, 70 ms apart (max 8 steps). */
  function reveal(container) {
    const themed = container.closest("[data-rui-motion]");
    const rich = !!themed && themed.dataset.ruiMotion === "rich";
    const reduced = global.matchMedia && global.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const items = container.querySelectorAll("[data-rui-reveal]");
    if (!rich || reduced) return;
    items.forEach((el, i) => {
      el.style.setProperty("--rui-reveal-delay", `${Math.min(i, 8) * 70}ms`);
      el.classList.add("rui-reveal-pending");
    });
    // Force the hidden state to apply, then release it so the transition runs.
    void container.offsetWidth;
    setTimeout(() => items.forEach((el) => el.classList.remove("rui-reveal-pending")), 20);
  }

  global.RuiTheme = {
    TEMPLATES,
    TEMPLATE_VERSION,
    apply,
    reveal,
    resolveTokens,
    parseBranding,
    color: { hex, lerp, css, luminance, contrastRatio, onColorFor },
  };
})(window);
