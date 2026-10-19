import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';

/// Named routes of the interactive prototype.
class DemoRoutes {
  const DemoRoutes._();

  static const login = '/login';
  static const otp = '/otp';
  static const main = '/main';
  static const address = '/address'; // arg: ServiceModule
  static const indPackages = '/ind/packages';
  static const workers = '/workers'; // arg: ServiceModule
  static const worker = '/worker'; // arg: ServiceModule
  static const contract = '/contract'; // arg: ServiceModule
  static const payment = '/payment'; // arg: ServiceModule
  static const success = '/success'; // arg: ServiceModule
  static const hrPackages = '/hr/packages';
  static const hrDetails = '/hr/details';
  static const medCriteria = '/med/criteria';
  static const medPackages = '/med/packages';
  static const medMethod = '/med/method';
  static const medSearch = '/med/search';
}

/// Places the builder's preview can jump to without completing earlier flows.
enum DemoEntry { login, home, individuals, hourly, mediation }

class PhoneRules {
  const PhoneRules._();

  static const dialCodes = ['+966', '+971', '+965', '+973', '+968', '+974'];

  /// Returns null when valid. `+966` numbers must be 9 digits starting with 5.
  static String? validate(String dial, String number) {
    final n = number.trim();
    if (n.isEmpty) return 'required';
    if (!RegExp(r'^[0-9]+$').hasMatch(n)) return 'digits';
    if (dial == '+966') {
      return RegExp(r'^5[0-9]{8}$').hasMatch(n) ? null : 'invalid';
    }
    return n.length >= 8 && n.length <= 10 ? null : 'invalid';
  }
}

class ContractRules {
  const ContractRules._();

  static bool validNationalId(String v) =>
      RegExp(r'^[12][0-9]{9}$').hasMatch(v.trim());
  static bool validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v.trim());
  static bool validPhone(String v) =>
      RegExp(r'^\+?[0-9]{8,14}$').hasMatch(v.trim());

  static bool isComplete(ContractData c) =>
      c.fullName.trim().length >= 3 &&
      validNationalId(c.nationalId) &&
      validEmail(c.email) &&
      validPhone(c.phone) &&
      c.startDate != null &&
      c.acknowledged;
}

/// All state of one preview session. Survives navigation, template switches
/// and language changes; [reset] returns it to its initial state.
class DemoSession extends ChangeNotifier {
  DemoSession({DemoRepository? repository, Set<ServiceModule>? enabledModules})
    : repo = repository ?? MockDemoRepository(),
      enabledModules = enabledModules ?? ServiceModule.values.toSet() {
    _initState();
  }

  final DemoRepository repo;

  GlobalKey<NavigatorState>? _navKey;

  /// The navigator of the mounted prototype, if any. Several [RecruitmentApp]
  /// widgets can briefly coexist (e.g. during a page transition); the most
  /// recently mounted one is the active one.
  NavigatorState? get navigator => _navKey?.currentState;

  void attachNavigator(GlobalKey<NavigatorState> key) => _navKey = key;

  void detachNavigator(GlobalKey<NavigatorState> key) {
    if (_navKey == key) _navKey = null;
  }

  Set<ServiceModule> enabledModules;

  // ---- where the customer currently is -----------------------------------
  RouteSettings? _topRoute;
  bool _disposed = false;

