import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment_ui/recruitment_ui.dart';

const _branding = BrandingConfig(
  primaryColor: Color(0xFF1565C0),
  secondaryColor: Color(0xFFFFB300),
  appNameAr: 'مكتب تجريبي',
  appNameEn: 'Demo Office',
);

DemoSession newSession({Set<ServiceModule>? modules}) => DemoSession(
  repository: MockDemoRepository(latency: Duration.zero),
  enabledModules: modules,
);

Future<void> pumpApp(
  WidgetTester tester,
  DemoSession session, {
  AppTemplate template = AppTemplate.simple,
  String lang = 'en',
  Brightness brightness = Brightness.light,
}) async {
  AppTemplate.useGoogleFonts = false;
  AppTemplate.skeletonDuration = Duration.zero;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: RecruitmentApp(
        session: session,
        template: template,
        branding: _branding,
        languageCode: lang,
        brightness: brightness,
      ),
    ),
  );
  await settle(tester);
}

/// Advances time enough for route transitions without waiting on endless
/// timers (the OTP countdown).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder k(String key) => find.byKey(ValueKey(key));

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = k(key);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: true);
  await settle(tester);
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final f = k(key);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> chooseNationality(WidgetTester tester, String name) async {
  await tapKey(tester, 'nationality-select');
  await tester.tap(find.textContaining(name).last);
  await settle(tester);
}

Future<void> fillContract(WidgetTester tester) async {
  await enter(tester, 'contract-name', 'Demo Customer');
  await enter(tester, 'contract-nid', '1012345678');
  await enter(tester, 'contract-email', 'demo@example.com');
  await tapKey(tester, 'contract-date');
  await tester.tap(find.text('OK'));
  await settle(tester);
  await tapKey(tester, 'contract-ack');
}

String routeName(DemoSession s) {
  String? name;
  s.navigator!.popUntil((r) {
    name = r.settings.name;
    return true;
  });
  return name ?? '';
}

