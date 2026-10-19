import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'scope.dart';

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Contract review + customer form, shared by Individuals and Mediation.
/// Demo only: nothing here is a legal contract and nothing is submitted.
class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nid;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _date;
  bool _ackError = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final c = DemoScope.of(context).session.contractFor(widget.module);
    _name = TextEditingController(text: c.fullName);
    _nid = TextEditingController(text: c.nationalId);
    _email = TextEditingController(text: c.email);
    _phone = TextEditingController(text: c.phone);
    _date = TextEditingController(
      text: c.startDate == null ? '' : formatDate(c.startDate!),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _nid, _email, _phone, _date]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save({DateTime? date, bool? acknowledged}) {
    final session = DemoScope.of(context).session;
    final old = session.contractFor(widget.module);
    session.setContract(
      widget.module,
      old.copyWith(
        fullName: _name.text,
        nationalId: _nid.text,
        email: _email.text,
        phone: _phone.text,
        startDate: date,
        acknowledged: acknowledged,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked == null) return;
    _date.text = formatDate(picked);
    _save(date: picked);
  }

  void _continue() {
    final session = DemoScope.of(context).session;
    final formOk = _form.currentState!.validate();
    final ack = session.contractFor(widget.module).acknowledged;
    setState(() => _ackError = !ack);
    if (!formOk || !ack) return;
    Navigator.of(
      context,
    ).pushNamed(DemoRoutes.payment, arguments: widget.module);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final summary = session.summary(widget.module);
    final contract = session.contractFor(widget.module);
    String? required(String? v) => (v == null || v.trim().isEmpty)
        ? s.x('هذا الحقل مطلوب', 'This field is required')
        : null;

    return RuiPage(
      title: s.x('نموذج العقد', 'Contract form'),
      subtitle: summary.title.of(d.lang),
      bottom: RuiButton(
        key: const ValueKey('contract-continue'),
        template: d.template,
        label: s.x('المتابعة للدفع', 'Continue to payment'),
        onPressed: _continue,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RuiNotice(
              s.x(
                'عقد تجريبي للعرض فقط وليس ملزماً قانونياً. لا يتم إرسال أي بيانات.',
                'Demo contract for preview only — not legally binding. No data is submitted.',
              ),
              kind: BannerKind.warning,
            ),
            RuiSectionTitle(s.x('مراجعة الطلب', 'Review order')),
            RuiCard(
              template: d.template,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final line in summary.details)
                    RuiInfoRow(line.label.of(d.lang), line.value.of(d.lang)),
                ],
              ),
            ),
            RuiSectionTitle(s.x('بيانات العميل', 'Customer details')),
            TextFormField(
              key: const ValueKey('contract-name'),
              controller: _name,
              onChanged: (_) => _save(),
              decoration: InputDecoration(
                labelText: s.x('الاسم الكامل', 'Full name'),
              ),
              validator: (v) => (v ?? '').trim().length < 3
                  ? s.x(
                      'أدخل الاسم الكامل (3 أحرف على الأقل)',
                      'Enter your full name (min 3 characters)',
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('contract-nid'),
              controller: _nid,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (_) => _save(),
              decoration: InputDecoration(
                labelText: s.x('رقم الهوية', 'National ID'),
              ),
              validator: (v) => ContractRules.validNationalId(v ?? '')
                  ? null
                  : s.x(
                      '10 أرقام تبدأ بـ 1 أو 2',
                      '10 digits starting with 1 or 2',
                    ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('contract-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              onChanged: (_) => _save(),
              decoration: InputDecoration(
                labelText: s.x('البريد الإلكتروني', 'Email'),
              ),
              validator: (v) => ContractRules.validEmail(v ?? '')
                  ? null
                  : s.x('بريد إلكتروني غير صحيح', 'Invalid email address'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('contract-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              onChanged: (_) => _save(),
              decoration: InputDecoration(
                labelText: s.x('رقم الجوال', 'Phone'),
              ),
              validator: (v) => ContractRules.validPhone(v ?? '')
                  ? null
                  : s.x('رقم جوال غير صحيح', 'Invalid phone number'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('contract-date'),
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: s.x('تاريخ بدء العقد', 'Contract start date'),
                suffixIcon: const Icon(Icons.calendar_month),
              ),
              validator: required,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const ValueKey('contract-ack'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: contract.acknowledged,
              onChanged: (v) {
                setState(() => _ackError = false);
                _save(acknowledged: v ?? false);
              },
              title: Text(
                s.x(
                  'أقرّ بأنني اطلعت على العقد التجريبي',
                  'I acknowledge this demo contract',
                ),
              ),
            ),
            if (_ackError)
              RuiNotice(
                s.x('يجب الإقرار للمتابعة', 'Acknowledgement is required'),
                kind: BannerKind.error,
              ),
          ],
        ),
      ),
    );
  }
}
