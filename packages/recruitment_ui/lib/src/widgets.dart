import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_template.dart';
import 'branding_config.dart';
import 'color_utils.dart';
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

/// Lift-on-hover / focus wrapper used by the richer templates.
class _Lift extends StatefulWidget {
  const _Lift({required this.enabled, required this.builder});
  final bool enabled;
  final Widget Function(BuildContext context, bool lifted) builder;

  @override
  State<_Lift> createState() => _LiftState();
}

class _LiftState extends State<_Lift> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(context, false);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (v) => setState(() => _focus = v),
        child: widget.builder(context, _hover || _focus),
      ),
    );
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
    final tokens = RuiTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(template.cornerRadius);
    final pad = padding is EdgeInsets
        ? (padding as EdgeInsets) * template.spacing
        : padding;

    Widget body(Color? bg) => Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        focusColor: tokens.focus,
        hoverColor: tokens.focus.withValues(alpha: 0.08),
        child: Padding(padding: pad, child: child),
      ),
    );

    switch (template.cardStyle) {
      case CardStyle.outlined:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? tokens.cardFill,
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : tokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: radius, child: body(null)),
        );
      case CardStyle.luxe:
        return _Lift(
          enabled: true,
          builder: (context, lifted) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: color != null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tokens.cardFill,
                        Color.lerp(
                          tokens.cardFill,
                          tokens.accent,
                          dark ? 0.06 : 0.1,
                        )!,
                      ],
                    ),
              color: color,
              border: Border.all(
                color: selected ? tokens.accent : tokens.cardBorder,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.45 : 0.08),
                  blurRadius: lifted ? 30 : 22,
                  offset: Offset(0, lifted ? 14 : 9),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: radius, child: body(null)),
          ),
        );
      case CardStyle.glass:
        return _Lift(
          enabled: true,
          builder: (context, lifted) => AnimatedScale(
            scale: lifted ? 1.015 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: lifted ? 0.28 : 0.16,
                    ),
                    blurRadius: lifted ? 32 : 22,
                    offset: Offset(0, lifted ? 14 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: color,
                      gradient: color != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                tokens.cardFill,
                                tokens.cardFill.withValues(
                                  alpha: tokens.cardFill.a * 0.55,
                                ),
                              ],
                            ),
                      border: Border.all(
                        color: selected ? scheme.primary : tokens.cardBorder,
                        width: selected ? 2 : 1.2,
                      ),
                    ),
                    child: body(null),
                  ),
                ),
              ),
            ),
          ),
        );
    }
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
    final tokens = RuiTokens.of(context);
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
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: template.buttonStyle == RuiButtonStyle.flat
                      ? null
                      : const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
    if (outlined && template.buttonStyle == RuiButtonStyle.flat) {
      // Secondary action of the reference design: filled accent button.
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
          ),
          child: content,
        ),
      );
    }
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
      final fg = onColorFor(tokens.heroGradient.first);
      return _Lift(
        enabled: enabled,
        builder: (context, lifted) => Opacity(
          opacity: enabled || loading ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: tokens.heroGradient),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: lifted ? 0.5 : 0.32),
                  blurRadius: lifted ? 26 : 18,
                  offset: Offset(0, lifted ? 10 : 6),
                ),
              ],
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: TextButton(
                onPressed: enabled ? onPressed : null,
                style: TextButton.styleFrom(
                  foregroundColor: fg,
                  disabledForegroundColor: fg,
                  shape: const StadiumBorder(),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    }
    // flat / luxe: the theme's FilledButton style carries the look.
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
    this.large = false,
  });

  final AppTemplate template;
  final BrandingConfig branding;
  final String title;
  final String? subtitle;
  final bool showLogo;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Taller variant for the Home screen (hero templates).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tokens = RuiTokens.of(context);
    final style = template.headerStyle;
    final fg = switch (style) {
      HeaderStyle.solid => onColorFor(tokens.chrome),
      HeaderStyle.luxe => tokens.onChrome,
      HeaderStyle.hero => onColorFor(tokens.heroGradient.first),
    };
    final subtitleColor = style == HeaderStyle.luxe
        ? tokens.accent
        : fg.withValues(alpha: 0.85);
    final vertical =
        (style == HeaderStyle.solid ? 10.0 : 14.0) * template.spacing;

    final logoBox = Container(
      padding: EdgeInsets.all(style == HeaderStyle.solid ? 6 : 4),
      decoration: switch (style) {
        HeaderStyle.solid => const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x33FFFFFF),
        ),
        HeaderStyle.luxe => BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.chrome,
          border: Border.all(color: tokens.accent, width: 1.2),
        ),
        HeaderStyle.hero => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      },
      child: style == HeaderStyle.solid
          ? Icon(Icons.person, size: 26, color: fg)
          : RuiLogo(
              logo: branding.logo,
              size: 38,
              color: style == HeaderStyle.luxe ? tokens.accent : null,
            ),
    );

    final content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        8,
        vertical + MediaQuery.paddingOf(context).top,
        12,
        vertical + (large && style == HeaderStyle.hero ? 22 : 0),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              key: const ValueKey('header-back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: fg),
            )
          else
            const SizedBox(width: 8),
          if (showLogo) ...[logoBox, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: style == HeaderStyle.solid && !showLogo
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (subtitle != null && large && style == HeaderStyle.hero)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: subtitleColor),
                  ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (large && style == HeaderStyle.hero
                              ? text.headlineSmall
                              : text.titleLarge)
                          ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                ),
                if (subtitle != null && !(large && style == HeaderStyle.hero))
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: subtitleColor),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (style == HeaderStyle.solid && !showLogo && onBack != null)
            const SizedBox(width: 48), // balances the back button
        ],
      ),
    );

    switch (style) {
      case HeaderStyle.solid:
        return Container(color: tokens.chrome, child: content);
      case HeaderStyle.luxe:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: tokens.heroGradient,
            ),
            border: Border(
              bottom: BorderSide(color: tokens.accent, width: 1.2),
            ),
          ),
          child: content,
        );
      case HeaderStyle.hero:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tokens.heroGradient,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(large ? 34 : 26),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(large ? 34 : 26),
            ),
            child: Stack(
              children: [
                // Layered translucent discs give the hero its depth.
                PositionedDirectional(
                  end: -30,
                  top: -40,
                  child: _Disc(size: 130, alpha: 0.12, color: fg),
                ),
                PositionedDirectional(
                  start: -24,
                  bottom: -50,
                  child: _Disc(size: 110, alpha: 0.08, color: fg),
                ),
                content,
              ],
            ),
          ),
        );
    }
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha, required this.color});
  final double size;
  final double alpha;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    ),
  );
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
    final d = DemoScope.maybeOf(context);
    final style = d?.template.headerStyle ?? HeaderStyle.solid;
    final tokens = RuiTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final spacing = d?.template.spacing ?? 1;
    final label = Text(
      text,
      style: switch (style) {
        _ => theme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      },
    );
    return Padding(
      padding: EdgeInsets.only(top: 12 * spacing, bottom: 10 * spacing),
      child: Row(
        children: [
          if (style == HeaderStyle.hero) ...[
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary, scheme.secondary],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (style == HeaderStyle.luxe)
            Expanded(
              child: Row(
                children: [
                  Flexible(child: label),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: tokens.cardBorder),
                  ),
                ],
              ),
            )
          else
            Expanded(child: label),
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
    final tokens = RuiTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget semantic(int i, Widget child) => Semantics(
      button: true,
      selected: i == selected,
      label: items[i].label,
      excludeSemantics: true,
      child: child,
    );

    switch (template.navStyle) {
      case NavStyle.line:
        return Container(
          decoration: BoxDecoration(
            color: tokens.page,
            border: Border(top: BorderSide(color: tokens.cardBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: semantic(
                      i,
                      InkWell(
                        onTap: () => onTap(i),
                        focusColor: tokens.focus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: i == selected
                                    ? scheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                items[i].icon,
                                size: 22,
                                color: i == selected
                                    ? scheme.primary
                                    : tokens.text.withValues(alpha: 0.6),
                              ),
                              Text(
                                items[i].label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: i == selected
                                      ? scheme.primary
                                      : tokens.text.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case NavStyle.luxe:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: tokens.heroGradient.reversed.toList(),
            ),
            border: Border(top: BorderSide(color: tokens.accent, width: 1.2)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: semantic(
                        i,
                        InkWell(
                          onTap: () => onTap(i),
                          borderRadius: BorderRadius.circular(14),
                          focusColor: tokens.focus,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  items[i].icon,
                                  color: i == selected
                                      ? tokens.accent
                                      : tokens.onChrome.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  items[i].label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                    color: i == selected
                                        ? tokens.accent
                                        : tokens.onChrome.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: i == selected ? 18 : 0,
                                  height: 2,
                                  color: tokens.accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      case NavStyle.floating:
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: dark ? 0.35 : 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        semantic(
                          i,
                          _FloatingItem(
                            item: items[i],
                            selected: i == selected,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
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
    final tokens = RuiTokens.of(context);
    return _Lift(
      enabled: true,
      builder: (context, lifted) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        focusColor: tokens.focus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: tokens.heroGradient)
                : null,
            color: !selected && lifted
                ? scheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: selected
                    ? onColorFor(tokens.heroGradient.first)
                    : tokens.text.withValues(alpha: 0.65),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: onColorFor(tokens.heroGradient.first),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggered fade/slide-in for list sections. Only templates with rich motion
/// animate; the others (and users who disabled animations) get the child as is.
class RuiReveal extends StatefulWidget {
  const RuiReveal({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<RuiReveal> createState() => _RuiRevealState();
}

class _RuiRevealState extends State<RuiReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Animation<double>? _a;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final rich =
        DemoScope.maybeOf(context)?.template.motion == MotionLevel.rich;
    if (!rich || MediaQuery.disableAnimationsOf(context)) return;
    final delay = (widget.index.clamp(0, 8)) * 70;
    final total = 420 + delay;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    )..forward();
    _a = CurvedAnimation(
      parent: _c!,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    if (a == null) return widget.child;
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(a),
        child: widget.child,
      ),
    );
  }
}

/// Shimmering placeholder block (skeleton loader).
class RuiSkeleton extends StatefulWidget {
  const RuiSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });
  final double height;
  final double? width;
  final double radius;

  @override
  State<RuiSkeleton> createState() => _RuiSkeletonState();
}

class _RuiSkeletonState extends State<RuiSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value, 0),
            end: Alignment(1 + 2 * _c.value, 0),
            colors: [
              base.withValues(alpha: 0.06),
              base.withValues(alpha: 0.14),
              base.withValues(alpha: 0.06),
            ],
          ),
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

/// Illustration-style empty state (icon in a soft disc, title, hint).
class RuiEmptyState extends StatelessWidget {
  const RuiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleKey,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              key: titleKey,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
