// Backend side of the builder's payment gateways. The wizard's registry
// (`lib/features/builder/domain/payment_gateways.dart`) is the source of truth
// for the form; this file mirrors the parts the backend needs: which field
// keys are secret, which are required, and how to check a gateway's
// credentials. Adding a gateway means one entry here and one there.

export type PaymentEnv = "test" | "live";

export const PAYMENT_ENVS: readonly PaymentEnv[] = ["test", "live"];

export type TestCode =
  | "ok"
  | "invalid-credentials"
  | "not-implemented"
  | "unreachable"
  | "error";

export interface TestResult {
  code: TestCode;
  /** The gateway's own message, when it gave one. */
  message?: string;
}

export interface GatewayDef {
  id: string;
  /** Keys stored in Secret Manager, never in Firestore. */
  secretKeys: readonly string[];
  /** Secret keys that must be present when the gateway is enabled. */
  requiredSecretKeys: readonly string[];
  /**
   * A lightweight authenticated call to the gateway's sandbox / live API.
   * Absent: not built yet, reported as "not-implemented" (never as success).
   */
  test?: (env: PaymentEnv, credentials: Record<string, string>) => Promise<TestResult>;
}

const TIMEOUT_MS = 15_000;

async function post(
  url: string,
  headers: Record<string, string>,
  body: string,
): Promise<{ status: number; json: unknown }> {
  const res = await fetch(url, {
    method: "POST",
    headers,
    body,
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  let json: unknown = null;
  try {
    json = await res.json();
  } catch {
    // Not JSON: the status code alone decides.
  }
  return { status: res.status, json };
}

const asRecord = (v: unknown): Record<string, unknown> =>
  v && typeof v === "object" ? (v as Record<string, unknown>) : {};

/**
 * HyperPay: prepares a checkout (1.00 SAR) for each entity ID with the access
 * token. A prepared checkout charges nothing and simply expires; wrong
 * credentials are rejected with 800.900.3xx or HTTP 401.
 */
async function testHyperpay(
  env: PaymentEnv,
  c: Record<string, string>,
): Promise<TestResult> {
  const base = env === "live" ? "https://eu-prod.oppwa.com" : "https://eu-test.oppwa.com";
  const entities = [c.entityIdCards, c.entityIdMada, c.entityIdApplePay, c.entityIdStcPay]
    .map((e) => (e ?? "").trim())
    .filter((e) => e !== "");
  if (!c.accessToken || entities.length === 0) return { code: "invalid-credentials" };
  for (const entityId of new Set(entities)) {
    const { status, json } = await post(
      `${base}/v1/checkouts`,
      {
        Authorization: `Bearer ${c.accessToken}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      new URLSearchParams({
        entityId,
        amount: "1.00",
        currency: "SAR",
        paymentType: "DB",
      }).toString(),
    );
    const result = asRecord(asRecord(json).result);
    const code = String(result.code ?? "");
    const description = typeof result.description === "string" ? result.description : undefined;
    if (status === 401 || status === 403 || /^800\.900\.30/.test(code)) {
      return { code: "invalid-credentials", message: description };
    }
    if (!/^000\./.test(code)) {
      return { code: "error", message: description ?? `HTTP ${status}` };
    }
  }
  return { code: "ok" };
}

/**
 * Paymob: exchanges the API key for an auth token. Paymob serves Egypt and
 * Saudi Arabia from different hosts and the key only works on its own, so
 * both are tried.
 */
async function testPaymob(
  _env: PaymentEnv,
  c: Record<string, string>,
): Promise<TestResult> {
  if (!c.apiKey) return { code: "invalid-credentials" };
  let last: TestResult = { code: "invalid-credentials" };
  for (const host of ["accept.paymob.com", "ksa.paymob.com"]) {
    try {
      const { status, json } = await post(
        `https://${host}/api/auth/tokens`,
        { "Content-Type": "application/json" },
        JSON.stringify({ api_key: c.apiKey }),
      );
      if (status >= 200 && status < 300 && typeof asRecord(json).token === "string") {
        return { code: "ok" };
      }
      if (status >= 500) last = { code: "error", message: `HTTP ${status}` };
    } catch {
      last = { code: "unreachable" };
    }
  }
  return last;
}

export const GATEWAYS: Record<string, GatewayDef> = {
  hyperpay: {
    id: "hyperpay",
    secretKeys: ["accessToken"],
    requiredSecretKeys: ["accessToken"],
    test: testHyperpay,
  },
  paymob: {
    id: "paymob",
    secretKeys: ["apiKey", "secretKey", "hmacSecret"],
    requiredSecretKeys: ["apiKey", "secretKey", "hmacSecret"],
    test: testPaymob,
  },
  payfort: {
    id: "payfort",
    secretKeys: ["accessCode", "shaRequestPhrase", "shaResponsePhrase"],
    requiredSecretKeys: ["accessCode", "shaRequestPhrase", "shaResponsePhrase"],
    // TODO: Amazon Payment Services has no plain "who am I" call. A real
    // check needs a signed CHECK_STATUS request (SHA of the request phrase
    // over the sorted parameters) and mapping its response codes, which has to
    // be verified against the sandbox first. Until then this is reported as
    // not implemented rather than guessed.
  },
};
