import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'address_sheet.dart';
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
            onPressed: () => showAddressForm(context),
          ),
        ],
      ),
    );
  }
}
