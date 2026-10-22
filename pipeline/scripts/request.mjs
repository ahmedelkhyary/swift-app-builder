#!/usr/bin/env node
// Runs inside the Azure Pipeline (see ../azure-pipelines.yml). Talks to
// Firestore/Storage with firebase-admin, using the Google service-account key
// the pipeline downloads as a secure file (GOOGLE_APPLICATION_CREDENTIALS).
//
// Usage:
//   node request.mjs fetch           # load the request + download its assets
//   node request.mjs status built    # mark it built
//   node request.mjs status failed   # mark it failed

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const REQUEST_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

const requestId = process.env.REQUEST_ID ?? "";
if (!REQUEST_ID_RE.test(requestId)) {
  console.error(`Invalid REQUEST_ID: "${requestId}"`);
  process.exit(1);
}

const storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
if (!storageBucket) {
  console.error("FIREBASE_STORAGE_BUCKET is not set");
  process.exit(1);
}

const buildId = process.env.BUILD_BUILDID ?? "";
const runUrl = `${process.env.SYSTEM_COLLECTIONURI ?? ""}${
  process.env.SYSTEM_TEAMPROJECT ?? ""
}/_build/results?buildId=${buildId}`;

initializeApp({ credential: applicationDefault(), storageBucket });

const db = getFirestore();
const docRef = db.collection("app_requests").doc(requestId);

/** Recursively turns Firestore Timestamps into ISO-8601 strings. */
function isoify(value) {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(isoify);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, isoify(v)]),
    );
  }
  return value;
}

/** True once another run has taken over this request (a re-submit). */
function isSuperseded(data) {
  const currentRunId = data?.pipeline?.runId;
  return currentRunId != null && String(currentRunId) !== String(buildId);
}

async function fetchCommand() {
  const snap = await docRef.get();
  if (!snap.exists) {
    console.error(`Request "${requestId}" does not exist`);
    process.exit(1);
  }
  const data = snap.data();
  if (isSuperseded(data)) {
    console.error(
      `Request "${requestId}" was superseded by run ${data.pipeline.runId}`,
    );
    process.exit(1);
  }

  await docRef.set(
    {
      status: "building",
      pipeline: {
        runId: buildId,
        runUrl,
        startedAt: FieldValue.serverTimestamp(),
      },
    },
    { merge: true },
  );

  const outDir = path.resolve("build_input");
  await mkdir(outDir, { recursive: true });
  await writeFile(
    path.join(outDir, "request.json"),
    JSON.stringify(isoify(data), null, 2),
  );

  const assetsDir = path.join(outDir, "assets");
  await mkdir(assetsDir, { recursive: true });
  const prefix = `app_requests/${requestId}/`;
  const [files] = await getStorage().bucket().getFiles({ prefix });
  for (const file of files) {
    const dest = path.join(assetsDir, path.basename(file.name));
    await file.download({ destination: dest });
    console.log(`Downloaded ${file.name} -> ${dest}`);
  }
  console.log(`Fetched request "${requestId}": ${files.length} asset(s)`);
}

async function statusCommand(next) {
  const snap = await docRef.get();
  if (!snap.exists) {
    console.log(`Request "${requestId}" no longer exists; nothing to do`);
    return;
  }
  const data = snap.data();
  if (isSuperseded(data)) {
    console.log(
      `Request "${requestId}" is now owned by run ${data.pipeline.runId} ` +
        `(this run: ${buildId}); not updating`,
    );
    return;
  }
  await docRef.set(
    { status: next, pipeline: { finishedAt: FieldValue.serverTimestamp() } },
    { merge: true },
  );
  console.log(`Request "${requestId}" marked ${next}`);
}

const [, , command, arg] = process.argv;
switch (command) {
  case "fetch":
    await fetchCommand();
    break;
  case "status":
    if (arg !== "built" && arg !== "failed") {
      console.error(`Unknown status "${arg}"; use "built" or "failed"`);
      process.exit(1);
    }
    await statusCommand(arg);
    break;
  default:
    console.error(`Unknown command "${command}"; use "fetch" or "status <built|failed>"`);
    process.exit(1);
}
