/* Login + OTP. Port of ui/auth_screens.dart. */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { h, icon, page, button, textButton, notice, input, select } = R.ui;

  function logo(ctx) {
    const url = ctx.branding.logoUrl;
    return h("div", { class: "rui-login__logo" }, url ? h("img", { src: url, alt: "" }) : icon("home_work"));
  }

  R.screens[R.Routes.login] = function login(ctx) {
    const { session, state: st, x } = ctx;
    if (st.phone == null) {
      st.phone = session.phone;
      st.dial = session.dialCode;
      st.busy = false;
      st.error = null;
      st.fieldError = null;
    }

    const validate = () => {
      switch (R.PhoneRules.validate(st.dial, st.phone)) {
        case null: return null;
        case "required": return x("أدخل رقم الجوال", "Enter your phone number");
        case "digits": return x("أرقام فقط", "Digits only");
        default:
          return st.dial === "+966"
            ? x("رقم سعودي من 9 أرقام يبدأ بـ 5", "Saudi number: 9 digits starting with 5")
            : x("رقم جوال غير صحيح", "Invalid phone number");
      }
    };

    async function next() {
      st.fieldError = validate();
      if (st.fieldError) return ctx.refresh();
      st.busy = true; st.error = null; ctx.refresh();
      ctx.busy(true);
      session.setPhone(st.dial, st.phone.trim());
      const ok = await session.sendOtp();
      ctx.busy(false);
      st.busy = false;
      if (ok) ctx.nav.push(R.Routes.otp);
      else { st.error = x("تعذر إرسال الرمز", "Could not send the code"); ctx.refresh(); }
    }

    async function biometric() {
      const confirmed = await ctx.dialog({
        icon: "fingerprint",
        title: x("تسجيل الدخول بالبصمة", "Biometric login"),
        content: x("محاكاة: لن يتم استخدام مستشعر الجهاز الحقيقي.", "Simulation: no real device biometric API is used."),
        actions: [
          { label: x("إلغاء", "Cancel"), value: false },
          { label: x("تأكيد البصمة", "Authenticate"), value: true, primary: true, key: "biometric-confirm" },
        ],
      });
      if (confirmed !== true) return;
      ctx.busy(true);
      const ok = await session.biometricLogin();
      ctx.busy(false);
      if (ok) ctx.nav.replaceAll(R.Routes.main);
    }

    return h("section", { class: "rui-page rui-login" },
      h("div", { class: "rui-login__brand" }, logo(ctx), h("h1", { class: "rui-title" }, ctx.appName())),
      h("div", { class: "rui-login__sheet", "data-scroll": "sheet" },
        h("div", null,
          h("h2", { class: "rui-headline" }, x("مرحباً بك", "Welcome")),
          h("p", { class: "rui-muted", style: { margin: "4px 0 10px" } }, x("سجّل الدخول للمتابعة", "Sign in to continue"))),
        h("div", { class: "rui-login__phone" },
          select({
            label: x("الرمز", "Code"), key: "dial-code", value: st.dial, dir: "ltr",
            options: R.PhoneRules.dialCodes.map((c) => ({ value: c, label: c })),
            onChange: (v) => { st.dial = v; st.fieldError = null; ctx.refresh(); },
          }),
          input({
            label: x("رقم الجوال", "Phone number"), key: "phone-field", value: st.phone, type: "tel", inputmode: "numeric",
            dir: "ltr", placeholder: "5XXXXXXXX", prefixIcon: "phone_iphone", error: st.fieldError,
            onInput: (v, e) => {
              const digits = v.replace(/\D/g, "");
              if (digits !== v) e.target.value = digits;
              st.phone = digits;
              if (st.fieldError) { st.fieldError = null; ctx.refresh(); }
            },
            onEnter: next,
          })),
        st.error ? notice(st.error, { kind: "error" }) : null,
        h("div", { class: "rui-login__actions" },
          h("div", { class: "rui-grow" }, button({ label: x("متابعة", "Continue"), key: "login-continue", loading: st.busy, onClick: next })),
          h("button", { class: "rui-login__bio", type: "button", key: "login-biometric", "aria-label": x("الدخول بالبصمة / الوجه", "Fingerprint / Face ID"), onClick: biometric },
            icon("fingerprint"))),
        notice(x(
          `تجريبي: أي رقم سعودي صحيح مقبول (مثل 500000000)، ورمز التحقق هو ${ctx.repo.demoOtp}.`,
          `Demo: any valid Saudi number works (e.g. 500000000); the verification code is ${ctx.repo.demoOtp}. No SMS is sent.`,
        ), { icon: "science" }),
        h("p", { class: "rui-body-sm rui-muted rui-center", style: { margin: 0 } }, x("تطبيق تجريبي — لا يتم إرسال رسائل حقيقية.", "Demo app — no real messages are sent."))));
  };

  const OTP_LENGTH = 6;
  const COUNTDOWN = 30;

  R.screens[R.Routes.otp] = function otp(ctx) {
    const { session, state: st, x } = ctx;
    if (st.code == null) {
      st.code = "";
      st.remaining = COUNTDOWN;
      st.busy = false;
      st.verified = false;
      st.error = null;
      st.start = () => {
        clearInterval(st.timer);
        st.remaining = COUNTDOWN;
        st.timer = setInterval(() => {
          st.remaining--;
          if (st.remaining <= 0) clearInterval(st.timer);
          ctx.refresh();
        }, 1000);
      };
      st.start();
      ctx.onDispose(() => clearInterval(st.timer));
    }

    async function verify() {
      st.busy = true; st.error = null; ctx.refresh();
      const ok = await session.verifyOtp(st.code);
      st.busy = false;
      if (!ok) {
        st.error = x("رمز التحقق غير صحيح. حاول مرة أخرى.", "Incorrect code. Please try again.");
        return ctx.refresh();
      }
      st.verified = true;
      ctx.refresh();
      setTimeout(() => ctx.nav.replaceAll(R.Routes.main), ctx.repo.latency / 2);
    }

    async function resend() {
      await session.sendOtp();
      st.code = ""; st.error = null;
      st.start();
      ctx.refresh();
      ctx.snack(x('تم "إرسال" رمز جديد (تجريبي)', 'A new code was "sent" (demo)'));
    }

    const digits = st.code;
    const boxes = Array.from({ length: OTP_LENGTH }, (_, i) =>
      h("span", { class: "rui-otp__box" + (i === digits.length ? " is-active" : "") }, digits[i] || ""));
    const field = h("input", {
      key: "otp-field", type: "text", inputmode: "numeric", autocomplete: "one-time-code", maxlength: OTP_LENGTH,
      value: digits, disabled: st.verified, "aria-label": x("رمز التحقق", "Verification code"),
      onInput: (e) => {
        const v = e.target.value.replace(/\D/g, "").slice(0, OTP_LENGTH);
        e.target.value = v;
        st.code = v; st.error = null;
        ctx.refresh();
      },
      onKeydown: (e) => { if (e.key === "Enter" && st.code.length === OTP_LENGTH && !st.verified) verify(); },
    });
    // Autofocus the hidden field once, like `autofocus: true`.
    if (!st.focused) { st.focused = true; setTimeout(() => field.isConnected && field.focus({ preventScroll: true }), 0); }

    return page(ctx, {
      title: x("رمز التحقق", "Verification"),
      subtitle: `${session.dialCode} ${session.phone}`,
      bottom: button({
        label: x("تحقق", "Verify"), key: "otp-verify", loading: st.busy,
        disabled: digits.length !== OTP_LENGTH || st.verified, onClick: verify,
      }),
      body: h("div", { class: "rui-stack rui-center", style: { justifyItems: "center", paddingTop: "16px" } },
        icon(st.verified ? "verified" : "sms", { size: 56, color: st.verified ? "#2e7d32" : "var(--rui-primary)" }),
        h("div", { class: "rui-subtitle", key: "otp-title", style: { fontWeight: 500 } },
          st.verified ? x("تم التحقق بنجاح", "Verified successfully") : x("أدخل الرمز المكوّن من 6 أرقام", "Enter the 6-digit code")),
        h("div", { class: "rui-otp" + (st.error ? " is-error" : ""), onClick: () => field.focus() }, boxes, field),
        st.error ? notice(st.error, { kind: "error" })
          : st.verified ? notice(x("جارٍ تحويلك إلى الرئيسية…", "Taking you to Home…"), { kind: "success" }) : null,
        st.remaining > 0
          ? h("div", { key: "otp-countdown" }, x(`إعادة الإرسال بعد ${st.remaining} ثانية`, `Resend code in ${st.remaining}s`))
          : textButton({ label: x("إعادة إرسال الرمز", "Resend code"), key: "otp-resend", onClick: resend }),
        notice(x(
          `تجريبي: رمز التحقق هو ${ctx.repo.demoOtp}. لا يتم إرسال رسائل.`,
          `Demo: the code is ${ctx.repo.demoOtp}. No SMS is sent.`,
        ), { icon: "science" })),
    });
  };
})(window);
