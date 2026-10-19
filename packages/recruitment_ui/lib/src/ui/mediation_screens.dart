import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/repository.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'individuals_screens.dart';
import 'scope.dart';

/// Mediation step 1: profession + nationality.
class MediationCriteriaScreen extends StatefulWidget {
  const MediationCriteriaScreen({super.key});

  @override
  State<MediationCriteriaScreen> createState() =>
      _MediationCriteriaScreenState();
}

class _MediationCriteriaScreenState extends State<MediationCriteriaScreen> {
  bool _submitted = false;

  void _continue() {
    final session = DemoScope.of(context).session;
    if (session.medProfessionId == null || session.medNationalityId == null) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).pushNamed(DemoRoutes.medPackages);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final scheme = Theme.of(context).colorScheme;
    return RuiPage(
      title: s.x('المهنة والجنسية', 'Profession & nationality'),
      subtitle: s.x('الخطوة 1', 'Step 1'),
      bottom: RuiButton(
        key: const ValueKey('med-criteria-continue'),
        template: d.template,
        label: s.x('عرض الباقات', 'View packages'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RuiSectionTitle(s.x('اختر المهنة', 'Choose a profession')),
          for (final p in session.repo.professions)
            RuiSelectTile(
              key: ValueKey('profession-${p.id}'),
              template: d.template,
              selected: session.medProfessionId == p.id,
              onTap: () => session.setMedCriteria(professionId: p.id),
              leading: Icon(p.icon, color: scheme.primary),
              title: p.name.of(d.lang),
            ),
          if (_submitted && session.medProfessionId == null)
            RuiNotice(
              s.x('اختر المهنة', 'Select a profession'),
              kind: BannerKind.error,
            ),
          const SizedBox(height: 8),
          NationalitySelector(
            value: session.medNationalityId,
            errorText: _submitted && session.medNationalityId == null
                ? s.x('اختر الجنسية', 'Select a nationality')
                : null,
            onChanged: (v) => session.setMedCriteria(nationalityId: v),
          ),
        ],
      ),
    );
  }
}

/// Mediation step 2: packages for the chosen criteria.
class MediationPackagesScreen extends StatefulWidget {
  const MediationPackagesScreen({super.key});

  @override
  State<MediationPackagesScreen> createState() =>
      _MediationPackagesScreenState();
}

class _MediationPackagesScreenState extends State<MediationPackagesScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final prof = session.repo.profession(
      session.medProfessionId ?? 'housemaid',
    );
    final nat = session.repo.nationality(session.medNationalityId ?? 'ph');
    return RuiPage(
      title: s.x('باقات الوساطة', 'Mediation packages'),
      subtitle: '${prof.name.of(d.lang)} · ${nat.name.of(d.lang)}',
      bottom: RuiButton(
        key: const ValueKey('med-packages-continue'),
        template: d.template,
        label: s.x('متابعة', 'Continue'),
        onPressed: () {
          if (session.medPackageId == null) {
            setState(() => _showError = true);
            return;
          }
          Navigator.of(context).pushNamed(DemoRoutes.medMethod);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in session.repo.mediationPackages)
            RecruitPackageCard(
              key: ValueKey('med-package-${p.id}'),
              package: p,
              price: PricingRules.mediationPrice(
                p,
                session.medNationalityId ?? 'ph',
                session.medProfessionId ?? 'housemaid',
              ),
              selected: p.id == session.medPackageId,
              onTap: () {
                setState(() => _showError = false);
                session.setMedPackage(p.id);
              },
            ),
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

/// Mediation step 3: how to choose the worker.
class WorkerMethodScreen extends StatelessWidget {
  const WorkerMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget option(
      Key key,
      IconData icon,
      String title,
      String body,
      VoidCallback onTap,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RuiCard(
        key: key,
        template: d.template,
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(body, style: text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );

    return RuiPage(
      title: s.x('طريقة اختيار العاملة', 'How to choose the worker'),
      subtitle: s.x('الوساطة', 'Mediation'),
      child: Column(
        children: [
          option(
            const ValueKey('method-browse'),
            Icons.grid_view,
            s.x('تصفح العاملات', 'Browse workers'),
            s.x(
              'استعرض العاملات المتاحات واطلع على التفاصيل',
              'See available workers and their details',
            ),
            () => Navigator.of(
              context,
            ).pushNamed(DemoRoutes.workers, arguments: ServiceModule.mediation),
          ),
          option(
            const ValueKey('method-search'),
            Icons.search,
            s.x('البحث بالاسم', 'Search by name'),
            s.x('ابحث عن عاملة محددة باسمها', 'Find a specific worker by name'),
            () => Navigator.of(context).pushNamed(DemoRoutes.medSearch),
          ),
        ],
      ),
    );
  }
}
