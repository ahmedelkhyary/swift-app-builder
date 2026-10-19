# Swift App Builder

Flutter Web tool for configuring white-label recruitment apps (domestic-worker
offices): a 5-step wizard (App info, Branding, Languages, Templates, Summary)
with a fully interactive phone preview, producing a validated, versioned JSON
configuration.

- `lib/` – the builder (Riverpod + go_router, ARB localization ar/en, RTL first)
- `packages/recruitment_ui` – the reusable interactive app prototype and the
  four design templates (shared with the generated mobile apps)
- `assets/config.schema.json` – JSON Schema every saved config is validated against

Data is in memory only (a stub `RemoteConfigRepository` marks where the real
backend plugs in). The preview uses mock data: no real SMS, payments or bookings.

## Run

```
flutter pub get
flutter run -d chrome
```

## Test

```
flutter analyze
flutter test
(cd packages/recruitment_ui && flutter test)
```

## Deploy

Pushing to `main` builds and publishes to GitHub Pages
(`.github/workflows/deploy.yml`). In the repository settings, set
**Pages → Source → GitHub Actions** once.
