import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:balloon_pop_game/storage/progress_storage_backend.dart';
import 'package:balloon_pop_game/storage/progress_storage_native.dart';

void main() {
  tearDown(() async {
    await ProgressStorage.resetForTesting();
  });

  test('native new player starts with safe defaults', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);

    expect(ProgressStorage.coinBalance(), 0);
    expect(ProgressStorage.nextPlayableStage(), 1);
    expect(ProgressStorage.bestScore(), 0);
    expect(ProgressStorage.soundEnabled(), isTrue);
    expect(ProgressStorage.hapticEnabled(), isTrue);
  });

  test('initial 20000 coins are granted only once', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);

    expect(
      ProgressStorage.initializeNewUserCoins(),
      ProgressStorage.initialCoinBalance,
    );
    expect(
      ProgressStorage.initializeNewUserCoins(),
      ProgressStorage.initialCoinBalance,
    );
    await ProgressStorage.flush();

    await _restart(store);
    expect(
      ProgressStorage.initializeNewUserCoins(),
      ProgressStorage.initialCoinBalance,
    );
    expect(store.writeValues(ProgressStorageKeys.coinBalance), [20000]);
  });

  test('coins survive adapter recreation', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.initializeNewUserCoins();
    ProgressStorage.addCoins(321);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.coinBalance(), 20321);
  });

  test('purchased products survive adapter recreation', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.initializeNewUserCoins();
    expect(
      ProgressStorage.tryPurchaseProduct('balloon-heart', 500),
      isTrue,
    );
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.ownedProductIds(), contains('balloon-heart'));
    expect(ProgressStorage.coinBalance(), 19500);
  });

  test('equipped products survive adapter recreation', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.setEquippedProductId('balloon', 'balloon-wari');
    await ProgressStorage.flush();

    await _restart(store);
    expect(
      ProgressStorage.equippedProductId('balloon'),
      'balloon-wari',
    );
  });

  test('stage progress survives and never decreases', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.advanceNextPlayableStage(21);
    ProgressStorage.advanceNextPlayableStage(11);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.nextPlayableStage(), 21);
  });

  test('best score stays highest and last score stays latest', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    expect(ProgressStorage.saveScore(94), isTrue);
    expect(ProgressStorage.saveScore(40), isFalse);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.bestScore(), 94);
    expect(ProgressStorage.lastScore(), 40);
  });

  test('endless best and last scores survive independently', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.saveEndlessBestScore(128);
    ProgressStorage.saveEndlessLastScore(72);
    ProgressStorage.setEndlessIntroSeen(true);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.endlessBestScore(), 128);
    expect(ProgressStorage.endlessLastScore(), 72);
    expect(ProgressStorage.endlessIntroSeen(), isTrue);
  });

  test('nickname and onboarding survive adapter recreation', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.setNickname('테스터');
    ProgressStorage.setNicknameOnboardingCompleted(true);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.nickname(), '테스터');
    expect(ProgressStorage.nicknameOnboardingCompleted(), isTrue);
  });

  test('sound and haptic settings survive adapter recreation', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.setSoundEnabled(false);
    ProgressStorage.setHapticEnabled(false);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.soundEnabled(), isFalse);
    expect(ProgressStorage.hapticEnabled(), isFalse);
  });

  test('corrupted values use safe defaults', () async {
    final store = _MemoryPersistentStore(initial: {
      ProgressStorageKeys.coinBalance: -10,
      ProgressStorageKeys.bestScore: 'broken',
      ProgressStorageKeys.soundEnabled: 'false',
      ProgressStorageKeys.hapticEnabled: 1,
      ProgressStorageKeys.nickname: 42,
    });
    await _initialize(store);

    expect(ProgressStorage.coinBalance(), 0);
    expect(ProgressStorage.bestScore(), 0);
    expect(ProgressStorage.soundEnabled(), isTrue);
    expect(ProgressStorage.hapticEnabled(), isTrue);
    expect(ProgressStorage.nickname(), isNull);
  });

  test('invalid stage and equipped entries use safe fallbacks', () async {
    final store = _MemoryPersistentStore(initial: {
      ProgressStorageKeys.nextPlayableStage: 99,
      ProgressStorageKeys.equippedProductIds: 'invalid-entry',
    });
    await _initialize(store);

    expect(ProgressStorage.nextPlayableStage(), 1);
    expect(ProgressStorage.equippedProductId('balloon'), isNull);
  });

  test('consecutive writes preserve invocation order', () async {
    final store = _MemoryPersistentStore(
        writeDelay: const Duration(
      milliseconds: 2,
    ));
    await _initialize(store);
    ProgressStorage.addCoins(1);
    ProgressStorage.addCoins(2);
    await ProgressStorage.flush();

    expect(store.writeValues(ProgressStorageKeys.coinBalance), [1, 3]);
    expect(store.maxConcurrentWrites, 1);
  });

  test('flush waits for pending native writes', () async {
    final gate = Completer<void>();
    final store = _MemoryPersistentStore(writeGate: gate.future);
    await _initialize(store);
    ProgressStorage.addCoins(5);

    var flushed = false;
    final flush = ProgressStorage.flush().then((_) => flushed = true);
    await Future<void>.delayed(Duration.zero);
    expect(flushed, isFalse);
    gate.complete();
    await flush;
    expect(flushed, isTrue);
    expect(store.values[ProgressStorageKeys.coinBalance], 5);
  });

  test('duplicate initialization creates one backend', () async {
    final store = _MemoryPersistentStore();
    var factoryCalls = 0;
    await ProgressStorage.resetForTesting();
    Future<ProgressStorageBackend> factory() async {
      factoryCalls++;
      return _MemoryBackend(store);
    }

    await ProgressStorage.initializeForTesting(factory);
    await Future.wait([
      ProgressStorage.initialize(),
      ProgressStorage.initialize(),
    ]);

    expect(factoryCalls, 1);
    expect(ProgressStorage.backendCreationCountForTesting, 1);
  });

  test('initialization failure never grants repeated starting coins', () async {
    await ProgressStorage.initializeForTesting(
      () async => throw StateError('unavailable'),
    );

    expect(ProgressStorage.initializeNewUserCoins(), 0);
    expect(ProgressStorage.initializeNewUserCoins(), 0);
    expect(ProgressStorage.initializationErrorForTesting, isNotNull);
  });

  test('injected backend uses no platform channel', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.addCoins(7);
    await ProgressStorage.flush();

    expect(store.backendCreations, 1);
    expect(store.values[ProgressStorageKeys.coinBalance], 7);
  });

  test('native and web adapters retain the authoritative key contract',
      () async {
    const expected = <String>{
      'balloon_pop_game_second_section_unlocked',
      'poppop_next_playable_stage',
      'poppop_best_score',
      'poppop_last_score',
      'poppop_coin_balance',
      'poppop_owned_product_ids',
      'poppop_equipped_product_ids',
      'poppop_nickname',
      'poppop_nickname_onboarding_completed',
      'poppop_sound_enabled',
      'poppop_haptic_enabled',
      'poppop_endless_best',
      'poppop_endless_last',
      'poppop_endless_intro_seen',
    };
    expect(ProgressStorage.storageKeysForTesting, expected);

    final webSource = File(
      'lib/storage/progress_storage_web.dart',
    ).readAsStringSync();
    for (final key in expected) {
      expect(webSource, contains("'$key'"));
    }
  });

  test('normal and endless records remain isolated after restart', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.saveScore(50);
    ProgressStorage.saveEndlessBestScore(80);
    ProgressStorage.saveEndlessLastScore(30);
    await ProgressStorage.flush();

    await _restart(store);
    expect(ProgressStorage.bestScore(), 50);
    expect(ProgressStorage.lastScore(), 50);
    expect(ProgressStorage.endlessBestScore(), 80);
    expect(ProgressStorage.endlessLastScore(), 30);
  });

  test('route-style reentry retains one storage instance', () async {
    final store = _MemoryPersistentStore();
    await _initialize(store);
    ProgressStorage.advanceNextPlayableStage(11);
    await ProgressStorage.initialize();
    ProgressStorage.addCoins(10);
    await ProgressStorage.initialize();
    await ProgressStorage.flush();

    expect(ProgressStorage.backendCreationCountForTesting, 1);
    expect(store.backendCreations, 1);
    expect(ProgressStorage.nextPlayableStage(), 11);
    expect(ProgressStorage.coinBalance(), 10);
  });
}

