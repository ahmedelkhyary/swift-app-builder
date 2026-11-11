# Design axes of a template

A template is one value per axis below plus a few numbers. These are the
values the three mobile templates use (source of truth:
`packages/recruitment_ui/lib/src/app_template.dart` and `widgets.dart`), and
where the web port styles each value.

## The three existing templates

| Field | `simple` (البسيط) | `luxury` (فاخر) | `premium` (بريميوم) |
|---|---|---|---|
| `cornerRadius` | 12 | 20 | 22 |
| `typographyScale` | 1.0 | 1.04 | 1.06 |
| `spacing` | 1 | 1.25 | 1.1 |
| `card` | `outlined` | `luxe` | `glass` |
| `header` | `solid` | `luxe` | `hero` |
| `button` | `flat` | `luxe` | `gradient` |
| `grid` | `list` | `grid2` | `featured` |
| `nav` | `line` | `luxe` | `floating` |
| `input` | `outlined` | `luxe` | `soft` |
| `transition` | `fade` (180ms) | `rise` (360ms) | `scale` (320ms) |
| `palette` | `neutral` | `luxe` | `vivid` |
| `motion` | `none` | `soft` | `rich` |
| `displayFont` | false | true (Amiri / Playfair Display) | false |
| `supportsPayments` | true | true | true |

Dart enum → web value: `CardStyle.outlined` → `"outlined"`,
`RuiButtonStyle.gradient` → `"gradient"`, `ServiceGridVariant.grid2` →
`"grid2"`, and so on (same names, lower camel case).

## What each value looks like

**card** (RuiCard). `outlined`: flat fill, 1px border, soft 0/3/10 shadow;
selected = 1.5px primary border. `luxe`: vertical gradient cardFill → 10%
accent, hairline border, 0/9/22 shadow that lifts to 0/14/30 on hover;
selected = 1.6px accent border. `glass`: translucent gradient, blur(14px),
1.2px border, primary-tinted shadow, scale(1.015) on hover; selected = 2px
primary.

**header** (RuiHeader). `solid`: flat `chrome` color, title centered when
there is no avatar. `luxe`: vertical `heroGradient`, 1.2px accent bottom
border, accent subtitle, round logo with accent ring. `hero`: diagonal
`heroGradient`, rounded bottom corners (26, 34 when large), primary shadow,
two translucent decorative discs.

**button** (RuiButton). `flat`: radius min(cornerRadius, 10), 46px, primary
fill; the secondary action is a filled *secondary* button. `luxe`: radius
14, 52px, bold, chrome fill with accent text (inverted in dark); secondary =
accent-outlined. `gradient`: pill, 52px, bold, `heroGradient` fill, primary
glow, lifts 2px on hover; secondary = outlined.

**grid** (Home categories). `list`: one horizontal tile per row. `grid2`:
two columns, aspect 1.3. `featured`: first tile full width (108px), the rest
in one row (140px).

**nav** (RuiNavBar). `line`: page-colored bar, 2px primary line over the
selected item. `luxe`: reversed vertical `heroGradient`, accent top border,
accent selected item with an 18px underline. `floating`: detached pill with
blur, selected item becomes a gradient pill showing its label.

**input** (InputDecorationTheme). `outlined`: radius 10, faint fill, 1px
border, 1.5px primary on focus. `luxe`: radius 14, card fill, focus border
chrome (accent in dark). `soft`: radius 18, primary-tinted fill, no border,
2px primary on focus.

**palette** (RuiTokens.resolve). `neutral`: white / near-black pages, brand
color only for chrome and actions. `luxe`: deep ink = primary mixed 84%
(92% dark) toward black, gold = secondary mixed 55% toward champagne
`#E8CE8A`. `vivid`: brand-tinted page (6% primary), translucent white cards,
3-stop `heroGradient` primary → primary/secondary mix → dark primary.

**motion**. `none`: page transition only. `soft`: transitions + hover lift.
`rich`: staggered reveal (70ms steps, max 8), Home skeleton (650ms), peeking
banner carousel (88% width, scale 0.93 off-center), floating "Order now"
button.

