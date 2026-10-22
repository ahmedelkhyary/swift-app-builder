# Phase 2 progress: the Azure DevOps build pipeline

Status snapshot as of **2026-10-22**. This file plus the repo should be enough
to resume Phase 2 without any other context. It records two things that don't
fully agree yet (see the conflict section right below) — read that first.

## Goal

After the builder saves a request to Firestore, an external build pipeline
starts automatically. It receives only the request id and fetches the request
data and assets from Firebase itself. Later it will generate and build the
white-label app (not started — see "Next steps").

## ⚠ Unresolved conflicts — read before continuing

Two different descriptions of "the current design" exist and don't fully
agree. The most recent direction says the points below describe a newer,
more-evolved setup done outside this repo/session (e.g. directly in Azure
DevOps) — but the first point is a verified technical fact from *this* repo's
own deploy history, not a preference, so it needs checking before anyone
relies on the dispatch mechanism described further down.

1. **Dispatch mechanism.** This session deployed and load-tested a Cloud
   Function trigger design twice:
   - First as `onDocumentWritten` (a Firestore background trigger) — this
     **failed twice with HTTP 403s** when deploying to `swift-saas-5ac3a`,
     because that project's Firestore database lives in `me-central2` and
     Cloud Functions 2nd gen cannot deploy into that region at all. A
     Firestore background trigger must run in the same region as its
     database, so this is a hard platform limitation, not a config mistake.
   - It was then rebuilt as a direct HTTPS call (`dispatchAppRequest`) made
     by the Flutter app right after the Firestore write, plus a scheduled
     sweep (`sweepPendingAppRequests`, every 5 minutes) as a safety net. Both
     deploy and run successfully in `us-central1` as of this writing —
     verified with a live test call.
   - **If the newer direction still calls for `triggerAppBuild` /
     `onDocumentWritten`**, it can only work if the Firestore database has
     since moved out of `me-central2` (or Cloud Functions added support for
     that region). Check `firebase firestore:databases:list --project
     swift-saas-5ac3a` before building that trigger again — otherwise reuse
     the already-working `dispatchAppRequest` / `sweepPendingAppRequests`
     design (`functions/src/index.ts`, `functions/src/dispatch.ts`).
2. **Azure DevOps project / pipeline id.** `functions/.env` in this repo
   already has concrete values (`AZDO_ORG=ExProtectionProduects`,
   `AZDO_PROJECT=Common Project`, `AZDO_PIPELINE_ID=54`) set during this
   session, and `dispatchAppRequest` is deployed and live with them. A more
   recent note says the project name and pipeline id "still have to be filled
   in," which would mean a *different* Azure DevOps project/pipeline than the
   one already wired up. Confirm which org/project/pipeline is actually
   authoritative before changing `functions/.env` — changing it without
   redeploying would silently leave the live function pointed at the old one.
3. **Pipeline location and shape.** This repo has a committed
   `pipeline/azure-pipelines.yml` + `pipeline/scripts/request.mjs` that check
   out this repo and use a dedicated variable group (`swift-app-pipeline`,
   holding `FIREBASE_STORAGE_BUCKET`). A more recent note describes a
   different, standalone design instead: a tiny separate Azure repo holding
   only `azure-pipelines.yml`, `checkout: none`, the helper script written
   inline by the YAML at runtime, no variable group (removed after a
   "variable group not found" error), and the bucket hardcoded in the YAML.
   **The actual YAML for that standalone design was not provided when this
   doc was written**, so it could not be saved here — paste it into
   `pipeline/azure-pipelines.yml` (or a new file, if both designs are meant to
   coexist for reference) once available, and decide which one is canonical.

## Architecture — most recently decided direction

1. Flutter web builder → Firestore `app_requests/{appId}` with
   `status: "pending"`. Logo and app icon go to Storage under
   `app_requests/{appId}/`. Uploads must finish **before** the doc is written
   as pending.
   - **Verified**: this is what `lib/features/builder/data/
     firebase_request_submitter.dart` does (not `lib/firebase.dart`, which
     only initializes Firebase and exposes the `firestore`/`storage`
     instances — it contains no request/upload logic). `_upload()` calls for
     logo, app icon and splash logo are awaited before the transaction that
     writes `status: "pending"`.
