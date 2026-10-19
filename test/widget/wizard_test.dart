import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/app/app.dart';
import 'package:swiftappbuilder/app/locale_provider.dart';
import 'package:swiftappbuilder/app/router.dart';
import 'package:swiftappbuilder/features/builder/application/providers.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_frame.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_preview.dart';

import '../helpers.dart';

class _EnglishLocale extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool arabic = false,
}) async {
  AppTemplate.useGoogleFonts = false;
  tester.view.physicalSize = const Size(1500, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schemaValidatorProvider.overrideWithValue(loadSchema()),
        if (!arabic) localeProvider.overrideWith(_EnglishLocale.new),
        demoRepositoryProvider.overrideWithValue(
          MockDemoRepository(latency: Duration.zero),
        ),
      ],
      child: const BuilderApp(useGoogleFonts: false),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(BuilderApp)));
}

FilledButton nextButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('wizard-next')));

/// Finds a widget inside the interactive phone only (template thumbnails also
/// render a Home screen with the same keys).
Finder inPhone(String key) => find.descendant(
  of: find.byType(PhonePreview),
  matching: find.byKey(ValueKey(key)),
);

/// Scrolls [f] into view (page and phone scrollables), then taps it.
Future<void> tapIn(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String currentPath(ProviderContainer c) =>
    c.read(routerProvider).state.uri.path;

void main() {
  testWidgets(
    'a fresh form shows no errors; Next reveals them and focuses the first',
    (tester) async {
      final container = await pumpApp(tester);
      expect(currentPath(container), '/builder/info');

      // Nothing is red on first load.
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(nextButton(tester).onPressed, isNotNull);

      await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
      expect(currentPath(container), '/builder/info', reason: 'blocked');
      expect(
        find.text('Enter the Arabic app name, e.g. متجر الورد'),
        findsOneWidget,
      );
      expect(
        find.text('Enter the Android package name, e.g. com.rose.store'),
        findsOneWidget,
      );
      // Focus moved to the first invalid field.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('name-ar')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
    },
  );

  testWidgets(
    'errors appear on blur, are specific, and Next proceeds when valid',
    (tester) async {
      final container = await pumpApp(tester);
      Finder f(String key) => find.byKey(ValueKey(key));

      await tester.enterText(f('name-ar'), 'سويفت');
      await tester.enterText(f('name-en'), 'Swift Maids');
      await tester.enterText(f('android-package'), 'Not Valid');
      // Still typing in the package field: no error yet.
      await tester.pump();
      expect(find.textContaining('for example com.rose.store'), findsNothing);

      // Leaving the field shows a specific message.
      await tester.enterText(f('client-name'), 'مكتب سويفت');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use lowercase letters without spaces, for example com.rose.store',
        ),
        findsOneWidget,
      );

      await tester.enterText(f('client-phone'), '+966500000000');
      await tester.enterText(f('client-email'), 'info@swift.example');
      await tester.enterText(f('android-package'), 'com.example.swift');
      await tester.pumpAndSettle();

      // appId was auto-generated from the English name.
      expect(container.read(draftProvider).appId, 'swift_maids');
      // iOS mirrors the Android value while the toggle is on.
      expect(tester.widget<TextField>(f('ios-bundle')).enabled, isFalse);
      expect(
        tester.widget<TextField>(f('ios-bundle')).controller!.text,
        'com.example.swift',
      );

      await tapIn(tester, f('wizard-next'));
      expect(currentPath(container), '/builder/branding');
      expect(find.text('Step 2 of 5'), findsOneWidget);

      // Branding needs a logo + icon: Next reveals the missing-file errors.
      expect(find.text('This file is required'), findsNothing);
      await tapIn(tester, f('wizard-next'));
      expect(currentPath(container), '/builder/branding');
      expect(find.text('This file is required'), findsNWidgets(2));
    },
  );

  testWidgets('turning the iOS toggle off makes the bundle ID required', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final c = container.read(draftProvider.notifier);
    c.setAndroidPackage('com.example.swift');
    await tester.pumpAndSettle();
    await tapIn(tester, find.byKey(const ValueKey('ios-same')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ios-bundle')))
          .enabled,
      isTrue,
    );
    await tester.enterText(find.byKey(const ValueKey('ios-bundle')), 'bad id');
    await tester.enterText(find.byKey(const ValueKey('client-name')), 'x');
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Use reverse-DNS format without spaces, for example com.rose.store',
      ),
      findsOneWidget,
    );
  });

  testWidgets('stepper: current/done states, back navigation, progress', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();

    await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
    await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
    expect(currentPath(container), '/builder/localization');
    expect(find.text('Step 3 of 5'), findsOneWidget);
    // Steps 1 and 2 are completed (check marks) and clickable.
    Finder checkIn(int i) => find.descendant(
      of: find.byKey(ValueKey('step-$i')),
      matching: find.byIcon(Icons.check),
    );
    expect(checkIn(0), findsOneWidget);
    expect(checkIn(1), findsOneWidget);
    expect(checkIn(2), findsNothing);
    expect(find.text('Next: Template'), findsOneWidget);

    await tapIn(tester, find.byKey(const ValueKey('step-0')));
    expect(currentPath(container), '/builder/info');
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('wizard-back')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('below 768px the stepper shows only the current step name', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    tester.view.physicalSize = const Size(600, 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('App info'), findsWidgets);
    expect(find.text('Branding'), findsNothing);
    expect(find.text('Localization'), findsNothing);
    // Fields stack vertically: the two name fields share the same x position.
    final ar = tester.getTopLeft(find.byKey(const ValueKey('name-ar')));
    final en = tester.getTopLeft(find.byKey(const ValueKey('name-en')));
    expect(ar.dx, en.dx);
    expect(currentPath(container), '/builder/info');
  });

  testWidgets('RTL: Arabic UI mirrors the layout', (tester) async {
    await pumpApp(tester, arabic: true);
    final dir = Directionality.of(
      tester.element(find.byKey(const ValueKey('name-ar'))),
    );
    expect(dir, TextDirection.rtl);
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(find.text('التالي: الهوية البصرية'), findsOneWidget);
    expect(find.text('تلقائي'), findsOneWidget);
    // First step sits at the start (right) of the last one.
    final first = tester.getTopLeft(find.byKey(const ValueKey('step-0'))).dx;
    final last = tester.getTopLeft(find.byKey(const ValueKey('step-4'))).dx;
    expect(first, greaterThan(last));
    // The English-only fields keep LTR input.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('name-en')))
          .textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets(
    'router refuses to open later sections while earlier ones are invalid',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/builder/summary');
      await tester.pumpAndSettle();
      expect(currentPath(container), '/builder/info');
    },
  );

  testWidgets('changing the primary color updates the live preview', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();
    expect(currentPath(container), '/builder/template');

    Color previewPrimary() {
      final preview = tester.widget<RecruitmentApp>(
        find.descendant(
          of: find.byType(PhonePreview),
          matching: find.byType(RecruitmentApp),
        ),
      );
      return preview.branding.primaryColor;
    }

    expect(previewPrimary(), const Color(0xFF1565C0));
    container.read(draftProvider.notifier).setPrimary('#00AA55');
    await tester.pumpAndSettle();
    expect(previewPrimary(), const Color(0xFF00AA55));

    final ctx = tester.element(
      find
          .descendant(
            of: find.byType(PhonePreview),
            matching: find.byType(Scaffold),
          )
          .last,
    );
    expect(Theme.of(ctx).colorScheme.primary, const Color(0xFF00AA55));
  });

  testWidgets('selecting a template card updates the draft and preview', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();

    await tapIn(tester, find.byKey(const ValueKey('template-premium')));
    expect(container.read(draftProvider).templateId, 'premium');
    final preview = tester.widget<RecruitmentApp>(
      find.descendant(
        of: find.byType(PhonePreview),
        matching: find.byType(RecruitmentApp),
      ),
    );
    expect(preview.template.id, 'premium');
  });

  testWidgets(
    'the preview is interactive and keeps state across template switches',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(draftProvider.notifier).replace(validDraft());
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/builder/template');
      await tester.pumpAndSettle();
      final session = container.read(demoSessionProvider);

      expect(inPhone('login-continue'), findsOneWidget);
      // The demo notice lives in the panel header, not inside the phone screen.
      expect(inPhone('demo-banner'), findsNothing);
      expect(
        find.text('Demo data, no real payments or bookings'),
        findsOneWidget,
      );

      await tapIn(tester, inPhone('login-biometric'));
      await tapIn(tester, inPhone('biometric-confirm'));
      expect(session.isAuthenticated, isTrue);
      expect(inPhone('banner-slider'), findsOneWidget);

      await tapIn(tester, find.byKey(const ValueKey('jump-individuals')));
      expect(inPhone('address-a1'), findsOneWidget);
      await tapIn(tester, inPhone('address-a1'));
      expect(session.selectedAddressId, 'a1');

      await tapIn(tester, find.byKey(const ValueKey('template-premium')));
      expect(inPhone('address-a1'), findsOneWidget);
      expect(session.selectedAddressId, 'a1');

      await tapIn(tester, find.byKey(const ValueKey('preview-reset')));
      expect(inPhone('login-continue'), findsOneWidget);
      expect(session.selectedAddressId, isNull);
    },
  );

  testWidgets('disabling a module removes it from the preview', (tester) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();
    final session = container.read(demoSessionProvider);

    await tapIn(tester, find.byKey(const ValueKey('jump-home')));
    expect(inPhone('category-mediation'), findsOneWidget);

    await tapIn(tester, find.byKey(const ValueKey('module-mediation')));
    expect(session.enabledModules, isNot(contains(ServiceModule.mediation)));
    expect(inPhone('category-mediation'), findsNothing);

    // At least one module is required: Next refuses to continue.
    final c = container.read(draftProvider.notifier);
    c.setModule('individuals', false);
    c.setModule('hourly', false);
    await tester.pumpAndSettle();
    await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
    expect(currentPath(container), '/builder/template');
  });

  testWidgets('full preview page: switch template, go back to the gallery', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('preview-open-full')));
    await tapIn(tester, find.byKey(const ValueKey('preview-open-full')));
    expect(currentPath(container), '/preview');
    expect(inPhone('login-continue'), findsOneWidget);

    await tapIn(tester, find.byKey(const ValueKey('preview-template-modern')));
    expect(container.read(draftProvider).templateId, 'modern');

    await tapIn(tester, find.byKey(const ValueKey('preview-use-template')));
    expect(currentPath(container), '/builder/template');
    expect(container.read(draftProvider).templateId, 'modern');
  });

  testWidgets(
    'the full preview is not reachable before earlier sections are valid',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/preview');
      await tester.pumpAndSettle();
      expect(currentPath(container), '/builder/info');
    },
  );

  Future<ProviderContainer> openTemplateStep(WidgetTester tester) async {
    final container = await pumpApp(tester);
    container.read(draftProvider.notifier).replace(validDraft());
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('templates step: heading, footer, stepper state', (tester) async {
    final container = await openTemplateStep(tester);
    expect(find.text('Choose the app template'), findsOneWidget);
    expect(find.text('4 templates available'), findsOneWidget);
    // Footer names the selected template; Next announces Summary.
    expect(find.textContaining('Step 4 of 5'), findsOneWidget);
    expect(find.textContaining('Selected template: Classic'), findsOneWidget);
    expect(find.text('Next: Summary'), findsOneWidget);
    // Steps 1-3 done, 4 current, 5 upcoming.
    for (final i in [0, 1, 2]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('step-$i')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('step-3')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );

    // Picking a template updates the footer immediately.
    await tapIn(tester, find.byKey(const ValueKey('template-modern')));
    expect(find.textContaining('Selected template: Modern'), findsOneWidget);
    expect(container.read(draftProvider).templateId, 'modern');
    // Selected card shows the pill; others do not.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('template-modern')),
        matching: find.text('Selected'),
      ),
      findsOneWidget,
    );
    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets(
    'service unit cards are toggle buttons that drive the preview pills',
    (tester) async {
      final container = await openTemplateStep(tester);
      final card = find.byKey(const ValueKey('module-hourly'));
      // aria-pressed equivalent: a button Semantics node with toggled state.
      final sem = tester.widget<Semantics>(
        find.descendant(of: card, matching: find.byType(Semantics)).first,
      );
      expect(sem.properties.button, isTrue);
      expect(sem.properties.toggled, isTrue);

      Finder pill(String e) => find.byKey(ValueKey('jump-$e'));
      // Home is the active pill after jumping there.
      await tapIn(tester, pill('home'));
      final session = container.read(demoSessionProvider);
      expect(session.currentEntry, DemoEntry.home);

      await tapIn(tester, card); // turn hourly off
      expect(
        container.read(draftProvider).enabledModules,
        isNot(contains('hourly')),
      );
      // Disabled pill: no navigation, explains why in a tooltip.
      await tester.ensureVisible(pill('hourly'));
      await tester.tap(pill('hourly'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(session.currentEntry, DemoEntry.home);
      expect(
        find.byTooltip('Enable “Hourly services” to view it'),
        findsOneWidget,
      );

      await tapIn(tester, pill('individuals'));
      expect(session.currentEntry, DemoEntry.individuals);
    },
  );

  testWidgets('device switch changes the frame; content keeps rendering', (
    tester,
  ) async {
    await openTemplateStep(tester);
    expect(
      PhoneFrame.topInsetFor(PhoneDevice.iphone),
      greaterThan(PhoneFrame.topInsetFor(PhoneDevice.android)),
    );
    PhoneFrame frame() => tester.widget<PhoneFrame>(find.byType(PhoneFrame));
    expect(frame().device, PhoneDevice.iphone);
    await tapIn(tester, find.byKey(const ValueKey('seg-PhoneDevice.android')));
    expect(frame().device, PhoneDevice.android);
    expect(inPhone('login-continue'), findsOneWidget);
    await tapIn(tester, find.byKey(const ValueKey('seg-PhoneDevice.iphone')));
    expect(frame().device, PhoneDevice.iphone);
  });

  testWidgets('narrow screens stack the panel and units; no overflow', (
    tester,
  ) async {
    await openTemplateStep(tester);
    tester.view.physicalSize = const Size(600, 1400);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final selection = tester.getTopLeft(find.text('Choose the app template'));
    final panel = tester.getTopLeft(find.text('Live preview'));
    expect(panel.dy, greaterThan(selection.dy), reason: 'panel wraps below');
    // One column of unit cards.
    final a = tester.getTopLeft(
      find.byKey(const ValueKey('module-individuals')),
    );
    final b = tester.getTopLeft(find.byKey(const ValueKey('module-hourly')));
    expect(a.dx, b.dx);
    expect(b.dy, greaterThan(a.dy));
  });

  testWidgets('wide screens place the panel beside the selection', (
    tester,
  ) async {
    await openTemplateStep(tester);
    final selection = tester.getTopLeft(find.text('Choose the app template'));
    final panel = tester.getTopLeft(find.text('Live preview'));
    expect(panel.dx, greaterThan(selection.dx));
    expect((panel.dy - selection.dy).abs(), lessThan(40));
  });

  testWidgets(
    'Arabic: the preview panel sits at the end (left) of the selection',
    (tester) async {
      final container = await pumpApp(tester, arabic: true);
      container.read(draftProvider.notifier).replace(validDraft());
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/builder/template');
      await tester.pumpAndSettle();
      expect(find.text('اختر قالب التطبيق'), findsOneWidget);
      expect(find.text('معاينة حيّة'), findsOneWidget);
      final selection = tester.getTopLeft(find.text('اختر قالب التطبيق'));
      final panel = tester.getTopLeft(find.text('معاينة حيّة'));
      expect(panel.dx, lessThan(selection.dx));
      expect(find.textContaining('القالب المختار: كلاسيكي'), findsOneWidget);
    },
  );
}
