import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'scope.dart';

/// Shared address selection used by the Individuals and Hourly flows.
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _showError = false;

  void _continue() {
    final d = DemoScope.of(context);
    if (d.session.selectedAddress == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pushNamed(
      widget.module == ServiceModule.hourly
          ? DemoRoutes.hrPackages
          : DemoRoutes.indPackages,
      arguments: widget.module,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    return RuiPage(
      title: s.x('اختر العنوان', 'Choose address'),
      subtitle: s.x('الخطوة 1', 'Step 1'),
      bottom: RuiButton(
        key: const ValueKey('address-continue'),
        template: d.template,
        label: s.x('متابعة', 'Continue'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RuiSectionTitle(s.x('عناويني المحفوظة', 'Saved addresses')),
          if (session.addresses.isEmpty)
            Text(s.x('لا توجد عناوين بعد', 'No saved addresses yet')),
          for (final a in session.addresses)
            RuiSelectTile(
              key: ValueKey('address-${a.id}'),
              template: d.template,
              selected: a.id == session.selectedAddressId,
              onTap: () {
                setState(() => _showError = false);
                session.selectAddress(a.id);
              },
              leading: const Icon(Icons.location_on_outlined),
              title: a.label.of(d.lang),
              subtitle: a.oneLine(d.lang),
            ),
          if (_showError)
            RuiNotice(
              s.x('اختر عنواناً للمتابعة', 'Select an address to continue'),
              kind: BannerKind.error,
            ),
          const SizedBox(height: 8),
          RuiButton(
            key: const ValueKey('address-add'),
            template: d.template,
            label: s.x('إضافة عنوان جديد', 'Add a new address'),
            icon: Icons.add_location_alt_outlined,
            outlined: true,
            onPressed: () =>
                showRuiSheet<void>(context, (_) => const _AddressForm()),
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm();

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _key = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _district = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _notes = TextEditingController();
  L? _city;

  @override
  void dispose() {
    for (final c in [_label, _district, _street, _building, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    final d = DemoScope.of(context);
    d.session.addAddress(
      DemoAddress(
        id: 'a${DateTime.now().microsecondsSinceEpoch}',
        label: L.same(_label.text.trim()),
        city: _city!,
        district: L.same(_district.text.trim()),
        street: L.same(_street.text.trim()),
        building: _building.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    String? required(String? v) => (v == null || v.trim().isEmpty)
        ? s.x('هذا الحقل مطلوب', 'This field is required')
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.x('عنوان جديد', 'New address'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('addr-label'),
                controller: _label,
                decoration: InputDecoration(
                  labelText: s.x(
                    'اسم العنوان (مثل: المنزل)',
                    'Label (e.g. Home)',
                  ),
                ),
                validator: required,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<L>(
                key: const ValueKey('addr-city'),
                initialValue: _city,
                decoration: InputDecoration(labelText: s.x('المدينة', 'City')),
                items: [
                  for (final c in d.session.repo.cities)
                    DropdownMenuItem(value: c, child: Text(c.of(d.lang))),
                ],
                onChanged: (v) => setState(() => _city = v),
                validator: (v) =>
                    v == null ? s.x('اختر المدينة', 'Select a city') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('addr-district'),
                controller: _district,
                decoration: InputDecoration(labelText: s.x('الحي', 'District')),
                validator: required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('addr-street'),
                controller: _street,
                decoration: InputDecoration(labelText: s.x('الشارع', 'Street')),
                validator: required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('addr-building'),
                controller: _building,
                decoration: InputDecoration(
                  labelText: s.x('رقم المبنى', 'Building no.'),
                ),
                validator: required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: s.x('ملاحظات (اختياري)', 'Notes (optional)'),
                ),
              ),
              const SizedBox(height: 14),
              RuiButton(
                key: const ValueKey('addr-save'),
                template: d.template,
                label: s.x('حفظ العنوان', 'Save address'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
