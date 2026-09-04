import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'generated/app_localizations_ko.dart';

extension PoppopLocalizations on BuildContext {
  AppLocalizations get l10n {
    final loaded = Localizations.of<AppLocalizations>(this, AppLocalizations);
    if (loaded != null) return loaded;
    final language = Localizations.maybeLocaleOf(this)?.languageCode;
    return language == 'en' ? AppLocalizationsEn() : AppLocalizationsKo();
  }
}

Locale poppopLocaleResolution(
  List<Locale>? preferred,
  Iterable<Locale> supported,
) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (locale.languageCode == 'ko') return const Locale('ko');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}
