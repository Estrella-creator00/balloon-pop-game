import 'package:balloon_pop_game/audio/game_bgm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGameBgmBackend backend;

  setUp(() async {
    backend = _FakeGameBgmBackend();
    await GameBgm.debugReset(backend: backend);
  });

  tearDown(() => GameBgm.shutdown());

  test('gameplay BGM loops at 16 percent without restarting between stages',
      () async {
    await GameBgm.startGameplay();

    expect(backend.startCount, 1);
    expect(backend.assetPath, GameBgm.assetPath);
    expect(backend.volume, 0.16);

    // Stage changes do not touch the session-wide BGM owner.
    await GameBgm.startGameplay();
    expect(backend.startCount, 1);
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
}

final class _FakeGameBgmBackend implements GameBgmBackend {
  int startCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  String? assetPath;
  double? volume;

  @override
  Future<void> startLoop(String assetPath, double volume) async {
    startCount++;
    this.assetPath = assetPath;
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
