import 'package:balloon_pop_game/audio/game_bgm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGameBgmBackend backend;

  setUp(() async {
    backend = _FakeGameBgmBackend();
    await GameBgm.debugReset(backend: backend);
  });

  tearDown(() => GameBgm.shutdown());

  test('home BGM loops once across non-game screens', () async {
    await GameBgm.startHome();
    await GameBgm.startHome();

    expect(backend.startCount, 1);
    expect(backend.assetPaths, [GameBgm.homeAssetPath]);
    expect(backend.startVolumes, [0]);
    expect(backend.volume, closeTo(0.12, 0.0001));
  });

  test('gameplay switches tracks and loops without restarting between stages',
      () async {
    await GameBgm.startHome();
    await GameBgm.startGameplay();

    expect(backend.startCount, 2);
    expect(backend.stopCount, 1);
    expect(
        backend.assetPaths, [GameBgm.homeAssetPath, GameBgm.gameplayAssetPath]);
    expect(backend.startVolumes, [0, 0]);
    expect(backend.volume, closeTo(0.16, 0.0001));
    expect(GameBgm.fadeDuration, lessThanOrEqualTo(const Duration(milliseconds: 500)));
    expect(backend.volumeChanges, contains(0));

    // Stage changes do not touch the session-wide BGM owner.
    await GameBgm.startGameplay();
    expect(backend.startCount, 2);
  });

  test('gameplay pause resumes the same loop and exit stops it', () async {
    await GameBgm.startGameplay();
    await GameBgm.pauseGameplay();
    await GameBgm.resumeGameplay();
    await GameBgm.stopGameplay();

    expect(backend.startCount, 1);
    expect(backend.pauseCount, 1);
    expect(backend.resumeCount, 1);
    expect(backend.stopCount, 1);
  });

  test('shared sound setting gates BGM without changing sound effects',
      () async {
    await GameBgm.setEnabled(false);
    await GameBgm.startGameplay();
    expect(backend.startCount, 0);

    await GameBgm.setEnabled(true);
    expect(backend.startCount, 1);

    await GameBgm.setEnabled(false);
    expect(backend.pauseCount, 1);

    await GameBgm.setEnabled(true);
    expect(backend.resumeCount, 1);
  });

  test('lifecycle pauses and resumes the active home track', () async {
    await GameBgm.startHome();
    await GameBgm.pauseForLifecycle();
    await GameBgm.resumeFromLifecycle();

    expect(backend.startCount, 1);
    expect(backend.pauseCount, 1);
    expect(backend.resumeCount, 1);
  });

  test('returning home stops gameplay and starts the home track', () async {
    await GameBgm.startGameplay();
    await GameBgm.startHome();

    expect(backend.stopCount, 1);
    expect(
        backend.assetPaths, [GameBgm.gameplayAssetPath, GameBgm.homeAssetPath]);
    expect(backend.volume, closeTo(0.12, 0.0001));
  });
}

final class _FakeGameBgmBackend implements GameBgmBackend {
  int startCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  final List<String> assetPaths = <String>[];
  final List<double> startVolumes = <double>[];
  final List<double> volumeChanges = <double>[];
  double? volume;

  @override
  Future<void> startLoop(String assetPath, double volume) async {
    startCount++;
    assetPaths.add(assetPath);
    startVolumes.add(volume);
    this.volume = volume;
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeChanges.add(volume);
    this.volume = volume;
  }

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> resume() async => resumeCount++;

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async {}
}
