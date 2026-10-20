# Swift App Builder

**English** · [العربية](README.ar.md)

A Flutter Web tool for configuring **white-label mobile apps for domestic-worker
recruitment offices**. Every generated app runs the same business; only the
branding, enabled service modules and design template differ.

The builder walks a team member through five steps and produces a validated,
versioned JSON configuration that a later pipeline (not part of this repo yet)
will consume to generate the app.

**Live demo:** https://ahmedelkhyary.github.io/swift-app-builder/

## What it does

| Step | Content |
|------|---------|
| 1. App info | App names (ar/en), auto-generated editable app ID, Android package, iOS bundle ID (or "same as Android"), client name / email / phone |
| 2. Visual identity | Inline color picker for primary / secondary / splash colors (HEX, RGB, eyedropper, contrast check, colors extracted from the logo), logo, app icon, splash logo, font |
| 3. Languages | Default language and supported languages (Arabic, English) |
| 4. Templates | Enabled service modules, four design templates, and a **fully interactive phone preview** |
| 5. Summary | Read-only review, formatted JSON, schema validation report, save as a new version, download JSON, version history with "restore as new draft" |

Highlights:

- **Arabic-first, RTL**, with an English toggle. The builder UI is localized with
  ARB files (`lib/l10n`).
- **Interactive preview, not screenshots.** The preview is the real
  `recruitment_ui` app running on mock data: login + OTP, home, and the
  Individuals, Hourly and Mediation flows through payment and success. No SMS,
  payments or bookings are ever real.
- **Templates are themes.** All four templates share the same business logic and
  flows; they differ only in design tokens (cards, headers, buttons, inputs,
  navigation bar, transitions, grid layout).
- **Validated, append-only configs.** Every save creates a new immutable version
  that is checked against `assets/config.schema.json` first. Secrets cannot be
  stored (the schema forbids unknown properties).

## Repository layout

```
lib/
  app/                     router, theme tokens, locale
  l10n/                    ARB files (ar, en) + generated localizations
  features/builder/
    domain/                draft + config models, validators, asset/color tools
    data/                  ConfigRepository, in-memory impl, remote stub
    application/           Riverpod providers, config service, schema validator
    presentation/          wizard shell, step screens, color picker, phone frame
packages/recruitment_ui/   reusable interactive app + templates (see its README)
assets/config.schema.json  JSON Schema of the saved configuration
docs/CONFIG.md             configuration reference
test/                      unit + widget tests
```

Stack: Flutter (web), `flutter_riverpod`, `go_router` (hash URLs), `intl` /
`flutter_localizations`, `google_fonts` (IBM Plex Sans Arabic / Mono, Cairo),
`json_schema`, `image`, `file_picker`.

## Getting started

Requirements: Flutter 3.41+ (Dart 3.11+).

```bash
flutter pub get
flutter run -d chrome
```

Fonts are fetched from Google Fonts at runtime, so the app needs internet access.

### Tests and checks

```bash
flutter analyze
flutter test                              # builder: unit + widget tests
(cd packages/recruitment_ui && flutter test)   # package: flows + screen sweep
```

### Build

```bash
flutter build web --release
```

## Configuration output

A saved configuration looks like this (full reference in
[docs/CONFIG.md](docs/CONFIG.md)):

```json
{
  "schemaVersion": 2,
  "appId": "khidma_recruitment",
  "configVersion": 1,
  "client": { "name": "…", "email": "…", "phone": "…" },
  "appName": { "ar": "الخدمة للاستقدام", "en": "Al Khidma Recruitment" },
  "android": { "packageName": "com.excp.enaya" },
  "ios": { "bundleId": "com.excp.enaya" },
  "templateId": "classic",
  "templateVersion": 1,
  "modules": ["individuals", "hourly", "mediation"],
  "branding": {
    "primaryColor": "#1565C0",
    "secondaryColor": "#FFB300",
    "fontFamily": "Cairo",
    "logo": "apps/khidma_recruitment/v1/logo.png",
    "appIcon": "apps/khidma_recruitment/v1/app_icon.png",
    "splash": { "backgroundColor": "#FFFFFF", "logo": "apps/khidma_recruitment/v1/logo.png" }
  },
  "localization": { "defaultLanguage": "ar", "supportedLanguages": ["ar", "en"] },
  "meta": { "createdAt": "…", "updatedAt": "…", "updatedBy": "…" }
}
```

Assets are stored under `apps/{appId}/v{configVersion}/…` and referenced by path.

## Storage and backend

Data lives **in memory only** and is lost on reload. `ConfigRepository`
(`lib/features/builder/data`) is the seam for a real backend:

- `InMemoryConfigRepository` – the current implementation.
- `RemoteConfigRepository` – a clearly marked stub. A real implementation must
  keep the append-only guarantee and throw `VersionConflictException` when
  `configVersion != latest + 1`.

Swap it by overriding `configRepositoryProvider`.

## Deployment (GitHub Pages)

Pushing to `main` runs `.github/workflows/deploy.yml`: analyze → tests → web build
with `--base-href /<repo>/` → deploy to Pages. The app uses hash URLs
(`/#/builder/info`), so deep links and refresh work on Pages. Enable
**Settings → Pages → Source → GitHub Actions** once.

## Limitations

- No backend yet (in-memory repository) and no CI/CD, Firebase or store-release
  pipeline; those will consume the saved JSON.
- The client is entered as name / email / phone; there is no client list or API.
- Imported JSON files carry no image bytes, so logo and icon must be re-uploaded.
- SVG logos are accepted, but colors can only be extracted from PNG logos.
- Preview strings inside `recruitment_ui` are inline Arabic/English pairs, not ARB.
