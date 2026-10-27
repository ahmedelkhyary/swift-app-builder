import { createHash, timingSafeEqual } from "node:crypto";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { GATEWAYS, PAYMENT_ENVS, PaymentEnv } from "./paymentGateways";

const APP_ID_RE = /^[a-z][a-z0-9_-]{2,29}$/;
const MAX_SECRET_LENGTH = 4096;

/** `env -> gatewayId -> key -> value`, as sent by the wizard. */
export type SecretsPayload = Record<string, Record<string, Record<string, string>>>;

export interface StoredSecret {
  gateway: string;
  env: PaymentEnv;
  key: string;
  isSet: true;
  /** `••••a1b2`: never the value itself. */
  masked: string;
}

export type SaveResult =
  | { ok: true; stored: StoredSecret[] }
  | { ok: false; status: number; reason: string };

const fail = (status: number, reason: string): SaveResult => ({ ok: false, status, reason });

export function maskSecret(value: string): string {
  return `••••${value.length > 8 ? value.slice(-4) : ""}`;
}

/** Secret Manager id of one stored value. */
export function secretId(appId: string, env: PaymentEnv, gateway: string, key: string): string {
  return `pg-${appId}-${env}-${gateway}-${key}`;
}

function tokenMatches(token: string, storedHash: unknown): boolean {
  if (typeof storedHash !== "string" || !/^[0-9a-f]{64}$/.test(storedHash)) return false;
  const actual = createHash("sha256").update(token).digest();
  return timingSafeEqual(actual, Buffer.from(storedHash, "hex"));
}

/**
 * Stores the secret keys of `app_requests/{appId}` in Secret Manager.
 *
 * The caller must present the one-time token whose SHA-256 the browser wrote
 * into the request (`payments.secretsTokenHash`). The browser cannot read the
 * request back, so only the client that submitted it can pass this check; the
 * hash is deleted once the secrets are stored, so the call works exactly once
 * (a retry after a partial failure still works, as the hash is kept until the
 * end). Only keys the registry declares secret, for gateways the request
 * enabled, are accepted.
 */
export async function savePaymentSecrets(
  appId: unknown,
  token: unknown,
  secrets: unknown,
  client: SecretManagerServiceClient = new SecretManagerServiceClient(),
): Promise<SaveResult> {
  if (typeof appId !== "string" || !APP_ID_RE.test(appId)) return fail(400, "invalid-app-id");
  if (typeof token !== "string" || token.length < 20 || token.length > 200) {
    return fail(400, "invalid-token");
  }
  if (!secrets || typeof secrets !== "object") return fail(400, "invalid-secrets");

  const docRef = getFirestore().collection("app_requests").doc(appId);
  const snap = await docRef.get();
  const payments = snap.data()?.payments;
  if (!snap.exists || !payments || !tokenMatches(token, payments.secretsTokenHash)) {
    // The same answer for a missing request and a wrong token.
    return fail(403, "forbidden");
  }

  const environment: unknown = payments.environment;
  const enabled = new Set<string>(
    Object.entries(payments.gateways ?? {})
      .filter(([, g]) => (g as { enabled?: boolean })?.enabled === true)
      .map(([id]) => id),
  );

  // Validate everything before writing anything.
  const writes: { env: PaymentEnv; gateway: string; key: string; value: string }[] = [];
  for (const [env, byGateway] of Object.entries(secrets as SecretsPayload)) {
    if (!PAYMENT_ENVS.includes(env as PaymentEnv)) return fail(400, "invalid-environment");
    if (!byGateway || typeof byGateway !== "object") return fail(400, "invalid-secrets");
    for (const [gateway, keys] of Object.entries(byGateway)) {
      const def = GATEWAYS[gateway];
      if (!def || !enabled.has(gateway)) return fail(400, "gateway-not-enabled");
      if (!keys || typeof keys !== "object") return fail(400, "invalid-secrets");
      for (const [key, value] of Object.entries(keys)) {
        if (!def.secretKeys.includes(key)) return fail(400, "not-a-secret-field");
        if (typeof value !== "string" || value.trim() === "" || value.length > MAX_SECRET_LENGTH) {
          return fail(400, "invalid-secret-value");
        }
        writes.push({ env: env as PaymentEnv, gateway, key, value: value.trim() });
      }
    }
  }
  // The selected environment must be complete; the other one may be partial.
  for (const gateway of enabled) {
    const def = GATEWAYS[gateway];
    if (!def) continue;
    const given = (secrets as SecretsPayload)[String(environment)]?.[gateway] ?? {};
    if (def.requiredSecretKeys.some((k) => !given[k])) return fail(400, "incomplete");
  }

  const projectId = await client.getProjectId();
  const stored: StoredSecret[] = [];
  for (const w of writes) {
    const id = secretId(appId, w.env, w.gateway, w.key);
    const parent = `projects/${projectId}`;
    try {
      await client.createSecret({
        parent,
        secretId: id,
        secret: { replication: { automatic: {} } },
      });
    } catch (e) {
      // ALREADY_EXISTS (6): a retry; a new version replaces the value.
      if ((e as { code?: number }).code !== 6) throw e;
    }
    await client.addSecretVersion({
      parent: `${parent}/secrets/${id}`,
      payload: { data: Buffer.from(w.value, "utf8") },
    });
    stored.push({
      gateway: w.gateway,
      env: w.env,
      key: w.key,
      isSet: true,
      masked: maskSecret(w.value),
    });
  }

  await docRef.update({
    "payments.secretsTokenHash": FieldValue.delete(),
    "payments.secretsStored": true,
    "payments.secretsStoredAt": FieldValue.serverTimestamp(),
  });
  return { ok: true, stored };
}