void main() {
  _screenSweep();
  _templateBehaviorTests();
  testWidgets(
    'login validates the phone, OTP rejects a wrong code, then Home',
    (tester) async {
      final session = newSession();
      await pumpApp(tester, session);
      expect(k('demo-banner'), findsOneWidget);

      await enter(tester, 'phone-field', '123');
      await tapKey(tester, 'login-continue');
      expect(find.textContaining('9 digits'), findsOneWidget);
      expect(routeName(session), DemoRoutes.login);

      await enter(tester, 'phone-field', '500000000');
      await tapKey(tester, 'login-continue');
      expect(routeName(session), DemoRoutes.otp);

      // Verify is disabled until six digits are typed.
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: k('otp-verify'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(k('otp-countdown'), findsOneWidget);

      await enter(tester, 'otp-field', '000000');
      await tapKey(tester, 'otp-verify');
      expect(find.textContaining('Incorrect code'), findsOneWidget);
      expect(session.isAuthenticated, isFalse);

      await enter(tester, 'otp-field', session.repo.demoOtp);
      await tapKey(tester, 'otp-verify');
      expect(session.isAuthenticated, isTrue);
      expect(routeName(session), DemoRoutes.main);
      expect(k('banner-slider'), findsOneWidget);
    },
  );

  testWidgets('biometric login is simulated and reaches Home', (tester) async {
    final session = newSession();
    await pumpApp(tester, session);
    await tapKey(tester, 'login-biometric');
    await tapKey(tester, 'biometric-confirm');
    expect(session.isAuthenticated, isTrue);
    expect(routeName(session), DemoRoutes.main);
  });

  testWidgets('Home shows every required section and the contact demo works', (
    tester,
  ) async {
    final session = newSession()..jumpTo(DemoEntry.home);
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.home);
    await settle(tester);

    expect(k('banner-slider'), findsOneWidget);
    expect(k('featured-individuals'), findsOneWidget);
    expect(k('featured-hourly'), findsOneWidget);
    final scrollable = find
        .descendant(of: k('home-list'), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      k('category-mediation'),
      300,
      scrollable: scrollable,
    );
    expect(k('category-individuals'), findsOneWidget);
    expect(k('category-hourly'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Customer reviews'),
      300,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(
      find.text('Our partners'),
      300,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(
      k('contact-phone'),
      300,
      scrollable: scrollable,
    );
    await tapKey(tester, 'contact-phone');
    expect(find.text('Demo call'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
  });

  testWidgets('slider swipes and a banner opens its flow', (tester) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.home);
    await settle(tester);

    expect(find.text('Recruit with confidence'), findsOneWidget);
    await tester.drag(k('banner-slider'), const Offset(-300, 0));
    await settle(tester);
    expect(find.text('Hourly cleaning'), findsOneWidget);
    await tapKey(tester, 'banner-1');
    expect(routeName(session), DemoRoutes.address);
  });

  testWidgets('bottom navigation switches sections and orders start empty', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.home);
    await settle(tester);
    await tester.tap(find.text('Orders').last);
    await settle(tester);
    expect(k('orders-empty'), findsOneWidget);
    await tester.tap(find.text('Account').last);
    await settle(tester);
    expect(k('account-reset'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(k('banner-slider'), findsOneWidget);
  });

  testWidgets('Individuals: complete flow with persistence and validation', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.home);
    await settle(tester);

    await tapKey(tester, 'category-individuals');
    expect(routeName(session), DemoRoutes.address);

    // No address selected -> blocked with feedback.
    await tapKey(tester, 'address-continue');
    expect(find.text('Select an address to continue'), findsOneWidget);

    // Add a new address through the bottom sheet (validated).
    await tapKey(tester, 'address-add');
    await tapKey(tester, 'addr-save');
    expect(find.text('This field is required'), findsWidgets);
    await enter(tester, 'addr-label', 'Office');
    await tapKey(tester, 'addr-city');
    await tester.tap(find.text('Dammam').last);
    await settle(tester);
    await enter(tester, 'addr-district', 'Al Faisaliyah');
    await enter(tester, 'addr-street', 'King Rd');
    await enter(tester, 'addr-building', '5');
    await tapKey(tester, 'addr-save');
    expect(session.addresses.length, 3);
    expect(session.selectedAddress!.label.en, 'Office');

    await tapKey(tester, 'address-a1');
    await tapKey(tester, 'address-continue');
    expect(routeName(session), DemoRoutes.indPackages);

    // Required selections.
    await tapKey(tester, 'ind-packages-continue');
    expect(find.text('Select a nationality'), findsOneWidget);
    await chooseNationality(tester, 'Philippines');
    await tapKey(tester, 'ind-package-standard');
    expect(session.indPackageId, 'standard');
    await tapKey(tester, 'ind-packages-continue');
    expect(routeName(session), DemoRoutes.workers);

    // Select a worker, open details, come back: selection is preserved.
    await tapKey(tester, 'worker-select-w_ph_housemaid_0');
    expect(session.indWorkerId, 'w_ph_housemaid_0');
    await tapKey(tester, 'worker-details-w_ph_housemaid_0');
    expect(routeName(session), DemoRoutes.worker);
    await tester.tap(find.text('Skills'));
    await settle(tester);
    expect(find.text('House cleaning'), findsOneWidget);
    await tester.tap(k('header-back'));
    await settle(tester);
    expect(routeName(session), DemoRoutes.workers);
    expect(session.indWorkerId, 'w_ph_housemaid_0');
    expect(session.indNationalityId, 'ph');

    await tapKey(tester, 'workers-continue');
    await tapKey(tester, 'worker-confirm');
    expect(routeName(session), DemoRoutes.contract);

    // Contract validation.
    await tapKey(tester, 'contract-continue');
    expect(find.textContaining('10 digits'), findsOneWidget);
    await fillContract(tester);
    await tapKey(tester, 'contract-continue');
    expect(routeName(session), DemoRoutes.payment);

    // Wallet balance rule: large amounts fail, no order is created.
    await tapKey(tester, 'method-wallet');
    await tapKey(tester, 'pay-button');
    await tapKey(tester, 'pay-confirm');
    expect(routeName(session), DemoRoutes.payment);
    expect(find.textContaining('Insufficient wallet balance'), findsOneWidget);
    expect(session.orders, isEmpty);

    // Card succeeds.
    await tapKey(tester, 'method-card');
    await tapKey(tester, 'pay-button');
    await tapKey(tester, 'pay-confirm');
    expect(routeName(session), DemoRoutes.success);
    expect(find.textContaining('DEMO-IND-'), findsOneWidget);
    expect(session.orders.length, 1);

    await tapKey(tester, 'success-home');
    expect(routeName(session), DemoRoutes.main);
    expect(session.indPackageId, isNull, reason: 'flow resets after success');
    await tester.tap(find.text('Orders').last);
    await settle(tester);
    expect(find.textContaining('DEMO-IND-'), findsOneWidget);
  });

  testWidgets('changing nationality drops a worker that no longer matches', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.setIndNationality('ph');
    session.setIndPackage('standard');
    session.selectIndWorker('w_ph_housemaid_0');
    session.setIndNationality('in');
    expect(session.indWorkerId, isNull);
    expect(
      session.individualsWorkers().every((w) => w.nationalityId == 'in'),
      isTrue,
    );
  });

  testWidgets('Hourly: fixed package, discount codes, payment and success', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.hourly);
    await settle(tester);

    await tapKey(tester, 'address-a2');
    await tapKey(tester, 'address-continue');
    expect(routeName(session), DemoRoutes.hrPackages);

    await tapKey(tester, 'hr-packages-continue');
    expect(find.text('Select a package to continue'), findsOneWidget);
    await tapKey(tester, 'hr-package-h_family');
    await tapKey(tester, 'hr-packages-continue');
    expect(routeName(session), DemoRoutes.hrDetails);

    // Missing schedule -> validation feedback.
    await tapKey(tester, 'hr-details-continue');
    expect(find.text('Select a start date'), findsOneWidget);
    expect(find.text('Select exactly 2 days'), findsOneWidget);

    // Friday is unavailable.
    await tapKey(tester, 'day-5');
    expect(session.hourlyDays, isEmpty);
    await tapKey(tester, 'day-1');
    await tapKey(tester, 'day-3');
    await tapKey(tester, 'day-4'); // exceeds the 2 allowed
    expect(session.hourlyDays, {1, 3});

    await tapKey(tester, 'hr-start-date');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(session.hourlyStartDate, isNotNull);

    final base = session.summary(ServiceModule.hourly).total;
    await enter(tester, 'discount-field', 'nope');
    await tapKey(tester, 'discount-apply');
    expect(find.text('Invalid discount code'), findsOneWidget);
    await enter(tester, 'discount-field', 'EXPIRED20');
    await tapKey(tester, 'discount-apply');
    expect(find.text('This code has expired'), findsOneWidget);
    expect(session.summary(ServiceModule.hourly).total, base);
    await enter(tester, 'discount-field', 'demo10');
    await tapKey(tester, 'discount-apply');
    expect(find.textContaining('DEMO10 applied'), findsOneWidget);
    expect(session.summary(ServiceModule.hourly).total, lessThan(base));

    await tapKey(tester, 'hr-details-continue');
    expect(routeName(session), DemoRoutes.payment);
    expect(find.textContaining('Discount (DEMO10)'), findsOneWidget);
    await tapKey(tester, 'pay-button');
    await tapKey(tester, 'pay-confirm');
    expect(routeName(session), DemoRoutes.success);
    expect(find.textContaining('DEMO-HRS-'), findsOneWidget);
    expect(find.text('Demo booking confirmed'), findsOneWidget);
  });

  testWidgets('Hourly: custom package updates the estimate and can be booked', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.hourly);
    await settle(tester);
    await tapKey(tester, 'address-a1');
    await tapKey(tester, 'address-continue');

    await tester.tap(find.text('Design your own'));
    await settle(tester);
    expect(session.hourlyCustom, isTrue);
    final before = session.hourlySubtotal;
    await tapKey(tester, 'custom-hours-plus');
    expect(session.customHourly.hoursPerVisit, 5);
    expect(session.hourlySubtotal, greaterThan(before));
    expect(
      session.hourlySubtotal,
      PricingRules.hourlyPrice(hoursPerVisit: 5, visitsPerWeek: 2, weeks: 4),
    );

    await tapKey(tester, 'hr-packages-continue');
    expect(routeName(session), DemoRoutes.hrDetails);
    expect(find.text('Custom package'), findsWidgets);
  });

  testWidgets('Mediation: browse path, failed then successful payment', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.mediation);
    await settle(tester);
    expect(routeName(session), DemoRoutes.medCriteria);

    await tapKey(tester, 'med-criteria-continue');
    expect(find.text('Select a profession'), findsOneWidget);
    await tapKey(tester, 'profession-cook');
    await chooseNationality(tester, 'India');
    await tapKey(tester, 'med-criteria-continue');

    await tapKey(tester, 'med-packages-continue');
    expect(find.text('Select a package to continue'), findsOneWidget);
    await tapKey(tester, 'med-package-m_plus');
    await tapKey(tester, 'med-packages-continue');
    expect(routeName(session), DemoRoutes.medMethod);

    await tapKey(tester, 'method-browse');
    expect(routeName(session), DemoRoutes.workers);
    expect(find.text('3 workers available'), findsOneWidget);
    await tapKey(tester, 'worker-select-w_in_cook_1');
    await tapKey(tester, 'workers-continue');
    await tapKey(tester, 'worker-confirm');
    expect(routeName(session), DemoRoutes.contract);

    await fillContract(tester);
    await tapKey(tester, 'contract-continue');

    // Simulated failure keeps the user on payment and creates no order.
    await tapKey(tester, 'simulate-failure');
    await tapKey(tester, 'pay-button');
    await tapKey(tester, 'pay-confirm');
    expect(routeName(session), DemoRoutes.payment);
    expect(find.textContaining('Payment failed'), findsOneWidget);
    expect(session.orders, isEmpty);

    await tapKey(tester, 'simulate-failure');
    await tapKey(tester, 'pay-button');
    await tapKey(tester, 'pay-confirm');
    expect(routeName(session), DemoRoutes.success);
    expect(session.orders.single.reference, startsWith('DEMO-MED-'));
  });

  testWidgets('Mediation: search by name, empty result, same downstream flow', (
    tester,
  ) async {
    final session = newSession();
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.mediation);
    await settle(tester);
    await tapKey(tester, 'profession-housemaid');
    await chooseNationality(tester, 'Philippines');
    await tapKey(tester, 'med-criteria-continue');
    await tapKey(tester, 'med-package-m_basic');
    await tapKey(tester, 'med-packages-continue');
    await tapKey(tester, 'method-search');

    await enter(tester, 'worker-search', 'zzzz');
    await settle(tester);
    expect(find.textContaining('No results'), findsOneWidget);

    final target = session.mediationWorkers().first;
    await enter(tester, 'worker-search', target.name.en.split(' ').first);
    await settle(tester);
    await tapKey(tester, 'worker-select-${target.id}');
    await tapKey(tester, 'search-continue');
    expect(routeName(session), DemoRoutes.worker);
    await tester.tap(k('header-back'));
    await settle(tester);
    expect(session.medQuery, isNotEmpty, reason: 'query survives going back');
    expect(session.medWorkerId, target.id);

    await tapKey(tester, 'search-continue');
    await tapKey(tester, 'worker-confirm');
    expect(routeName(session), DemoRoutes.contract);
  });

  testWidgets('disabling a module hides it; reset restores the initial state', (
    tester,
  ) async {
    final session = newSession(modules: {ServiceModule.individuals});
    await pumpApp(tester, session);
    session.jumpTo(DemoEntry.home);
    await settle(tester);
    expect(k('category-individuals'), findsOneWidget);
    expect(k('category-hourly'), findsNothing);
    expect(k('category-mediation'), findsNothing);
    expect(k('featured-hourly'), findsNothing);

    session.setIndNationality('ph');
    session.setEnabledModules(ServiceModule.values.toSet());
    session.reset();
    await settle(tester);
    expect(routeName(session), DemoRoutes.login);
    expect(session.isAuthenticated, isFalse);
    expect(session.indNationalityId, isNull);
  });

  for (final template in AppTemplate.all) {
    testWidgets('${template.id}: same business flow, no layout errors', (
      tester,
    ) async {
      final session = newSession();
      await pumpApp(tester, session, template: template, lang: 'ar');
      for (final lang in ['ar', 'en']) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('en'), Locale('ar')],
              home: RecruitmentApp(
                session: session,
                template: template,
                branding: _branding,
                languageCode: lang,
                brightness: brightness,
              ),
            ),
          );
          for (final entry in [
            DemoEntry.login,
            DemoEntry.home,
            DemoEntry.individuals,
            DemoEntry.hourly,
            DemoEntry.mediation,
          ]) {
            session.jumpTo(entry);
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${template.id}/$lang/$brightness/$entry',
            );
          }
        }
      }
    });
  }
}

