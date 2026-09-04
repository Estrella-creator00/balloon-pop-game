import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:balloon_pop_game/l10n/l10n.dart';
import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/services/settings_service.dart';
import 'package:balloon_pop_game/settings_page.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ProgressStorage.clear();
    ProgressStorage.setNicknameOnboardingCompleted(true);
    SettingsService.applyStoredPreferences();
  });

  for (final locale in const [Locale('ko'), Locale('en')]) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets(
          '${locale.languageCode} home, shop and settings fit ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

        final strings = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(const BalloonPopApp());
        await tester.pump();
        expect(find.text(strings.home), findsOneWidget);
        expect(find.text(strings.shop), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('home-coin-add-button')));
        await tester.pumpAndSettle();
        expect(find.text(strings.coinPurchase), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('coin-purchase-back')));
        await tester.pump(const Duration(milliseconds: 350));

        await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text(strings.skinBasic), findsWidgets);
        expect(find.text(strings.filterAll), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(onDataReset: () {}),
        ));
        await tester.pump();
        expect(find.text(strings.settings), findsOneWidget);
        expect(find.text(strings.soundEffects), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('all catalog skin IDs have Korean and English names', () async {
    final ko = await AppLocalizations.delegate.load(const Locale('ko'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    const expected = {
      'balloon-default': ('기본 풍선', 'Basic Balloon'),
      'balloon-heart': ('하트 풍선', 'Heart Balloon'),
      'balloon-star': ('별 풍선', 'Star Balloon'),
      'balloon-flower': ('꽃 풍선', 'Flower Balloon'),
      'balloon-rabbit': ('모찌', 'MOCHI'),
      'balloon-wari': ('와리', 'WARI'),
      'balloon-kicks': ('KICKS', 'KICKS'),
      'balloon-boo': ('BOO', 'BOO'),
      'balloon-jello': ('무기', 'MUGI'),
      'balloon-lumen': ('제미', 'GEMI'),
      'balloon-chouchou': ('슈슈', 'SHUSHU'),
    };
    for (final entry in expected.entries) {
      expect(localizedSkinName(ko, entry.key), entry.value.$1);
      expect(localizedSkinName(en, entry.key), entry.value.$2);
    }
  });
}
