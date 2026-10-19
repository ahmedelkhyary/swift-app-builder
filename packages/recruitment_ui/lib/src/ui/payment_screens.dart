import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'main_shell.dart';
import 'scope.dart';

/// Order summary card shared by payment and success.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.summary});
  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    return RuiCard(
      template: d.template,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (final line in summary.details)
            RuiInfoRow(line.label.of(d.lang), line.value.of(d.lang)),
          const Divider(),
          for (final p in summary.prices)
            RuiInfoRow(
              p.label.of(d.lang),
              '${p.amount < 0 ? '-' : ''}${p.amount.abs()} ${s.x('ر.س', 'SAR')}',
            ),
          const Divider(),
          RuiInfoRow(
            s.x('الإجمالي', 'Total'),
            '${summary.total} ${s.x('ر.س', 'SAR')}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

/// Common simulated payment for every module. No real payment is made.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _busy = false;
  String? _failure;

  Future<void> _pay() async {
    final d = DemoScope.of(context);
    final s = d.s;
    final total = d.session.summary(widget.module).total;
    final ok = await showRuiDialog<bool>(
      context,
      (ctx) => AlertDialog(
        title: Text(s.x('تأكيد الدفع التجريبي', 'Confirm demo payment')),
        content: Text(
          s.x(
            'سيتم "دفع" $total ر.س بشكل تجريبي. لن يتم خصم أي مبلغ.',
            'This will "pay" $total SAR as a simulation. No money is charged.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.x('إلغاء', 'Cancel')),
          ),
          FilledButton(
            key: const ValueKey('pay-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.x('تأكيد', 'Confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await d.session.pay(widget.module);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      Navigator.of(
        context,
      ).pushReplacementNamed(DemoRoutes.success, arguments: widget.module);
    } else {
      setState(() => _failure = result.failureReason!.of(d.lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final summary = session.summary(widget.module);
    return RuiPage(
      title: s.x('الدفع', 'Payment'),
      subtitle: summary.title.of(d.lang),
      bottom: RuiButton(
        key: const ValueKey('pay-button'),
        template: d.template,
        label: '${s.x('ادفع', 'Pay')} ${summary.total} ${s.x('ر.س', 'SAR')}',
        loading: _busy,
        onPressed: _pay,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RuiNotice(
            s.x(
              'دفع تجريبي: لا يتم إدخال أو حفظ بيانات بطاقات حقيقية.',
              'Simulated payment: no real card data is entered or stored.',
            ),
            kind: BannerKind.warning,
          ),
          RuiSectionTitle(s.x('ملخص الطلب', 'Order summary')),
          OrderSummaryCard(summary: summary),
          RuiSectionTitle(s.x('طريقة الدفع', 'Payment method')),
          for (final m in session.repo.paymentMethods)
            RuiSelectTile(
              key: ValueKey('method-${m.id}'),
              template: d.template,
              selected: session.paymentMethodId == m.id,
              onTap: () => session.setPaymentMethod(m.id),
              leading: Icon(m.icon),
              title: m.name.of(d.lang),
            ),
          SwitchListTile(
            key: const ValueKey('simulate-failure'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              s.x(
                'تجريبي: محاكاة فشل الدفع',
                'Demo: simulate a failed payment',
              ),
            ),
            value: session.simulateFailure,
            onChanged: session.setSimulateFailure,
          ),
          if (_failure != null)
            RuiNotice(
              '${s.x('فشل الدفع', 'Payment failed')}: $_failure',
              kind: BannerKind.error,
            ),
        ],
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final order = d.session.lastOrder;
    final text = Theme.of(context).textTheme;
    final info = ModuleInfo.of(module);
    return RuiPage(
      title: s.x('تم بنجاح', 'Success'),
      showBack: false,
      bottom: RuiButton(
        key: const ValueKey('success-home'),
        template: d.template,
        label: s.x('العودة إلى الرئيسية', 'Back to Home'),
        icon: Icons.home,
        onPressed: () {
          d.session.completeFlow(module);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(DemoRoutes.main, (_) => false);
        },
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.check_circle, size: 84, color: Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          Text(
            module == ServiceModule.hourly
                ? s.x('تم تأكيد الحجز التجريبي', 'Demo booking confirmed')
                : s.x('تم تأكيد الطلب التجريبي', 'Demo order confirmed'),
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(info.title.of(d.lang), style: text.bodyMedium),
          const SizedBox(height: 12),
          if (order != null) ...[
            SelectableText(
              order.reference,
              key: const ValueKey('order-reference'),
              style: text.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            OrderSummaryCard(summary: order.summary),
          ],
          const SizedBox(height: 8),
          Text(
            s.x(
              'هذه رسالة تأكيد تجريبية. لم يتم إنشاء حجز حقيقي.',
              'This is a demo confirmation. No real booking was created.',
            ),
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
