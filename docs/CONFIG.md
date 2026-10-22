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
| `appId` | string | `^[a-z][a-z0-9_-]{2,29}$` (normalized: trimmed, lowercase), unique: checked in Firestore (`app_ids/{appId}`) while typing and again, atomically, on submit |
| `configVersion` | int ≥ 1 | assigned by the service: latest + 1 |
| `client.name / email / phone` | string | non-empty; email and phone format-checked (`email` is the primary email) |
| `client.supportEmails` | string[] | optional; unique, each a valid email (older configs without it load as empty) |
| `appName.ar / en` | string | non-empty |
| `android.packageName` | string | `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$` |
| `ios.bundleId` | string | reverse-DNS, e.g. `com.excp.enaya` |
| `templateId` | enum | `simple`, `luxury`, `premium` |
| `templateVersion` | int ≥ 1 | version of the template implementations (currently `2`; required in v2) |
| `modules` | string[] | non-empty subset of `individuals`, `hourly`, `mediation` (required in v2) |
| `branding.primaryColor / secondaryColor` | string | `#RRGGBB` |
| `branding.accentColor` | string | `#RRGGBB`; links, success states, selected items (older configs: `#2E9E5B`) |
| `branding.backgroundColor / textColor` | string | optional `#RRGGBB` overrides of the template page / text colors |
| `branding.fontFamily` | string | non-empty |
| `branding.logoSourceUrl / appIconSourceUrl` | string | optional http(s) link the image was loaded from; the bytes are still stored under `apps/{appId}/v{n}/…` |
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

Images can also be added from a public http(s) link (PNG, JPG, JPEG, SVG, WEBP). They go through the same rules; JPG and WEBP are converted to PNG, and the original link is kept as a reference. The browser downloads the file, so hosts that block cross-origin requests must be uploaded as a file instead.
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

## Request status and the `pipeline.*` fields

This section is about `app_requests/{appId}` (the submitted request, written by
`FirebaseRequestSubmitter`), not the versioned config above. The browser can only
ever create this document; everything described here after that is written by the
Cloud Function (`functions/`) or the Azure Pipeline (`pipeline/`) through the
Admin SDK, which bypasses `firestore.rules`.

`status` lifecycle:

| Status | Set by | Meaning |
|--------|--------|---------|
| `pending` | the wizard (create), or a re-submit of the same App ID | Waiting for the Cloud Function to dispatch a pipeline run. |
| `queued` | the Cloud Function | A run was claimed; `pipeline.queuedAt` is set, `pipeline.runId` / `runUrl` / `error` are cleared. |
| `building` | the pipeline (`request.mjs fetch`) | The pipeline fetched the request and assets and is running; `pipeline.startedAt` is set. |
| `built` | the pipeline (`request.mjs status built`) | The run finished successfully; `pipeline.finishedAt` is set. |
| `failed` | the pipeline (`request.mjs status failed`) | The run failed; `pipeline.finishedAt` is set. |
| `trigger_failed` | the Cloud Function | The request id was invalid, or the Azure DevOps API call to queue a run failed; `pipeline.error` holds the detail. |

Re-submitting an existing App ID puts its document back to `pending`, which
re-enters this lifecycle; a run still `queued` or `building` for the previous
submission is cancelled first.

`pipeline` fields (all optional; none of them exist until the Cloud Function
first claims the request):

| Field | Type | Set by |
|-------|------|--------|
| `pipeline.queuedAt` | timestamp | Cloud Function, on claim |
| `pipeline.runId` | string | Cloud Function, after a run is queued (the Azure DevOps build id) |
| `pipeline.runUrl` | string | Cloud Function, after a run is queued (the run's web link) |
| `pipeline.startedAt` | timestamp | pipeline, in `request.mjs fetch` |
| `pipeline.finishedAt` | timestamp | pipeline, in `request.mjs status built\|failed` |
| `pipeline.error` | string | Cloud Function, when dispatch fails (`trigger_failed`) |

See the root README's "Build pipeline (Azure DevOps)" section for the
dispatch/claim/cancel mechanics and setup steps.
