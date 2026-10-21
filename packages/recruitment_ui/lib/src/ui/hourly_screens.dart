import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/repository.dart' show PricingRules;
import '../demo/session.dart';
import '../strings.dart';
import '../widgets.dart';
import 'contract_screen.dart' show formatDate;
import 'payment_screens.dart';
import 'scope.dart';

/// Hourly step 2: fixed packages or a custom package.
class HourlyPackagesScreen extends StatefulWidget {
  const HourlyPackagesScreen({super.key});

  @override
  State<HourlyPackagesScreen> createState() => _HourlyPackagesScreenState();
}

class _HourlyPackagesScreenState extends State<HourlyPackagesScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return RuiPage(
      title: s.x('اختر الباقة', 'Choose a package'),
      subtitle: s.x('الخطوة 2', 'Step 2'),
      bottom: RuiButton(
        key: const ValueKey('hr-packages-continue'),
        template: d.template,
        label: s.x('متابعة', 'Continue'),
        onPressed: () {
          if (!session.hourlyHasSelection) {
            setState(() => _showError = true);
            return;
          }
          Navigator.of(context).pushNamed(DemoRoutes.hrDetails);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            key: const ValueKey('hr-mode'),
            segments: [
              ButtonSegment(
                value: false,
                label: Text(s.x('باقات جاهزة', 'Fixed packages')),
              ),
              ButtonSegment(
                value: true,
                label: Text(s.x('صمّم باقتك', 'Design your own')),
              ),
            ],
            selected: {session.hourlyCustom},
            onSelectionChanged: (v) {
              setState(() => _showError = false);
              if (v.first) {
                session.useCustomHourly();
              } else {
                session.useFixedHourly();
              }
            },
          ),
          const SizedBox(height: 12),
          if (!session.hourlyCustom)
            for (final p in session.repo.hourlyPackages)
              RuiSelectTile(
                key: ValueKey('hr-package-${p.id}'),
                template: d.template,
                selected: session.hourlyPackageId == p.id,
                onTap: () {
                  setState(() => _showError = false);
                  session.selectHourlyPackage(p.id);
                },
                title: p.name.of(d.lang),
                subtitle: p.description.of(d.lang),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session.priceFor(p.hoursPerVisit, p.visitsPerWeek, p.weeks)}',
                      style: text.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(s.x('ر.س', 'SAR'), style: text.bodySmall),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('${p.totalHours} ${s.x('ساعة', 'hours')}'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('${p.visits} ${s.x('زيارة', 'visits')}'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('${p.visitsPerWeek}/${s.x('أسبوع', 'wk')}'),
                      ),
                    ],
                  ),
                ),
              )
          else
            const _CustomPackageBuilder(),
          if (_showError)
            RuiNotice(
              s.x('اختر باقة للمتابعة', 'Select a package to continue'),
              kind: BannerKind.error,
            ),
        ],
      ),
    );
  }
}

