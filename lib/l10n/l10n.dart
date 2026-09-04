import 'package:flutter/widgets.dart';

import '../balloon_skin_catalog.dart';
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

AppLocalizations poppopLocalizationsForLocale(Locale locale) =>
    locale.languageCode == 'ko' ? AppLocalizationsKo() : AppLocalizationsEn();

String localizedSkinName(AppLocalizations strings, String id) => switch (id) {
      BalloonSkinCatalog.defaultId => strings.skinBasic,
      'balloon-heart' => strings.skinHeart,
      'balloon-star' => strings.skinStar,
      'balloon-flower' => strings.skinFlower,
      'balloon-rabbit' => strings.skinMochi,
      'balloon-wari' => strings.skinWari,
      'balloon-kicks' => strings.skinKicks,
      'balloon-boo' => strings.skinBoo,
      'balloon-jello' => strings.skinMugi,
      'balloon-lumen' => strings.skinGemi,
      'balloon-chouchou' => strings.skinShushu,
      _ => strings.skinBasic,
    };

String localizedSkinDescription(AppLocalizations strings, String id) =>
    switch (id) {
      'balloon-star' => strings.skinStarDescription,
      'balloon-flower' => strings.skinFlowerDescription,
      'balloon-rabbit' => strings.skinMochiDescription,
      'balloon-wari' => strings.skinWariDescription,
      'balloon-kicks' => strings.skinKicksDescription,
      'balloon-boo' => strings.skinBooDescription,
      'balloon-jello' => strings.skinMugiDescription,
      'balloon-lumen' => strings.skinGemiDescription,
      'balloon-chouchou' => strings.skinShushuDescription,
      _ => '',
    };
