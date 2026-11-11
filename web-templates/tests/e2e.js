/*
 * Drives every flow through the UI (clicks and typing on data-key elements),
 * once per template. ?templates=a,b limits the run; default: all templates.
 * Each template runs in a different language / brightness to cover both.
 */
const log = [];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const root = document.getElementById("app");
const q = (key) => root.querySelector(`[data-key="${key}"]`);
let app;
const where = () => (app ? app.nav.current : "?");
async function click(key) { const el = q(key); if (!el) throw new Error(`missing ${key} on ${where()}`); el.click(); await sleep(40); }
async function type(key, v) { const el = q(key); if (!el) throw new Error(`missing input ${key} on ${where()}`); el.value = v; el.dispatchEvent(new Event("input", { bubbles: true })); await sleep(20); }
async function choose(key, v) { const el = q(key); if (!el) throw new Error(`missing select ${key} on ${where()}`); el.value = v; el.dispatchEvent(new Event("change", { bubbles: true })); await sleep(20); }
async function check(key, v) { const el = q(key); if (!el) throw new Error(`missing checkbox ${key} on ${where()}`); el.checked = v; el.dispatchEvent(new Event("change", { bubbles: true })); await sleep(20); }
async function confirmDialog(key) { await sleep(30); const b = root.querySelector(`.rui-dialog [data-key="${key}"]`); if (!b) throw new Error(`no dialog ${key}`); b.click(); await sleep(80); }
const expect = (cond, msg) => { if (!cond) throw new Error(`expected ${msg} (at ${where()})`); };
// Rich-motion templates show the Home skeleton (650 ms) every time Home mounts.
const HOME_WAIT = 750;

const session = RuiApp.createSession({ repository: RuiApp.createRepository({ latency: 10 }) });

async function pay(module) {
  await click("pay-button"); await confirmDialog("pay-confirm"); await sleep(60);
  expect(app.nav.current === "/success", `success screen for ${module}`);
  log.push(`  ${module} order ${q("order-reference").textContent}`);
  await click("success-home"); expect(app.nav.current === "/main", "back home");
  await sleep(HOME_WAIT);
}

async function contract() {
  await type("contract-name", "Test User"); await type("contract-nid", "1234567890"); await type("contract-email", "t@example.com");
  await type("contract-date", RuiApp.fmtDate(new Date(Date.now() + 5 * 864e5)));
  await check("contract-ack", true);
  await click("contract-continue"); expect(app.nav.current === "/payment", "payment after contract");
}

