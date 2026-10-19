# Configuration reference

The builder produces one JSON document per saved version. It is validated
against [`assets/config.schema.json`](../assets/config.schema.json) before
saving. The schema sets `additionalProperties: false` everywhere, so unknown
fields (including anything that looks like a secret) are rejected.

**Never put secrets here** — payment keys, signing keys, API tokens.

## Fields

| Path | Type | Rules |
|------|------|-------|
| `schemaVersion` | int | `2` (version `1` documents are still read and validate) |
| `appId` | string | `^[a-z][a-z0-9_]{2,39}$`, unique across apps |
| `configVersion` | int ≥ 1 | assigned by the service: latest + 1 |
| `client.name / email / phone` | string | non-empty; email and phone format-checked |
| `appName.ar / en` | string | non-empty |
| `android.packageName` | string | `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$` |
| `ios.bundleId` | string | reverse-DNS, e.g. `com.rose.store` |
| `templateId` | enum | `classic`, `modern`, `minimal`, `premium` |
| `templateVersion` | int ≥ 1 | version of that template implementation (required in v2) |
| `modules` | string[] | non-empty subset of `individuals`, `hourly`, `mediation` (required in v2) |
| `branding.primaryColor / secondaryColor` | string | `#RRGGBB` |
| `branding.fontFamily` | string | non-empty |
| `branding.logo / appIcon` | string | storage path `apps/{appId}/v{n}/…` |
| `branding.splash.backgroundColor` | string | `#RRGGBB` |
| `branding.splash.logo` | string | storage path (same as `logo` when no dedicated splash logo) |
| `localization.defaultLanguage` | enum | `ar` or `en`, must be in `supportedLanguages` |
| `localization.supportedLanguages` | enum[] | unique, non-empty |
| `meta.createdAt / updatedAt / updatedBy` | string | ISO-8601 timestamps; `createdAt` is kept from version 1 |

The "default language is supported" rule cannot be expressed in JSON Schema, so
it is checked in code (`ConfigSchemaValidator`) right after the schema.

## Assets

Uploaded files are stored per version under `apps/{appId}/v{configVersion}/`:

| File | Rules |
|------|-------|
| `logo.png` / `logo.svg` | PNG or SVG, ≤ 2 MB, at least 512×512 (SVG: when it declares a size) |
| `app_icon.png` | PNG, exactly 1024×1024, fully opaque |
| `splash_logo.*` | optional; same rules as the logo |

## Versioning

- Each save appends a new immutable version (`configVersion` = latest + 1).
- A repository must reject non-sequential versions (`VersionConflictException`).
- Old versions are never modified. "Restore as new draft" loads a version into
  the form; saving it creates a *new* version.

## Template ↔ generator contract

`templateId` + `templateVersion` identify a concrete implementation in
`packages/recruitment_ui`. Bump `AppTemplate.version` when a template's behavior
changes so already-saved configs keep pointing at what they were built with.
`modules` tells the generated app which service flows to include.
