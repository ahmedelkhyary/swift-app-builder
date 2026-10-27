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
| 1. App info | App names (ar/en), auto-generated editable app ID, Android package, iOS bundle ID (or "same as Android"), client name / primary email / phone, optional support emails (chips) |
| 2. Visual identity | Inline color picker for primary / secondary / splash colors (HEX, RGB, eyedropper, contrast check, colors extracted from the logo), logo, app icon, splash logo, font |
| 3. Languages | Default language and supported languages (Arabic, English) |
| 4. Templates | Enabled service modules, three design templates — Simple, Luxury and Premium (tick several and **compare** them side by side), and a **fully interactive phone preview** |
| 5. Summary | Read-only review, formatted JSON, schema validation report, save as a new version, download JSON, version history with "restore as new draft" |

Highlights:

- **Arabic-first, RTL**, with an English toggle. The builder UI is localized with
  ARB files (`lib/l10n`).
- **Interactive preview, not screenshots.** The preview is the real
  `recruitment_ui` app running on mock data: login + OTP, home, and the
  Individuals, Hourly and Mediation flows through payment and success. No SMS,
  payments or bookings are ever real.
- **Templates are themes.** All three templates share the same business logic and
  flows; they differ only in design tokens (palette, cards, headers, buttons,
  inputs, navigation bar, transitions, motion, grid layout). **Simple** is flat
  and light, **Luxury** uses dark ink with champagne-gold accents and serif
  headings, **Premium** adds glass surfaces, gradients, staggered animations,
  skeleton loading and a floating quick-order button (light and dark mode).
  Colors come from the Step 2 brand colors through theme tokens.
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
  "templateId": "simple",
  "templateVersion": 2,
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

## Submitting a request (Firebase)

Step 5 ends with **Submit request**: the wizard is stored in Firestore as
`app_requests/{appId}` (`status: pending`, `createdAt` / `updatedAt` server timestamps)
and the logo / app icon are uploaded to Storage under `app_requests/{appId}/`; the
document holds their download URLs. If a request with that App ID already exists the user
must confirm updating it (`createdAt` is kept).

Setup: the app uses `lib/firebase_options.dart` (created by `flutterfire configure`). To point a build at another project, copy `.env.example` to `.env` and run with `--dart-define-from-file=.env` (optional; the same keys can be GitHub secrets). Enable Firestore and Storage in the console and deploy `firestore.rules` and `storage.rules` — note this replaces the project's existing rules. The Firebase code lives in `lib/firebase.dart`.

## Build pipeline (Azure DevOps)

Once a request is saved (`status: "pending"`), a Cloud Function dispatches an
Azure DevOps pipeline run with only the request id; the pipeline reads
everything else itself. This repo stops at "the pipeline has the request data
and assets on disk" — generating the app and building it for the stores is a
placeholder step in `pipeline/azure-pipelines.yml`, not part of this repo yet.

```
Flutter app ─▶ Firestore app_requests/{id} (status: pending)
       │                       ▲
       │ POST {requestId}      │ also polled every 5 min
       ▼                       │ (sweepPendingAppRequests, a safety net
  functions/: dispatchAppRequest ──▶ Azure DevOps REST API   for a dropped POST)
                                        (queue a run)
                        │
                        ▼
      pipeline/azure-pipelines.yml ─▶ pipeline/scripts/request.mjs
        (fetch: reads the doc + downloads assets to build_input/,
         then — once a generator exists — builds, then reports status back)
```

Not a Firestore *trigger*: this project's Firestore database can live in a
region Cloud Functions 2nd gen doesn't support running in (a background
Firestore trigger must run in the same region as its database), so the app
calls `dispatchAppRequest` directly right after writing the "pending" document,
and `sweepPendingAppRequests` (Cloud Scheduler, every 5 minutes) is a safety
net for a call that never arrives (closed tab, dropped connection). Both live
in `us-central1`, independent of whatever region Firestore itself is in.