async function runTemplate(t, i) {
  if (app) app.destroy();
  session._init();
  app = RuiApp.mount(root, {
    session, templateId: t, loadFonts: false,
    branding: { primaryColor: "#1B4D89", secondaryColor: "#F2A541" },
    lang: i % 2 ? "en" : "ar", dark: i % 3 === 2,
  });
  expect(root.dataset.ruiTemplate === t, `template "${t}" registered in RuiTheme.TEMPLATES`);

  // Login + OTP
  await click("login-continue"); expect(q("phone-field").getAttribute("aria-invalid") === "true", "phone required error");
  await type("phone-field", "512345678"); await click("login-continue"); await sleep(60);
  expect(app.nav.current === "/otp", "otp screen");
  await type("otp-field", "000000"); await click("otp-verify"); await sleep(60); expect(root.querySelector(".rui-notice--error"), "wrong otp error");
  await type("otp-field", "123456"); await click("otp-verify"); await sleep(120);
  expect(app.nav.current === "/main", "main after otp");
  await sleep(HOME_WAIT);

  // Individuals
  await click("category-individuals"); await click("address-continue"); expect(root.querySelector(".rui-notice--error"), "address error");
  await click("address-a1"); await click("address-continue"); expect(app.nav.current === "/ind/packages", "ind packages");
  await choose("nationality-select", "ph"); await click("ind-package-standard"); await click("ind-packages-continue");
  expect(app.nav.current === "/workers", "workers"); await click("filter-nanny");
  root.querySelector('[data-key^="worker-select-"]').click(); await sleep(30);
  await click("workers-continue"); expect(app.nav.current === "/worker", "worker details");
  await click("worker-tab-2"); await click("worker-confirm"); expect(app.nav.current === "/contract", "contract");
  await click("contract-continue"); expect(app.nav.current === "/contract" && root.querySelector(".rui-field__error"), "contract errors");
  await contract(); await pay("individuals");

  // Hourly: custom package, schedule, discount, simulated failure
  await click("category-hourly"); await click("address-a2"); await click("address-continue");
  await click("hr-packages-continue"); expect(root.querySelector(".rui-notice--error"), "hourly package error");
  root.querySelector('[data-key="hr-mode"] button:last-child').click(); await sleep(30);
  await click("custom-hours-plus"); await click("hr-packages-continue"); expect(app.nav.current === "/hr/details", "hourly details");
  let d = new Date(Date.now() + 2 * 864e5); while (RuiApp.isoWeekday(d) === 5) d = new Date(d.getTime() + 864e5);
  await type("hr-start-date", RuiApp.fmtDate(d)); await click("day-1"); await click("day-3");
  await type("discount-field", "demo10"); await click("discount-apply"); expect(root.querySelector(".rui-notice--success"), "discount applied");
  await click("hr-details-continue"); expect(app.nav.current === "/payment", "hourly payment");
  await check("simulate-failure", true);
  await click("pay-button"); await confirmDialog("pay-confirm"); await sleep(60); expect(root.querySelector(".rui-notice--error"), "payment failure notice");
  await check("simulate-failure", false);
  await pay("hourly");

  // Mediation via search
  await click("category-mediation"); await click("profession-cook"); await choose("nationality-select", "in"); await click("med-criteria-continue");
  await click("med-package-m_plus"); await click("med-packages-continue"); await click("method-search");
  await type("worker-search", "zzz"); expect(root.querySelector(".rui-notice--warning"), "no search results");
  await type("worker-search", ""); root.querySelector('[data-key^="worker-select-"]').click(); await sleep(30);
  await click("search-continue"); await click("worker-confirm"); await contract(); await pay("mediation");

  // Featured service, main-address sheet, tabs, dialog
  await click("featured-hourly-maid"); await sleep(60);
  expect(app.nav.current === "/hr/packages", "featured opens hourly packages");
  app.nav.replaceAll("/main"); await sleep(HOME_WAIT);
  await click("home-address"); await sleep(40); expect(root.querySelector(".rui-sheet"), "main address sheet");
  root.querySelector('.rui-sheet [data-key="sheet-address-a2"]').click(); await sleep(60);
  expect(session.mainAddress.id === "a2", "main address a2");
  await click("nav-1"); expect(session.orders.length === 3, `3 orders, got ${session.orders.length}`);
  await click("nav-2"); await click("nav-0"); await sleep(HOME_WAIT);
  await click("contact-phone"); await sleep(30); expect(root.querySelector(".rui-dialog"), "contact dialog");
  root.querySelector(".rui-dialog button").click(); await sleep(30);
  log.push(`${t}: all flows OK`);
}

(async () => {
  const param = new URLSearchParams(location.search).get("templates");
  const templates = param ? param.split(",").map((s) => s.trim()).filter(Boolean) : Object.keys(RuiTheme.TEMPLATES);
  let ok = true;
  for (let i = 0; i < templates.length; i++) {
    try { await runTemplate(templates[i], i); }
    catch (e) { ok = false; log.push(`${templates[i]}: FAIL: ${e.message}`); }
  }
  if (window.__errors.length) ok = false;
  log.push(`errors: ${JSON.stringify(window.__errors)}`);
  log.push(ok ? "RESULT: PASS" : "RESULT: FAIL");
  document.getElementById("log").textContent = log.join("\n");
  document.title = ok ? "E2E PASS" : "E2E FAIL";
})();