  /// Reported by the prototype's navigator observer.
  void reportRoute(RouteSettings? settings) {
    _topRoute = settings;
    // Navigator callbacks can fire during build; notify afterwards.
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  /// The entry point (Login, Home or a service flow) the visible screen
  /// belongs to, or null before the first route exists.
  DemoEntry? get currentEntry {
    final r = _topRoute;
    if (r == null) return null;
    final module = r.arguments is ServiceModule
        ? r.arguments as ServiceModule
        : ServiceModule.individuals;
    DemoEntry byModule() => switch (module) {
      ServiceModule.individuals => DemoEntry.individuals,
      ServiceModule.hourly => DemoEntry.hourly,
      ServiceModule.mediation => DemoEntry.mediation,
    };
    return switch (r.name) {
      DemoRoutes.login || DemoRoutes.otp => DemoEntry.login,
      DemoRoutes.main => DemoEntry.home,
      DemoRoutes.indPackages => DemoEntry.individuals,
      DemoRoutes.hrPackages || DemoRoutes.hrDetails => DemoEntry.hourly,
      DemoRoutes.medCriteria ||
      DemoRoutes.medPackages ||
      DemoRoutes.medMethod ||
      DemoRoutes.medSearch => DemoEntry.mediation,
      DemoRoutes.address ||
      DemoRoutes.workers ||
      DemoRoutes.worker ||
      DemoRoutes.contract ||
      DemoRoutes.payment ||
      DemoRoutes.success => byModule(),
      _ => null,
    };
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---- auth ---------------------------------------------------------------
  String dialCode = '+966';
  String phone = '';
  bool isAuthenticated = false;

  // ---- main shell ---------------------------------------------------------
  int mainTab = 0;

  // ---- addresses (shared by individuals + hourly) -------------------------
  late List<DemoAddress> addresses;
  String? selectedAddressId;

  // ---- individuals --------------------------------------------------------
  String? indNationalityId;
  String? indPackageId;
  String? indWorkerId;
  String? indProfessionFilter;
  ContractData indContract = const ContractData();

  // ---- hourly -------------------------------------------------------------
  bool hourlyCustom = false;
  String? hourlyPackageId;
  CustomHourly customHourly = const CustomHourly();
  DateTime? hourlyStartDate;
  Set<int> hourlyDays = {};
  String appliedDiscountCode = '';

  // ---- mediation ----------------------------------------------------------
  String? medProfessionId;
  String? medNationalityId;
  String? medPackageId;
  String? medWorkerId;
  String medQuery = '';
  ContractData medContract = const ContractData();

  // ---- shared -------------------------------------------------------------
  String? viewWorkerId;
  String paymentMethodId = 'card';
  bool simulateFailure = false;
  List<DemoOrder> orders = [];
  DemoOrder? lastOrder;

  void _initState() {
    dialCode = '+966';
    phone = '';
    isAuthenticated = false;
    mainTab = 0;
    addresses = List.of(repo.initialAddresses);
    selectedAddressId = null;
    indNationalityId = null;
    indPackageId = null;
    indWorkerId = null;
    indProfessionFilter = null;
    indContract = const ContractData();
    hourlyCustom = false;
    hourlyPackageId = null;
    customHourly = const CustomHourly();
    hourlyStartDate = null;
    hourlyDays = {};
    appliedDiscountCode = '';
    medProfessionId = null;
    medNationalityId = null;
    medPackageId = null;
    medWorkerId = null;
    medQuery = '';
    medContract = const ContractData();
    viewWorkerId = null;
    paymentMethodId = 'card';
    simulateFailure = false;
    orders = [];
    lastOrder = null;
  }

  /// Returns the demo to its initial state and shows the login screen.
  void reset() {
    _initState();
    notifyListeners();
    navigator?.pushNamedAndRemoveUntil(DemoRoutes.login, (_) => false);
  }

  void setEnabledModules(Set<ServiceModule> modules) {
    if (modules.length == enabledModules.length &&
        modules.containsAll(enabledModules)) {
      return;
    }
    enabledModules = Set.of(modules);
    notifyListeners();
  }

  // ---- auth ---------------------------------------------------------------

  void setPhone(String dial, String number) {
    dialCode = dial;
    phone = number;
    notifyListeners();
  }

  Future<bool> sendOtp() => repo.sendOtp(dialCode, phone);

  Future<bool> verifyOtp(String code) async {
    final ok = await repo.verifyOtp(phone, code);
    if (ok) _signIn();
    return ok;
  }

  Future<bool> biometricLogin() async {
    final ok = await repo.biometricLogin();
    if (ok) _signIn();
    return ok;
  }

  /// Marks the demo customer as signed in (used by previews that skip login).
  void signInDemo() => _signIn();

  void _signIn() {
    isAuthenticated = true;
    if (phone.isEmpty) phone = '500000000';
    indContract = indContract.copyWith(phone: '$dialCode$phone');
    medContract = medContract.copyWith(phone: '$dialCode$phone');
    notifyListeners();
  }

  void logout() {
    isAuthenticated = false;
    notifyListeners();
    navigator?.pushNamedAndRemoveUntil(DemoRoutes.login, (_) => false);
  }

  void setMainTab(int i) {
    mainTab = i;
    notifyListeners();
  }

  // ---- navigation helpers -------------------------------------------------

  static String entryRoute(ServiceModule m) => switch (m) {
    ServiceModule.individuals => DemoRoutes.address,
    ServiceModule.hourly => DemoRoutes.address,
    ServiceModule.mediation => DemoRoutes.medCriteria,
  };

  /// Opens a service flow from Home.
  void openModule(ServiceModule m) {
    navigator?.pushNamed(entryRoute(m), arguments: m);
  }

  /// Jumps straight to an entry point (used by the builder's preview chips).
  /// Signs in with the demo account when needed so no flow has to be
  /// completed first.
  void jumpTo(DemoEntry entry) {
    final nav = navigator;
    if (nav == null) return;
    if (entry == DemoEntry.login) {
      isAuthenticated = false;
      notifyListeners();
      nav.pushNamedAndRemoveUntil(DemoRoutes.login, (_) => false);
      return;
    }
    if (!isAuthenticated) _signIn();
    mainTab = 0;
    nav.pushNamedAndRemoveUntil(DemoRoutes.main, (_) => false);
    switch (entry) {
      case DemoEntry.individuals:
        openModule(ServiceModule.individuals);
      case DemoEntry.hourly:
        openModule(ServiceModule.hourly);
      case DemoEntry.mediation:
        openModule(ServiceModule.mediation);
      case DemoEntry.login:
      case DemoEntry.home:
        break;
    }
  }

  // ---- addresses ----------------------------------------------------------

  DemoAddress? get selectedAddress {
    for (final a in addresses) {
      if (a.id == selectedAddressId) return a;
    }
    return null;
  }

  void selectAddress(String id) {
    selectedAddressId = id;
    notifyListeners();
  }

  /// Saves a new address locally and selects it.
  void addAddress(DemoAddress a) {
    addresses = [...addresses, a];
    selectedAddressId = a.id;
    notifyListeners();
  }

  // ---- individuals --------------------------------------------------------

  RecruitPackage? get indPackage =>
      _pkg(repo.individualsPackages, indPackageId);

  void setIndNationality(String? id) {
    if (id == indNationalityId) return;
    indNationalityId = id;
    _dropIndWorkerIfInvalid();
    notifyListeners();
  }

  void setIndPackage(String? id) {
    if (id == indPackageId) return;
    indPackageId = id;
    _dropIndWorkerIfInvalid();
    notifyListeners();
  }

  void setIndProfessionFilter(String? id) {
    indProfessionFilter = id;
    notifyListeners();
  }

  void _dropIndWorkerIfInvalid() {
    if (indWorkerId != null &&
        !individualsWorkers(
          ignoreProfession: true,
        ).any((w) => w.id == indWorkerId)) {
      indWorkerId = null;
    }
  }

  List<DemoWorker> individualsWorkers({bool ignoreProfession = false}) {
    return repo.workers.where((w) {
      if (w.nationalityId != indNationalityId) return false;
      if (indPackageId != null && !w.packageIds.contains(indPackageId)) {
        return false;
      }
      if (!ignoreProfession &&
          indProfessionFilter != null &&
          w.professionId != indProfessionFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  void selectIndWorker(String id) {
    indWorkerId = id;
    notifyListeners();
  }

  // ---- mediation ----------------------------------------------------------

  RecruitPackage? get medPackage => _pkg(repo.mediationPackages, medPackageId);

  void setMedCriteria({String? professionId, String? nationalityId}) {
    if (professionId != null) medProfessionId = professionId;
    if (nationalityId != null) medNationalityId = nationalityId;
    if (medWorkerId != null &&
        !mediationWorkers().any((w) => w.id == medWorkerId)) {
      medWorkerId = null;
    }
    notifyListeners();
  }

  void setMedPackage(String id) {
    medPackageId = id;
    notifyListeners();
  }

  void setMedQuery(String q) {
    medQuery = q;
    notifyListeners();
  }

  List<DemoWorker> mediationWorkers({String? query}) {
    return repo.workers.where((w) {
      if (w.professionId != medProfessionId) return false;
      if (w.nationalityId != medNationalityId) return false;
      if (query != null && query.trim().isNotEmpty) {
        return w.name.matches(query) ||
            w.code.toLowerCase().contains(query.trim().toLowerCase());
      }
      return true;
    }).toList();
  }

  void selectMedWorker(String id) {
    medWorkerId = id;
    notifyListeners();
  }

  // ---- worker lookup / viewing --------------------------------------------

  DemoWorker? workerById(String? id) {
    if (id == null) return null;
    for (final w in repo.workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  void viewWorker(String id) {
    viewWorkerId = id;
    notifyListeners();
  }

  // ---- contracts ----------------------------------------------------------

  ContractData contractFor(ServiceModule m) =>
      m == ServiceModule.mediation ? medContract : indContract;

  void setContract(ServiceModule m, ContractData c) {
    if (m == ServiceModule.mediation) {
      medContract = c;
    } else {
      indContract = c;
    }
    notifyListeners();
  }

  // ---- hourly -------------------------------------------------------------

  HourlyPackage? get hourlyPackage {
    for (final p in repo.hourlyPackages) {
      if (p.id == hourlyPackageId) return p;
    }
    return null;
  }

  bool get hourlyHasSelection => hourlyCustom || hourlyPackage != null;

  int get hoursPerVisit => hourlyCustom
      ? customHourly.hoursPerVisit
      : (hourlyPackage?.hoursPerVisit ?? 0);
  int get visitsPerWeek => hourlyCustom
      ? customHourly.visitsPerWeek
      : (hourlyPackage?.visitsPerWeek ?? 0);
  int get weeks =>
      hourlyCustom ? customHourly.weeks : (hourlyPackage?.weeks ?? 0);
  int get totalVisits => visitsPerWeek * weeks;
  int get totalHours => hoursPerVisit * totalVisits;

  int priceFor(int hours, int perWeek, int weeks) => PricingRules.hourlyPrice(
    hoursPerVisit: hours,
    visitsPerWeek: perWeek,
    weeks: weeks,
  );

  int get hourlySubtotal => hourlyHasSelection
      ? PricingRules.hourlyPrice(
          hoursPerVisit: hoursPerVisit,
          visitsPerWeek: visitsPerWeek,
          weeks: weeks,
        )
      : 0;

  void selectHourlyPackage(String id) {
    hourlyCustom = false;
    hourlyPackageId = id;
    _trimDays();
    notifyListeners();
  }

  void useFixedHourly() {
    hourlyCustom = false;
    _trimDays();
    notifyListeners();
  }

  void useCustomHourly() {
    hourlyCustom = true;
    _trimDays();
    notifyListeners();
  }

  void setCustomHourly(CustomHourly c) {
    customHourly = c;
    _trimDays();
    notifyListeners();
  }

  void _trimDays() {
    if (hourlyDays.length > visitsPerWeek) hourlyDays = {};
  }

  void setHourlyStart(DateTime d) {
    hourlyStartDate = d;
    notifyListeners();
  }

  void toggleHourlyDay(int weekday) {
    final next = Set.of(hourlyDays);
    if (!next.remove(weekday)) {
      if (next.length >= visitsPerWeek) return;
      next.add(weekday);
    }
    hourlyDays = next;
    notifyListeners();
  }

  /// Validates [code] against the local demo rules. Applied codes are kept and
  /// re-evaluated as the price changes.
  DiscountResult applyDiscount(String code) {
    final result = DiscountRules.apply(code, hourlySubtotal);
    appliedDiscountCode = result.isApplied ? result.code : '';
    notifyListeners();
    return result;
  }

  void clearDiscount() {
    appliedDiscountCode = '';
    notifyListeners();
  }

  DiscountResult get hourlyDiscount => appliedDiscountCode.isEmpty
      ? const DiscountResult.none()
      : DiscountRules.apply(appliedDiscountCode, hourlySubtotal);

  bool get hourlyDetailsComplete =>
      hourlyHasSelection &&
      hourlyStartDate != null &&
      hourlyDays.length == visitsPerWeek &&
      selectedAddress != null;

  static const weekdayNames = <int, L>{
    1: L('الإثنين', 'Mon'),
    2: L('الثلاثاء', 'Tue'),
    3: L('الأربعاء', 'Wed'),
    4: L('الخميس', 'Thu'),
    5: L('الجمعة', 'Fri'),
    6: L('السبت', 'Sat'),
    7: L('الأحد', 'Sun'),
  };

  // ---- payment & orders ---------------------------------------------------

  void setPaymentMethod(String id) {
    paymentMethodId = id;
    notifyListeners();
  }

  void setSimulateFailure(bool v) {
    simulateFailure = v;
    notifyListeners();
  }

  /// Totals for the payment screen, for any module.
  OrderSummary summary(ServiceModule module) {
    switch (module) {
      case ServiceModule.individuals:
        final pkg = indPackage;
        final nat = indNationalityId == null
            ? null
            : repo.nationality(indNationalityId!);
        final worker = workerById(indWorkerId);
        final addr = selectedAddress;
        final price = pkg == null || indNationalityId == null
            ? 0
            : PricingRules.recruitmentPrice(pkg, indNationalityId!);
        final base = pkg?.basePrice ?? 0;
        final vat = PricingRules.vat(price);
        return OrderSummary(
          module: module,
          title: const L('خدمات الأفراد', 'Individuals service'),
          details: [
            OrderLine(
              const L('الباقة', 'Package'),
              pkg?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('الجنسية', 'Nationality'),
              nat?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('العاملة', 'Worker'),
              worker?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('العنوان', 'Address'),
              addr == null
                  ? const L.same('-')
                  : L(addr.oneLine('ar'), addr.oneLine('en')),
            ),
          ],
          prices: [
            PriceLine(const L('سعر الباقة', 'Package price'), base),
            PriceLine(const L('رسوم الجنسية', 'Nationality fee'), price - base),
            PriceLine(const L('ضريبة القيمة المضافة 15%', 'VAT 15%'), vat),
          ],
          total: price + vat,
        );
      case ServiceModule.hourly:
        final subtotal = hourlySubtotal;
        final discount = hourlyDiscount.isApplied ? hourlyDiscount.amount : 0;
        final vat = PricingRules.vat(subtotal - discount);
        final start = hourlyStartDate;
        final days = (hourlyDays.toList()..sort())
            .map((d) => weekdayNames[d]!)
            .toList();
        return OrderSummary(
          module: module,
          title: const L('خدمة بالساعة', 'Hourly service'),
          details: [
            OrderLine(
              const L('الباقة', 'Package'),
              hourlyCustom
                  ? const L('باقة مخصصة', 'Custom package')
                  : (hourlyPackage?.name ?? const L.same('-')),
            ),
            OrderLine(
              const L('المدة', 'Duration'),
              L(
                '$hoursPerVisit ساعات × $totalVisits زيارة',
                '$hoursPerVisit h × $totalVisits visits',
              ),
            ),
            OrderLine(
              const L('الجدول', 'Schedule'),
              L(
                '${start == null ? '-' : _fmt(start)} · ${days.map((d) => d.ar).join('، ')}',
                '${start == null ? '-' : _fmt(start)} · ${days.map((d) => d.en).join(', ')}',
              ),
            ),
            OrderLine(
              const L('العنوان', 'Address'),
              selectedAddress == null
                  ? const L.same('-')
                  : L(
                      selectedAddress!.oneLine('ar'),
                      selectedAddress!.oneLine('en'),
                    ),
            ),
          ],
          prices: [
            PriceLine(const L('سعر الخدمة', 'Service price'), subtotal),
            if (discount > 0)
              PriceLine(
                L(
                  'خصم (${hourlyDiscount.code})',
                  'Discount (${hourlyDiscount.code})',
                ),
                -discount,
              ),
            PriceLine(const L('ضريبة القيمة المضافة 15%', 'VAT 15%'), vat),
          ],
          total: subtotal - discount + vat,
        );
      case ServiceModule.mediation:
        final pkg = medPackage;
        final nat = medNationalityId == null
            ? null
            : repo.nationality(medNationalityId!);
        final prof = medProfessionId == null
            ? null
            : repo.profession(medProfessionId!);
        final worker = workerById(medWorkerId);
        final price =
            pkg == null || medNationalityId == null || medProfessionId == null
            ? 0
            : PricingRules.mediationPrice(
                pkg,
                medNationalityId!,
                medProfessionId!,
              );
        final vat = PricingRules.vat(price);
        return OrderSummary(
          module: module,
          title: const L('خدمة الوساطة', 'Mediation service'),
          details: [
            OrderLine(
              const L('الباقة', 'Package'),
              pkg?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('المهنة', 'Profession'),
              prof?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('الجنسية', 'Nationality'),
              nat?.name ?? const L.same('-'),
            ),
            OrderLine(
              const L('العاملة', 'Worker'),
              worker?.name ?? const L.same('-'),
            ),
          ],
          prices: [
            PriceLine(const L('رسوم الوساطة', 'Mediation fee'), price),
            PriceLine(const L('ضريبة القيمة المضافة 15%', 'VAT 15%'), vat),
          ],
          total: price + vat,
        );
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Runs the simulated payment. Only on success an order is created.
  Future<PaymentResult> pay(ServiceModule module) async {
    final summary = this.summary(module);
    final result = await repo.pay(
      methodId: paymentMethodId,
      amount: summary.total,
      simulateFailure: simulateFailure,
    );
    if (result.isSuccess) {
      lastOrder = DemoOrder(
        reference: repo.nextOrderReference(module),
        summary: summary,
        createdAt: DateTime.now(),
      );
      orders = [lastOrder!, ...orders];
      notifyListeners();
    }
    return result;
  }

  /// Clears the finished flow so the next one starts fresh. Addresses and
  /// other modules' progress are kept.
  void completeFlow(ServiceModule module) {
    switch (module) {
      case ServiceModule.individuals:
        indNationalityId = null;
        indPackageId = null;
        indWorkerId = null;
        indProfessionFilter = null;
        indContract = ContractData(phone: indContract.phone);
      case ServiceModule.hourly:
        hourlyCustom = false;
        hourlyPackageId = null;
        customHourly = const CustomHourly();
        hourlyStartDate = null;
        hourlyDays = {};
        appliedDiscountCode = '';
      case ServiceModule.mediation:
        medProfessionId = null;
        medNationalityId = null;
        medPackageId = null;
        medWorkerId = null;
        medQuery = '';
        medContract = ContractData(phone: medContract.phone);
    }
    mainTab = 0;
    notifyListeners();
  }

  RecruitPackage? _pkg(List<RecruitPackage> list, String? id) {
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }
}
