import 'package:flutter/material.dart' show Color, IconData;

/// A bilingual text. Mock content is authored once and rendered per language.
class L {
  const L(this.ar, this.en);
  const L.same(String s) : ar = s, en = s;

  final String ar;
  final String en;

  String of(String lang) => lang == 'ar' ? ar : en;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return ar.contains(q) || en.toLowerCase().contains(q);
  }
}

/// Business modules a generated app can enable.
enum ServiceModule { individuals, hourly, mediation }

class DemoAddress {
  const DemoAddress({
    required this.id,
    required this.label,
    required this.city,
    required this.district,
    required this.street,
    required this.building,
    this.notes = '',
  });

  final String id;
  final L label;
  final L city;
  final L district;
  final L street;
  final String building;
  final String notes;

  String oneLine(String lang) =>
      '${city.of(lang)} - ${district.of(lang)}, ${street.of(lang)}, $building';
}

class Nationality {
  const Nationality(this.id, this.name, this.flag);
  final String id;
  final L name;
  final String flag;
}

class Profession {
  const Profession(this.id, this.name, this.icon);
  final String id;
  final L name;
  final IconData icon;
}

/// A recruitment / mediation package.
class RecruitPackage {
  const RecruitPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.includes,
    this.popular = false,
  });

  final String id;
  final L name;
  final L description;
  final int basePrice;
  final List<L> includes;
  final bool popular;
}

class DemoWorker {
  const DemoWorker({
    required this.id,
    required this.code,
    required this.name,
    required this.nationalityId,
    required this.professionId,
    required this.age,
    required this.years,
    required this.rating,
    required this.skills,
    required this.languages,
    required this.packageIds,
    required this.bio,
  });

  final String id;

  /// Demo identifier shown on cards, e.g. `W-PH-HM-1`.
  final String code;
  final L name;
  final String nationalityId;
  final String professionId;
  final int age;
  final int years;
  final double rating;
  final List<L> skills;
  final List<L> languages;

  /// Individuals packages this worker is offered under.
  final Set<String> packageIds;
  final L bio;
}

/// A fixed hourly package; its price comes from [PricingRules].
class HourlyPackage {
  const HourlyPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.hoursPerVisit,
    required this.visitsPerWeek,
    required this.weeks,
  });

  final String id;
  final L name;
  final L description;
  final int hoursPerVisit;
  final int visitsPerWeek;
  final int weeks;

  int get visits => visitsPerWeek * weeks;
  int get totalHours => hoursPerVisit * visits;
}

/// Parameters of the "design your own package" option.
class CustomHourly {
  const CustomHourly({
    this.hoursPerVisit = 4,
    this.visitsPerWeek = 2,
    this.weeks = 4,
  });

  final int hoursPerVisit;
  final int visitsPerWeek;
  final int weeks;

  int get visits => visitsPerWeek * weeks;
  int get totalHours => hoursPerVisit * visits;

  CustomHourly copyWith({int? hoursPerVisit, int? visitsPerWeek, int? weeks}) =>
      CustomHourly(
        hoursPerVisit: hoursPerVisit ?? this.hoursPerVisit,
        visitsPerWeek: visitsPerWeek ?? this.visitsPerWeek,
        weeks: weeks ?? this.weeks,
      );
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.target,
  });

  final String id;
  final L title;
  final L subtitle;
  final Color color;
  final ServiceModule target;
}

class Review {
  const Review(this.author, this.rating, this.text);
  final L author;
  final int rating;
  final L text;
}

class Partner {
  const Partner(this.name);
  final L name;
}

class ContactInfo {
  const ContactInfo({
    required this.phone,
    required this.email,
    required this.address,
    required this.hours,
  });
  final String phone;
  final String email;
  final L address;
  final L hours;
}

class PaymentMethodInfo {
  const PaymentMethodInfo(this.id, this.name, this.icon);
  final String id;
  final L name;
  final IconData icon;
}

class OrderLine {
  const OrderLine(this.label, this.value);
  final L label;
  final L value;
}

class PriceLine {
  const PriceLine(this.label, this.amount);
  final L label;

  /// Negative for discounts.
  final int amount;
}

/// Everything the payment and success screens need, for any module.
class OrderSummary {
  const OrderSummary({
    required this.module,
    required this.title,
    required this.details,
    required this.prices,
    required this.total,
  });

  final ServiceModule module;
  final L title;
  final List<OrderLine> details;
  final List<PriceLine> prices;
  final int total;
}

class DemoOrder {
  const DemoOrder({
    required this.reference,
    required this.summary,
    required this.createdAt,
  });
  final String reference;
  final OrderSummary summary;
  final DateTime createdAt;
}

class ContractData {
  const ContractData({
    this.fullName = '',
    this.nationalId = '',
    this.email = '',
    this.phone = '',
    this.startDate,
    this.acknowledged = false,
  });

  final String fullName;
  final String nationalId;
  final String email;
  final String phone;
  final DateTime? startDate;
  final bool acknowledged;

  ContractData copyWith({
    String? fullName,
    String? nationalId,
    String? email,
    String? phone,
    DateTime? startDate,
    bool? acknowledged,
  }) => ContractData(
    fullName: fullName ?? this.fullName,
    nationalId: nationalId ?? this.nationalId,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    startDate: startDate ?? this.startDate,
    acknowledged: acknowledged ?? this.acknowledged,
  );
}

enum DiscountStatus { none, applied, invalid, expired, minimumNotMet }

class DiscountResult {
  const DiscountResult(this.status, {this.code = '', this.amount = 0});
  const DiscountResult.none() : this(DiscountStatus.none);

  final DiscountStatus status;
  final String code;
  final int amount;
  bool get isApplied => status == DiscountStatus.applied;
}

class PaymentResult {
  const PaymentResult.success() : failureReason = null;
  const PaymentResult.failure(L this.failureReason);
  final L? failureReason;
  bool get isSuccess => failureReason == null;
}
