import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { AzdoApiError, AzdoConfig, cancelRun, queueRun } from "./azdo";

const REQUEST_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export interface DispatchResult {
  dispatched: boolean;
  reason: string;
}

/**
 * Claims `app_requests/{requestId}` if it is still "pending" and dispatches
 * an Azure DevOps pipeline run for it. Called both from the direct HTTPS
 * nudge (`dispatchAppRequest`) and the scheduled safety net
 * (`sweepPendingAppRequests`), so it must be safe to call repeatedly and
 * concurrently for the same id.
 */
export async function claimAndDispatch(
  requestId: string,
  config: AzdoConfig,
): Promise<DispatchResult> {
  if (!REQUEST_ID_RE.test(requestId)) {
    return { dispatched: false, reason: "invalid-request-id" };
  }

  const db = getFirestore();
  const docRef = db.collection("app_requests").doc(requestId);

  // Claim atomically: re-read inside the transaction so two overlapping
  // callers (the direct nudge and a sweep, or two sweeps) cannot both
  // dispatch the same submission. Every write below moves `status` away
  // from "pending", so a claim can never be taken twice.
  let previousRunId: string | number | undefined;
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    if (!snap.exists) return false;
    const data = snap.data()!;
    if (data.status !== "pending") return false;
    previousRunId = data.pipeline?.runId;
    tx.set(
      docRef,
      {
        status: "queued",
        pipeline: {
          queuedAt: FieldValue.serverTimestamp(),
          runId: FieldValue.delete(),
          runUrl: FieldValue.delete(),
          error: FieldValue.delete(),
        },
      },
      { merge: true },
    );
    return true;
  });
  if (!claimed) return { dispatched: false, reason: "not-pending" };

  // A run id can only be present here from an earlier dispatch of this same
  // request (for example after someone manually reset it back to "pending").
  // Cancelling an already-finished build is harmless, so this is tried
  // unconditionally and never allowed to fail the new dispatch.
  if (previousRunId != null) {
    try {
      await cancelRun(config, previousRunId);
    } catch (e) {
      logger.warn(
        `Could not cancel previous run ${previousRunId} for ${requestId}`,
        e,
      );
    }
  }

  try {
    const run = await queueRun(config, requestId);
    await docRef.set(
      {
        pipeline: {
          runId: String(run.id),
          runUrl: run._links?.web?.href ?? null,
        },
      },
      { merge: true },
    );
    return { dispatched: true, reason: "queued" };
  } catch (e) {
    const detail =
      e instanceof AzdoApiError ? `${e.status}: ${e.body}` : String(e);
    logger.error(`Failed to queue a run for ${requestId}: ${detail}`);
    await docRef.set(
      { status: "trigger_failed", pipeline: { error: detail } },
      { merge: true },
    );
    return { dispatched: false, reason: "azdo-error" };
  }
}
