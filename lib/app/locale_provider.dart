import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language of the builder UI itself (Arabic by default).
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar');

  void toggle() => state = state.languageCode == 'ar'
      ? const Locale('en')
      : const Locale('ar');
}
