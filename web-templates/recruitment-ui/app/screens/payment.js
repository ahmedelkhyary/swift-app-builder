/* Payment + success, shared by every flow. Port of ui/payment_screens.dart. */
(function (global) {
  "use strict";
  const R = global.RuiApp;
  const { h, icon, page, card, button, textButton, selectTile, notice, infoRow, sectionTitle, toggle } = R.ui;
  const W = (R.widgets = R.widgets || {});

  /** OrderSummaryCard. */
  W.orderSummaryCard = function orderSummaryCard(ctx, summary, { canChangeAddress = false } = {}) {
    const { x } = ctx;
    return card({ pad: 14 },
      summary.details.map((l) => infoRow(ctx.t(l.label), ctx.t(l.value))),
      canChangeAddress && summary.module !== "mediation"
        ? h("div", { style: { textAlign: "end" } }, h("span", { class: "rui-link-btn" }, textButton({
          key: "change-address", icon: "edit_location_alt", label: x("تغيير العنوان", "Change address"),
          onClick: () => W.showAddressSheet(ctx, { target: "order" }),
        })))
        : null,
      h("hr", { class: "rui-divider" }),
      summary.prices.map((p) => infoRow(ctx.t(p.label), `${p.amount < 0 ? "-" : ""}${Math.abs(p.amount)} ${x("ر.س", "SAR")}`)),
      h("hr", { class: "rui-divider" }),
      infoRow(x("الإجمالي", "Total"), ctx.money(summary.total), { bold: true }));
  };

  R.screens[R.Routes.payment] = function paymentScreen(ctx) {
    const { x, session, state: st } = ctx;
    const module = ctx.args || "individuals";
    const summary = session.summary(module);

    async function pay() {
      const total = session.summary(module).total;
      const ok = await ctx.dialog({
        title: x("تأكيد الدفع التجريبي", "Confirm demo payment"),
        content: x(`سيتم "دفع" ${total} ر.س بشكل تجريبي. لن يتم خصم أي مبلغ.`, `This will "pay" ${total} SAR as a simulation. No money is charged.`),
        actions: [
          { label: x("إلغاء", "Cancel"), value: false },
          { label: x("تأكيد", "Confirm"), value: true, primary: true, key: "pay-confirm" },
        ],
      });
      if (ok !== true) return;
      st.busy = true; st.failure = null; ctx.refresh();
      const result = await session.pay(module);
      st.busy = false;
      if (result.isSuccess) ctx.nav.replace(R.Routes.success, module);
      else { st.failure = ctx.t(result.failureReason); ctx.refresh(); }
    }

    return page(ctx, {
      title: x("الدفع", "Payment"),
      subtitle: ctx.t(summary.title),
      bottom: button({ key: "pay-button", label: `${x("ادفع", "Pay")} ${ctx.money(summary.total)}`, loading: st.busy, onClick: pay }),
      body: [
        notice(x("دفع تجريبي: لا يتم إدخال أو حفظ بيانات بطاقات حقيقية.", "Simulated payment: no real card data is entered or stored."), { kind: "warning" }),
        sectionTitle(x("ملخص الطلب", "Order summary")),
        W.orderSummaryCard(ctx, summary, { canChangeAddress: true }),
        sectionTitle(x("طريقة الدفع", "Payment method")),
        ctx.repo.paymentMethods.map((m) => selectTile({
          key: `method-${m.id}`, selected: session.paymentMethodId === m.id, onTap: () => session.setPaymentMethod(m.id),
          leading: icon(m.icon), title: ctx.t(m.name),
        })),
        h("div", { style: { padding: "6px 0" } }, toggle({
          key: "simulate-failure", checked: session.simulateFailure,
          label: x("تجريبي: محاكاة فشل الدفع", "Demo: simulate a failed payment"),
          onChange: (v) => session.setSimulateFailure(v),
        })),
        st.failure ? notice(`${x("فشل الدفع", "Payment failed")}: ${st.failure}`, { kind: "error" }) : null,
      ],
    });
  };

  R.screens[R.Routes.success] = function successScreen(ctx) {
    const { x, session } = ctx;
    const module = ctx.args || "individuals";
    const order = session.lastOrder;
    const info = R.ModuleInfo[module];
    return page(ctx, {
      title: x("تم بنجاح", "Success"),
      back: false,
      bottom: button({
        key: "success-home", label: x("العودة إلى الرئيسية", "Back to Home"), icon: "home",
        onClick: () => { session.completeFlow(module); ctx.nav.replaceAll(R.Routes.main); },
      }),
      body: h("div", { class: "rui-stack", style: { justifyItems: "center", textAlign: "center", paddingTop: "12px" } },
        icon("check_circle", { size: 84, fill: true, color: "#2E7D32" }),
        h("h2", { class: "rui-title" }, module === "hourly" ? x("تم تأكيد الحجز التجريبي", "Demo booking confirmed") : x("تم تأكيد الطلب التجريبي", "Demo order confirmed")),
        h("div", null, ctx.t(info.title)),
        order ? h("strong", { class: "rui-subtitle", key: "order-reference", style: { color: "var(--rui-primary)", userSelect: "all" } }, order.reference) : null,
        order ? h("div", { style: { width: "100%", textAlign: "start" } }, W.orderSummaryCard(ctx, order.summary)) : null,
        h("p", { class: "rui-body-sm" }, x("هذه رسالة تأكيد تجريبية. لم يتم إنشاء حجز حقيقي.", "This is a demo confirmation. No real booking was created."))),
    });
  };
})(window);
