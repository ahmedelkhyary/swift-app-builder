import 'package:flutter/material.dart';

import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'scope.dart';

String? _selectedWorkerId(DemoSession s, ServiceModule m) =>
    m == ServiceModule.mediation ? s.medWorkerId : s.indWorkerId;

void _selectWorker(DemoSession s, ServiceModule m, String id) =>
    m == ServiceModule.mediation
    ? s.selectMedWorker(id)
    : s.selectIndWorker(id);

/// Worker card shared by browse lists and search results.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, required this.module});
  final DemoWorker worker;
  final ServiceModule module;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedWorkerId(session, module) == worker.id;
    final nat = session.repo.nationality(worker.nationalityId);
    final prof = session.repo.profession(worker.professionId);
    return RuiSelectTile(
      key: ValueKey('worker-${worker.id}'),
      template: d.template,
      selected: selected,
      onTap: () => _selectWorker(session, module, worker.id),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: scheme.primary.withValues(alpha: 0.14),
        child: Icon(prof.icon, color: scheme.primary),
      ),
      title: worker.name.of(d.lang),
      subtitle: '${worker.code} · ${prof.name.of(d.lang)}',
      trailing: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: scheme.secondary),
              Text('${worker.rating}', style: text.bodySmall),
            ],
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? scheme.primary : scheme.outline,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${nat.flag} ${nat.name.of(d.lang)} · ${worker.years} ${s.x('سنوات خبرة', 'yrs experience')} · ${worker.age} ${s.x('سنة', 'y/o')}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('worker-details-${worker.id}'),
                    onPressed: () {
                      session.viewWorker(worker.id);
                      Navigator.of(
                        context,
                      ).pushNamed(DemoRoutes.worker, arguments: module);
                    },
                    child: Text(s.x('عرض التفاصيل', 'View details')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('worker-select-${worker.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () => _selectWorker(session, module, worker.id),
                    child: Text(
                      selected
                          ? s.x('تم الاختيار', 'Selected')
                          : s.x('اختيار', 'Select'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Browse list of workers (individuals: by nationality + package; mediation:
/// by profession + nationality).
class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  bool _showError = false;

  void _continue() {
    final session = DemoScope.of(context).session;
    final id = _selectedWorkerId(session, widget.module);
    if (id == null) {
      setState(() => _showError = true);
      return;
    }
    session.viewWorker(id);
    Navigator.of(
      context,
    ).pushNamed(DemoRoutes.worker, arguments: widget.module);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final isInd = widget.module == ServiceModule.individuals;
    final workers = isInd
        ? session.individualsWorkers()
        : session.mediationWorkers();
    return RuiPage(
      title: s.x('اختر العاملة', 'Choose a worker'),
      subtitle: isInd
          ? s.x('الخطوة 3', 'Step 3')
          : s.x('تصفح العاملات', 'Browse workers'),
      bottom: RuiButton(
        key: const ValueKey('workers-continue'),
        template: d.template,
        label: s.x('متابعة', 'Continue'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isInd) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      key: const ValueKey('filter-all'),
                      label: Text(s.x('الكل', 'All')),
                      selected: session.indProfessionFilter == null,
                      onSelected: (_) => session.setIndProfessionFilter(null),
                    ),
                  ),
                  for (final p in session.repo.professions)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        key: ValueKey('filter-${p.id}'),
                        label: Text(p.name.of(d.lang)),
                        selected: session.indProfessionFilter == p.id,
                        onSelected: (_) => session.setIndProfessionFilter(p.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
          RuiSectionTitle(
            s.x(
              '${workers.length} عاملة متاحة',
              '${workers.length} workers available',
            ),
          ),
          if (workers.isEmpty)
            RuiNotice(
              s.x(
                'لا توجد عاملات مطابقة. غيّر الفلتر أو الباقة.',
                'No workers match. Change the filter or package.',
              ),
              kind: BannerKind.warning,
            ),
          for (final w in workers) WorkerCard(worker: w, module: widget.module),
          if (_showError)
            RuiNotice(
              s.x('اختر عاملة للمتابعة', 'Select a worker to continue'),
              kind: BannerKind.error,
            ),
        ],
      ),
    );
  }
}

/// Mediation: select a worker by searching for their name.
class WorkerSearchScreen extends StatefulWidget {
  const WorkerSearchScreen({super.key});

  @override
  State<WorkerSearchScreen> createState() => _WorkerSearchScreenState();
}

class _WorkerSearchScreenState extends State<WorkerSearchScreen> {
  late final TextEditingController _query;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = DemoScope.of(context).session.medQuery;
    if (_query.text.isEmpty && q.isNotEmpty) _query.text = q;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _continue() {
    final session = DemoScope.of(context).session;
    final id = session.medWorkerId;
    if (id == null) {
      setState(() => _showError = true);
      return;
    }
    session.viewWorker(id);
    Navigator.of(
      context,
    ).pushNamed(DemoRoutes.worker, arguments: ServiceModule.mediation);
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final query = session.medQuery.trim();
    final results = session.mediationWorkers(query: query);
    final total = session.mediationWorkers().length;
    return RuiPage(
      title: s.x('البحث بالاسم', 'Search by name'),
      subtitle: s.x('الوساطة', 'Mediation'),
      bottom: RuiButton(
        key: const ValueKey('search-continue'),
        template: d.template,
        label: s.x('متابعة', 'Continue'),
        onPressed: _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('worker-search'),
            controller: _query,
            onChanged: (v) {
              setState(() => _showError = false);
              session.setMedQuery(v);
            },
            decoration: InputDecoration(
              labelText: s.x('اسم العاملة', 'Worker name'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _query.clear();
                        session.setMedQuery('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.x(
              'البحث ضمن $total عاملة تطابق مهنتك وجنسيتك.',
              'Searching among $total workers matching your profession and nationality.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (results.isEmpty)
            RuiNotice(
              s.x(
                'لا توجد نتائج لـ "$query". جرّب اسماً آخر.',
                'No results for "$query". Try another name.',
              ),
              kind: BannerKind.warning,
              icon: Icons.search_off,
            ),
          for (final w in results)
            WorkerCard(worker: w, module: ServiceModule.mediation),
          if (_showError)
            RuiNotice(
              s.x('اختر عاملة للمتابعة', 'Select a worker to continue'),
              kind: BannerKind.error,
            ),
        ],
      ),
    );
  }
}

/// Worker details with profile / skills / package tabs.
class WorkerDetailsScreen extends StatelessWidget {
  const WorkerDetailsScreen({super.key, required this.module});
  final ServiceModule module;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final worker = session.workerById(session.viewWorkerId);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (worker == null) {
      return RuiPage(
        title: s.x('التفاصيل', 'Details'),
        child: Text(s.x('لم يتم اختيار عاملة', 'No worker selected')),
      );
    }
    final nat = session.repo.nationality(worker.nationalityId);
    final prof = session.repo.profession(worker.professionId);
    final summary = session.summary(module);

    Widget profile() => Column(
      children: [
        RuiInfoRow(s.x('الرمز', 'Code'), worker.code),
        RuiInfoRow(
          s.x('الجنسية', 'Nationality'),
          '${nat.flag} ${nat.name.of(d.lang)}',
        ),
        RuiInfoRow(s.x('المهنة', 'Profession'), prof.name.of(d.lang)),
        RuiInfoRow(s.x('العمر', 'Age'), '${worker.age}'),
        RuiInfoRow(
          s.x('الخبرة', 'Experience'),
          '${worker.years} ${s.x('سنوات', 'years')}',
        ),
        RuiInfoRow(
          s.x('اللغات', 'Languages'),
          worker.languages.map((l) => l.of(d.lang)).join(', '),
        ),
        const SizedBox(height: 6),
        Text(worker.bio.of(d.lang), style: text.bodySmall),
      ],
    );

    Widget skills() => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in worker.skills)
          Chip(
            avatar: const Icon(Icons.check_circle_outline, size: 16),
            label: Text(k.of(d.lang)),
          ),
      ],
    );

    Widget package() => Column(
      children: [
        RuiInfoRow(s.x('الخدمة', 'Service'), summary.title.of(d.lang)),
        for (final line in summary.details.take(3))
          RuiInfoRow(line.label.of(d.lang), line.value.of(d.lang)),
        const Divider(),
        RuiInfoRow(
          s.x('الإجمالي', 'Total'),
          '${summary.total} ${s.x('ر.س', 'SAR')}',
          bold: true,
        ),
      ],
    );

    return DefaultTabController(
      length: 3,
      child: RuiPage(
        title: worker.name.of(d.lang),
        subtitle: worker.code,
        bottom: RuiButton(
          key: const ValueKey('worker-confirm'),
          template: d.template,
          label: s.x('اختيار العاملة ومتابعة', 'Select worker & continue'),
          onPressed: () {
            _selectWorker(session, module, worker.id);
            Navigator.of(
              context,
            ).pushNamed(DemoRoutes.contract, arguments: module);
          },
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primary.withValues(alpha: 0.14),
              child: Icon(prof.icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: scheme.secondary, size: 18),
                Text(' ${worker.rating}'),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              key: const ValueKey('worker-tabs'),
              tabs: [
                Tab(text: s.x('الملف', 'Profile')),
                Tab(text: s.x('المهارات', 'Skills')),
                Tab(text: s.x('الباقة', 'Package')),
              ],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: profile(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: skills(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: package(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