/// Opens every screen of every flow directly (state pre-filled) so layout
/// problems in any template/language/theme are caught, not only the happy path.
void _screenSweep() {
  for (final template in AppTemplate.all) {
    testWidgets(
      '${template.id}: every screen renders in ar/en and light/dark',
      (tester) async {
        final session = newSession()..signInDemo();
        session
          ..selectAddress('a1')
          ..setIndNationality('ph')
          ..setIndPackage('standard')
          ..selectIndWorker('w_ph_housemaid_0')
          ..viewWorker('w_ph_housemaid_0')
          ..selectHourlyPackage('h_family')
          ..setHourlyStart(DateTime.now().add(const Duration(days: 3)))
          ..toggleHourlyDay(1)
          ..toggleHourlyDay(3)
          ..applyDiscount('DEMO10')
          ..setMedCriteria(professionId: 'cook', nationalityId: 'in')
          ..setMedPackage('m_plus')
          ..selectMedWorker('w_in_cook_0');

        final routes = <(String, ServiceModule?)>[
          (DemoRoutes.login, null),
          (DemoRoutes.otp, null),
          (DemoRoutes.main, null),
          (DemoRoutes.address, ServiceModule.individuals),
          (DemoRoutes.indPackages, null),
          (DemoRoutes.workers, ServiceModule.individuals),
          (DemoRoutes.worker, ServiceModule.individuals),
          (DemoRoutes.contract, ServiceModule.individuals),
          (DemoRoutes.payment, ServiceModule.individuals),
          (DemoRoutes.hrPackages, null),
          (DemoRoutes.hrDetails, null),
          (DemoRoutes.payment, ServiceModule.hourly),
          (DemoRoutes.medCriteria, null),
          (DemoRoutes.medPackages, null),
          (DemoRoutes.medMethod, null),
          (DemoRoutes.workers, ServiceModule.mediation),
          (DemoRoutes.medSearch, null),
          (DemoRoutes.worker, ServiceModule.mediation),
          (DemoRoutes.contract, ServiceModule.mediation),
          (DemoRoutes.payment, ServiceModule.mediation),
        ];

        for (final lang in ['ar', 'en']) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(
              MaterialApp(
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                supportedLocales: const [Locale('en'), Locale('ar')],
                home: RecruitmentApp(
                  session: session,
                  template: template,
                  branding: _branding,
                  languageCode: lang,
                  brightness: brightness,
                ),
              ),
            );
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            await settle(tester);
            for (final r in routes) {
              session.navigator!.pushNamed(r.$1, arguments: r.$2);
              await settle(tester);
              expect(
                tester.takeException(),
                isNull,
                reason: '${template.id}/$lang/$brightness/${r.$1}/${r.$2}',
              );
            }
            // Success needs a real order.
            final paying = session.pay(ServiceModule.individuals);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 10));
            await paying;
            session.navigator!.pushNamed(
              DemoRoutes.success,
              arguments: ServiceModule.individuals,
            );
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${template.id}/$lang/$brightness/success',
            );
          }
        }
        addTearDown(tester.view.reset);
      },
    );
  }
}

