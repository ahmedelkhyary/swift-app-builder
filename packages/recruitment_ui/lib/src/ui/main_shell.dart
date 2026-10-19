import 'package:flutter/material.dart';

import '../app_template.dart';
import '../demo/models.dart';
import '../widgets.dart';
import 'scope.dart';

class ModuleInfo {
  const ModuleInfo(this.title, this.subtitle, this.icon);
  final L title;
  final L subtitle;
  final IconData icon;

  static ModuleInfo of(ServiceModule m) => switch (m) {
    ServiceModule.individuals => const ModuleInfo(
      L('خدمات الأفراد', 'Individuals'),
      L('استقدام عاملة منزلية بعقد دائم', 'Recruit a domestic worker'),
      Icons.people_alt,
    ),
    ServiceModule.hourly => const ModuleInfo(
      L('الخدمة بالساعة', 'Hourly services'),
      L('تنظيف بالساعة حسب جدولك', 'Cleaning on your schedule'),
      Icons.schedule,
    ),
    ServiceModule.mediation => const ModuleInfo(
      L('الوساطة', 'Mediation'),
      L(
        'اختر العاملة بنفسك وتولّ الإجراءات',
        'Pick your worker, we handle paperwork',
      ),
      Icons.handshake,
    ),
  };
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final tab = d.session.mainTab;
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [_HomeTab(), _OrdersTab(), _AccountTab()],
      ),
      bottomNavigationBar: RuiNavBar(
        template: d.template,
        selected: tab,
        onTap: d.session.setMainTab,
        items: [
          RuiNavItem(Icons.home_outlined, s.x('الرئيسية', 'Home')),
          RuiNavItem(Icons.receipt_long_outlined, s.x('طلباتي', 'Orders')),
          RuiNavItem(Icons.person_outline, s.x('حسابي', 'Account')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final modules = ServiceModule.values
        .where(session.enabledModules.contains)
        .toList();
    final featured = modules
        .where((m) => m != ServiceModule.mediation)
        .toList();

    return Column(
      children: [
        RuiHeader(
          template: d.template,
          branding: d.branding,
          title: d.branding.appName(d.lang),
          subtitle: s.x('مرحباً بك', 'Welcome'),
          showLogo: true,
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('home-list'),
            padding: const EdgeInsets.all(16),
            children: [
              _BannerSlider(
                banners: session.repo.banners
                    .where((b) => session.enabledModules.contains(b.target))
                    .toList(),
              ),
              if (featured.isNotEmpty) ...[
                RuiSectionTitle(s.x('خدمات مميزة', 'Featured services')),
                Row(
                  children: [
                    for (var i = 0; i < featured.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _FeaturedCard(module: featured[i])),
                    ],
                  ],
                ),
              ],
              RuiSectionTitle(s.x('الأقسام الرئيسية', 'Main categories')),
              _Categories(modules: modules),
              RuiSectionTitle(s.x('آراء العملاء', 'Customer reviews')),
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final r in session.repo.reviews)
                      _ReviewCard(review: r),
                  ],
                ),
              ),
              RuiSectionTitle(s.x('شركاؤنا', 'Our partners')),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in session.repo.partners)
                    _PartnerChip(partner: p),
                ],
              ),
              RuiSectionTitle(s.x('تواصل معنا', 'Contact us')),
              const _ContactCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerSlider extends StatefulWidget {
  const _BannerSlider({required this.banners});
  final List<PromoBanner> banners;

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final text = Theme.of(context).textTheme;
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 204,
          child: PageView.builder(
            key: const ValueKey('banner-slider'),
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  key: ValueKey('banner-$i'),
                  borderRadius: BorderRadius.circular(d.template.cornerRadius),
                  onTap: () => d.session.openModule(b.target),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        d.template.cornerRadius,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          b.color,
                          Color.lerp(b.color, Colors.black, 0.4)!,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b.title.of(d.lang),
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.subtitle.of(d.lang),
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            d.s.x('اكتشف', 'Explore'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.module});
  final ServiceModule module;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final info = ModuleInfo.of(module);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return RuiCard(
      key: ValueKey('featured-${module.name}'),
      template: d.template,
      onTap: () => d.session.openModule(module),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Icon(info.icon, color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            info.title.of(d.lang),
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            info.subtitle.of(d.lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.modules});
  final List<ServiceModule> modules;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget tile(ServiceModule m, {required bool horizontal}) {
      final info = ModuleInfo.of(m);
      final icon = Icon(
        info.icon,
        color: scheme.primary,
        size: horizontal ? 28 : 30,
      );
      final label = Text(
        info.title.of(d.lang),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      );
      return RuiCard(
        key: ValueKey('category-${m.name}'),
        template: d.template,
        onTap: () => d.session.openModule(m),
        child: horizontal
            ? Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Flexible(child: label),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(height: 8),
                  Flexible(child: label),
                ],
              ),
      );
    }

    if (modules.isEmpty) return const SizedBox.shrink();
    switch (d.template.serviceGrid) {
      case ServiceGridVariant.list:
        return Column(
          children: [
            for (final m in modules)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: tile(m, horizontal: true),
                ),
              ),
          ],
        );
      case ServiceGridVariant.featured:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 96,
              child: tile(modules.first, horizontal: false),
            ),
            if (modules.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i < modules.length; i++) ...[
                    if (i > 1) const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 124,
                        child: tile(modules[i], horizontal: false),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      case ServiceGridVariant.grid2:
      case ServiceGridVariant.grid3:
        final cols = d.template.serviceGrid == ServiceGridVariant.grid2 ? 2 : 3;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: cols == 2 ? 1.3 : 0.75,
          children: [for (final m in modules) tile(m, horizontal: false)],
        );
    }
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 230,
      margin: const EdgeInsetsDirectional.only(end: 10),
      child: RuiCard(
        template: d.template,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: scheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                review.text.of(d.lang),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                style: text.bodySmall,
              ),
            ),
            Text(
              review.author.of(d.lang),
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.partner});
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final name = partner.name.of(d.lang);
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(
              String.fromCharCode(name.runes.first),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final c = d.session.repo.contact;
    final scheme = Theme.of(context).colorScheme;

    Widget row(
      Key key,
      IconData icon,
      String title,
      String value,
      VoidCallback onTap,
    ) => ListTile(
      key: key,
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: Text(
        value,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
      ),
      onTap: onTap,
    );

    return RuiCard(
      template: d.template,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          row(
            const ValueKey('contact-phone'),
            Icons.phone,
            s.x('اتصل بنا', 'Call us'),
            c.phone,
            () {
              showRuiDialog<void>(
                context,
                (ctx) => AlertDialog(
                  icon: const Icon(Icons.phone_in_talk),
                  title: Text(s.x('اتصال تجريبي', 'Demo call')),
                  content: Text(
                    s.x(
                      'في التطبيق الحقيقي سيتم الاتصال بالرقم ${c.phone}. لم يتم إجراء أي اتصال.',
                      'In the real app this would dial ${c.phone}. No call was placed.',
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(s.x('حسناً', 'OK')),
                    ),
                  ],
                ),
              );
            },
          ),
          row(
            const ValueKey('contact-email'),
            Icons.email_outlined,
            s.x('البريد', 'Email'),
            c.email,
            () => showRuiSnack(
              context,
              s.x(
                'تجريبي: كان سيفتح تطبيق البريد',
                'Demo: would open the email app',
              ),
            ),
          ),
          row(
            const ValueKey('contact-address'),
            Icons.location_on_outlined,
            s.x('العنوان', 'Address'),
            c.address.of(d.lang),
            () {
              showRuiSheet<void>(
                context,
                (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.x('معلومات التواصل', 'Contact details'),
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      RuiInfoRow(
                        s.x('العنوان', 'Address'),
                        c.address.of(d.lang),
                      ),
                      RuiInfoRow(
                        s.x('ساعات العمل', 'Hours'),
                        c.hours.of(d.lang),
                      ),
                      RuiInfoRow(s.x('الهاتف', 'Phone'), c.phone),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orders & Account
// ---------------------------------------------------------------------------

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final orders = d.session.orders;
    return Column(
      children: [
        RuiHeader(
          template: d.template,
          branding: d.branding,
          title: s.x('طلباتي', 'My orders'),
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 56,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.x('لا توجد طلبات بعد', 'No orders yet'),
                        key: const ValueKey('orders-empty'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final o in orders)
                      RuiSelectTile(
                        template: d.template,
                        selected: false,
                        onTap: null,
                        leading: Icon(ModuleInfo.of(o.summary.module).icon),
                        title: o.summary.title.of(d.lang),
                        subtitle: o.reference,
                        trailing: Text(
                          '${o.summary.total} ${s.x('ر.س', 'SAR')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    return Column(
      children: [
        RuiHeader(
          template: d.template,
          branding: d.branding,
          title: s.x('حسابي', 'My account'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RuiCard(
                template: d.template,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    RuiInfoRow(
                      s.x('الجوال', 'Phone'),
                      '${d.session.dialCode} ${d.session.phone}',
                    ),
                    RuiInfoRow(
                      s.x('القالب', 'Template'),
                      d.template.name(d.lang),
                    ),
                    RuiInfoRow(
                      s.x('العناوين المحفوظة', 'Saved addresses'),
                      '${d.session.addresses.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RuiNotice(
                s.x(
                  'هذا عرض تجريبي ببيانات وهمية. لا يتم حفظ أي بيانات حقيقية.',
                  'This is a demo with mock data. No real data is stored.',
                ),
              ),
              const SizedBox(height: 8),
              RuiButton(
                key: const ValueKey('account-reset'),
                template: d.template,
                label: s.x('إعادة ضبط العرض', 'Reset demo'),
                icon: Icons.restart_alt,
                outlined: true,
                onPressed: d.session.reset,
              ),
              const SizedBox(height: 8),
              RuiButton(
                key: const ValueKey('account-logout'),
                template: d.template,
                label: s.x('تسجيل الخروج', 'Log out'),
                icon: Icons.logout,
                onPressed: d.session.logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
