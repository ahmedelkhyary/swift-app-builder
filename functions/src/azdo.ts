/** Minimal Azure DevOps REST client: just the two calls this function needs. */

export interface QueuedRun {
  id: number | string;
  _links?: { web?: { href?: string } };
}

export interface AzdoConfig {
  org: string;
  project: string;
  pipelineId: string;
  pat: string;
}

function authHeader(pat: string): string {
  return `Basic ${Buffer.from(`:${pat}`).toString("base64")}`;
}

/** Thrown for any non-2xx response; carries enough detail for `pipeline.error`. */
export class AzdoApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly body: string,
  ) {
    super(`Azure DevOps API error ${status}: ${body}`);
  }
}

async function azdoFetch(
  url: string,
  config: AzdoConfig,
  init: RequestInit,
): Promise<Response> {
  const res = await fetch(url, {
    ...init,
    headers: {
      ...init.headers,
      Authorization: authHeader(config.pat),
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) {
    throw new AzdoApiError(res.status, await res.text());
  }
  return res;
}

/** Queues a run of the configured pipeline on `refs/heads/main`. */
export async function queueRun(
  config: AzdoConfig,
  requestId: string,
): Promise<QueuedRun> {
  const url =
    `https://dev.azure.com/${config.org}/${encodeURIComponent(config.project)}` +
    `/_apis/pipelines/${config.pipelineId}/runs?api-version=7.1`;
  const res = await azdoFetch(url, config, {
    method: "POST",
    body: JSON.stringify({
      resources: { repositories: { self: { refName: "refs/heads/main" } } },
      templateParameters: { requestId },
    }),
  });
  return (await res.json()) as QueuedRun;
}

/** Cancels a (previously queued/running) build. Never throws: logging the
 * failure is the caller's job, since a failed cancel must not fail dispatch
 * of the new run. */
export async function cancelRun(
  config: AzdoConfig,
  runId: string | number,
): Promise<void> {
  const url =
    `https://dev.azure.com/${config.org}/${encodeURIComponent(config.project)}` +
    `/_apis/build/builds/${runId}?api-version=7.1`;
  await azdoFetch(url, config, {
    method: "PATCH",
    body: JSON.stringify({ status: "cancelling" }),
  });
}