void _templateBehaviorTests() {
  testWidgets('premium shows a quick-order button; the others do not', (
    tester,
  ) async {
    for (final template in AppTemplate.all) {
      final session = newSession()..signInDemo();
      await pumpApp(tester, session, template: template, lang: 'en');
      expect(
        k('quick-order'),
        template.id == 'premium' ? findsOneWidget : findsNothing,
        reason: template.id,
      );
    }
  });

  testWidgets('premium shows skeleton placeholders before Home content', (
    tester,
  ) async {
    final session = newSession()..signInDemo();
    await pumpApp(tester, session, template: AppTemplate.premium);
    // pumpApp disables the delay; re-pump with it enabled.
    AppTemplate.skeletonDuration = const Duration(milliseconds: 300);
    addTearDown(() => AppTemplate.skeletonDuration = Duration.zero);
    await tester.pumpWidget(const SizedBox());
    final fresh = newSession()..signInDemo();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: RecruitmentApp(
          session: fresh,
          template: AppTemplate.premium,
          branding: _branding,
          languageCode: 'en',
        ),
      ),
    );
    await tester.pump();
    expect(k('home-skeleton'), findsOneWidget);
    expect(k('home-list'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(k('home-skeleton'), findsNothing);
    expect(k('home-list'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('unknown template ids fall back to Simple', () {
    expect(AppTemplate.byId('premium').id, 'premium');
    expect(AppTemplate.byId('unknown').id, 'simple');
  });
}
