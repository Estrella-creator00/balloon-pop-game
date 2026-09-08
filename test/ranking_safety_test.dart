import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:balloon_pop_game/ranking/online_ranking_models.dart';
import 'package:balloon_pop_game/ranking/ranking_functions_client.dart';
import 'package:balloon_pop_game/ranking/ranking_moderation_service.dart';
import 'package:balloon_pop_game/ranking/ranking_nickname.dart';
import 'package:balloon_pop_game/ranking/ranking_safety_dialog.dart';
import 'package:balloon_pop_game/ranking/ranking_safety_store.dart';
import 'package:balloon_pop_game/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nickname policy normalizes NFKC and common spacing', () {
    expect(RankingNickname.normalize('  ＰＯＰＰＯＰ   친구  '), 'POPPOP 친구');
    expect(RankingNickname.normalize('Happy Player'), 'Happy Player');
    expect(RankingNickname.normalize('시발점'), '시발점');
    expect(RankingNickname.normalize('Sussex'), 'Sussex');
  });

  test('nickname policy rejects unsafe, PII, Unicode, and meaningless input',
      () {
    const invalid = [
      '',
      'f.u.c.k',
      'sh111t',
      '씨 발',
      '010 1234 5678',
      'kid@example.com',
      'my discord',
      '우리학교짱',
      '가\u200B나',
      'abcabcabc',
      'ㅋㅋㅋㅋ',
    ];
    for (final value in invalid) {
      expect(RankingNickname.validate(value).isValid, isFalse, reason: value);
    }
  });

  test('parent control and safety state stay local and preserve game data',
      () async {
    SharedPreferences.setMockInitialValues({'poppop_coin_balance': 321});
    final store = SharedPreferencesRankingSafetyStore();
    expect(await store.isOnlineRankingEnabled(), isTrue);
    expect(await store.hasCurrentConsent(), isFalse);
    await store.acceptCurrentPolicy();
    await store.disableWithParentPin('2468');
    expect(await store.isOnlineRankingEnabled(), isFalse);
    expect(await store.enableWithParentPin('0000'), isFalse);
    expect(await store.enableWithParentPin('2468'), isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('poppop_coin_balance'), 321);
  });

  test('actor blocks span both ranking categories and can be removed',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesRankingSafetyStore();
    final actorId = List.filled(64, 'a').join();
    await store.hideActor(actorId, 'Safe Player');
    expect(await store.hiddenActorIds(), {actorId});
    expect((await store.blockedActors()).single.displayName, 'Safe Player');
    expect(await store.hiddenEntryIds(RankingCategory.stage), isEmpty);
    expect(await store.hiddenEntryIds(RankingCategory.sixtySeconds), isEmpty);
    await store.unhideActor(actorId);
    expect(await store.blockedActors(), isEmpty);
  });

  testWidgets('safety notice requires both confirmations and supports decline',
      (tester) async {
    final store = _MemorySafetyStore();
    bool? result;
    await tester.pumpWidget(_app(
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => FilledButton(
          key: const ValueKey('open-safety'),
          onPressed: () async => result = await ensureRankingSafetyConsent(
            context,
            store: store,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('open-safety')));
    await tester.pumpAndSettle();
    final accept = find.byKey(const ValueKey('ranking-safety-accept'));
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('ranking-safety-confirmation')));
    await tester.tap(find.byKey(const ValueKey('ranking-terms-confirmation')));
    await tester.pump();
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(store.consented, isTrue);

    store.consented = false;
    await tester.tap(find.byKey(const ValueKey('open-safety')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranking-safety-decline')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets(
      'Korean notice and unsupported locale English fallback fit phones',
      (tester) async {
    for (final locale in const [Locale('ko'), Locale('fr')]) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      final store = _MemorySafetyStore();
      await tester.pumpWidget(_app(
        locale: locale,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => ensureRankingSafetyConsent(context, store: store),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(locale.languageCode == 'ko'
            ? '온라인에서 안전하게 이용해요'
            : 'Stay safe online'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('ranking-safety-decline')));
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets('settings parent switch uses a local PIN and does not overflow',
      (tester) async {
    final store = _MemorySafetyStore();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(
      locale: const Locale('en'),
      home: SettingsPage(onDataReset: () {}, rankingSafetyStore: store),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-online-ranking-switch')),
      100,
    );
    await tester
        .tap(find.byKey(const ValueKey('settings-online-ranking-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('parent-pin-input')), '2468');
    await tester.tap(find.byKey(const ValueKey('parent-pin-confirm')));
    await tester.pumpAndSettle();
    expect(store.enabled, isFalse);
    expect(
        find.byKey(const ValueKey('settings-blocked-users-row')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden user management unblocks a local actor', (tester) async {
    final store = _MemorySafetyStore();
    final actorId = List.filled(64, 'a').join();
    await store.hideActor(actorId, 'Safe Player');
    await tester.pumpWidget(_app(
      locale: const Locale('en'),
      home: SettingsPage(onDataReset: () {}, rankingSafetyStore: store),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-blocked-users-row')));
    await tester.pumpAndSettle();
    expect(find.text('Safe Player'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('unblock-ranking-user-$actorId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blocked-ranking-users-empty')),
        findsOneWidget);
    expect(await store.hiddenActorIds(), isEmpty);
  });

  test('reports are fixed-choice, idempotent locally, and hide by actor',
      () async {
    final entryId = List.filled(64, 'a').join();
    final actorId = List.filled(64, 'b').join();
    final store = _MemorySafetyStore();
    final functions = _FakeFunctionsClient();
    final service = RankingModerationService(
      functionsClient: functions,
      safetyStore: store,
    );
    expect(
        await service.report(
          category: RankingCategory.stage,
          entryId: entryId,
          publicActorId: actorId,
          displayName: 'Safe Player',
          reason: RankingReportReason.personalInformation,
        ),
        isTrue);
    expect(
        await service.report(
          category: RankingCategory.stage,
          entryId: entryId,
          publicActorId: actorId,
          displayName: 'Safe Player',
          reason: RankingReportReason.personalInformation,
        ),
        isFalse);
    expect(functions.calls, hasLength(1));
    expect(functions.calls.single.data.keys, {
      'category',
      'entryId',
      'reason',
      'policyVersion',
    });
    expect(await store.hiddenActorIds(), {actorId});
    expect(await store.hiddenEntryIds(RankingCategory.stage), isEmpty);
    await store.unhideActor(actorId);
    expect(await store.hiddenActorIds(), isEmpty);
  });
}

Widget _app({required Locale locale, required Widget home}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

class _MemorySafetyStore implements RankingSafetyStore {
  bool enabled = true;
  bool consented = false;
  String? pin;
  final Set<String> hidden = {};
  final Set<String> reported = {};
  final Map<String, String> actors = {};

  String _key(RankingCategory category, String entryId) =>
      '${category.wireName}:$entryId';

  @override
  Future<void> acceptCurrentPolicy() async => consented = true;
  @override
  Future<void> clearAll() async {
    enabled = true;
    consented = false;
    hidden.clear();
    reported.clear();
    actors.clear();
  }

  @override
  Future<void> disableWithParentPin(String value) async {
    if (!RegExp(r'^\d{4,8}$').hasMatch(value)) throw const FormatException();
    pin = value;
    enabled = false;
  }

  @override
  Future<bool> enableWithParentPin(String value) async {
    if (value != pin) return false;
    enabled = true;
    return true;
  }

  @override
  Future<bool> hasCurrentConsent() async => consented;
  @override
  Future<void> hide(RankingCategory category, String entryId) async =>
      hidden.add(_key(category, entryId));
  @override
  Future<Set<String>> hiddenEntryIds(RankingCategory category) async {
    final prefix = '${category.wireName}:';
    return hidden
        .where((value) => value.startsWith(prefix))
        .map((value) => value.substring(prefix.length))
        .toSet();
  }

  @override
  Future<void> hideActor(String actorId, String displayName) async =>
      actors[actorId] = displayName;
  @override
  Future<Set<String>> hiddenActorIds() async => actors.keys.toSet();
  @override
  Future<List<BlockedRankingActor>> blockedActors() async => actors.entries
      .map((entry) => BlockedRankingActor(
            actorId: entry.key,
            displayName: entry.value,
          ))
      .toList();
  @override
  Future<void> unhideActor(String actorId) async => actors.remove(actorId);

  @override
  Future<bool> isOnlineRankingEnabled() async => enabled;
  @override
  Future<void> markReported(RankingCategory category, String entryId) async =>
      reported.add(_key(category, entryId));
  @override
  Future<bool> wasReported(RankingCategory category, String entryId) async =>
      reported.contains(_key(category, entryId));
}

class _FakeFunctionsClient implements RankingFunctionsClient {
  final List<({String name, Map<String, dynamic> data})> calls = [];

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    calls.add((name: name, data: Map<String, dynamic>.from(data)));
    return const {'reported': true};
  }
}
