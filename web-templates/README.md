# Web templates (plain HTML / CSS / JS)

The web counterpart of `packages/recruitment_ui`: the same three templates
(Simple, Luxury, Premium) for a regular website, with no framework and no
build step. Same idea as the Flutter package: a template is a set of design
tokens, not a separate app, so one page renders in all three.

```
web-templates/
  recruitment-ui/      the package (use it on any page)
    rui-theme.js       templates + token resolution (port of app_template.dart, color_utils.dart)
    rui.css            the components, one rule set per template variant (port of widgets.dart)
  wizard/
    index.html         builder-style page: settings panel + the app in a phone frame
```

## The package

`RuiTheme.apply(root, options)` turns a template id + brand colors into
`--rui-*` CSS variables and `data-rui-*` attributes on `root`. `root` is
`<html>` for a full page, or any element (the wizard themes only the phone
screen and leaves the rest of the page alone).

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined&display=block">
<link rel="stylesheet" href="recruitment-ui/rui.css">
<script src="recruitment-ui/rui-theme.js"></script>
<script>
  RuiTheme.apply(document.documentElement, {
    templateId: config.templateId,   // "simple" | "luxury" | "premium"
    branding: config.branding,       // the builder's saved config, as is
    dark: false,
    lang: "ar",                      // also sets dir="rtl" / "ltr" on root
  });
</script>
```

Markup uses the component classes only: `rui-header`, `rui-card`
(`rui-card--tap`, `rui-card--selected`), `rui-btn` (`rui-btn--secondary`),
`rui-input`, `rui-section-title`, `rui-services` / `rui-service`, `rui-nav` /
`rui-nav__item`, `rui-skeleton`, and `data-rui-reveal` for the staggered
reveal (`RuiTheme.reveal(container)`).

Layout hooks: `--rui-safe-top` / `--rui-safe-bottom` reserve room for a
status bar and home indicator (the wizard's phone frame sets them).

## The interactive app (`recruitment-ui/app/`)

The whole prototype of `RecruitmentApp`, with mock data only (no SMS,
payment or booking is real): login + OTP, Home (banners, featured services,
categories, reviews, partners, contact), Orders, Account, and the
Individuals, Hourly and Mediation flows through contract, payment and success.

| File | Port of |
|------|---------|
| `app/repository.js` | `demo/repository.dart`: mock data, pricing, discount codes |
| `app/session.js` | `demo/session.dart`: all state and business rules |
| `app/core.js` | `ui/app.dart` + `widgets.dart`: navigator with the template's page transition, widgets, dialogs/sheets/snack |
| `app/app.css` | styles of those widgets, per template |
| `app/screens/*.js` | `ui/*_screens.dart`, one file per flow |

```js
const app = RuiApp.mount(element, { templateId, branding, dark, lang });
app.update({ templateId: "luxury" }); // re-theme, state is kept
app.session.jumpTo("hourly");         // "login" | "home" | "individuals" | "hourly" | "mediation"
```

Load order: `rui-theme.js`, `app/repository.js`, `app/session.js`,
`app/core.js`, then the screen files (see `wizard/index.html`).

## The wizard

Open `wizard/index.html` in a browser. Deep links:
`?template=luxury&dark=1&lang=en&device=android`.

## Keeping it in sync with Flutter

The numbers (radii, spacing, color mixes, shadows) are copied from the Dart
files above. When a template changes there, change it here too and bump
`TEMPLATE_VERSION` alongside `AppTemplate.version`.
