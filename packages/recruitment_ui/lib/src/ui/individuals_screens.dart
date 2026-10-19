import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/repository.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'scope.dart';

/// Nationality dropdown shared by Individuals and Mediation.
class NationalitySelector extends StatelessWidget {
  const NationalitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    return DropdownButtonFormField<String>(
      key: const ValueKey('nationality-select'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: d.s.x('الجنسية', 'Nationality'),
        errorText: errorText,
        prefixIcon: const Icon(Icons.flag_outlined),
      ),
      items: [
        for (final n in d.session.repo.nationalities)
          DropdownMenuItem(
            value: n.id,
            child: Text('${n.flag}  ${n.name.of(d.lang)}'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Package card shared by Individuals and Mediation.
class RecruitPackageCard extends StatelessWidget {
  const RecruitPackageCard({
    super.key,
    required this.package,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final RecruitPackage package;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return RuiSelectTile(
      template: d.template,
      selected: selected,
      onTap: onTap,
      title: package.name.of(d.lang),
      subtitle: package.description.of(d.lang),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (package.popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: scheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.x('الأكثر طلباً', 'Popular'),
                style: TextStyle(fontSize: 10, color: scheme.onSecondary),
              ),
            ),
          Text(
            '$price',
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
            for (final inc in package.includes)
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.check, size: 14),
                label: Text(
                  inc.of(d.lang),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individuals step 2: packages and nationality.
class IndividualsPackagesScreen extends StatefulWidget {
  const IndividualsPackagesScreen({super.key});

  @override
  State<IndividualsPackagesScreen> createState() =>
      _IndividualsPackagesScreenState();
}

class _IndividualsPackagesScreenState extends State<IndividualsPackagesScreen> {
  bool _submitted = false;

  void _continue() {
    final session = DemoScope.of(context).session;
    if (session.indNationalityId == null || session.indPackageId == null) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(DemoRoutes.workers, arguments: ServiceModule.individuals);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final natError = _submitted && session.indNationalityId == null
        ? s.x('اختر الجنسية', 'Select a nationality')
        : null;
    final pkgError = _submitted && session.indPackageId == null
        ? s.x('اختر باقة', 'Select a package')
        : null;
    return RuiPage(
      title: s.x('الباقات والجنسية', 'Packages & nationality'),
      subtitle: s.x('الخطوة 2', 'Step 2'),
      bottom: RuiButton(
        key: const ValueKey('ind-packages-continue'),
        template: d.template,
        label: s.x('عرض العاملات', 'View workers'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NationalitySelector(
            value: session.indNationalityId,
            errorText: natError,
            onChanged: session.setIndNationality,
          ),
          RuiSectionTitle(s.x('الباقات المتاحة', 'Available packages')),
          for (final p in session.repo.individualsPackages)
            RecruitPackageCard(
              key: ValueKey('ind-package-${p.id}'),
              package: p,
              price: PricingRules.recruitmentPrice(
                p,
                session.indNationalityId ?? '',
              ),
              selected: p.id == session.indPackageId,
              onTap: () => session.setIndPackage(p.id),
            ),
          if (session.indNationalityId == null)
            Text(
              s.x(
                'اختر الجنسية لعرض الأسعار النهائية.',
                'Select a nationality to see final prices.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (pkgError != null) RuiNotice(pkgError, kind: BannerKind.error),
        ],
      ),
    );
  }
}
