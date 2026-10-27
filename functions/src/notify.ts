import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { AzdoApiError, AzdoConfig, queuePipeline } from "./azdo";

export interface ConfirmationEmailResult {
  ok: boolean;
  reason: string;
}

/**
 * Queues the confirmation-email pipeline (Azure DevOps definition id 55) for
 * a newly created `app_requests/{requestId}`, once. The pipeline reads
 * everything else it needs from the document itself — only `requestId` is
 * sent. Idempotent: a document that already has `email.queuedRunId` is left
 * untouched, so a retried call never queues a second run.
 */
export async function triggerConfirmationEmail(
  requestId: string,
  config: AzdoConfig,
  emailPipelineId: string,
): Promise<ConfirmationEmailResult> {
  const docRef = getFirestore().collection("app_requests").doc(requestId);
  const snap = await docRef.get();
  if (!snap.exists) return { ok: false, reason: "not-found" };

  if (snap.data()!.email?.queuedRunId) {
    return { ok: true, reason: "already-queued" };
  }

  try {
    const run = await queuePipeline(config, emailPipelineId, { requestId });
    await docRef.set(
      {
        email: {
          status: "queued",
          queuedRunId: String(run.id),
          queuedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
    return { ok: true, reason: "queued" };
  } catch (e) {
    const detail =
      e instanceof AzdoApiError ? `${e.status}: ${e.body}` : String(e);
    logger.error(
      `Failed to queue confirmation email for ${requestId}: ${detail}`,
    );
    await docRef.set(
      {
        email: {
          status: "queue_failed",
          error: detail,
          queuedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
    return { ok: false, reason: "azdo-error" };
  }
}
