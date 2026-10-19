import 'package:flutter/widgets.dart';

import '../app_template.dart';
import '../branding_config.dart';
import '../demo/session.dart';
import '../strings.dart';

/// Gives every screen of the prototype access to the session, the active
/// template, the branding and the language. Rebuilds dependents whenever the
/// session notifies or any of these change.
class DemoScope extends InheritedNotifier<DemoSession> {
  const DemoScope({
    super.key,
    required DemoSession session,
    required this.template,
    required this.branding,
    required this.languageCode,
    required super.child,
  }) : super(notifier: session);

  final AppTemplate template;
  final BrandingConfig branding;
  final String languageCode;

  DemoSession get session => notifier!;
  RuiStrings get s => RuiStrings(languageCode);
  String get lang => languageCode;

  static DemoScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DemoScope>();
    assert(scope != null, 'No DemoScope found; wrap screens in RecruitmentApp');
    return scope!;
  }

  @override
  bool updateShouldNotify(DemoScope oldWidget) =>
      super.updateShouldNotify(oldWidget) ||
      template != oldWidget.template ||
      branding != oldWidget.branding ||
      languageCode != oldWidget.languageCode;
}
