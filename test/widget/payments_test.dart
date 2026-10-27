import 'dart:async';

import 'package:country_flags/country_flags.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';
import 'package:swiftappbuilder/app/app.dart';
import 'package:swiftappbuilder/app/locale_provider.dart';
import 'package:swiftappbuilder/app/router.dart';
import 'package:swiftappbuilder/features/builder/application/providers.dart';
import 'package:swiftappbuilder/features/builder/data/app_id_checker.dart';
import 'package:swiftappbuilder/features/builder/data/payment_backend.dart';
import 'package:swiftappbuilder/features/builder/domain/payments.dart';

import '../helpers.dart';

class _EnglishLocale extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

/// A tester the test controls: answers when [gate] completes, or at once.
class FakeGatewayTester implements PaymentGatewayTester {
  FakeGatewayTester({
    this.result = const GatewayTestResult(GatewayTestResult.ok),
  });

  GatewayTestResult result;
  Completer<void>? gate;
  final calls = <(String, PaymentEnv, Map<String, String>)>[];

  @override
  Future<GatewayTestResult> test(
    String gatewayId,
    PaymentEnv env,
    Map<String, String> credentials,
  ) async {
    calls.add((gatewayId, env, credentials));
    await gate?.future;
    return result;
  }
}

Future<ProviderContainer> openPayments(
  WidgetTester tester, {
  bool arabic = false,
  PaymentsDraft payments = const PaymentsDraft(),
  FakeGatewayTester? gatewayTester,
}) async {
  AppTemplate.useGoogleFonts = false;
  AppTemplate.skeletonDuration = Duration.zero;
  tester.view.physicalSize = const Size(1500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schemaValidatorProvider.overrideWithValue(loadSchema()),
        if (!arabic) localeProvider.overrideWith(_EnglishLocale.new),
        appIdCheckerProvider.overrideWithValue(InMemoryAppIdChecker()),
        appIdDebounceProvider.overrideWithValue(Duration.zero),
        demoRepositoryProvider.overrideWithValue(
          MockDemoRepository(latency: Duration.zero),
        ),
        if (gatewayTester != null)
          paymentGatewayTesterProvider.overrideWithValue(gatewayTester),
      ],
      child: const BuilderApp(useGoogleFonts: false),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(BuilderApp)),
  );
  container
      .read(draftProvider.notifier)
      .replace(validDraft().copyWith(payments: payments));
  await tester.pumpAndSettle();
  container.read(routerProvider).go('/builder/payments');
  await tester.pumpAndSettle();
  return container;
}

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> tapIn(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> typeIn(WidgetTester tester, String k, String text) async {
  await tester.ensureVisible(key(k));
  await tester.enterText(key(k), text);
  await tester.pumpAndSettle();
}

String currentPath(ProviderContainer c) =>
    c.read(routerProvider).routeInformationProvider.value.uri.path;

PaymentsDraft payments(ProviderContainer c) => c.read(draftProvider).payments;

Future<void> fillHyperpay(WidgetTester tester) async {
  await typeIn(tester, 'field-hyperpay-accessToken', 'tok-1234567890');
  await typeIn(tester, 'field-hyperpay-entityIdCards', 'cards-entity');
  await typeIn(tester, 'field-hyperpay-entityIdMada', 'mada-entity');
}

void main() {
  narrowTests();
  testWidgets('is step 5 of 6, between Template and Summary', (tester) async {
    final container = await openPayments(tester);
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(find.text('Next: Summary'), findsOneWidget);
    expect(find.text('Payment methods'), findsWidgets);
    expect(
      find.text(
        'Turn on the payment gateways that appear in the app, then choose the default one.',
      ),
      findsOneWidget,
    );
    // Six steps in the stepper.
    for (var i = 0; i < 6; i++) {
      expect(key('step-$i'), findsOneWidget);
    }
    await tapIn(tester, key('wizard-back'));
    expect(currentPath(container), '/builder/template');
  });

  testWidgets('shows a tile per gateway: region and at most 3 method chips', (
    tester,
  ) async {
    await openPayments(tester);
    for (final id in ['hyperpay', 'paymob', 'payfort']) {
      expect(key('gateway-tile-$id'), findsOneWidget);
      expect(key('gateway-check-$id'), findsNothing);
    }
    expect(find.text('Choose payment gateways'), findsOneWidget);
    expect(find.text('Connection details'), findsOneWidget);
    expect(find.text('HyperPay'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsNothing);
    // HyperPay supports five methods but its tile shows three.
    for (final m in ['mada', 'Visa', 'Mastercard', 'Fawry']) {
      expect(find.text(m), findsWidgets, reason: m);
    }
    expect(find.text('STC Pay'), findsNothing);
    expect(find.text('valU'), findsNothing);
    // Nothing is selected: no rows, no credential fields.
    expect(key('payments-details-empty'), findsOneWidget);
    expect(key('field-hyperpay-accessToken'), findsNothing);
    expect(
      find.text(
        'Secret keys are stored on the server only and are never put inside the app file.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('region tags: flags for Egypt and Saudi, a globe for the Gulf', (
    tester,
  ) async {
    await openPayments(tester);
    // HyperPay: Saudi + Gulf. Paymob and PayFort: Egypt + Saudi + Gulf.
    Finder inTile(String id, String region) => find.descendant(
      of: key('gateway-tile-$id'),
      matching: key('region-$region'),
    );
    expect(inTile('hyperpay', 'sa'), findsOneWidget);
    expect(inTile('hyperpay', 'gulf'), findsOneWidget);
    expect(inTile('hyperpay', 'eg'), findsNothing);
    for (final id in ['paymob', 'payfort']) {
      for (final r in ['eg', 'sa', 'gulf']) {
        expect(inTile(id, r), findsOneWidget, reason: '$id $r');
      }
    }
    final flags = find.descendant(
      of: key('gateway-tile-paymob'),
      matching: find.byType(CountryFlags),
    );
    expect(flags, findsNWidgets(2)); // eg and sa; the Gulf has no flag
    expect(tester.getSize(flags.first), const Size(16, 12));
    expect(
      find.descendant(
        of: inTile('paymob', 'gulf'),
        matching: find.byIcon(Icons.public),
      ),
      findsOneWidget,
    );
    // Method chips stay below the region tags.
    expect(
      tester
          .getTopLeft(
            find.descendant(
              of: key('gateway-tile-paymob'),
              matching: find.text('Fawry'),
            ),
          )
          .dy,
      greaterThan(tester.getBottomLeft(inTile('paymob', 'eg')).dy),
    );
  });

  testWidgets('the Gulf tag lists its countries in a tooltip', (tester) async {
    await openPayments(tester);
    final gulf = find.descendant(
      of: key('gateway-tile-hyperpay'),
      matching: key('region-gulf'),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(gulf));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('UAE, Kuwait, Qatar, Bahrain, Oman'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('Arabic Gulf tooltip uses Arabic names and commas', (
    tester,
  ) async {
    await openPayments(tester, arabic: true);
    final gulf = find.descendant(
      of: key('gateway-tile-hyperpay'),
      matching: key('region-gulf'),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(gulf));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('الإمارات، الكويت، قطر، البحرين، عُمان'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('a missing logo file falls back to the initials badge', (
    tester,
  ) async {
    await openPayments(tester);
    // No logo files are bundled in tests: every tile shows its initials.
    for (final e in {
      'hyperpay': 'HP',
      'paymob': 'PM',
      'payfort': 'APS',
    }.entries) {
      expect(
        find.descendant(
          of: key('gateway-logo-${e.key}'),
          matching: find.text(e.value),
        ),
        findsOneWidget,
        reason: e.key,
      );
      // One consistent 48x48 size.
      expect(tester.getSize(key('gateway-logo-${e.key}')), const Size(48, 48));
    }
  });

  testWidgets('selecting tiles is multiple; a check badge marks them', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    await tapIn(tester, key('gateway-tile-paymob'));
    expect(key('gateway-check-hyperpay'), findsOneWidget);
    expect(key('gateway-check-paymob'), findsOneWidget);
    expect(payments(container).enabledIds, ['hyperpay', 'paymob']);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(key('gateway-check-hyperpay'), findsNothing);
    expect(key('payments-details-empty'), findsNothing);
  });

  testWidgets('rows follow the selection order, not the registry order', (
    tester,
  ) async {
    await openPayments(tester);
    await tapIn(tester, key('gateway-tile-payfort'));
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(
      tester.getTopLeft(key('gateway-row-payfort')).dy,
      lessThan(tester.getTopLeft(key('gateway-row-hyperpay')).dy),
    );
  });

  testWidgets('status pills, default open row and the accordion', (
    tester,
  ) async {
    final complete = const PaymentsDraft()
        .withEnabled('hyperpay', true)
        .withValue('hyperpay', PaymentEnv.test, 'accessToken', 'tok-1234567890')
        .withValue('hyperpay', PaymentEnv.test, 'entityIdCards', 'c')
        .withValue('hyperpay', PaymentEnv.test, 'entityIdMada', 'm')
        .withEnabled('paymob', true);
    final container = await openPayments(tester, payments: complete);
    expect(
      find.descendant(
        of: key('gateway-status-hyperpay'),
        matching: find.text('Complete'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('gateway-status-paymob'),
        matching: find.text('5 fields missing'),
      ),
      findsOneWidget,
    );
    // Only the first incomplete row is open.
    expect(key('field-hyperpay-accessToken'), findsNothing);
    expect(key('field-paymob-apiKey'), findsOneWidget);

    await tapIn(tester, key('gateway-row-header-hyperpay'));
    expect(key('field-hyperpay-accessToken'), findsOneWidget);
    await tapIn(tester, key('gateway-row-header-paymob'));
    expect(key('field-paymob-apiKey'), findsNothing);

    // The pill follows the current environment.
    await tapIn(
      tester,
      find.descendant(of: key('payments-env'), matching: find.text('Live')),
    );
    expect(
      find.descendant(
        of: key('gateway-status-hyperpay'),
        matching: find.text('3 fields missing'),
      ),
      findsOneWidget,
    );
    expect(payments(container).env, PaymentEnv.live);
  });

  testWidgets('enabling a gateway expands it; disabling keeps the values', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(key('field-hyperpay-accessToken'), findsOneWidget);
    expect(key('field-hyperpay-entityIdApplePay'), findsOneWidget);
    expect(key('gateway-test-hyperpay'), findsOneWidget);

    await typeIn(tester, 'field-hyperpay-entityIdCards', 'cards-entity');
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(key('field-hyperpay-entityIdCards'), findsNothing);
    expect(payments(container).isEnabled('hyperpay'), isFalse);

    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(
      tester
          .widget<TextField>(key('field-hyperpay-entityIdCards'))
          .controller!
          .text,
      'cards-entity',
    );
  });

  testWidgets('the first selected gateway is the default; the star moves it', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-paymob'));
    expect(payments(container).defaultGateway, 'paymob');
    expect(
      find.descendant(
        of: key('gateway-star-paymob'),
        matching: find.text('Default'),
      ),
      findsOneWidget,
    );

    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(
      find.descendant(
        of: key('gateway-star-hyperpay'),
        matching: find.text('Set as default'),
      ),
      findsOneWidget,
    );
    await tapIn(tester, key('gateway-star-hyperpay'));
    expect(payments(container).defaultGateway, 'hyperpay');
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Set as default'), findsOneWidget);

    // Unselecting the default hands it to the next selected gateway.
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(payments(container).defaultGateway, 'paymob');
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('test and live credentials are stored separately', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    await typeIn(tester, 'field-hyperpay-entityIdCards', 'test-entity');

    await tapIn(
      tester,
      find.descendant(of: key('payments-env'), matching: find.text('Live')),
    );
    expect(payments(container).env, PaymentEnv.live);
    expect(
      tester
          .widget<TextField>(key('field-hyperpay-entityIdCards'))
          .controller!
          .text,
      isEmpty,
    );
    await typeIn(tester, 'field-hyperpay-entityIdCards', 'live-entity');

    await tapIn(
      tester,
      find.descendant(of: key('payments-env'), matching: find.text('Test')),
    );
    expect(
      tester
          .widget<TextField>(key('field-hyperpay-entityIdCards'))
          .controller!
          .text,
      'test-entity',
    );
    final json = payments(container).toJson();
    final hp = (json['gateways'] as Map)['hyperpay'] as Map;
    expect((hp['test'] as Map)['entityIdCards'], 'test-entity');
    expect((hp['live'] as Map)['entityIdCards'], 'live-entity');
  });

  testWidgets('secret fields are password inputs with a show/hide toggle', (
    tester,
  ) async {
    await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    TextField field(String k) => tester.widget<TextField>(key(k));
    expect(field('field-hyperpay-accessToken').obscureText, isTrue);
    expect(field('field-hyperpay-entityIdCards').obscureText, isFalse);

    await tapIn(tester, key('secret-toggle-hyperpay-accessToken'));
    expect(field('field-hyperpay-accessToken').obscureText, isFalse);
    await tapIn(tester, key('secret-toggle-hyperpay-accessToken'));
    expect(field('field-hyperpay-accessToken').obscureText, isTrue);
    // Public fields have no toggle.
    expect(key('secret-toggle-hyperpay-entityIdCards'), findsNothing);
  });

  testWidgets('PayFort has an SHA type select defaulting to SHA-256', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-payfort'));
    expect(find.text('SHA-256'), findsOneWidget);
    await tapIn(tester, find.byType(DropdownButtonFormField<String>));
    await tapIn(tester, find.text('SHA-512').last);
    final pf =
        (payments(container).toJson()['gateways'] as Map)['payfort'] as Map;
    expect((pf['test'] as Map)['shaType'], 'SHA-512');
  });

  group('Next', () {
    testWidgets('with nothing enabled it is blocked with a message', (
      tester,
    ) async {
      final container = await openPayments(tester);
      expect(key('payments-none-enabled'), findsNothing);
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/payments');
      expect(key('payments-none-enabled'), findsOneWidget);
      expect(
        find.text('Enable at least one gateway or choose Configure later'),
        findsOneWidget,
      );
    });

    testWidgets('validates only enabled gateways and shows inline errors', (
      tester,
    ) async {
      final container = await openPayments(tester);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/payments');
      expect(find.text('This field is required'), findsNWidgets(3));
      // The first invalid field takes the focus.
      expect(
        tester
            .widget<TextField>(key('field-hyperpay-accessToken'))
            .focusNode!
            .hasFocus,
        isTrue,
      );

      await fillHyperpay(tester);
      expect(find.text('This field is required'), findsNothing);
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/summary');
    });

    testWidgets('only the current environment is validated', (tester) async {
      final container = await openPayments(tester);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await fillHyperpay(tester);
      // Live is empty, but test is the selected environment.
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/summary');

      container.read(routerProvider).go('/builder/payments');
      await tester.pumpAndSettle();
      await tapIn(
        tester,
        find.descendant(of: key('payments-env'), matching: find.text('Live')),
      );
      await tapIn(tester, key('wizard-next'));
      expect(currentPath(container), '/builder/payments');
    });

    testWidgets('an unselected gateway is not validated', (tester) async {
      final container = await openPayments(tester);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await tapIn(tester, key('gateway-tile-hyperpay')); // back off
      await tapIn(tester, key('wizard-next'));
      // Nothing selected and not postponed: blocked.
      expect(currentPath(container), '/builder/payments');
    });
  });

  testWidgets('"Configure later" sits in the bottom bar and skips the step', (
    tester,
  ) async {
    final container = await openPayments(tester);
    expect(key('payments-configure-later'), findsOneWidget);
    await tapIn(tester, key('payments-configure-later'));
    expect(currentPath(container), '/builder/summary');
    expect(payments(container).configureLater, isTrue);
    expect(find.text('Configure later'), findsWidgets); // in the review
  });

  testWidgets('"Configure later" unselects gateways but keeps their values', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    await typeIn(tester, 'field-hyperpay-entityIdCards', 'cards-entity');
    await tapIn(tester, key('payments-configure-later'));
    expect(currentPath(container), '/builder/summary');
    expect(payments(container).enabledIds, isEmpty);
    expect(payments(container).defaultGateway, isNull);

    container.read(routerProvider).go('/builder/payments');
    await tester.pumpAndSettle();
    await tapIn(tester, key('gateway-tile-hyperpay'));
    expect(payments(container).configureLater, isFalse);
    expect(
      tester
          .widget<TextField>(key('field-hyperpay-entityIdCards'))
          .controller!
          .text,
      'cards-entity',
    );
  });

  group('Test connection', () {
    testWidgets('missing required fields block the call and show errors', (
      tester,
    ) async {
      final fake = FakeGatewayTester();
      await openPayments(tester, gatewayTester: fake);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await tapIn(tester, key('gateway-test-hyperpay'));
      expect(fake.calls, isEmpty);
      expect(find.text('This field is required'), findsNWidgets(3));
    });

    testWidgets('shows a loading state, then a success check', (tester) async {
      final fake = FakeGatewayTester()..gate = Completer<void>();
      await openPayments(tester, gatewayTester: fake);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await fillHyperpay(tester);

      await tester.ensureVisible(key('gateway-test-hyperpay'));
      await tester.tap(key('gateway-test-hyperpay'));
      await tester.pump();
      expect(find.text('Testing...'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(key('gateway-test-hyperpay')).onPressed,
        isNull,
      );

      fake.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Connection successful'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // The call carried the current environment and the entered values.
      final (id, env, credentials) = fake.calls.single;
      expect(id, 'hyperpay');
      expect(env, PaymentEnv.test);
      expect(credentials['entityIdCards'], 'cards-entity');
      expect(credentials['accessToken'], 'tok-1234567890');
    });

    testWidgets('failures are shown in red and clear when values change', (
      tester,
    ) async {
      final fake = FakeGatewayTester(
        result: const GatewayTestResult(GatewayTestResult.invalidCredentials),
      );
      await openPayments(tester, gatewayTester: fake);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await fillHyperpay(tester);
      await tapIn(tester, key('gateway-test-hyperpay'));
      expect(
        find.text('The gateway rejected these credentials'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await typeIn(tester, 'field-hyperpay-entityIdMada', 'other');
      expect(key('gateway-test-result-hyperpay'), findsNothing);
    });

    testWidgets('a not implemented check is never shown as success', (
      tester,
    ) async {
      final fake = FakeGatewayTester(
        result: const GatewayTestResult(GatewayTestResult.notImplemented),
      );
      await openPayments(tester, gatewayTester: fake);
      await tapIn(tester, key('gateway-tile-paymob'));
      for (final k in [
        'apiKey',
        'secretKey',
        'publicKey',
        'cardIntegrationId',
        'hmacSecret',
      ]) {
        await typeIn(tester, 'field-paymob-$k', 'value-$k');
      }
      await tapIn(tester, key('gateway-test-paymob'));
      expect(
        find.text('Connection test is not available for this gateway yet'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('an unreachable service is reported', (tester) async {
      final fake = FakeGatewayTester(
        result: const GatewayTestResult(GatewayTestResult.unreachable),
      );
      await openPayments(tester, gatewayTester: fake);
      await tapIn(tester, key('gateway-tile-hyperpay'));
      await fillHyperpay(tester);
      await tapIn(tester, key('gateway-test-hyperpay'));
      expect(
        find.text('Could not reach the test service. Try again.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Arabic: title, subtitle, note and labels, RTL', (tester) async {
    await openPayments(tester, arabic: true);
    expect(find.text('طرق الدفع'), findsWidgets);
    expect(
      find.text(
        'فعّل بوابات الدفع اللي هتظهر في التطبيق، وحدّد البوابة الافتراضية.',
      ),
      findsOneWidget,
    );
    expect(find.text('أضبطها لاحقًا'), findsOneWidget);
    expect(
      find.text(
        'المفاتيح السرية بتتخزّن على السيرفر فقط ومش بتتحط جوّه ملف التطبيق.',
      ),
      findsOneWidget,
    );
    expect(find.text('الخطوة 5 من 6'), findsOneWidget);

    expect(find.text('السعودية'), findsWidgets);
    expect(find.text('الخليج'), findsWidgets);
    expect(find.text('مصر'), findsWidgets);
    expect(find.text('اختر بوابات الدفع'), findsOneWidget);
    expect(find.text('بيانات الربط'), findsOneWidget);
    expect(find.text('تجريبي'), findsOneWidget);

    await tapIn(tester, key('wizard-next'));
    expect(
      find.text('فعّل بوابة واحدة على الأقل أو اختار أضبطها لاحقًا'),
      findsOneWidget,
    );
    await tapIn(tester, key('gateway-tile-hyperpay'));
    // The check badge is on the left of the tile.
    final tile = tester.getRect(key('gateway-tile-hyperpay'));
    final badge = tester.getRect(key('gateway-check-hyperpay'));
    expect(badge.center.dx, lessThan(tile.center.dx));
    expect(find.text('افتراضية'), findsOneWidget);
    expect(find.text('ناقص 3 حقول'), findsOneWidget);
    expect(find.text('اختبار الاتصال'), findsOneWidget);
  });

  testWidgets('the summary lists the enabled gateways, never a secret', (
    tester,
  ) async {
    final container = await openPayments(tester);
    await tapIn(tester, key('gateway-tile-hyperpay'));
    await fillHyperpay(tester);
    await tapIn(tester, key('gateway-tile-paymob'));
    await tapIn(tester, key('gateway-star-paymob'));
    for (final k in [
      'apiKey',
      'secretKey',
      'publicKey',
      'cardIntegrationId',
      'hmacSecret',
    ]) {
      await typeIn(tester, 'field-paymob-$k', 'value-$k');
    }
    await tapIn(tester, key('wizard-next'));
    expect(currentPath(container), '/builder/summary');
    expect(find.text('HyperPay, Paymob (default)'), findsOneWidget);
    expect(find.textContaining('tok-1234567890'), findsNothing);
    final prepared = await container.read(preparedConfigProvider.future);
    expect(prepared!.isValid, isTrue, reason: prepared.schemaErrors.join('\n'));
    expect(prepared.config.toPrettyJson(), isNot(contains('tok-1234567890')));
    expect(prepared.config.toPrettyJson(), contains('mada-entity'));
  });
}

void narrowTests() {
  testWidgets('phone width: tiles stack, no overflow, footer buttons fit', (
    tester,
  ) async {
    await openPayments(tester);
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    await tapIn(tester, key('gateway-tile-hyperpay'));
    await tapIn(tester, key('gateway-tile-paymob'));
    expect(tester.takeException(), isNull);
    expect(key('payments-configure-later'), findsOneWidget);
    expect(key('wizard-next'), findsOneWidget);
  });
}
