import 'dart:async';

import 'package:flutter/material.dart';

import '../app_template.dart';
import '../color_utils.dart';
import '../demo/models.dart';
import '../widgets.dart';
import 'featured.dart';
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
      floatingActionButton: _QuickOrderButton(visible: tab == 0),
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

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Timer? _timer;
  bool _loading = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Rich-motion templates show skeleton placeholders while "loading".
    final rich = DemoScope.of(context).template.motion == MotionLevel.rich;
    final delay = AppTemplate.skeletonDuration;
    if (rich && delay > Duration.zero) {
      _loading = true;
      _timer = Timer(delay, () {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final session = d.session;
    final gap = d.template.spacing;
    final modules = ServiceModule.values
        .where(session.enabledModules.contains)
        .toList();

    final sections = <Widget>[
      _BannerSlider(
        banners: session.repo.banners
            .where((b) => session.enabledModules.contains(b.target))
            .toList(),
      ),
      const FeaturedSection(),
      RuiSectionTitle(s.x('الأقسام الرئيسية', 'Main categories')),
      _Categories(modules: modules),
      RuiSectionTitle(s.x('آراء العملاء', 'Customer reviews')),
      SizedBox(
        height: 128,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final r in session.repo.reviews) _ReviewCard(review: r),
          ],
        ),
      ),
      RuiSectionTitle(s.x('شركاؤنا', 'Our partners')),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final p in session.repo.partners) _PartnerChip(partner: p),
        ],
      ),
      RuiSectionTitle(s.x('تواصل معنا', 'Contact us')),
      const _ContactCard(),
      const SizedBox(height: 12),
    ];

    return Column(
      children: [
        RuiHeader(
          template: d.template,
          branding: d.branding,
          title: s.x(
            'مرحباً ${d.session.repo.userName.ar}',
            'Hello ${d.session.repo.userName.en}',
          ),
          showAvatar: true,
          subtitleBuilder: (color) => HomeAddressLine(color: color),
          large: true,
          trailing: IconButton(
            key: const ValueKey('home-bell'),
            tooltip: s.x('الإشعارات', 'Notifications'),
            icon: Icon(
              Icons.notifications_none,
              color: onColorFor(RuiTokens.of(context).chrome),
            ),
            onPressed: () => showRuiSheet<void>(
              context,
              (ctx) => SizedBox(
                height: 320,
                child: RuiEmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: s.x('لا توجد إشعارات', 'No notifications'),
                  subtitle: s.x(
                    'ستظهر إشعاراتك هنا',
                    'Your notifications will appear here',
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const _HomeSkeleton()
              : ListView(
                  key: const ValueKey('home-list'),
                  padding: EdgeInsets.all(16 * gap),
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      RuiReveal(index: i, child: sections[i]),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('home-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        RuiSkeleton(height: 170, radius: 22),
        SizedBox(height: 20),
        RuiSkeleton(height: 18, width: 140),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: RuiSkeleton(height: 110, radius: 22)),
            SizedBox(width: 12),
            Expanded(child: RuiSkeleton(height: 110, radius: 22)),
          ],
        ),
        SizedBox(height: 20),
        RuiSkeleton(height: 18, width: 110),
        SizedBox(height: 12),
        RuiSkeleton(height: 70, radius: 22),
        SizedBox(height: 10),
        RuiSkeleton(height: 70, radius: 22),
      ],
    );
  }
}

/// Floating "order now" shortcut of the rich-motion template. It opens the
/// first enabled service, exactly like tapping its card.
class _QuickOrderButton extends StatelessWidget {
  const _QuickOrderButton({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    if (d.template.motion != MotionLevel.rich) return const SizedBox.shrink();
    final first = ServiceModule.values
        .where(d.session.enabledModules.contains)
        .firstOrNull;
    final tokens = RuiTokens.of(context);
    final show = visible && first != null;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: show ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: show ? 1 : 0,
        child: IgnorePointer(
          ignoring: !show,
          child: FloatingActionButton.extended(
            key: const ValueKey('quick-order'),
            onPressed: first == null ? null : () => d.session.openModule(first),
            icon: const Icon(Icons.bolt),
            label: Text(d.s.x('اطلب الآن', 'Order now')),
            backgroundColor: tokens.heroGradient.first,
            foregroundColor: onColorFor(tokens.heroGradient.first),
            elevation: 8,
          ),
        ),
      ),
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
  PageController? _controller;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rich-motion templates show a peeking carousel.
    _controller ??= PageController(
      viewportFraction:
          DemoScope.of(context).template.motion == MotionLevel.rich ? 0.88 : 1,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  BoxDecoration _decoration(BuildContext context, Color color) {
    final d = DemoScope.of(context);
    final template = d.template;
    final tokens = RuiTokens.of(context);
    final radius = BorderRadius.circular(template.cornerRadius);
    return switch (template.cardStyle) {
      CardStyle.outlined => BoxDecoration(
        borderRadius: radius,
        color: Color.lerp(color, Colors.black, 0.12),
      ),
      CardStyle.luxe => BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, tokens.chrome, 0.55)!,
            Color.lerp(color, Colors.black, 0.6)!,
          ],
        ),
        border: Border.all(color: tokens.accent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      CardStyle.glass => BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Theme.of(context).colorScheme.primary, 0.5)!,
            Color.lerp(color, Colors.black, 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final text = Theme.of(context).textTheme;
    final tokens = RuiTokens.of(context);
    final template = d.template;
    final rich = template.motion == MotionLevel.rich;
    final luxe = template.cardStyle == CardStyle.luxe;
    final controller = _controller!;
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    Widget card(int i) {
      final b = widget.banners[i];
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: rich ? 6 : 2,
          vertical: rich ? 8 : 0,
        ),
        child: Semantics(
          button: true,
          label: b.title.of(d.lang),
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('banner-$i'),
            borderRadius: BorderRadius.circular(template.cornerRadius),
            focusColor: tokens.focus,
            onTap: () => d.session.openModule(b.target),
            child: Ink(
              decoration: _decoration(context, b.color),
              padding: EdgeInsets.all(18 * template.spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    b.title.of(d.lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.subtitle.of(d.lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: luxe ? Colors.transparent : Colors.white24,
                      borderRadius: BorderRadius.circular(
                        template.cardStyle == CardStyle.outlined ? 4 : 20,
                      ),
                      border: luxe ? Border.all(color: tokens.accent) : null,
                    ),
                    child: Text(
                      d.s.x('اكتشف', 'Explore'),
                      style: TextStyle(
                        color: luxe ? tokens.accent : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            key: const ValueKey('banner-slider'),
            controller: controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              if (!rich) return card(i);
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  var delta = (_page - i).toDouble();
                  if (controller.hasClients &&
                      controller.position.haveDimensions) {
                    delta = (controller.page ?? _page.toDouble()) - i;
                  }
                  final scale = (1 - delta.abs() * 0.07).clamp(0.9, 1.0);
                  return Transform.scale(scale: scale, child: child);
                },
                child: card(i),
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
                width: i == _page && template.cardStyle != CardStyle.outlined
                    ? 18
                    : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? (luxe
                            ? tokens.accent
                            : Theme.of(context).colorScheme.primary)
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
              height: 108,
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
                        height: 140,
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
        const cols = 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
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
              ? RuiEmptyState(
                  icon: Icons.receipt_long,
                  title: s.x('لا توجد طلبات بعد', 'No orders yet'),
                  titleKey: const ValueKey('orders-empty'),
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
