import 'package:flutter/material.dart';

import '../app_template.dart';
import '../demo/models.dart';
import '../demo/session.dart';
import '../widgets.dart';
import 'address_sheet.dart';
import 'scope.dart';

/// Opens a featured service straight on its packages screen with the main
/// address, skipping the address step. Without a main address the address
/// sheet opens first and the flow continues with the chosen one.
Future<void> startFeatured(BuildContext context, FeaturedService f) async {
  final d = DemoScope.of(context);
  var address = d.session.mainAddress;
  address ??= await showAddressSheet(context, target: AddressTarget.main);
  if (address == null || !context.mounted) return;
  d.session.startFeatured(f, address);
}

/// The main address under the greeting in the Home header. Tapping opens the
/// address sheet (or the add form when there is no saved address yet).
class HomeAddressLine extends StatelessWidget {
  const HomeAddressLine({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final main = d.session.mainAddress;
    final text = main == null
        ? s.x('أضف عنوانك', 'Add your address')
        : '${main.city.of(d.lang)} - ${main.district.of(d.lang)}';
    return Semantics(
      button: true,
      label: '${s.x('العنوان الرئيسي', 'Main address')}: $text',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('home-address'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => main == null
            ? showAddressForm(context, offerMain: true, mainByDefault: true)
            : showAddressSheet(context, target: AddressTarget.main),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// "الخدمات المميزة": a horizontal row of image cards that are shortcuts into
/// real services.
class FeaturedSection extends StatelessWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final items = d.session.featuredServices;
    if (items.isEmpty) return const SizedBox.shrink();
    final tokens = RuiTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RuiSectionTitle(
          s.x('الخدمات المميزة', 'Featured services'),
          trailing: TextButton(
            key: const ValueKey('featured-view-all'),
            onPressed: () =>
                Navigator.of(context).pushNamed(DemoRoutes.featured),
            style: TextButton.styleFrom(
              foregroundColor: tokens.link,
              minimumSize: const Size(44, 44),
            ),
            child: Text(s.x('عرض الكل', 'View all')),
          ),
        ),
        SizedBox(
          height: 184,
          child: ListView.separated(
            key: const ValueKey('featured-list'),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => FeaturedImageCard(
              service: items[i],
              width: 150,
              onTap: () => startFeatured(context, items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Image card with the service name on the image.
class FeaturedImageCard extends StatelessWidget {
  const FeaturedImageCard({
    super.key,
    required this.service,
    required this.width,
    required this.onTap,
  });

  final FeaturedService service;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final tokens = RuiTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final template = d.template;
    final radius = BorderRadius.circular(template.cornerRadius);
    final title = service.title.of(d.lang);
    final luxe = template.cardStyle == CardStyle.luxe;
    final glass = template.cardStyle == CardStyle.glass;
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: luxe ? Border.all(color: tokens.accent, width: 1.2) : null,
            boxShadow: [
              BoxShadow(
                color: glass
                    ? scheme.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: luxe ? 0.18 : 0.08),
                blurRadius: glass || luxe ? 20 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('featured-${service.id}'),
                onTap: onTap,
                focusColor: tokens.focus,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        service.color,
                        Color.lerp(service.color, Colors.black, 0.5)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PositionedDirectional(
                        end: -14,
                        top: -6,
                        child: Icon(
                          service.icon,
                          size: 110,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      // Scrim so the name stays readable on any image.
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "عرض الكل": every featured service as a list.
class FeaturedServicesScreen extends StatelessWidget {
  const FeaturedServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    final s = d.s;
    final items = d.session.featuredServices;
    return RuiPage(
      title: s.x('الخدمات المميزة', 'Featured services'),
      child: Column(
        children: [
          if (items.isEmpty)
            RuiEmptyState(
              icon: Icons.star_border,
              title: s.x('لا توجد خدمات مميزة', 'No featured services'),
            ),
          for (final f in items)
            RuiSelectTile(
              key: ValueKey('featured-all-${f.id}'),
              template: d.template,
              selected: false,
              onTap: () => startFeatured(context, f),
              leading: CircleAvatar(
                backgroundColor: f.color,
                child: Icon(f.icon, color: Colors.white),
              ),
              title: f.title.of(d.lang),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ),
    );
  }
}