2. A Cloud Function dispatches the pipeline, validating the request id with
   `^[A-Za-z0-9_-]{1,128}$`, claiming the request in a transaction
   (`status: "queued"`, clearing old `pipeline.*` fields), cancelling a
   previous run still `queued`/`building` via
   `PATCH _apis/build/builds/{id}` `{"status":"cancelling"}`, then queuing a
   new run via
   `POST https://dev.azure.com/{org}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1`
   with `templateParameters: { requestId }` on `refs/heads/main`. Stores
   `pipeline.runId` / `pipeline.runUrl`, or `status: "trigger_failed"` +
   `pipeline.error` on failure. Config: secret `AZDO_PAT` (scope **Build: Read
   & execute**) plus `AZDO_ORG` / `AZDO_PROJECT` / `AZDO_PIPELINE_ID` in
   `functions/.env`. Requires the Blaze plan.
   - **Verified, but as a different trigger shape** — see conflict #1 above.
     The logic (validate → claim transaction → cancel previous → queue →
     store result) is implemented exactly as described, in
     `functions/src/dispatch.ts`'s `claimAndDispatch()`, shared by both
     `dispatchAppRequest` (HTTPS) and `sweepPendingAppRequests` (scheduled).
3. Azure DevOps pipeline: reads the request itself from only the id. `fetch`
   checks the doc exists and this run is current (`pipeline.runId` unset or
   equal to this build's id), sets `status: "building"`, writes
   `build_input/request.json` (Firestore `Timestamp`s converted to ISO
   strings) and downloads every Storage object under `app_requests/{id}/`
   into `build_input/assets/`. `status built|failed` writes the final status
   only if this run is still current; the failed step uses
   `condition: failed()` so a cancelled run writes nothing.
   - **Verified** as implemented in this repo's `pipeline/scripts/
     request.mjs` — but see conflict #3 for the pipeline-shape/location
     disagreement with the more recent "standalone" description.

## Status lifecycle (`app_requests/{id}`)

`pending` (client, create or re-submit) → `queued` (Cloud Function claims it)
→ `building` (pipeline `fetch`) → `built` | `failed` (pipeline, final step).
The Cloud Function can also set `trigger_failed` (invalid id, or the Azure
DevOps API call itself failed). A re-submit of the same App ID sets `pending`
again, which cancels any run still `queued`/`building` and queues a new one.

Fields written by the backend (never by the browser — `firestore.rules`
blocks a client `create` that includes a `pipeline` key):
`pipeline.runId`, `pipeline.runUrl`, `pipeline.error`, `pipeline.queuedAt`,
`pipeline.startedAt`, `pipeline.finishedAt`. Full reference:
[`docs/CONFIG.md`](CONFIG.md#request-status-and-the-pipeline-fields).

## Environment facts

- Firebase project: `swift-saas-5ac3a`. Firestore database: `(default)`,
  `FIRESTORE_NATIVE`, region `me-central2` (confirmed via `firebase
  firestore:databases:list` on 2026-10-22 — re-check this if conflict #1
  above needs resolving). Storage bucket:
  `swift-saas-5ac3a.firebasestorage.app`.
- Azure DevOps org: `ExProtectionProduects`. As configured in this repo's
  `functions/.env` right now: project `Common Project`, pipeline id `54` —
  see conflict #2 if a different project/pipeline is actually intended.
- Cloud Functions runtime/build identity:
  `619089453592-compute@developer.gserviceaccount.com` (the project's default
  compute service account). This project does not auto-grant IAM roles to
  default service accounts, so deploying `functions/` needed three roles
  added manually: **Cloud Build Service Account**
  (`roles/cloudbuild.builds.builder`), **Artifact Registry Writer**
  (`roles/artifactregistry.writer`, for the build step) and **Cloud Datastore
  User** (`roles/datastore.user`, for the function to actually read/write
  Firestore at runtime). `dispatchAppRequest` also needed `invoker: "public"`
  set explicitly in its Cloud Functions options — recent `firebase-functions`
  versions no longer make HTTPS functions publicly callable by default.
- A separately-noted service-account key (same project, roles **Cloud
  Datastore User** and **Storage Object Viewer**) is meant for the pipeline's
  own Firestore/Storage access from Azure DevOps, stored as the Azure secure
  file `firebase-service-account.json`; the pipeline needs to be authorized
  under that file's **Pipeline permissions**. Not independently verified in
  this session (no Azure DevOps access from here).
- No secret values (PATs, private keys) are recorded in this file or in the
  repo; `functions/.env` holds only the non-secret `AZDO_ORG` / `AZDO_PROJECT`
  / `AZDO_PIPELINE_ID` and is git-ignored regardless.

## Issues already solved (Azure DevOps side, self-reported — not independently verified in this session)

- **"Variable group was not found or is not authorized"** → removed the group
  and put the bucket inline instead. Resources used by API-triggered runs
  must be authorized under Library → Pipeline permissions, not with the
  per-run "Permit" button. (This conflicts with this repo's committed
  pipeline, which still uses a variable group — see conflict #3.)
- **"Not found workingDirectory .../s/scripts"** → stopped depending on repo
  files for the script (`checkout: none`, script generated inline by the
  YAML at runtime).
- **New Azure orgs may have 0 Microsoft-hosted parallel jobs** → check
  Organization settings → Parallel jobs.

## Checklist

- [ ] Standalone pipeline runs end-to-end from a manual run with a real
      `requestId` — **unverified from this session** (no Azure DevOps access
      here; reported as working).
- [x] A Cloud Function is deployed with the `AZDO_*` config and is live on
      `swift-saas-5ac3a` — **done**, but as `dispatchAppRequest` (HTTPS) +
      `sweepPendingAppRequests` (scheduled), not `triggerAppBuild` /
      `onDocumentWritten` — see conflict #1.
- [ ] curl test of the Azure DevOps Runs API succeeded — **partially
      verified**: `dispatchAppRequest` was called live and correctly reaches
      Firestore and runs its claim logic (confirmed response
      `{"ok":false,"reason":"not-pending"}` for a non-existent id), but no
      test has yet gone through a *real* pending document all the way to an
      actual Azure DevOps run — that still needs one real submission.
- [x] Upload order verified: in
      `lib/features/builder/data/firebase_request_submitter.dart` (not
      `lib/firebase.dart`), uploads complete before the `status: "pending"`
      write.
- [x] `firestore.rules`: clients may only `create` with `status == "pending"`
      and cannot include a `pipeline` field; verified by reading the deployed
      rules file, and deployed to `swift-saas-5ac3a`.
- [x] `README.md` / `README.ar.md` / `docs/CONFIG.md` updated with the status
      lifecycle, `pipeline.*` fields and setup steps, and the Limitations
      section no longer says "no Firebase" — done, but describing the HTTPS
      dispatch + sweep design (see conflict #1 if that needs to change).

## Next steps (not started)

1. **Generator**: turn `build_input/request.json` + assets into a configured
   Flutter app — package name / bundle id, app names (ar/en), icons
   (`flutter_launcher_icons`) and splash (`flutter_native_splash`), theme
   tokens and `templateId`, enabled modules and localization. Based on
   `packages/recruitment_ui`; the pipeline will check out the template repo
   through `resources.repositories`.
2. **Android build**: `flutter build appbundle`, with a signing keystore per
   client kept in Azure secure files.
3. **iOS build**: needs `macos-latest` and signing certificates/profiles.
4. **Distribution**: Firebase App Distribution / TestFlight, then the stores.
5. **Status in the builder UI**: show request status and run link after
   submitting (ARB ar + en, RTL-first) — this was scoped as optional in the
   original task and skipped, since `app_requests` isn't client-readable and
   adding that would need a `firestore.rules` change beyond what was asked
   for.

## Unrelated, noticed in passing

A Cloud Function `checkAppIdAvailability` (callable, `europe-west1`,
`nodejs22`) is deployed on `swift-saas-5ac3a` but isn't referenced anywhere in
this repo's code or history. Not touched or investigated further — worth
checking what it is and whether it's still needed.
