import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { AzdoConfig } from "./azdo";
import { claimAndDispatch } from "./dispatch";
import { triggerConfirmationEmail as queueConfirmationEmail } from "./notify";
import { GATEWAYS, PAYMENT_ENVS } from "./paymentGateways";
import { savePaymentSecrets as storePaymentSecrets } from "./paymentSecrets";

initializeApp();

const AZDO_PAT = defineSecret("AZDO_PAT");
const AZDO_ORG = defineString("AZDO_ORG");
const AZDO_PROJECT = defineString("AZDO_PROJECT");
const AZDO_PIPELINE_ID = defineString("AZDO_PIPELINE_ID");
// Confirmation-email pipeline (Azure DevOps definition id 55); same org and
// project as the build pipeline above, so only its own id is separate config.
const EMAIL_PIPELINE_ID = defineString("EMAIL_PIPELINE_ID");

const REQUEST_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

function azdoConfig(): AzdoConfig {
  return {
    org: AZDO_ORG.value(),
    project: AZDO_PROJECT.value(),
    pipelineId: AZDO_PIPELINE_ID.value(),
    pat: AZDO_PAT.value(),
  };
}

// Not a Firestore `onDocumentWritten` trigger: this project's Firestore
// database lives in `me-central2`, a region Cloud Functions 2nd gen does not
// support deploying into, and a Firestore background trigger must run in the
// same region as its database. So the app calls `dispatchAppRequest` directly
// right after writing the "pending" document, and `sweepPendingAppRequests`
// is a safety net for any call that never arrives.

/**
 * Called by the Flutter app right after it writes `app_requests/{requestId}`
 * with status "pending" — dispatches an Azure DevOps pipeline run for it.
 *
 * Public and unauthenticated by design: a call only ever moves a document
 * that already exists and is "pending" one step forward (the Firestore
 * create rules are the real gate on what can exist), and claiming is
 * idempotent, so repeated or guessed calls are harmless no-ops.
 */
export const dispatchAppRequest = onRequest(
  { secrets: [AZDO_PAT], cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, reason: "method-not-allowed" });
      return;
    }
    const requestId = req.body?.requestId;
    if (typeof requestId !== "string" || requestId.length === 0) {
      res.status(400).json({ ok: false, reason: "missing-request-id" });
      return;
    }
    const result = await claimAndDispatch(requestId, azdoConfig());
    res.status(200).json({ ok: result.dispatched, reason: result.reason });
  },
);

/**
 * Safety net for `dispatchAppRequest`: picks up any "pending" request whose
 * direct dispatch call never reached us (closed tab, dropped connection).
 */
export const sweepPendingAppRequests = onSchedule(
  { schedule: "every 5 minutes", secrets: [AZDO_PAT] },
  async () => {
    const snap = await getFirestore()
      .collection("app_requests")
      .where("status", "==", "pending")
      .get();
    if (snap.empty) return;
    const config = azdoConfig();
    for (const doc of snap.docs) {
      try {
        await claimAndDispatch(doc.id, config);
      } catch (e) {
        logger.error(`Sweep failed to dispatch ${doc.id}`, e);
      }
    }
  },
);

/**
 * Queues the confirmation-email pipeline (Azure DevOps definition id 55, same
 * org/project as the build pipeline) for a just-created `app_requests/{id}`.
 *
 * Deliberately NOT an `onDocumentCreated` Firestore trigger, for the same
 * reason `dispatchAppRequest` below isn't `onDocumentWritten`: this project's
 * Firestore database lives in `me-central2`, a region Cloud Functions 2nd gen
 * cannot deploy a background trigger into (verified by repeated failed
 * deploys — not a style choice). So the Flutter app calls this directly right
 * after creating the document, mirroring `dispatchAppRequest`'s pattern.
 *
 * Public and unauthenticated by design (see `dispatchAppRequest`): queuing is
 * idempotent on `email.queuedRunId`, so a repeated or guessed call is a
 * harmless no-op, and a failure here never touches `status` or `pipeline.*`
 * (the build pipeline's own fields).
 */
export const triggerConfirmationEmail = onRequest(
  { secrets: [AZDO_PAT], cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, reason: "method-not-allowed" });
      return;
    }
    const requestId = req.body?.requestId;
    if (typeof requestId !== "string" || !REQUEST_ID_RE.test(requestId)) {
      res.status(400).json({ ok: false, reason: "missing-request-id" });
      return;
    }
    const result = await queueConfirmationEmail(
      requestId,
      azdoConfig(),
      EMAIL_PIPELINE_ID.value(),
    );
    res.status(200).json(result);
  },
);

/**
 * Called by the Flutter app right after a request with payment secrets was
 * created: stores the keys in Secret Manager (never in Firestore) once the
 * caller proves it is the submitter with the one-time token whose hash is in
 * the request. See `paymentSecrets.ts`.
 */
export const savePaymentSecrets = onRequest(
  { cors: true, invoker: "public", maxInstances: 10 },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, reason: "method-not-allowed" });
      return;
    }
    try {
      const { appId, token, secrets } = req.body ?? {};
      const result = await storePaymentSecrets(appId, token, secrets);
      if (!result.ok) {
        res.status(result.status).json({ ok: false, reason: result.reason });
        return;
      }
      res.status(200).json({ ok: true, stored: result.stored });
    } catch (e) {
      // Never log the body: it holds the secrets.
      logger.error("savePaymentSecrets failed", (e as Error)?.message);
      res.status(500).json({ ok: false, reason: "internal" });
    }
  },
);

const TEST_ROUTE = /^\/payment-gateways\/([a-z0-9_-]{1,32})\/test\/?$/;

/**
 * `POST /payment-gateways/:id/test` — checks a gateway's credentials with a
 * lightweight authenticated call to its sandbox or live API. Reachable at
 * `/paymentGateways/payment-gateways/:id/test` on the function's URL.
 * Body: `{ environment: "test" | "live", credentials: { [fieldKey]: string } }`.
 * Answers `{ ok, code, message? }`; a gateway without a real check answers
 * `not-implemented`, never `ok`.
 */
export const paymentGateways = onRequest(
  { cors: true, invoker: "public", maxInstances: 10, timeoutSeconds: 60 },
  async (req, res) => {
    const match = TEST_ROUTE.exec(req.path);
    if (!match) {
      res.status(404).json({ ok: false, code: "error", message: "not-found" });
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, code: "error", message: "method-not-allowed" });
      return;
    }
    const def = GATEWAYS[match[1]];
    const { environment, credentials } = req.body ?? {};
    if (
      !def ||
      !PAYMENT_ENVS.includes(environment) ||
      !credentials ||
      typeof credentials !== "object" ||
      Object.values(credentials).some((v) => typeof v !== "string" || v.length > 4096)
    ) {
      res.status(400).json({ ok: false, code: "error", message: "bad-request" });
      return;
    }
    if (!def.test) {
      res.status(200).json({ ok: false, code: "not-implemented" });
      return;
    }
    try {
      const result = await def.test(environment, credentials as Record<string, string>);
      res.status(200).json({ ok: result.code === "ok", ...result });
    } catch {
      // Timeouts and network errors: never include the credentials.
      res.status(200).json({ ok: false, code: "unreachable" });
    }
  },
);