## Where the web port styles each axis

Every value is selected by a data attribute that `RuiTheme.apply()` writes
on the themed root: `data-rui-card`, `-header`, `-button`, `-grid`, `-nav`,
`-input`, `-transition`, `-motion`, `-palette`, `-theme` (light/dark),
`-template` (id). Use `data-rui-palette` for palette-specific touches that no
token covers, e.g. `calm` tones down the mock banner / featured colors,
which come from data and not from the brand.

Fixed radii that are not tokens follow the template through `min()` /
`clamp()` of `var(--rui-radius)` (outlined inputs, notices, login logo and
sheet), so a sharp template gets sharp corners everywhere without new axis
values. Do the same for any fixed radius you meet.

To see everything a value controls, grep it, for example:

```bash
grep -n 'data-rui-card="luxe"' web-templates/recruitment-ui/rui.css web-templates/recruitment-ui/app/app.css
```

| Axis | Base rules (`rui.css`) | Extra rules (`app/app.css`) | JS branches |
|---|---|---|---|
| card | Card section | select-tile mark, chips, tabs, dialog/sheet fill (glass), banners, featured cards, dots, price | `screens/main.js` `bannerVars()` |
| header | Header section, section-title marker | — | `app/core.js` `header()` (centering for `solid`) |
| button | Buttons section | text button color (luxe) | — |
| grid | Service grid section | — | `screens/main.js` `categories()` (`list` = horizontal tiles) |
| nav | Bottom navigation section | shell layout for `floating` | `screens/main.js` (filled icons except `line`) |
| input | Inputs section | — | — |
| transition | Screen transitions | — | — |
| motion | Motion section | banners, FAB | `screens/main.js` (skeleton, carousel scale, FAB) |
| palette | — | Palettes section (`data-rui-palette`) | `rui-theme.js` `resolveTokens()` |

## Web-only templates

| Id | Name | Values |
|---|---|---|
| `modern` | عصري / Modern | radius 4, spacing 1.1, `outlined` / `solid` / `flat` / `grid2` / `line` / `outlined` / `fade`, palette `calm` (brand muted toward slate `#5B6574`, also softens `primary` / `secondary`), motion `soft`. Not in `app_template.dart` or `config.schema.json`. |
| `jadara` | جدارة / Jadara | From the Enaya/Ajel design. radius 16, spacing 1.1, card **`soft`**, header **`plain`**, button **`pill`**, `grid2` / `line` / input `soft` / `fade`, palette `neutral`, motion `soft`. Not in Flutter / schema. |

### Web-only axis values

These exist only in the web CSS (no Dart enum yet); reuse them freely.

- **header `plain`**: page-colored bar, text-colored title (centered when
  there is no avatar, like `solid`), round `primary-a10` icon buttons and
  avatar. `app/core.js` `header()` treats it like `solid` for centering.
- **card `soft`**: white, borderless, `0 4px 18px` soft shadow (border in
  dark); selected = 6% primary tint + 30% primary border; service icons,
  list leading icons and avatars sit in a light rounded square.
- **button `pill`**: solid primary capsule (50px, bold); secondary = light
  outlined capsule with primary text.

## Token contract (what a palette must produce)

`resolveTokens(template, brand, dark)` returns, for every brand and both
brightnesses: `page`, `text`, `cardFill`, `cardBorder`, `chrome`, `onChrome`,
`accent`, `focus`, `heroGradient` (2 or 3 colors), `link`, `primary`,
`secondary`. `apply()` turns them into the `--rui-*` custom properties
(`--rui-page`, `--rui-chrome`, `--rui-on-hero`, `--rui-hero`, `--rui-hero-v`,
`--rui-hero-h`, `--rui-primary-a10` ... ; full list in `apply()`), and the
on-colors are always computed with `onColorFor()` (WCAG contrast), never
hard-coded. The client's own `backgroundColor` / `textColor` override
`page` / `text` after the palette runs.
