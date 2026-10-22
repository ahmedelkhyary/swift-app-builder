import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { AzdoConfig } from "./azdo";
import { claimAndDispatch } from "./dispatch";

initializeApp();

const AZDO_PAT = defineSecret("AZDO_PAT");
const AZDO_ORG = defineString("AZDO_ORG");
const AZDO_PROJECT = defineString("AZDO_PROJECT");
const AZDO_PIPELINE_ID = defineString("AZDO_PIPELINE_ID");

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
