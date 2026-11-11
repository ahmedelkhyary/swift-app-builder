---
name: add-web-template
description: Add a new design template (theme) to the web port of the recruitment app in web-templates/ (plain HTML/CSS/JS), or change how an existing template looks. A template only changes how components look (palette, cards, header, buttons, inputs, nav, grid, motion); the business logic, screens, steps and data stay fixed. Use when asked to add, create, design or modify a template / theme / قالب / ثيم for the web version, to port a new mobile template to the web, or to make a template look like a given design.
---

# Add a web template

The web port in `web-templates/` mirrors the Flutter package
`packages/recruitment_ui`. In both, **a template is a set of design tokens,
not a separate app**: every template runs the same screens, the same flows
and the same rules, and differs only in how components are drawn. Keep it
that way.

Read `references/design-axes.md` first: it lists every axis, the values the
three existing templates (`simple`, `luxury`, `premium`) use, what each value
looks like, and where it is styled.

## What never changes for a template

Do not edit these to add or restyle a template:

- `web-templates/recruitment-ui/app/session.js`: state, rules, pricing use.
- `web-templates/recruitment-ui/app/repository.js`: mock data, prices, codes.
- `web-templates/recruitment-ui/app/screens/*.js`: screens, steps, order of
  steps, validation, texts, `data-key` names (the e2e test relies on them).
- Routes (`RuiApp.Routes`) and the navigator in `app/core.js`.

If a new look seems to need a different DOM, solve it in CSS first (layout,
`::before` / `::after`, `display`, `order`, grid). Only if that is
impossible, add a branch on `ctx.template.<axis>` in a widget builder of
`app/core.js`, never in business code, and keep the same elements, keys and
behavior in every branch.

## What a template is made of

1. **One entry in `TEMPLATES`** in `web-templates/recruitment-ui/rui-theme.js`
   with every field: `id`, `nameAr`, `nameEn`, `cornerRadius`,
   `typographyScale`, `spacing`, `card`, `header`, `button`, `grid`, `nav`,
   `input`, `transition`, `palette`, `motion`, `displayFont`.
2. **Its axis values.** Each one either reuses an existing value (no CSS
   needed) or is a new value (needs CSS, see step 4).
3. **A palette**: an existing one, or a new `case` in `resolveTokens()`.

A template made only of existing values is a few lines in `TEMPLATES`. Prefer
that whenever it gives the requested look.

## Steps

### 1. Pin down the design, then confirm it

From the request (or the design / screenshot / description given), fill one
row per axis: reuse an existing value, or describe the new one. Also decide
the radius, spacing, type scale, display font and palette. Show this table
to the user and get a yes before writing code. It is the whole design
decision; everything after it is mechanical.

### 2. Register the template

Add the entry to `TEMPLATES` in `rui-theme.js`. Ids are lowercase ASCII
(`[a-z][a-z0-9_-]*`), names are given in Arabic and English. The wizard
(`web-templates/wizard/index.html`) builds its template cards from
`TEMPLATES` automatically; add a one-line Arabic description for the new id
to its `DESCRIPTIONS` map.

### 3. New palette (only if needed)

Add a `case` to `resolveTokens()` in `rui-theme.js` that returns **every**
token of the contract in `references/design-axes.md`, for light **and** dark.
Rules the existing palettes follow, keep them:

- Derive everything from the brand colors (`b.primary`, `b.secondary`,
  `b.accent`) with `lerp()` / `alpha()`. Fixed hex values only for neutrals.
- `link` is always the client's accent; do not override it.
- On-colors (`onChrome` and the ones `apply()` computes) come from
  `onColorFor()`, so text stays readable for any brand color.
- Do not touch the code after the `switch`: the client's
  `backgroundColor` / `textColor` must keep winning.
- If you add a token, also add its `--rui-*` variable in `apply()`.

### 4. CSS for each new axis value (only if needed)

For every axis that gets a new value `X`:

1. Find everything the closest existing value styles:
   `grep -n 'data-rui-<axis>="<closest>"' web-templates/recruitment-ui/rui.css web-templates/recruitment-ui/app/app.css`
2. Write the same set of rules for `[data-rui-<axis>="X"]`, next to the
   existing ones (base components in `rui.css`, app widgets in
   `app/app.css`). Cover every match, or that component falls back to the
   unstyled base in the new template.
3. Check the JS branches listed in the reference table (`screens/main.js`
   banner gradients and Home motion, `app/core.js` header). A new value
   takes the `default` branch there; make sure that looks right.

CSS rules:

- Colors only through `var(--rui-*)` tokens or `color-mix()` of them. No
  hard-coded brand colors.
- Logical properties (`inset-inline-start`, `padding-inline`,
  `margin-inline-end`): every screen runs RTL (Arabic) and LTR (English).
- Dark mode: add `[data-rui-theme="dark"]` overrides where light-only values
  were used.
- Motion: anything animated must stop under `prefers-reduced-motion`
  (`rui.css` already disables animations and transitions globally there; do
  not override that with `!important`).
- Keep focus rings visible (`:focus-visible` with `var(--rui-focus)`).
- Sizes in `px` × `var(--rui-space)` / `var(--rui-type)` where the existing
  rules do the same.

### 5. Mobile parity

The Flutter package is the source of truth for the three existing templates.
Ask the user whether the new template must also exist in the mobile app and
the builder. If yes (or if it came from the mobile app), these must match
the web values exactly:

- `packages/recruitment_ui/lib/src/app_template.dart`: a new `AppTemplate`
  constant, added to `AppTemplate.all`; new enum values and their `switch`
  cases (tokens, theme, `widgets.dart`) for any new axis value.
- Builder: name in `lib/features/builder/presentation/l10n_ext.dart`,
  description in `template_section.dart` and the ARB files `lib/l10n/`.
- `assets/config.schema.json` `templateId` enum and `docs/CONFIG.md`.
  Without this, the builder's schema validation rejects the new id.
- Bump `AppTemplate.version` and `TEMPLATE_VERSION` in `rui-theme.js`
  together whenever an existing template's look changes.

If the template is web-only, say so in the report, including that the
builder cannot save a config with that id until the schema allows it.

### 6. Verify

1. Run every flow in the new template (and the old ones, to catch CSS that
   leaked):

   ```bash
   "/c/Program Files/Google/Chrome/Application/chrome.exe" --headless=new --disable-gpu \
     --allow-file-access-from-files --virtual-time-budget=150000 \
     --dump-dom "file:///D:/AzureApps/swiftAppBuilder/web-templates/tests/e2e.html?templates=<id>" \
     2>/dev/null | sed -n '/<pre id="log">/,/<\/pre>/p'
   ```

   It must end with `RESULT: PASS` and `errors: []`. Then run it without
   `?templates=` for all templates.
2. Screenshot the wizard at 1280×860 with deep links
   `wizard/index.html?template=<id>&entry=<login|home|individuals|hourly|mediation>`,
   plus `&dark=1`, `&lang=en` and `&device=android`, and look at each image:
   readable text on every surface, nothing cut off, RTL mirrored correctly.
3. Compare against the other templates on the same screens: only the look
   may differ, never the content or the steps.

### 7. Report

List the axis table, the files changed, the e2e result, which screenshots
were checked, and whether mobile parity was done or left out.
