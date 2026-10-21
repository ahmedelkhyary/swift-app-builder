import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/validators.dart';

/// Availability of the typed App ID, shown under the field: checking,
/// available, taken (with free alternatives) or a network error with retry.
/// Nothing is shown while the ID is empty or malformed (the field itself
/// reports format errors).
class AppIdStatus extends ConsumerWidget {
  const AppIdStatus({super.key, required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (appId.isEmpty || !Validators.appIdRegex.hasMatch(appId)) {
      return const SizedBox.shrink();
    }
    final availability = ref.watch(appIdAvailabilityProvider(appId));

    Widget line(Widget icon, String text, Color color, {Widget? action}) =>
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 4), action],
              ],
            ),
          ),
        );

    return availability.when(
      loading: () => KeyedSubtree(
        key: const ValueKey('app-id-checking'),
        child: line(
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          l10n.appIdChecking,
          AppColors.muted,
        ),
      ),
      error: (_, _) => KeyedSubtree(
        key: const ValueKey('app-id-error'),
        child: line(
          const Icon(Icons.wifi_off, size: 16, color: AppColors.error),
          l10n.appIdCheckFailed,
          AppColors.error,
          action: TextButton(
            key: const ValueKey('app-id-retry'),
            onPressed: () => ref.invalidate(appIdAvailabilityProvider(appId)),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.retry),
          ),
        ),
      ),
      data: (free) {
        if (free) {
          return KeyedSubtree(
            key: const ValueKey('app-id-available'),
            child: line(
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF1A8F5F),
              ),
              l10n.appIdAvailable,
              const Color(0xFF14724C),
            ),
          );
        }
        return _Taken(appId: appId);
      },
    );
  }
}

/// The "taken" state: the field shows the error, here come the alternatives.
class _Taken extends ConsumerWidget {
  const _Taken({required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final suggestions = ref.watch(appIdSuggestionsProvider(appId));
    final free = suggestions.valueOrNull ?? const <String>[];
    if (free.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appIdSuggestions,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in free)
                ActionChip(
                  key: ValueKey('suggest-$s'),
                  label: Text(
                    s,
                    textDirection: TextDirection.ltr,
                    style: monoStyle(),
                  ),
                  onPressed: () => ref.read(draftProvider.notifier).setAppId(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