Future<void> _initialize(_MemoryPersistentStore store) async {
  await ProgressStorage.initializeForTesting(() async {
    store.backendCreations++;
    return _MemoryBackend(store);
  });
}

Future<void> _restart(_MemoryPersistentStore store) async {
  await ProgressStorage.resetForTesting();
  await _initialize(store);
}

final class _MemoryPersistentStore {
  _MemoryPersistentStore({
    Map<String, Object?> initial = const <String, Object?>{},
    this.writeDelay = Duration.zero,
    this.writeGate,
  }) : values = Map<String, Object?>.from(initial);

  final Map<String, Object?> values;
  final Duration writeDelay;
  final Future<void>? writeGate;
  final List<MapEntry<String, Object?>> writes = [];
  int backendCreations = 0;
  int activeWrites = 0;
  int maxConcurrentWrites = 0;

  List<Object?> writeValues(String key) => writes
      .where((entry) => entry.key == key)
      .map((entry) => entry.value)
      .toList();
}

final class _MemoryBackend implements ProgressStorageBackend {
  _MemoryBackend(this.store);

  final _MemoryPersistentStore store;

  @override
  Set<String> get keys => store.values.keys.toSet();

  @override
  Object? get(String key) => store.values[key];

  Future<void> _write(String key, Object value) async {
    store.activeWrites++;
    if (store.activeWrites > store.maxConcurrentWrites) {
      store.maxConcurrentWrites = store.activeWrites;
    }
    try {
      if (store.writeGate case final gate?) await gate;
      if (store.writeDelay > Duration.zero) {
        await Future<void>.delayed(store.writeDelay);
      }
      store.values[key] = value;
      store.writes.add(MapEntry(key, value));
    } finally {
      store.activeWrites--;
    }
  }

  @override
  Future<void> setBool(String key, bool value) => _write(key, value);

  @override
  Future<void> setInt(String key, int value) => _write(key, value);

  @override
  Future<void> setString(String key, String value) => _write(key, value);

  @override
  Future<void> clear() async {
    store.values.clear();
    store.writes.add(const MapEntry('<clear>', null));
  }
}