class _CustomPackageBuilder extends StatelessWidget {
  const _CustomPackageBuilder();

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final c = session.customHourly;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget stepper(
      Key key,
      String label,
      int value,
      int min,
      int max,
      ValueChanged<int> onChanged, {
      String suffix = '',
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton.outlined(
              key: ValueKey('${(key as ValueKey).value}-minus'),
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 70,
              child: Text(
                '$value$suffix',
                key: key,
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ),
            IconButton.outlined(
              key: ValueKey('${key.value}-plus'),
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      );
    }

    final price = session.priceFor(c.hoursPerVisit, c.visitsPerWeek, c.weeks);
    return RuiCard(
      template: d.template,
      selected: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stepper(
            const ValueKey('custom-hours'),
            s.x('ساعات الزيارة', 'Hours per visit'),
            c.hoursPerVisit,
            2,
            8,
            (v) => session.setCustomHourly(c.copyWith(hoursPerVisit: v)),
            suffix: s.x(' س', ' h'),
          ),
          stepper(
            const ValueKey('custom-visits'),
            s.x('زيارات أسبوعياً', 'Visits per week'),
            c.visitsPerWeek,
            1,
            5,
            (v) => session.setCustomHourly(c.copyWith(visitsPerWeek: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<int>(
              key: const ValueKey('custom-weeks'),
              initialValue: c.weeks,
              decoration: InputDecoration(
                labelText: s.x('المدة (أسابيع)', 'Duration (weeks)'),
              ),
              items: [
                for (final w in const [1, 2, 4, 8, 12])
                  DropdownMenuItem(
                    value: w,
                    child: Text('$w ${s.x('أسبوع', 'weeks')}'),
                  ),
              ],
              onChanged: (v) => session.setCustomHourly(c.copyWith(weeks: v)),
            ),
          ),
          const Divider(),
          RuiInfoRow(s.x('إجمالي الزيارات', 'Total visits'), '${c.visits}'),
          RuiInfoRow(s.x('إجمالي الساعات', 'Total hours'), '${c.totalHours}'),
          RuiInfoRow(
            s.x('السعر التقديري', 'Estimated price'),
            '$price ${s.x('ر.س', 'SAR')}',
            bold: true,
          ),
          Text(
            s.x(
              'تسعير تجريبي: ${PricingRules.hourlyRate} ر.س/ساعة مع خصم للمدد الطويلة.',
              'Demo pricing: ${PricingRules.hourlyRate} SAR/hour with a discount for longer terms.',
            ),
            style: text.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

/// Hourly step 3: schedule, discount code, summary.
class HourlyDetailsScreen extends StatefulWidget {
  const HourlyDetailsScreen({super.key});

  @override
  State<HourlyDetailsScreen> createState() => _HourlyDetailsScreenState();
}

class _HourlyDetailsScreenState extends State<HourlyDetailsScreen> {
  final _code = TextEditingController();
  final _start = TextEditingController();
  DiscountResult? _lastResult;
  bool _submitted = false;

  @override
  void dispose() {
    _code.dispose();
    _start.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final session = DemoScope.of(context).session;
    final now = DateTime.now();
    var first = now.add(const Duration(days: 1));
    while (!session.repo.serviceWeekdays.contains(first.weekday)) {
      first = first.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: session.hourlyStartDate ?? first,
      firstDate: first,
      lastDate: now.add(const Duration(days: 90)),
      selectableDayPredicate: (day) =>
          session.repo.serviceWeekdays.contains(day.weekday),
    );
    if (picked != null) session.setHourlyStart(picked);
  }

  void _apply() {
    final session = DemoScope.of(context).session;
    if (_code.text.trim().isEmpty) return;
    setState(() => _lastResult = session.applyDiscount(_code.text));
  }

  String _discountMessage(DiscountResult r, RuiStrings s) => switch (r.status) {
    DiscountStatus.applied => s.x(
      'تم تطبيق الكود ${r.code}: خصم ${r.amount} ر.س',
      'Code ${r.code} applied: -${r.amount} SAR',
    ),
    DiscountStatus.invalid => s.x(
      'كود الخصم غير صحيح',
      'Invalid discount code',
    ),
    DiscountStatus.expired => s.x(
      'انتهت صلاحية الكود',
      'This code has expired',
    ),
    DiscountStatus.minimumNotMet => s.x(
      'الحد الأدنى للطلب 300 ر.س لهذا الكود',
      'Minimum order of 300 SAR for this code',
    ),
    DiscountStatus.none => '',
  };

  void _continue() {
    final session = DemoScope.of(context).session;
    if (!session.hourlyDetailsComplete) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(DemoRoutes.payment, arguments: ServiceModule.hourly);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final summary = session.summary(ServiceModule.hourly);
    final addr = session.selectedAddress;
    final need = session.visitsPerWeek;
    final start = session.hourlyStartDate;
    _start.text = start == null ? '' : formatDate(start);

    return RuiPage(
      title: s.x('تفاصيل الخدمة', 'Service details'),
      subtitle: s.x('الخطوة 3', 'Step 3'),
      bottom: RuiButton(
        key: const ValueKey('hr-details-continue'),
        template: d.template,
        label: s.x('المتابعة للدفع', 'Continue to payment'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RuiCard(
            template: d.template,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                RuiInfoRow(
                  s.x('العنوان', 'Address'),
                  addr?.oneLine(d.lang) ?? '-',
                ),
                RuiInfoRow(
                  s.x('الباقة', 'Package'),
                  summary.details[0].value.of(d.lang),
                ),
                RuiInfoRow(
                  s.x('المدة', 'Duration'),
                  summary.details[1].value.of(d.lang),
                ),
              ],
            ),
          ),
          RuiSectionTitle(s.x('تاريخ البدء', 'Start date')),
          TextFormField(
            key: const ValueKey('hr-start-date'),
            readOnly: true,
            controller: _start,
            onTap: _pickStart,
            decoration: InputDecoration(
              labelText: s.x(
                'اختر تاريخ أول زيارة',
                'Pick the first visit date',
              ),
              suffixIcon: const Icon(Icons.calendar_month),
              errorText: _submitted && start == null
                  ? s.x('اختر تاريخ البدء', 'Select a start date')
                  : null,
            ),
          ),
          RuiSectionTitle(
            s.x(
              'أيام الخدمة ($need أيام أسبوعياً)',
              'Service days ($need per week)',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in DemoSession.weekdayNames.entries)
                FilterChip(
                  key: ValueKey('day-${entry.key}'),
                  label: Text(entry.value.of(d.lang)),
                  selected: session.hourlyDays.contains(entry.key),
                  onSelected: session.repo.serviceWeekdays.contains(entry.key)
                      ? (_) => session.toggleHourlyDay(entry.key)
                      : null,
                ),
            ],
          ),
          Text(
            s.x('الجمعة غير متاحة.', 'Friday is unavailable.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_submitted && session.hourlyDays.length != need)
            RuiNotice(
              s.x('اختر $need أيام بالضبط', 'Select exactly $need days'),
              kind: BannerKind.error,
            ),
          RuiSectionTitle(s.x('كود الخصم', 'Discount code')),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('discount-field'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: s.x('أدخل الكود', 'Enter code'),
                    helperText: 'DEMO10 · SAVE50 · EXPIRED20',
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton(
                  key: const ValueKey('discount-apply'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(90, 48),
                  ),
                  onPressed: _apply,
                  child: Text(s.x('تطبيق', 'Apply')),
                ),
              ),
            ],
          ),
          if (_lastResult != null && _lastResult!.status != DiscountStatus.none)
            RuiNotice(
              _discountMessage(_lastResult!, s),
              kind: _lastResult!.isApplied
                  ? BannerKind.success
                  : BannerKind.error,
            ),
          RuiSectionTitle(s.x('ملخص السعر', 'Price summary')),
          OrderSummaryCard(summary: summary, canChangeAddress: true),
        ],
      ),
    );
  }
}