See [`docs/CONFIG.md`](docs/CONFIG.md#request-status-and-the-pipeline-fields)
for the `status` lifecycle and the `pipeline.*` fields this writes back onto
the request document.

### Setup

1. **Blaze plan.** The Cloud Functions (`functions/`) need outbound network
   access (to call Azure DevOps), which requires the Blaze (pay-as-you-go) plan.
2. **Cloud Function config.** In `functions/`:
   - Copy `functions/.env.example` to `functions/.env` and fill in `AZDO_ORG`,
     `AZDO_PROJECT` and `AZDO_PIPELINE_ID` (not secret, but project-specific).
   - Set the Azure DevOps PAT (scope: **Build: Read & execute**) as a secret:
     `firebase functions:secrets:set AZDO_PAT`.
   - Deploy: `cd functions && npm install && firebase deploy --only functions`.
   - **If the deploy fails on a build or permission error:** some projects
     don't auto-grant IAM roles to the default service account anymore. Grant
     `{project-number}-compute@developer.gserviceaccount.com` (Console → IAM)
     the roles **Cloud Build Service Account**, **Artifact Registry Writer**
     and **Cloud Datastore User**, then redeploy.
   - **Payment keys (Secret Manager).** The wizard's "Payment methods" step
     stores gateway secrets with `savePaymentSecrets` in Google Secret Manager
     (see [`docs/CONFIG.md`](docs/CONFIG.md#payment-methods-payments-and-secrets)).
     Enable the **Secret Manager API** in the GCP project and grant the
     functions' service account
     (`{project-number}-compute@developer.gserviceaccount.com`) the role
     **Secret Manager Admin** (it creates secrets and adds versions). The
     `paymentGateways` function (connection test) needs no extra role.
3. **Azure DevOps pipeline.** Create a pipeline from `pipeline/azure-pipelines.yml`
   (see below for keeping `pipeline/` here vs. a separate Azure Repos repo),
   with `trigger: none` / `pr: none` so it only ever runs via the REST API.
   - **Secure file:** upload a Firebase service-account JSON key as
     `firebase-service-account.json` (Pipelines → Library → Secure files). Grant
     it the roles **Cloud Datastore User** and **Storage Object Viewer** in the
     Firebase/GCP project's IAM.
   - **Variable group:** create `swift-app-pipeline` (Pipelines → Library →
     Variable groups) with `FIREBASE_STORAGE_BUCKET` set to the project's bucket.
   - **First manual run:** queue the pipeline once by hand (Run pipeline, with
     any `requestId`) — this is what prompts Azure DevOps to let the pipeline
     use the secure file and the variable group; later REST-triggered runs then
     go through without approval.
4. Note the pipeline id (from its URL or `az pipelines list`) for
   `AZDO_PIPELINE_ID` in step 2.

### Confirmation email (Azure DevOps pipeline 55)

Right after a request is **created** (not on a re-submit), the app also calls
`triggerConfirmationEmail`, which queues pipeline 55 (already set up in Azure
DevOps — its YAML isn't part of this repo) with just the request id; the
pipeline reads the rest from the document itself. Idempotent on
`email.queuedRunId` (see
[`docs/CONFIG.md`](docs/CONFIG.md#the-emailfields) for the `email.*` fields),
and a failure here never affects the submission or the build pipeline. Set
`EMAIL_PIPELINE_ID=55` in `functions/.env`, then deploy with the same command
as the rest of `functions/`: `cd functions && firebase deploy --only functions`.

### `pipeline/` location

`pipeline/` lives in this repo by default. To move it to a separate Azure Repos
repository instead: copy `pipeline/azure-pipelines.yml` and
`pipeline/scripts/` there, point the Azure DevOps pipeline's YAML path at the
new location, and update `AZDO_PIPELINE_ID` if the pipeline is recreated.

## Storage and backend

Data lives **in memory only** and is lost on reload. `ConfigRepository`
(`lib/features/builder/data`) is the seam for a real backend:

- `InMemoryConfigRepository` – used for the app-ID check and "load existing".
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

- The wizard's own draft/version storage is in-memory only (see "Storage and
  backend" below); Firebase handles submitted requests, and an Azure DevOps
  pipeline is dispatched for each one (see "Build pipeline" above) — but that
  pipeline stops once the request data and assets are on disk. There is no app
  generator or store-release build yet. See
  [`docs/PHASE2_PROGRESS.md`](docs/PHASE2_PROGRESS.md) for the pipeline's
  current state, open conflicts and next steps.
- The client is entered as name / email / phone; there is no client list or API.
- Imported JSON files carry no image bytes, so logo and icon must be re-uploaded.
- SVG logos are accepted, but colors can only be extracted from PNG logos.
- Preview strings inside `recruitment_ui` are inline Arabic/English pairs, not ARB.
