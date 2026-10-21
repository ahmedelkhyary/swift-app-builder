import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/app/app.dart';
import 'package:swiftappbuilder/app/locale_provider.dart';
import 'package:swiftappbuilder/app/router.dart';
import 'package:swiftappbuilder/features/builder/application/image_probe.dart';
import 'package:swiftappbuilder/features/builder/application/image_url_loader.dart';
import 'package:swiftappbuilder/features/builder/application/providers.dart';
import 'package:swiftappbuilder/features/builder/data/app_id_checker.dart';
import 'package:swiftappbuilder/features/builder/data/request_submitter.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_frame.dart';
import 'package:swiftappbuilder/features/builder/presentation/phone_preview.dart';

import 'package:swiftappbuilder/features/builder/domain/asset.dart';
import 'package:swiftappbuilder/features/builder/domain/draft.dart';
import 'package:image/image.dart' as img;
import '../helpers.dart';

class _EnglishLocale extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool arabic = false,
  ImageFetch? fetch,
  ImageProbe? probe,
  RequestSubmitter? submitter,
  AppIdChecker? checker,
}) async {
  AppTemplate.useGoogleFonts = false;
  AppTemplate.skeletonDuration = Duration.zero;
  tester.view.physicalSize = const Size(1500, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schemaValidatorProvider.overrideWithValue(loadSchema()),
        if (!arabic) localeProvider.overrideWith(_EnglishLocale.new),
        if (fetch != null) imageFetchProvider.overrideWithValue(fetch),
        if (probe != null) imageProbeProvider.overrideWithValue(probe),
        if (submitter != null)
          requestSubmitterProvider.overrideWithValue(submitter),
        appIdCheckerProvider.overrideWithValue(
          checker ?? InMemoryAppIdChecker(),
        ),
        appIdDebounceProvider.overrideWithValue(Duration.zero),
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
      // The package starts with the fixed prefix only: that counts as empty.
      expect(find.text('This field is required'), findsWidgets);
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
      await tester.enterText(f('android-package'), '9bad');
      // Still typing in the package field: no error yet.
      await tester.pump();
      expect(find.textContaining('start'), findsNothing);

      // Leaving the field shows a specific message.
      await tester.enterText(f('client-name'), 'مكتب سويفت');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Use lowercase English letters and digits only'),
        findsOneWidget,
      );

      await tester.enterText(f('client-phone'), '+966500000000');
      await tester.enterText(f('client-email'), 'info@swift.example');
      await tester.enterText(f('android-package'), 'swift');
      await tester.pumpAndSettle();

      // appId was auto-generated from the English name.
      expect(container.read(draftProvider).appId, 'swift_maids');
      // iOS mirrors the Android value while the toggle is on.
      expect(tester.widget<TextField>(f('ios-bundle')).readOnly, isTrue);
      expect(
        tester.widget<TextField>(f('ios-bundle')).controller!.text,
        'swift',
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
    c.setAndroidPackage('com.excp.swift');
    await tester.pumpAndSettle();
    await tapIn(tester, find.byKey(const ValueKey('ios-same')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ios-bundle')))
          .readOnly,
      isFalse,
    );
    await tester.enterText(find.byKey(const ValueKey('ios-bundle')), '-bad');
    await tester.enterText(find.byKey(const ValueKey('client-name')), 'x');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Use English letters, digits and hyphens'),
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

    expect(previewPrimary(), const Color(0xFF213F80));
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

    // Ticking a second template keeps the first and previews the new one.
    await tapIn(tester, find.byKey(const ValueKey('template-premium')));
    expect(container.read(draftProvider).templateId, 'simple');
    // Unticking the first leaves premium as the single, final choice.
    await tapIn(tester, find.byKey(const ValueKey('template-simple')));
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

    await tapIn(tester, find.byKey(const ValueKey('preview-template-luxury')));
    // Browsing does not change the saved choice...
    expect(container.read(draftProvider).templateId, 'simple');

    // ...until the user confirms it.
    await tapIn(tester, find.byKey(const ValueKey('preview-use-template')));
    expect(currentPath(container), '/builder/template');
    expect(container.read(draftProvider).templateId, 'luxury');
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
    expect(find.text('3 templates available'), findsOneWidget);
    // Footer names the selected template; Next announces Summary.
    expect(find.textContaining('Step 4 of 5'), findsOneWidget);
    expect(find.textContaining('Selected template: Simple'), findsOneWidget);
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

    // Ticking a second template switches the footer to compare mode.
    await tapIn(tester, find.byKey(const ValueKey('template-luxury')));
    expect(find.textContaining('2 templates selected'), findsNWidgets(2));
    expect(find.text('Compare templates (2)'), findsOneWidget);
    // Unticking the first leaves luxury as the single, final choice.
    await tapIn(tester, find.byKey(const ValueKey('template-simple')));
    expect(find.textContaining('Selected template: Luxury'), findsOneWidget);
    expect(find.text('Next: Summary'), findsOneWidget);
    expect(container.read(draftProvider).templateId, 'luxury');
  });

  testWidgets('gallery has Simple, Luxury and a Premium badge; preview first', (
    tester,
  ) async {
    final container = await openTemplateStep(tester);
    for (final id in ['simple', 'luxury', 'premium']) {
      expect(find.byKey(ValueKey('template-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('badge-premium')), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);

    // "Preview" opens the full-size page on that template without selecting it.
    await tapIn(tester, find.byKey(const ValueKey('preview-card-premium')));
    expect(currentPath(container), '/preview');
    expect(container.read(draftProvider).templateId, 'simple');
    final app = tester.widget<RecruitmentApp>(
      find.descendant(
        of: find.byType(PhonePreview),
        matching: find.byType(RecruitmentApp),
      ),
    );
    expect(app.template.id, 'premium');
  });

  testWidgets('zero templates selected disables Next with a hint', (
    tester,
  ) async {
    await openTemplateStep(tester);
    await tapIn(tester, find.byKey(const ValueKey('template-simple')));
    expect(find.text('No templates selected'), findsOneWidget);
    expect(find.textContaining('Pick at least one template'), findsOneWidget);
    expect(nextButton(tester).onPressed, isNull);
    await tapIn(tester, find.byKey(const ValueKey('template-simple')));
    expect(nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('compare view: same screen on every phone, choose, back', (
    tester,
  ) async {
    final container = await openTemplateStep(tester);
    final next = find.byKey(const ValueKey('wizard-next'));
    await tapIn(tester, find.byKey(const ValueKey('template-luxury')));
    await tapIn(tester, find.byKey(const ValueKey('template-premium')));
    expect(find.text('Compare templates (3)'), findsOneWidget);
    await tapIn(tester, next);

    // Sub-view of step 4: stepper and counter unchanged, no Next button.
    expect(currentPath(container), '/builder/template');
    expect(find.text('Compare and pick your template'), findsOneWidget);
    expect(find.text('Choose one template for your app'), findsOneWidget);
    expect(find.textContaining('Step 4 of 5'), findsOneWidget);
    expect(next, findsNothing);
    expect(find.byType(PhonePreview), findsNWidgets(3));

    // One shared switcher drives all phones.
    await tapIn(tester, find.byKey(const ValueKey('jump-login')));
    final apps = tester.widgetList<RecruitmentApp>(find.byType(RecruitmentApp));
    expect(apps, hasLength(3));
    expect({for (final a in apps) a.session.currentEntry}, {DemoEntry.login});

    // Back keeps the ticks; the saved template is unchanged.
    await tapIn(tester, find.byKey(const ValueKey('compare-back')));
    expect(find.textContaining('3 templates selected'), findsNWidgets(2));
    expect(container.read(draftProvider).templateId, 'simple');

    // Choosing from the compare view sets the template and goes to Summary.
    await tapIn(tester, next);
    await tapIn(tester, find.byKey(const ValueKey('compare-choose-premium')));
    expect(container.read(draftProvider).templateId, 'premium');
    expect(currentPath(container), '/builder/summary');

    // Back in step 4 only the final template is selected.
    container.read(routerProvider).go('/builder/template');
    await tester.pumpAndSettle();
    expect(find.text('1 template selected'), findsOneWidget);
    expect(find.textContaining('Selected template: Premium'), findsOneWidget);
  });

  testWidgets('compare view: mobile shows one phone at a time', (tester) async {
    await openTemplateStep(tester);
    for (final id in ['luxury', 'premium']) {
      await tapIn(tester, find.byKey(ValueKey('template-$id')));
    }
    // Three templates: one row on desktop.
    await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
    expect(find.byKey(const ValueKey('compare-indicator')), findsNothing);

    await tapIn(tester, find.byKey(const ValueKey('compare-back')));
    tester.view.physicalSize = const Size(420, 900);
    await tester.pumpAndSettle();
    await tapIn(tester, find.byKey(const ValueKey('wizard-next')));
    expect(find.text('1 / 3'), findsOneWidget);
    await tapIn(tester, find.byKey(const ValueKey('compare-next')));
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('support emails: chips, paste, duplicates, invalid, remove', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final field = find.byKey(const ValueKey('support-emails'));
    List<String> emails() => container.read(draftProvider).supportEmails;
    Future<void> submit() async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Primary email'), findsOneWidget);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();

    // Enter turns text into a chip.
    await tester.tap(field);
    await tester.enterText(field, 'one@example.com');
    await submit();
    expect(emails(), ['one@example.com']);

    // Pasting several addresses (commas or spaces) makes many chips.
    await tester.enterText(
      field,
      'two@example.com, three@example.com four@example.com ',
    );
    await tester.pumpAndSettle();
    expect(emails(), [
      'one@example.com',
      'two@example.com',
      'three@example.com',
      'four@example.com',
    ]);

    // Duplicates (case-insensitive) are ignored with a hint.
    await tester.enterText(field, 'ONE@example.com,');
    await tester.pump();
    expect(emails(), hasLength(4));
    expect(find.text('This email is already added'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    // Invalid text stays in the input with an error.
    await tester.enterText(field, 'not-an-email');
    await submit();
    expect(emails(), hasLength(4));
    expect(find.text('Invalid email format'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'not-an-email');

    // Remove via the chip's button (labelled for assistive tech).
    await tester.enterText(field, '');
    await tester.tap(find.byTooltip('Remove two@example.com'));
    await tester.pumpAndSettle();
    expect(emails(), [
      'one@example.com',
      'three@example.com',
      'four@example.com',
    ]);

    // Backspace in the empty input removes the last chip.
    await tester.tap(field);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(emails(), ['one@example.com', 'three@example.com']);
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
      expect(find.textContaining('القالب المختار: البسيط'), findsOneWidget);
    },
  );

  Future<ProviderContainer> openBranding(
    WidgetTester tester, {
    bool arabic = false,
    bool withLogo = true,
    ImageFetch? fetch,
    ImageProbe? probe,
  }) async {
    final container = await pumpApp(
      tester,
      arabic: arabic,
      fetch: fetch,
      probe: probe,
    );
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
      expect(primary(), '#213F80');

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
    expect(container.read(draftProvider).primaryHex, '#21FF80');
    await tester.enterText(key('rgb-b'), '999');
    await tester.pumpAndSettle();
    expect(container.read(draftProvider).primaryHex, '#21FF80');
    await tapIn(tester, key('hex-field'));
    expect(tester.widget<TextField>(key('rgb-b')).controller!.text, '128');
  });

  testWidgets('branding: accent, optional background/text, palettes, reset', (
    tester,
  ) async {
    final container = await openBranding(tester);
    AppConfigDraft d() => container.read(draftProvider);
    for (final r in ['accent', 'background', 'text']) {
      expect(key('role-$r'), findsOneWidget);
    }

    // A ready-made palette sets primary, secondary and accent together.
    await tapIn(tester, key('palette-teal'));
    expect(
      [d().primaryHex, d().secondaryHex, d().accentHex],
      ['#00695C', '#FFB300', '#2E7D32'],
    );

    // Background / text are unset until chosen, and can be cleared again.
    expect(d().backgroundHex, isEmpty);
    await tapIn(tester, key('role-background'));
    await tester.enterText(key('hex-field'), '#FAF3E0');
    await tester.pumpAndSettle();
    expect(d().backgroundHex, '#FAF3E0');
    expect(key('role-clear'), findsOneWidget);
    await tapIn(tester, key('role-clear'));
    expect(d().backgroundHex, isEmpty);

    // Text on the page: a low-contrast choice warns but is never blocked.
    await tapIn(tester, key('role-text'));
    await tester.enterText(key('hex-field'), '#F5F5F5');
    await tester.pumpAndSettle();
    expect(d().textHex, '#F5F5F5');
    expect(find.textContaining('may not be readable'), findsOneWidget);

    await tapIn(tester, key('reset-colors'));
    expect(
      [d().primaryHex, d().secondaryHex, d().accentHex],
      ['#213F80', '#29ABE2', '#2E9E5B'],
    );
    expect(d().textHex, isEmpty);
  });

  testWidgets(
    'branding: live preview Home has the address header and featured',
    (tester) async {
      await openBranding(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BuilderApp)),
      );
      container.read(demoSessionProvider).jumpTo(DemoEntry.home);
      await tester.pumpAndSettle();
      expect(inPhone('home-address'), findsOneWidget);
      expect(inPhone('featured-hourly-maid'), findsOneWidget);
    },
  );

  testWidgets('branding: logo from an image URL', (tester) async {
    const ok = 'https://cdn.example.com/brand/ok.png';
    final container = await openBranding(
      tester,
      fetch: (u) async {
        if (u.toString() == ok) return pngBytes(700, 700);
        throw StateError('blocked');
      },
      probe: (u) async {
        if (u == ok) return const ProbedImage(700, 700);
        throw const ImageProbeException('error');
      },
    );
    AppConfigDraft d() => container.read(draftProvider);
    Finder logoTab(String seg) => find.descendant(
      of: key('source-logo'),
      matching: key('seg-AssetSource.$seg'),
    );
    final before = d().logo!;
    await tester.ensureVisible(key('source-logo'));
    await tester.pumpAndSettle();
    expect(key('upload-logo'), findsOneWidget);

    // URL mode: a bad link shows the error and keeps the current image.
    await tapIn(tester, logoTab('url'));
    expect(key('upload-logo'), findsNothing);
    await tester.enterText(key('url-logo'), 'https://nope.example.com/x.png');
    await tapIn(tester, key('load-logo'));
    expect(
      find.textContaining("Couldn't load image from this link"),
      findsOneWidget,
    );
    expect(identical(d().logo, before), isTrue);

    // A malformed link is rejected before any download.
    await tester.enterText(key('url-logo'), 'ftp://example.com/x.png');
    await tapIn(tester, key('load-logo'));
    expect(find.text('The link is not valid'), findsOneWidget);

    // A good link replaces the image and keeps the original URL.
    await tester.enterText(key('url-logo'), ok);
    await tapIn(tester, key('load-logo'));
    expect(d().logo!.sourceUrl, ok);
    expect(d().logo!.name, 'ok.png');
    expect(find.textContaining("Couldn't load"), findsNothing);

    // The chosen source is remembered when coming back to the step.
    container.read(routerProvider).go('/builder/localization');
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/builder/branding');
    await tester.pumpAndSettle();
    expect(key('url-logo'), findsOneWidget);
    expect(tester.widget<TextField>(key('url-logo')).controller!.text, ok);

    // Remove works the same as for uploads; the file mode is back on demand.
    await tapIn(tester, key('remove-logo'));
    expect(d().logo, isNull);
    await tapIn(tester, logoTab('file'));
    expect(key('upload-logo'), findsOneWidget);
  });

  testWidgets('branding: app icon from a URL follows the icon rules', (
    tester,
  ) async {
    final container = await openBranding(
      tester,
      fetch: (u) async => u.path.endsWith('small.png')
          ? pngBytes(512, 512)
          : pngBytes(1024, 1024),
      probe: (u) async => u.endsWith('small.png')
          ? const ProbedImage(512, 512)
          : const ProbedImage(1024, 1024),
    );
    await tester.ensureVisible(key('source-appIcon'));
    await tester.pumpAndSettle();
    await tapIn(
      tester,
      find.descendant(
        of: key('source-appIcon'),
        matching: key('seg-AssetSource.url'),
      ),
    );
    await tester.enterText(
      key('url-appIcon'),
      'https://x.example.com/small.png',
    );
    await tapIn(tester, key('load-appIcon'));
    expect(
      find.text(
        'Unsuitable image size: required exactly 1024×1024, current 512×512',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      key('url-appIcon'),
      'https://x.example.com/icon.png',
    );
    await tapIn(tester, key('load-appIcon'));
    expect(
      container.read(draftProvider).appIcon!.sourceUrl,
      'https://x.example.com/icon.png',
    );
  });

  group('summary: submit request', () {
    Future<ProviderContainer> openSummary(
      WidgetTester tester,
      RequestSubmitter submitter,
    ) async {
      final container = await pumpApp(tester, submitter: submitter);
      container.read(draftProvider.notifier).replace(validDraft());
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/builder/summary');
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('JSON, download and version history are gone', (tester) async {
      await openSummary(tester, _FakeSubmitter());
      expect(find.text('Configuration JSON'), findsNothing);
      expect(key('download-json'), findsNothing);
      expect(find.text('Version history'), findsNothing);
      expect(find.text('Review'), findsWidgets);
      expect(find.text('Submit request'), findsWidgets);
      expect(find.text('Save configuration'), findsNothing);
    });

    testWidgets('submits, shows success with the App ID, then resets', (
      tester,
    ) async {
      final submitter = _FakeSubmitter();
      final container = await openSummary(tester, submitter);
      await tapIn(tester, key('submit-request'));
      expect(submitter.calls, ['swift_maids']);
      expect(key('submit-success'), findsOneWidget);
      expect(find.text('Your request was submitted'), findsOneWidget);
      expect(
        tester.widget<SelectableText>(key('request-ref')).data,
        'swift_maids',
      );

      await tapIn(tester, key('back-to-start'));
      // Everything is cleared and the user is back on step 1.
      expect(currentPath(container), '/builder/info');
      final d = container.read(draftProvider);
      expect(d.appId, isEmpty);
      expect(d.nameEn, isEmpty);
      expect(d.logo, isNull);
      expect(d.supportEmails, isEmpty);
    });

    testWidgets('shows a loading state and blocks double submissions', (
      tester,
    ) async {
      final gate = Completer<SubmitResult>();
      final submitter = _FakeSubmitter(gate: gate);
      await openSummary(tester, submitter);
      await tester.ensureVisible(key('submit-request'));
      await tester.tap(key('submit-request'));
      await tester.pump();
      expect(find.text('Submitting...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(key('submit-request')).onPressed,
        isNull,
      );
      gate.complete(SubmitResult.created);
      await tester.pumpAndSettle();
      expect(submitter.calls, hasLength(1));
      expect(key('submit-success'), findsOneWidget);
    });

    testWidgets('an error keeps the data and offers a retry', (tester) async {
      final submitter = _FakeSubmitter(
        failures: [const SubmitException(SubmitErrorKind.network)],
      );
      final container = await openSummary(tester, submitter);
      await tapIn(tester, key('submit-request'));
      expect(key('submit-error'), findsOneWidget);
      expect(find.textContaining('Could not reach the server'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(container.read(draftProvider).appId, 'swift_maids');

      await tapIn(tester, key('submit-request'));
      expect(submitter.calls, hasLength(2));
      expect(key('submit-error'), findsNothing);
      expect(key('submit-success'), findsOneWidget);
    });

    testWidgets('an ID taken in the meantime sends the user back to Step 1', (
      tester,
    ) async {
      final submitter = _FakeSubmitter(taken: true);
      final container = await openSummary(tester, submitter);
      await tapIn(tester, key('submit-request'));
      // Nothing is lost; the user is on Step 1 with the ID marked as used.
      expect(currentPath(container), '/builder/info');
      expect(container.read(draftProvider).clientName, 'مكتب سويفت');
      expect(key('app-id-just-taken'), findsOneWidget);
      expect(find.textContaining('was just taken'), findsOneWidget);
      expect(
        find.text('This App ID is already taken, choose another one'),
        findsOneWidget,
      );
      expect(key('submit-success'), findsNothing);
      // Next stays blocked until another ID is chosen.
      expect(currentPath(container), '/builder/info');
    });
  });

  group('step 1: App ID availability (Firestore)', () {
    Future<ProviderContainer> openInfo(
      WidgetTester tester,
      AppIdChecker checker,
    ) async {
      final container = await pumpApp(tester, checker: checker);
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> fillRest(WidgetTester tester) async {
      Finder f(String k) => find.byKey(ValueKey(k));
      await tester.enterText(f('name-ar'), 'عناية');
      await tester.enterText(f('client-name'), 'مكتب عناية');
      await tester.enterText(f('client-phone'), '+966500000000');
      await tester.enterText(f('client-email'), 'info@enaya.example');
      await tester.pumpAndSettle();
    }

    testWidgets('a taken ID shows the error, suggestions, and blocks Next', (
      tester,
    ) async {
      final checker = InMemoryAppIdChecker(taken: {'enaya', 'enaya-app'});
      final container = await openInfo(tester, checker);
      await tester.enterText(key('name-en'), 'Enaya');
      await fillRest(tester);
      expect(container.read(draftProvider).appId, 'enaya');
      expect(
        find.text('This App ID is already taken, choose another one'),
        findsOneWidget,
      );
      // Only checked, free alternatives are offered.
      expect(key('suggest-enaya-app'), findsNothing);
      expect(key('suggest-enaya-2'), findsOneWidget);

      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/info');

      // Tapping a suggestion fills the field and unblocks the step.
      await tapIn(tester, key('suggest-enaya-2'));
      expect(container.read(draftProvider).appId, 'enaya-2');
      expect(find.text('App ID is available'), findsOneWidget);
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), isNot('/builder/info'));
    });

    testWidgets('IDs are normalized: spaces and capitals do not matter', (
      tester,
    ) async {
      final checker = InMemoryAppIdChecker(taken: {'enaya'});
      final container = await openInfo(tester, checker);
      await tester.enterText(key('name-en'), 'Something');
      await tester.pumpAndSettle();
      await tapIn(tester, key('app-id-edit'));
      await tester.enterText(key('app-id'), '  ENAYA ');
      await tester.pumpAndSettle();
      expect(container.read(draftProvider).appId, 'enaya');
      expect(checker.calls, contains('enaya'));
      expect(checker.calls.every((c) => c == c.trim().toLowerCase()), isTrue);
      expect(
        find.text('This App ID is already taken, choose another one'),
        findsOneWidget,
      );
    });

    testWidgets('a malformed ID is not sent to the backend', (tester) async {
      final checker = InMemoryAppIdChecker();
      await openInfo(tester, checker);
      await tester.enterText(key('name-en'), 'Something');
      await tester.pumpAndSettle();
      checker.calls.clear();
      await tapIn(tester, key('app-id-edit'));
      await tester.enterText(key('app-id'), '9bad id!');
      await tester.pumpAndSettle();
      expect(checker.calls, isEmpty);
      expect(key('app-id-available'), findsNothing);
    });

    testWidgets('a network error offers a retry and blocks Next', (
      tester,
    ) async {
      final checker = InMemoryAppIdChecker(failing: true);
      final container = await openInfo(tester, checker);
      await tester.enterText(key('name-en'), 'Enaya');
      await fillRest(tester);
      expect(find.text("Couldn't check the App ID, try again"), findsOneWidget);
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/info');

      checker.failing = false;
      await tapIn(tester, key('app-id-retry'));
      expect(find.text('App ID is available'), findsOneWidget);
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), isNot('/builder/info'));
    });

    testWidgets('only the latest check result is applied', (tester) async {
      final slow = _SlowChecker();
      final container = await openInfo(tester, slow);
      await tester.enterText(key('name-en'), 'Slow One');
      await tester.pump();
      // The user keeps typing: the first answer arrives late and is ignored.
      await tester.enterText(key('name-en'), 'Fast Two');
      await tester.pump();
      slow.answer('slow_one', false); // outdated: "taken"
      await tester.pump();
      slow.answer('fast_two', true);
      await tester.pumpAndSettle();
      expect(container.read(draftProvider).appId, 'fast_two');
      expect(find.text('App ID is available'), findsOneWidget);
      expect(
        find.text('This App ID is already taken, choose another one'),
        findsNothing,
      );
    });
  });

  group('step 1: iOS bundle ID', () {
    testWidgets('mirrors Android, converting underscores, with a note', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      final ios = key('ios-bundle');
      AppConfigDraft d() => container.read(draftProvider);
      expect(
        find.descendant(
          of: key('fixed-prefix').last,
          matching: find.text('com.excp.'),
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(ios).readOnly, isTrue);

      await tester.enterText(key('android-package'), 'my_app');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(ios).controller!.text, 'my-app');
      expect(d().effectiveIosBundleId, 'com.excp.my-app');
      expect(d().androidPackage, 'com.excp.my_app');
      expect(key('ios-converted-note'), findsOneWidget);
      expect(find.text('Bundle ID: com.excp.my-app'), findsOneWidget);

      await tester.enterText(key('android-package'), 'enaya');
      await tester.pumpAndSettle();
      expect(key('ios-converted-note'), findsNothing);
      expect(tester.widget<TextField>(ios).controller!.text, 'enaya');
    });

    testWidgets('unticking makes it editable on its own and filters input', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      AppConfigDraft d() => container.read(draftProvider);
      await tester.enterText(key('android-package'), 'my_app');
      await tester.pumpAndSettle();
      await tapIn(tester, key('ios-same'));
      expect(d().iosSameAsAndroid, isFalse);
      // It starts from the current (converted) value...
      expect(
        tester.widget<TextField>(key('ios-bundle')).controller!.text,
        'my-app',
      );
      expect(tester.widget<TextField>(key('ios-bundle')).readOnly, isFalse);

      // ...and then follows only its own input: lowercase, hyphens, dots.
      await tester.enterText(key('ios-bundle'), 'My_Other App.v2!');
      await tester.pumpAndSettle();
      expect(d().iosBundleId, 'com.excp.my-otherapp.v2');
      expect(
        d().androidPackage,
        'com.excp.my_app',
        reason: 'Android unchanged',
      );
      await tester.enterText(key('android-package'), 'changed');
      await tester.pumpAndSettle();
      expect(d().iosBundleId, 'com.excp.my-otherapp.v2');

      // Ticking again goes back to mirroring.
      await tapIn(tester, key('ios-same'));
      expect(d().effectiveIosBundleId, 'com.excp.changed');
    });

    testWidgets('Android and iOS sit side by side, stacked on phones', (
      tester,
    ) async {
      await pumpApp(tester);
      final a = tester.getTopLeft(key('android-package'));
      final i = tester.getTopLeft(key('ios-bundle'));
      expect(a.dy, i.dy, reason: 'same row on a wide screen');
      tester.view.physicalSize = const Size(420, 900);
      await tester.pumpAndSettle();
      final a2 = tester.getTopLeft(key('android-package'));
      final i2 = tester.getTopLeft(key('ios-bundle'));
      expect(i2.dy, greaterThan(a2.dy));
    });
  });

  group('step 1: package name with a fixed prefix', () {
    testWidgets(
      'the prefix is a read-only addon; only the suffix is editable',
      (tester) async {
        final container = await pumpApp(tester);
        final field = key('android-package');
        expect(
          find.descendant(
            of: key('fixed-prefix').first,
            matching: find.text('com.excp.'),
          ),
          findsOneWidget,
        );
        // The editable text never contains the prefix.
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(find.text('Package name: com.excp.'), findsOneWidget);

        // Uppercase becomes lowercase; spaces and other characters are dropped.
        await tester.enterText(field, ' My App-1! ');
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).controller!.text, 'myapp1');
        expect(container.read(draftProvider).androidPackage, 'com.excp.myapp1');
        expect(find.text('Package name: com.excp.myapp1'), findsOneWidget);

        // Pasting the prefix as well does not duplicate it.
        await tester.enterText(field, 'com.excp.enaya.client');
        await tester.pumpAndSettle();
        expect(
          container.read(draftProvider).androidPackage,
          'com.excp.enaya.client',
        );

        // The field is laid out left-to-right in the Arabic page too.
        final dir = tester.widget<TextField>(field).textDirection;
        expect(dir, TextDirection.ltr);
      },
    );

    testWidgets('invalid suffixes show specific errors', (tester) async {
      final container = await pumpApp(tester);
      final field = key('android-package');
      Future<void> typeAndLeave(String v) async {
        await tester.enterText(field, v);
        await tester.enterText(key('client-name'), 'x');
        await tester.pumpAndSettle();
      }

      for (final bad in ['9app', '.app', 'app.', 'a..b', 'enaya._x']) {
        await typeAndLeave(bad);
        expect(
          find.textContaining('Use lowercase English letters and digits only'),
          findsOneWidget,
          reason: bad,
        );
      }
      await typeAndLeave('enaya.class');
      expect(find.textContaining('Java reserved word'), findsOneWidget);
      await typeAndLeave('a' * 95);
      expect(find.textContaining('too long'), findsOneWidget);
      await typeAndLeave('enaya.client');
      expect(find.textContaining('Use lowercase'), findsNothing);
      expect(
        container.read(draftProvider).androidPackage,
        'com.excp.enaya.client',
      );
    });

    testWidgets(
      'loading existing data keeps only the last part under the prefix',
      (tester) async {
        final container = await pumpApp(tester);
        container.read(draftProvider.notifier).replace(validDraft());
        await tester.pumpAndSettle();
        expect(normalizePackage('com.example.swift'), 'com.excp.swift');
        expect(normalizePackage('com.excp.a.b'), 'com.excp.a.b');
        expect(normalizePackage('swift'), 'com.excp.swift');
        expect(packageSuffix('com.excp.a.b'), 'a.b');
      },
    );
  });

  testWidgets('branding: Firebase Storage link works, fields stay separate', (
    tester,
  ) async {
    const own =
        'https://firebasestorage.googleapis.com/v0/b/swift-saas-5ac3a.firebasestorage.app/o/app_requests%2Fblkedma_req%2Flogo_1792593994316.png?alt=media&token=709a3722-3fee-4f74-93e5-df777b635897';
    final seen = <String>[];
    final container = await openBranding(
      tester,
      // Reading bytes is blocked (no CORS), like on the real host.
      fetch: (u) async => throw StateError('CORS'),
      probe: (u) async {
        seen.add(u);
        if (u == own) return const ProbedImage(1024, 1024);
        throw const ImageProbeException('error');
      },
    );
    AppConfigDraft d() => container.read(draftProvider);
    Finder tab(String field, String seg) => find.descendant(
      of: key('source-$field'),
      matching: key('seg-AssetSource.$seg'),
    );
    await tester.ensureVisible(key('source-logo'));
    await tester.pumpAndSettle();
    await tapIn(tester, tab('logo', 'url'));

    // The exact link, untouched (%2F stays), is accepted without any download.
    await tester.enterText(key('url-logo'), ' $own ');
    await tapIn(tester, key('load-logo'));
    expect(seen.single, own);
    expect(d().logo!.isRemote, isTrue);
    expect(d().logo!.sourceUrl, own);
    expect(find.textContaining("Couldn't load"), findsNothing);

    // A broken link in the logo field shows its error once, and the previous
    // image is kept. Switching the icon to URL mode does not copy the error.
    await tester.enterText(key('url-logo'), 'https://example.com/broken.png');
    await tapIn(tester, key('load-logo'));
    expect(find.textContaining("Couldn't load image"), findsOneWidget);
    expect(d().logo!.sourceUrl, own);
    await tester.ensureVisible(key('source-appIcon'));
    await tapIn(tester, tab('appIcon', 'url'));
    expect(find.textContaining("Couldn't load image"), findsOneWidget);
  });

  testWidgets('branding: splash logo has Image URL with its own state', (
    tester,
  ) async {
    const good = 'https://cdn.example.com/brand/splash.png';
    final container = await openBranding(
      tester,
      fetch: (u) async => pngBytes(700, 700),
      probe: (u) async {
        if (u == good) return const ProbedImage(700, 700);
        throw const ImageProbeException('error');
      },
    );
    AppConfigDraft d() => container.read(draftProvider);
    Finder tab(String field, String seg) => find.descendant(
      of: key('source-$field'),
      matching: key('seg-AssetSource.$seg'),
    );

    // Optional: nothing selected is fine and the hint explains the fallback.
    expect(d().splashLogo, isNull);
    expect(find.text('Uses the main logo when empty'), findsOneWidget);

    await tester.ensureVisible(key('source-splashLogo'));
    await tapIn(tester, tab('splashLogo', 'url'));
    expect(key('upload-splashLogo'), findsNothing);

    // A broken link: its own error, nothing changes elsewhere.
    final logoBefore = d().logo;
    await tester.enterText(key('url-splashLogo'), 'https://example.com/x.png');
    await tapIn(tester, key('load-splashLogo'));
    expect(find.textContaining("Couldn't load image"), findsOneWidget);
    expect(d().splashLogo, isNull);
    expect(identical(d().logo, logoBefore), isTrue);
    // The logo and icon fields are still in file mode, without errors.
    expect(key('upload-logo'), findsOneWidget);
    expect(key('upload-appIcon'), findsOneWidget);

    // A good link is loaded, previewed, and can be changed or removed.
    await tester.enterText(key('url-splashLogo'), good);
    await tapIn(tester, key('load-splashLogo'));
    expect(d().splashLogo!.sourceUrl, good);
    expect(d().splashLogo!.name, 'splash.png');
    expect(find.textContaining("Couldn't load"), findsNothing);
    expect(find.text('splash.png  700×700'), findsOneWidget);
    await tapIn(tester, key('remove-splashLogo'));
    expect(d().splashLogo, isNull);
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
    expect(previewPrimary(), const Color(0xFF213F80));
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

class _FakeSubmitter implements RequestSubmitter {
  _FakeSubmitter({this.gate, this.failures = const [], this.taken = false});

  final Completer<SubmitResult>? gate;
  final List<SubmitException> failures;

  /// The ID is used by someone else when the user submits.
  final bool taken;
  final calls = <String>[];

  @override
  Future<SubmitResult> submit(AppConfigDraft draft) async {
    calls.add(draft.appId);
    if (failures.length >= calls.length) throw failures[calls.length - 1];
    if (gate != null) return gate!.future;
    return taken ? SubmitResult.taken : SubmitResult.created;
  }
}

/// Answers each check only when the test says so.
class _SlowChecker implements AppIdChecker {
  final _pending = <String, Completer<bool>>{};

  @override
  Future<bool> isAvailable(String appId) =>
      (_pending[appId] ??= Completer<bool>()).future;

  void answer(String appId, bool free) =>
      (_pending[appId] ??= Completer<bool>()).complete(free);
}
