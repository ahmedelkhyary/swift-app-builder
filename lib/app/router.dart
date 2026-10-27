import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/builder/application/providers.dart';
import '../features/builder/domain/validators.dart';
import '../features/builder/presentation/preview_page.dart';
import '../features/builder/presentation/wizard_page.dart';

WizardSection? _parse(String? name) {
  for (final s in WizardSection.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// `/builder/:section`, guarded so a section opens only when all the
/// sections before it are valid.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/builder/info',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/') return '/builder/info';
      if (path == '/preview') {
        return ref.read(sectionEnabledProvider(WizardSection.template))
            ? null
            : '/builder/info';
      }
      final section = _parse(state.pathParameters['section']);
      if (section == null) return '/builder/info';
      if (!activeSections(ref.read(draftProvider)).contains(section)) {
        return '/builder/${WizardSection.summary.name}';
      }
      if (!ref.read(sectionEnabledProvider(section))) {
        // Send the user to the first section that blocks them.
        for (final s in activeSections(ref.read(draftProvider))) {
          if (s == section) break;
          if (!ref.read(sectionValidProvider(s))) return '/builder/${s.name}';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/builder/info'),
      GoRoute(
        path: '/preview',
        builder: (context, state) => const PreviewPage(),
      ),
      GoRoute(
        path: '/builder/:section',
        builder: (context, state) => WizardPage(
          key: ValueKey(state.pathParameters['section']),
          section: _parse(state.pathParameters['section'])!,
        ),
      ),
    ],
  );
});
