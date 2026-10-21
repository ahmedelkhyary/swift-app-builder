import 'package:flutter/material.dart';

import '../app_template.dart';
import '../branding_config.dart';
import '../demo/models.dart';
import '../demo/session.dart';
import 'address_screen.dart';
import 'auth_screens.dart';
import 'contract_screen.dart';
import 'hourly_screens.dart';
import 'individuals_screens.dart';
import 'main_shell.dart';
import 'mediation_screens.dart';
import 'payment_screens.dart';
import 'scope.dart';
import 'worker_screens.dart';

/// The interactive, fully mocked prototype of a generated app.
///
/// All business behaviour lives in [DemoSession] and is shared by every
/// template; [template] only changes how screens look and transition.
/// Nothing here performs a network call, SMS, biometric or payment.
class RecruitmentApp extends StatefulWidget {
  const RecruitmentApp({
    super.key,
    required this.session,
    required this.template,
    required this.branding,
    required this.languageCode,
    this.brightness = Brightness.light,
    this.showDemoBanner = true,
    this.initialRoute,
    this.topInset = 0,
  });

  final DemoSession session;
  final AppTemplate template;
  final BrandingConfig branding;
  final String languageCode;
  final Brightness brightness;
  final bool showDemoBanner;

  /// Defaults to login, or Home when the session is already signed in.
  final String? initialRoute;

  /// Space reserved at the top of every screen (e.g. for a device cutout).
  final double topInset;

  @override
  State<RecruitmentApp> createState() => _RecruitmentAppState();
}

class _RecruitmentAppState extends State<RecruitmentApp> {
  final _navKey = GlobalKey<NavigatorState>();
  late final _SessionObserver _observer = _SessionObserver(widget.session);

  @override
  void initState() {
    super.initState();
    widget.session.attachNavigator(_navKey);
  }

  @override
  void didUpdateWidget(RecruitmentApp old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.detachNavigator(_navKey);
      widget.session.attachNavigator(_navKey);
    }
  }

  @override
  void dispose() {
    widget.session.detachNavigator(_navKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final session = w.session;
    final template = w.template;
    final branding = w.branding;
    final languageCode = w.languageCode;
    final isAr = languageCode == 'ar';
    final theme = template.buildTheme(
      branding,
      w.brightness,
      languageCode: languageCode,
    );
    final start =
        w.initialRoute ??
        (session.isAuthenticated ? DemoRoutes.main : DemoRoutes.login);
    return Theme(
      data: theme,
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: ScaffoldMessenger(
          child: DemoScope(
            session: session,
            template: template,
            branding: branding,
            languageCode: languageCode,
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
                  if (w.showDemoBanner) _DemoBanner(isAr: isAr),
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(padding: EdgeInsets.only(top: w.topInset)),
                      child: Navigator(
                        key: _navKey,
                        observers: [_observer],
                        initialRoute: start,
                        onGenerateRoute: _route,
                      ),
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

  Route<dynamic> _route(RouteSettings settings) {
    final module = settings.arguments is ServiceModule
        ? settings.arguments as ServiceModule
        : ServiceModule.individuals;
    final Widget page = switch (settings.name) {
      DemoRoutes.login => const LoginScreen(),
      DemoRoutes.otp => const OtpScreen(),
      DemoRoutes.main => const MainShell(),
      DemoRoutes.address => AddressScreen(module: module),
      DemoRoutes.indPackages => const IndividualsPackagesScreen(),
      DemoRoutes.workers => WorkersScreen(module: module),
      DemoRoutes.worker => WorkerDetailsScreen(module: module),
      DemoRoutes.contract => ContractScreen(module: module),
      DemoRoutes.payment => PaymentScreen(module: module),
      DemoRoutes.success => SuccessScreen(module: module),
      DemoRoutes.hrPackages => const HourlyPackagesScreen(),
      DemoRoutes.hrDetails => const HourlyDetailsScreen(),
      DemoRoutes.medCriteria => const MediationCriteriaScreen(),
      DemoRoutes.medPackages => const MediationPackagesScreen(),
      DemoRoutes.medMethod => const WorkerMethodScreen(),
      DemoRoutes.medSearch => const WorkerSearchScreen(),
      _ => const LoginScreen(),
    };
    return _TemplateRoute(
      settings: settings,
      transition: widget.template.transition,
      builder: (_) => page,
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('demo-banner'),
      width: double.infinity,
      height: 26,
      color: const Color(0xFF263238),
      alignment: Alignment.center,
      child: Text(
        isAr
            ? 'عرض تجريبي — بيانات وهمية، لا مدفوعات حقيقية'
            : 'DEMO PREVIEW — mock data, no real payments',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Page route whose transition is chosen by the template.
class _TemplateRoute extends PageRoute<void> {
  _TemplateRoute({
    required RouteSettings settings,
    required this.transition,
    required this.builder,
  }) : super(settings: settings);

  final PageTransitionKind transition;
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => Duration(
    milliseconds: switch (transition) {
      PageTransitionKind.fade => 180,
      PageTransitionKind.rise => 360,
      PageTransitionKind.scale => 320,
    },
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    switch (transition) {
      case PageTransitionKind.fade:
        return FadeTransition(opacity: curved, child: child);
      case PageTransitionKind.rise:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      case PageTransitionKind.scale:
        return ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
    }
  }
}

/// Tells the session which screen is on top (for the builder's nav pills).
// Routes removed below the top (pushNamedAndRemoveUntil) never change which
// screen is visible, so didRemove is intentionally not reported.
class _SessionObserver extends NavigatorObserver {
  _SessionObserver(this.session);
  final DemoSession session;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      session.reportRoute(route.settings);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      session.reportRoute(previousRoute?.settings);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      session.reportRoute(newRoute?.settings);
}
