import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_template.dart';
import 'branding_config.dart';
import 'ui/scope.dart';

/// Renders the brand logo, or a placeholder icon when none was uploaded.
class RuiLogo extends StatelessWidget {
  const RuiLogo({super.key, required this.logo, this.size = 40, this.color});
  final BrandLogo? logo;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l = logo;
    final Widget child;
    if (l == null) {
      child = Icon(
        Icons.home_work_rounded,
        size: size * 0.8,
        color: color ?? Theme.of(context).colorScheme.primary,
      );
    } else if (l.isSvg) {
      child = SvgPicture.memory(l.bytes, fit: BoxFit.contain);
    } else {
      child = Image.memory(l.bytes, fit: BoxFit.contain);
    }
    return SizedBox(width: size, height: size, child: child);
  }
}

/// Card that adapts to the template's card style.
class RuiCard extends StatelessWidget {
  const RuiCard({
    super.key,
    required this.template,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.color,
  });

  final AppTemplate template;
  final Widget child;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(template.cornerRadius);
    Color fill;
    BorderSide side = BorderSide.none;
    switch (template.cardStyle) {
      case CardStyle.elevated:
        fill = scheme.surface;
      case CardStyle.outlined:
        fill = scheme.surface;
        side = BorderSide(color: scheme.outlineVariant);
      case CardStyle.filled:
        fill = scheme.primary.withValues(alpha: 0.08);
      case CardStyle.glass:
        fill = scheme.primary.withValues(alpha: 0.06);
        side = BorderSide(color: scheme.secondary.withValues(alpha: 0.6));
    }
    if (selected) side = BorderSide(color: scheme.primary, width: 2);
    return Material(
      color: color ?? fill,
      elevation: template.elevation,
      shape: RoundedRectangleBorder(borderRadius: radius, side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Primary action button adapting to the template's button style.
/// A null [onPressed] renders the disabled state.
class RuiButton extends StatelessWidget {
  const RuiButton({
    super.key,
    required this.template,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  final AppTemplate template;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final content = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: content,
        ),
      );
    }
    if (template.buttonStyle == RuiButtonStyle.gradient) {
      return Opacity(
        opacity: enabled || loading ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, Colors.black, 0.35)!,
              ],
            ),
            borderRadius: BorderRadius.circular(template.cornerRadius),
          ),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: TextButton(
              onPressed: enabled ? onPressed : null,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onPrimary,
                disabledForegroundColor: scheme.onPrimary,
              ),
              child: content,
            ),
          ),
        ),
      );
    }
    return FilledButton(onPressed: enabled ? onPressed : null, child: content);
  }
}

/// Page header whose shape depends on the template's header style.
class RuiHeader extends StatelessWidget {
  const RuiHeader({
    super.key,
    required this.template,
    required this.branding,
    required this.title,
    this.subtitle,
    this.showLogo = false,
    this.onBack,
    this.trailing,
  });

  final AppTemplate template;
  final BrandingConfig branding;
  final String title;
  final String? subtitle;
  final bool showLogo;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final plain = template.headerStyle == HeaderStyle.plain;
    final fg = plain ? scheme.onSurface : scheme.onPrimary;

    final content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        8,
        12 + MediaQuery.paddingOf(context).top,
        12,
        16,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              key: const ValueKey('header-back'),
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: fg),
            )
          else
            const SizedBox(width: 8),
          if (showLogo) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  template.cornerRadius / 1.5,
                ),
              ),
              child: RuiLogo(logo: branding.logo, size: 36),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    switch (template.headerStyle) {
      case HeaderStyle.solid:
        return Container(color: scheme.primary, child: content);
      case HeaderStyle.curved:
        return Container(
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: content,
        );
      case HeaderStyle.plain:
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: content,
        );
      case HeaderStyle.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, Colors.black, 0.45)!,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          child: content,
        );
    }
  }
}

/// Standard page: template header, scrollable body, optional bottom action.
class RuiPage extends StatelessWidget {
  const RuiPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.bottom,
    this.showBack = true,
    this.scroll = true,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;
  final bool showBack;
  final bool scroll;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final d = DemoScope.of(context);
    return Scaffold(
      body: Column(
        children: [
          RuiHeader(
            template: d.template,
            branding: d.branding,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onBack: showBack
                ? (onBack ?? () => Navigator.of(context).maybePop())
                : null,
          ),
          Expanded(
            child: scroll
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  )
                : child,
          ),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: bottom,
              ),
            ),
        ],
      ),
    );
  }
}

/// A selectable row/card (address, package, payment method...).
class RuiSelectTile extends StatelessWidget {
  const RuiSelectTile({
    super.key,
    required this.template,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.child,
  });

  final AppTemplate template;
  final bool selected;
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RuiCard(
        template: template,
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
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
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null)
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
              ],
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class RuiSectionTitle extends StatelessWidget {
  const RuiSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum BannerKind { info, success, error, warning }

/// Inline feedback message (errors, success, hints).
class RuiNotice extends StatelessWidget {
  const RuiNotice(
    this.message, {
    super.key,
    this.kind = BannerKind.info,
    this.icon,
  });
  final String message;
  final BannerKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, defaultIcon) = switch (kind) {
      BannerKind.info => (scheme.primary, Icons.info_outline),
      BannerKind.success => (Colors.green.shade700, Icons.check_circle_outline),
      BannerKind.error => (scheme.error, Icons.error_outline),
      BannerKind.warning => (Colors.orange.shade800, Icons.warning_amber),
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Key/value row used by summaries.
class RuiInfoRow extends StatelessWidget {
  const RuiInfoRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: bold ? scheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims the child and shows a spinner while [busy].
class RuiBusy extends StatelessWidget {
  const RuiBusy({super.key, required this.busy, required this.child});
  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (busy)
          const Positioned.fill(
            child: ModalBarrier(color: Color(0x55000000), dismissible: false),
          ),
        if (busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class RuiNavItem {
  const RuiNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Bottom navigation whose look depends on the template.
class RuiNavBar extends StatelessWidget {
  const RuiNavBar({
    super.key,
    required this.template,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final AppTemplate template;
  final List<RuiNavItem> items;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (template.navStyle) {
      case NavStyle.standard:
        return NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: onTap,
          destinations: [
            for (final i in items)
              NavigationDestination(icon: Icon(i.icon), label: i.label),
          ],
        );
      case NavStyle.floating:
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _FloatingItem(
                    item: items[i],
                    selected: i == selected,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        );
      case NavStyle.line:
        return Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: i == selected
                                  ? scheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[i].icon,
                              color: i == selected
                                  ? scheme.primary
                                  : scheme.outline,
                            ),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 11,
                                color: i == selected
                                    ? scheme.primary
                                    : scheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case NavStyle.dark:
        return Container(
          color: const Color(0xFF14141A),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: i == selected
                              ? scheme.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[i].icon,
                              color: i == selected
                                  ? scheme.onSecondary
                                  : Colors.white70,
                            ),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 11,
                                color: i == selected
                                    ? scheme.onSecondary
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _FloatingItem extends StatelessWidget {
  const _FloatingItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final RuiNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: selected ? scheme.onPrimary : scheme.outline,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(item.label, style: TextStyle(color: scheme.onPrimary)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog shown inside the phone (not over the whole builder window).
Future<T?> showRuiDialog<T>(BuildContext context, WidgetBuilder builder) =>
    showDialog<T>(context: context, useRootNavigator: false, builder: builder);

/// Bottom sheet shown inside the phone.
Future<T?> showRuiSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      builder: builder,
    );

void showRuiSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
