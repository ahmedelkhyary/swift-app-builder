# recruitment_ui

The interactive, fully mocked app prototype shared by the **App Builder preview**
and (later) the generated mobile apps. Pure Flutter, no web-only imports, no
builder-specific code, no state-management dependency.

## What's inside

```dart
RecruitmentApp(
  session: session,          // all state; survives rebuilds and template switches
  template: AppTemplate.modern,
  branding: BrandingConfig(primaryColor: …, secondaryColor: …, logo: …),
  languageCode: 'ar',        // 'ar' (RTL) or 'en'
  brightness: Brightness.light,
)
```

- **`RecruitmentApp`** – a nested `Navigator` with every screen: login, OTP, home
  (slider, featured services, categories, reviews, partners, contact), orders,
  account, and the three flows below. Dialogs and sheets open *inside* the app
  (never over the host page).
- **`DemoSession`** (`ChangeNotifier`) – the single source of truth: auth, saved
  addresses, each flow's selections, contract forms, discount, payment method,
  created orders. Changing an upstream selection (e.g. nationality) invalidates
  dependent ones (the selected worker).
- **`AppTemplate`** – design tokens, not separate apps: `classic`, `modern`,
  `minimal`, `premium`. Tokens: corner radius, card style, elevation, typography
  scale, header style, button style, service-grid variant, nav-bar style, input
  style, page transition. `AppTemplate.version` is the template implementation
  version the project generator maps to.
- **`BrandingConfig`** – colors, font, names, optional logo (PNG or SVG bytes).
- **`DemoRepository` / `MockDemoRepository`** – the backend surface (mock data,
  OTP, payment simulation, order references). Replace it in production apps.
- **`PricingRules` / `DiscountRules`** – all demo pricing in one place.

## Flows

| Flow | Screens |
|------|---------|
| Individuals | address → packages & nationality → workers → worker details → contract → payment → success |
| Hourly | address → fixed or custom package → details (start date, service days, discount code) → payment → success |
| Mediation | profession & nationality → packages → browse **or** search by name → worker details → contract → payment → success |

Address, worker details, contract, payment and success are shared by the flows.

## Demo behavior

- Login accepts any valid Saudi mobile number (`5xxxxxxxx`); the **OTP is `123456`**.
  No SMS is sent. Biometric login is a simulated dialog; no device API is called.
- Discount codes: `DEMO10` (10%), `SAVE50` (50 SAR off, minimum 300), `EXPIRED20` (expired).
- Payment is simulated. A toggle on the payment screen forces a failure, and the
  wallet fails above 5000 SAR. An order exists only after a successful payment.
- Everything is clearly demo data; nothing is sent anywhere.

## Embedding notes

- The host needs Material/Widgets localization delegates (any locale).
- Use `DemoSession.jumpTo(DemoEntry.…)` to open Login, Home or a flow without
  completing earlier steps, `session.reset()` to restart, and
  `session.currentEntry` to know which area is visible.
- `topInset` reserves space at the top (device cutouts); `showDemoBanner`
  toggles the in-screen "demo" strip.
- Tests can set `AppTemplate.useGoogleFonts = false` and use
  `MockDemoRepository(latency: Duration.zero)`.

## Tests

```bash
flutter test
```

`flows_test.dart` drives the real UI through login, all three flows (including
validation, failed payments and back-navigation persistence) and sweeps every
screen of every template in Arabic/English and light/dark to catch layout errors.
