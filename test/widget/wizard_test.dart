import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/app/app.dart';
import 'package:swiftappbuilder/app/locale_provider.dart';
import 'package:swiftappbuilder/app/router.dart';
import 'package:swiftappbuilder/features/builder/application/providers.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_frame.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_preview.dart';

import 'package:swiftappbuilder/features/builder/domain/asset.dart';
import 'package:image/image.dart' as img;
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
        find.text('Enter the Arabic app name, e.g. الخدمة للاستقدام'),
        findsOneWidget,
      );
      expect(
        find.text('Enter the Android package name, e.g. com.excp.enaya'),
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
      expect(find.textContaining('for example com.excp.enaya'), findsNothing);

      // Leaving the field shows a specific message.
      await tester.enterText(f('client-name'), 'مكتب سويفت');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use lowercase letters without spaces, for example com.excp.enaya',
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
        'Use reverse-DNS format without spaces, for example com.excp.enaya',
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

  Future<ProviderContainer> openBranding(
    WidgetTester tester, {
    bool arabic = false,
    bool withLogo = true,
  }) async {
    final container = await pumpApp(tester, arabic: arabic);
    final d = validDraft();
    container
        .read(draftProvider.notifier)
        .replace(withLogo ? d : d.copyWith(clearLogo: true));
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/branding');
    await tester.pumpAndSettle();
    return container;
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('branding: inline picker, three real roles, no popup', (
    tester,
  ) async {
    await openBranding(tester);
    expect(find.text('Branding'), findsWidgets);
    expect(
      find.text(
        'Pick any color you like from the picker, or type the color code directly.',
      ),
      findsOneWidget,
    );
    for (final r in ['primary', 'secondary', 'splash']) {
      expect(key('role-$r'), findsOneWidget);
    }
    // The picker is always visible; selecting a role never opens a dialog.
    expect(key('sv-area'), findsOneWidget);
    expect(key('hue-slider'), findsOneWidget);
    await tapIn(tester, key('role-secondary'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(key('sv-area'), findsOneWidget);
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Next: Localization'), findsOneWidget);
  });

  testWidgets(
    'branding: HEX input is live, accepts 3 digits, reverts when invalid',
    (tester) async {
      final container = await openBranding(tester);
      String primary() => container.read(draftProvider).primaryHex;
      expect(primary(), '#1565C0');

      await tester.ensureVisible(key('hex-field'));
      await tester.enterText(key('hex-field'), '#00aa55');
      await tester.pumpAndSettle();
      expect(primary(), '#00AA55');

      await tester.enterText(key('hex-field'), '0f8');
      await tester.pumpAndSettle();
      expect(primary(), '#00FF88');

      // Invalid partial value: nothing is applied, and on blur it reverts.
      await tester.enterText(key('hex-field'), '12');
      await tester.pumpAndSettle();
      expect(primary(), '#00FF88');
      await tapIn(tester, key('rgb-r')); // moves focus away
      expect(
        tester.widget<TextField>(key('hex-field')).controller!.text,
        '#00FF88',
      );
      // The role tab reflects the color.
      expect(
        find.descendant(
          of: key('role-primary'),
          matching: find.text('#00FF88'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('branding: RGB inputs update the color; out-of-range reverts', (
    tester,
  ) async {
    final container = await openBranding(tester);
    await tester.ensureVisible(key('rgb-g'));
    await tester.enterText(key('rgb-g'), '255');
    await tester.pumpAndSettle();
    expect(container.read(draftProvider).primaryHex, '#15FFC0');
    await tester.enterText(key('rgb-b'), '999');
    await tester.pumpAndSettle();
    expect(container.read(draftProvider).primaryHex, '#15FFC0');
    await tapIn(tester, key('hex-field'));
    expect(tester.widget<TextField>(key('rgb-b')).controller!.text, '192');
  });

  testWidgets('branding: contrast row warns but never blocks', (tester) async {
    final container = await openBranding(tester);
    expect(
      find.textContaining('White text is clear on this color'),
      findsOneWidget,
    );
    container.read(draftProvider.notifier).setPrimary('#FFB300');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Text may not be clear on this color'),
      findsOneWidget,
    );
    // Still allowed to continue.
    await tapIn(tester, key('wizard-next'));
    expect(currentPath(container), '/builder/localization');

    container.read(routerProvider).go('/builder/branding');
    await tester.pumpAndSettle();
    await tapIn(tester, key('role-splash'));
    // Splash background is checked against the primary color.
    expect(find.textContaining('primary color'), findsWidgets);
  });

  testWidgets(
    'branding: suggested swatches keep the old presets and show a ring',
    (tester) async {
      final container = await openBranding(tester);
      await tapIn(tester, key('preset-#00897B'));
      expect(container.read(draftProvider).primaryHex, '#00897B');
      expect(
        find.bySemanticsLabel('Color #00897B'),
        findsNothing,
      ); // semantics off by default
      expect(key('preset-#00897B'), findsOneWidget);
      for (final c in ['#1565C0', '#FFB300', '#FFFFFF']) {
        expect(key('preset-$c'), findsOneWidget);
      }
    },
  );

  testWidgets('branding: area and hue slider work with keyboard and drag', (
    tester,
  ) async {
    final container = await openBranding(tester);
    HSVColor hsv() =>
        HSVColor.fromColor(container.read(draftProvider).primaryColor);

    await tester.ensureVisible(key('sv-area'));
    await tester.pumpAndSettle();
    final before = hsv();
    await tester.tap(key('sv-area')); // focuses the area and picks the centre
    await tester.pumpAndSettle();
    final centre = hsv();
    expect(centre.saturation, closeTo(0.5, 0.05));
    expect(centre.value, closeTo(0.5, 0.05));
    expect(centre.hue, closeTo(before.hue, 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(hsv().saturation, greaterThan(centre.saturation));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(hsv().value, greaterThan(centre.value));

    await tester.ensureVisible(key('hue-slider'));
    await tester.tap(key('hue-slider'));
    await tester.pumpAndSettle();
    final hue0 = hsv().hue;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect((hsv().hue - hue0).abs(), greaterThan(0.5));

    // Dragging on the area changes the color and notifies at most once a frame.
    final start = container.read(draftProvider).primaryHex;
    await tester.ensureVisible(key('sv-area'));
    await tester.pumpAndSettle();
    await tester.drag(key('sv-area'), const Offset(40, -30));
    await tester.pumpAndSettle();
    expect(container.read(draftProvider).primaryHex, isNot(start));
  });

  testWidgets('branding: picker controls expose slider semantics', (
    tester,
  ) async {
    await openBranding(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    Semantics byLabel(String label) => tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      ),
    );
    final area = byLabel('Saturation and brightness').properties;
    expect(area.slider, isTrue);
    expect(
      area.value,
      matches(RegExp(r'Saturation [0-9]+%, brightness [0-9]+%')),
    );
    final hue = byLabel('Hue').properties;
    expect(hue.slider, isTrue);
    expect(hue.value, contains('°'));
    handle.dispose();
  });

  testWidgets(
    'branding: logo colors and extraction only appear with a raster logo',
    (tester) async {
      // No logo: neither the button nor the section.
      var container = await openBranding(tester, withLogo: false);
      expect(key('extract-colors'), findsNothing);
      expect(find.text('From logo'), findsNothing);
      container.read(draftProvider.notifier).replace(validDraft());
      await tester.pumpAndSettle();
      expect(key('extract-colors'), findsOneWidget);
      expect(find.text('From logo'), findsOneWidget);

      // A two-colour logo: extraction fills primary and secondary.
      final image = img.Image(width: 32, height: 32);
      for (final p in image) {
        p.setRgb(p.y < 20 ? 200 : 20, p.y < 20 ? 40 : 160, p.y < 20 ? 40 : 80);
      }
      final png = Uint8List.fromList(img.encodePng(image));
      container
          .read(draftProvider.notifier)
          .setAsset(
            AssetKind.logo,
            PickedAsset(
              name: 'logo.png',
              bytes: png,
              extension: 'png',
              width: 32,
              height: 32,
            ),
          );
      await tester.pumpAndSettle();
      await tapIn(tester, key('extract-colors'));
      final d = container.read(draftProvider);
      expect(d.primaryHex, '#C82828');
      expect(d.secondaryHex, '#14A050');
      expect(key('logo-color-#C82828'), findsOneWidget);

      // SVG logos cannot be sampled: the button is hidden.
      container
          .read(draftProvider.notifier)
          .setAsset(
            AssetKind.logo,
            PickedAsset(
              name: 'logo.svg',
              bytes: Uint8List.fromList(
                '<svg width="600" height="600"/>'.codeUnits,
              ),
              extension: 'svg',
            ),
          );
      await tester.pumpAndSettle();
      expect(key('extract-colors'), findsNothing);
    },
  );

  testWidgets('branding: live preview follows every color change', (
    tester,
  ) async {
    final container = await openBranding(tester);
    Color previewPrimary() => tester
        .widget<RecruitmentApp>(
          find.descendant(
            of: find.byType(PhonePreview),
            matching: find.byType(RecruitmentApp),
          ),
        )
        .branding
        .primaryColor;
    expect(find.text('Live preview'), findsOneWidget);
    expect(find.text('Colors update instantly as you choose'), findsOneWidget);
    expect(previewPrimary(), const Color(0xFF1565C0));
    await tester.ensureVisible(key('hex-field'));
    await tester.enterText(key('hex-field'), '#00AA55');
    await tester.pumpAndSettle();
    expect(previewPrimary(), const Color(0xFF00AA55));
    container.read(draftProvider.notifier).setPrimary('#AA0000');
    await tester.pumpAndSettle();
    expect(previewPrimary(), const Color(0xFFAA0000));
  });

  testWidgets(
    'branding: narrow screens use a 2x2 role grid and stack the picker',
    (tester) async {
      await openBranding(tester);
      tester.view.physicalSize = const Size(600, 1600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final p = tester.getTopLeft(key('role-primary'));
      final s = tester.getTopLeft(key('role-secondary'));
      final x = tester.getTopLeft(key('role-splash'));
      expect(p.dy, s.dy);
      expect(x.dy, greaterThan(p.dy));
      // Picker and details are stacked: the HEX field sits below the area.
      expect(
        tester.getTopLeft(key('hex-field')).dy,
        greaterThan(tester.getBottomLeft(key('sv-area')).dy),
      );
      // Preview wraps below the settings.
      expect(
        tester.getTopLeft(find.text('Live preview')).dy,
        greaterThan(tester.getTopLeft(key('role-primary')).dy),
      );
    },
  );

  testWidgets('branding: Arabic heading, subtitle and RTL page layout', (
    tester,
  ) async {
    await openBranding(tester, arabic: true);
    expect(
      find.text('اختر أي لون تحبه من المنتقي، أو اكتب كود اللون مباشرة.'),
      findsOneWidget,
    );
    expect(find.text('ألوان التطبيق'), findsOneWidget);
    expect(find.text('معاينة حيّة'), findsOneWidget);
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);
    expect(find.text('التالي: اللغات'), findsOneWidget);
    // Page layout mirrors: the settings sit to the right of the preview.
    expect(
      tester.getTopLeft(find.text('ألوان التطبيق')).dx,
      greaterThan(tester.getTopLeft(find.text('معاينة حيّة')).dx),
    );
    // The picker itself never mirrors.
    final dir = Directionality.of(tester.element(key('sv-area')));
    expect(dir, TextDirection.ltr);
  });
}
