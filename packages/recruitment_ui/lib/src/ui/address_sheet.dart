import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../widgets.dart';
import 'scope.dart';

/// What picking an address in [showAddressSheet] changes.
enum AddressTarget {
  /// The customer's main address (shown in the Home header).
  main,

  /// The address of the order being placed.
  order,
}

/// Bottom sheet listing the saved addresses. Tapping one applies it to
/// [target] and closes the sheet; "Add a new address" opens the add form and
/// applies the new address too. Returns the chosen address, or null when the
/// sheet was dismissed.
Future<DemoAddress?> showAddressSheet(
  BuildContext context, {
  required AddressTarget target,
}) {
  return showRuiSheet<DemoAddress>(
    context,
    (_) => _AddressSheet(target: target),
  );
}

/// Opens the add-address form. Returns the saved address (already added to the
/// session), or null if cancelled.
Future<DemoAddress?> showAddressForm(
  BuildContext context, {
  bool offerMain = false,
  bool mainByDefault = false,
}) {
  return showRuiSheet<DemoAddress>(
    context,
    (_) => AddressFormSheet(offerMain: offerMain, mainByDefault: mainByDefault),
  );
}

class _AddressSheet extends StatelessWidget {
  const _AddressSheet({required this.target});
  final AddressTarget target;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final main = target == AddressTarget.main;
    final selectedId = main
        ? session.mainAddress?.id
        : session.selectedAddressId;

    void pick(DemoAddress a) {
      main ? session.setMainAddress(a.id) : session.selectAddress(a.id);
      Navigator.of(context).pop(a);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                main
                    ? s.x('عنواني الرئيسي', 'My main address')
                    : s.x('عنوان الطلب', 'Order address'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (session.addresses.isEmpty)
                      RuiEmptyState(
                        icon: Icons.location_off_outlined,
                        title: s.x(
                          'لا توجد عناوين بعد',
                          'No saved addresses yet',
                        ),
                      ),
                    for (final a in session.addresses)
                      RuiSelectTile(
                        key: ValueKey('sheet-address-${a.id}'),
                        template: d.template,
                        selected: a.id == selectedId,
                        onTap: () => pick(a),
                        leading: const Icon(Icons.location_on_outlined),
                        title: a.label.of(d.lang),
                        subtitle: a.oneLine(d.lang),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RuiButton(
                key: const ValueKey('sheet-address-add'),
                template: d.template,
                label: s.x('إضافة عنوان جديد', 'Add a new address'),
                icon: Icons.add_location_alt_outlined,
                outlined: true,
                onPressed: () async {
                  final added = await showAddressForm(
                    context,
                    offerMain: main,
                    mainByDefault: main,
                  );
                  if (added != null && context.mounted) {
                    Navigator.of(context).pop(added);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The add-address form (shared by the flow's address step and the Home
/// header). Saving adds the address to the session, selects it and pops it.
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({
    super.key,
    this.offerMain = false,
    this.mainByDefault = false,
  });

  /// Shows the "use as my main address" switch.
  final bool offerMain;
  final bool mainByDefault;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _key = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _district = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _notes = TextEditingController();
  L? _city;
  late bool _makeMain = widget.mainByDefault;

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
    final address = DemoAddress(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      label: L.same(_label.text.trim()),
      city: _city!,
      district: L.same(_district.text.trim()),
      street: L.same(_street.text.trim()),
      building: _building.text.trim(),
      notes: _notes.text.trim(),
    );
    d.session.addAddress(address);
    if (widget.offerMain && _makeMain) d.session.setMainAddress(address.id);
    Navigator.of(context).pop(address);
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
              if (widget.offerMain)
                SwitchListTile(
                  key: const ValueKey('addr-make-main'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    s.x('عيّنه كعنواني الرئيسي', 'Set as my main address'),
                  ),
                  value: _makeMain,
                  onChanged: (v) => setState(() => _makeMain = v),
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
