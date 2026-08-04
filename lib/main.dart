import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'audio/pop_sound.dart';
import 'storage/progress_storage.dart';

void main() {
  runApp(const BalloonPopApp());
}

class BalloonPopApp extends StatelessWidget {
  const BalloonPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POPPOP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B9D)),
        useMaterial3: true,
        fontFamilyFallback: const ['Arial', 'sans-serif'],
      ),
      home: const BalloonGamePage(),
    );
  }
}

enum GamePhase {
  menu,
  playing,
  paused,
  stageClear,
  bossClear,
  completed,
  gameOver,
}

enum MainTab { home, store }

enum StoreCategory { balloon, popEffect, background, soundEffect, music }

enum StorePreviewType { balloon, effect, background, sound, music }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    required this.owned,
    required this.equipped,
    required this.previewType,
    required this.previewData,
  });

  final String id;
  final StoreCategory category;
  final String name;
  final int price;
  final bool owned;
  final bool equipped;
  final StorePreviewType previewType;
  final Color previewData;
}

class Balloon {
  Balloon({
    required this.id,
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.floatPhase,
    required this.floatPower,
    required this.hp,
    required this.maxHp,
  });

  final int id;
  Offset position;
  Offset velocity;
  final Color color;
  double size;
  double floatPhase;
  final double floatPower;
  int hp;
  final int maxHp;
}

class BossBalloon {
  BossBalloon({
    required this.id,
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxHp,
  });

  final int id;
  Offset position;
  Offset velocity;
  double size;
  final int maxHp;
  late int hp = maxHp;
  double turnCooldown = 0.65;
}

class StageConfig {
  const StageConfig({
    required this.stage,
    required this.isBoss,
    required this.balloonCount,
    required this.balloonHp,
    required this.duration,
    required this.bossHp,
    required this.bossSpeed,
    required this.bossCount,
  });

  final int stage;
  final bool isBoss;
  final int balloonCount;
  final int balloonHp;
  final Duration duration;
  final int bossHp;
  final double bossSpeed;
  final int bossCount;

  factory StageConfig.forStage(int stage) {
    final isBoss = stage % 10 == 0;
    final tier = (stage - 1) ~/ 10;
    final positionInTier = (stage - 1) % 10 + 1;
    final timeGroup = (positionInTier - 1) ~/ 3;

    return StageConfig(
      stage: stage,
      isBoss: isBoss,
      balloonCount: isBoss ? 0 : positionInTier + 1,
      balloonHp: tier + 1,
      duration: Duration(
        seconds: isBoss ? 8 + tier * 2 : 10 + tier * 2 + timeGroup * 5,
      ),
      bossHp: isBoss ? 10 + tier * 5 : 0,
      bossSpeed: isBoss ? 105 * pow(1.2, tier).toDouble() : 0,
      bossCount: isBoss ? tier + 1 : 0,
    );
  }
}

class PopPiece {
  PopPiece({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.life,
    required this.maxLife,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double rotation;
  final double spin;
  double life;
  final double maxLife;
}

class BurstRing {
  BurstRing({
    required this.center,
    required this.color,
    required this.radius,
    required this.life,
    required this.maxLife,
  });

  final Offset center;
  final Color color;
  final double radius;
  double life;
  final double maxLife;
}

bool advanceEffects(
  List<PopPiece> pieces,
  List<BurstRing> rings,
  double dt,
) {
  if (pieces.isEmpty && rings.isEmpty) return false;
  const gravity = 520.0;
  for (final piece in pieces) {
    piece.life -= dt;
    piece.velocity = Offset(
      piece.velocity.dx,
      piece.velocity.dy + gravity * dt,
    );
    piece.position += piece.velocity * dt;
    piece.rotation += piece.spin * dt;
  }
  pieces.removeWhere((piece) => piece.life <= 0);

  for (final ring in rings) {
    ring.life -= dt;
  }
  rings.removeWhere((ring) => ring.life <= 0);
  return true;
}

const gameLoopInterval = Duration(milliseconds: 33);
const maxFrameDeltaSeconds = 0.05;

double calculateFrameDelta(Duration elapsed) =>
    (elapsed.inMicroseconds / Duration.microsecondsPerSecond)
        .clamp(0.0, maxFrameDeltaSeconds);

typedef PeriodicTimerFactory = Timer Function(
  Duration interval,
  void Function(Timer timer) callback,
);

class SinglePeriodicGameLoop {
  SinglePeriodicGameLoop({PeriodicTimerFactory? timerFactory})
      : _timerFactory = timerFactory ?? Timer.periodic;

  final PeriodicTimerFactory _timerFactory;
  Timer? _timer;

  bool get isRunning => _timer?.isActive ?? false;

  void start(Duration interval, void Function(Timer timer) callback) {
    stop();
    _timer = _timerFactory(interval, callback);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class BalloonGamePage extends StatefulWidget {
  const BalloonGamePage({super.key});

  @override
  State<BalloonGamePage> createState() => _BalloonGamePageState();
}

class _BalloonGamePageState extends State<BalloonGamePage>
    with WidgetsBindingObserver {
  static const _homeCoinBalance = 23450;
  static const _storeProducts = [
    StoreProduct(
        id: 'balloon-default',
        category: StoreCategory.balloon,
        name: '기본 풍선',
        price: 0,
        owned: true,
        equipped: true,
        previewType: StorePreviewType.balloon,
        previewData: Color(0xFFFF5C8A)),
    StoreProduct(
        id: 'balloon-a',
        category: StoreCategory.balloon,
        name: '특별 풍선 A',
        price: 500,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.balloon,
        previewData: Color(0xFF54A8FF)),
    StoreProduct(
        id: 'balloon-b',
        category: StoreCategory.balloon,
        name: '특별 풍선 B',
        price: 700,
        owned: true,
        equipped: false,
        previewType: StorePreviewType.balloon,
        previewData: Color(0xFF8B7CF6)),
    StoreProduct(
        id: 'pop-default',
        category: StoreCategory.popEffect,
        name: '기본 효과',
        price: 0,
        owned: true,
        equipped: true,
        previewType: StorePreviewType.effect,
        previewData: Color(0xFFFFC857)),
    StoreProduct(
        id: 'pop-a',
        category: StoreCategory.popEffect,
        name: '특별 효과 A',
        price: 300,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.effect,
        previewData: Color(0xFFFF6B9D)),
    StoreProduct(
        id: 'pop-b',
        category: StoreCategory.popEffect,
        name: '특별 효과 B',
        price: 700,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.effect,
        previewData: Color(0xFF7E57C2)),
    StoreProduct(
        id: 'background-default',
        category: StoreCategory.background,
        name: '기본 배경',
        price: 0,
        owned: true,
        equipped: true,
        previewType: StorePreviewType.background,
        previewData: Color(0xFF56CCFF)),
    StoreProduct(
        id: 'background-a',
        category: StoreCategory.background,
        name: '특별 배경 A',
        price: 800,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.background,
        previewData: Color(0xFF85D86A)),
    StoreProduct(
        id: 'background-b',
        category: StoreCategory.background,
        name: '특별 배경 B',
        price: 1200,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.background,
        previewData: Color(0xFFFFA45B)),
    StoreProduct(
        id: 'sound-default',
        category: StoreCategory.soundEffect,
        name: '기본 POP',
        price: 0,
        owned: true,
        equipped: true,
        previewType: StorePreviewType.sound,
        previewData: Color(0xFF42B8E8)),
    StoreProduct(
        id: 'sound-a',
        category: StoreCategory.soundEffect,
        name: '특별 효과음 A',
        price: 300,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.sound,
        previewData: Color(0xFF5CD6C0)),
    StoreProduct(
        id: 'sound-b',
        category: StoreCategory.soundEffect,
        name: '특별 효과음 B',
        price: 500,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.sound,
        previewData: Color(0xFFFF8A5B)),
    StoreProduct(
        id: 'music-default',
        category: StoreCategory.music,
        name: '기본 음악',
        price: 0,
        owned: true,
        equipped: true,
        previewType: StorePreviewType.music,
        previewData: Color(0xFF7354E8)),
    StoreProduct(
        id: 'music-a',
        category: StoreCategory.music,
        name: '특별 음악 A',
        price: 700,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.music,
        previewData: Color(0xFFFF6D9A)),
    StoreProduct(
        id: 'music-b',
        category: StoreCategory.music,
        name: '특별 음악 B',
        price: 1000,
        owned: false,
        equipped: false,
        previewType: StorePreviewType.music,
        previewData: Color(0xFFFFB300)),
  ];
  static const _stageClearDelay = Duration(milliseconds: 400);
  static const _bossClearDelay = Duration(seconds: 1);
  static const _colors = [
    Color(0xFFFF5C8A),
    Color(0xFFFFC857),
    Color(0xFF5CD6C0),
    Color(0xFF8B7CF6),
    Color(0xFFFF8A5B),
    Color(0xFF54A8FF),
    Color(0xFFFF7FDB),
  ];

  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _frameStopwatch = Stopwatch();
  final List<Balloon> _balloons = [];
  final List<PopPiece> _pieces = [];
  final List<BurstRing> _rings = [];
  int _effectsRevision = 0;
  final SinglePeriodicGameLoop _gameLoop = SinglePeriodicGameLoop();
  Timer? _stageTimer;
  Size _playArea = Size.zero;
  int _nextId = 0;
  int _score = 0;
  int _stage = 1;
  int _secondsLeft = 15;
  int _sectionStartStage = 1;
  GamePhase _phase = GamePhase.menu;
  final List<BossBalloon> _bosses = [];
  bool _secondSectionUnlocked = false;
  int _bestScore = 0;
  int _lastScore = 0;
  bool _isNewBest = false;
  bool _resultSaved = false;
  MainTab _mainTab = MainTab.home;
  bool _storeNavigationVisible = true;
  Timer? _storeNavigationRevealTimer;
  late final PageController _stagePageController;
  late final ValueNotifier<GameHeaderData> _headerData;
  late final Widget _gameHeader;
  int _stagePage = 0;

  StageConfig get _stageConfig => StageConfig.forStage(_stage);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondSectionUnlocked = ProgressStorage.isSecondSectionUnlocked();
    _bestScore = ProgressStorage.bestScore();
    _lastScore = ProgressStorage.lastScore();
    _stagePageController = PageController();
    _headerData = ValueNotifier(_createHeaderData());
    _gameHeader = GameHeader(
      data: _headerData,
      onPause: _pauseGame,
      onEnd: _confirmEndGame,
    );
  }

  GameHeaderData _createHeaderData() => GameHeaderData(
        stage: _stage,
        score: _score,
        remaining: _bosses.isNotEmpty ? _bosses.length : _balloons.length,
        secondsLeft: _secondsLeft,
        controlsEnabled: _phase == GamePhase.playing,
      );

  void _publishHeader() {
    final next = _createHeaderData();
    if (_headerData.value != next) _headerData.value = next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _pauseGame();
    }
  }

  void _startGame(int startStage) {
    _stopGameLoop();
    _stageTimer?.cancel();
    _storeNavigationRevealTimer?.cancel();
    _stopwatch.reset();
    _nextId = 0;
    _score = 0;
    _resultSaved = false;
    _isNewBest = false;
    _sectionStartStage = startStage;
    _stage = startStage;
    _secondsLeft = StageConfig.forStage(startStage).duration.inSeconds;
    _phase = GamePhase.playing;
    _balloons.clear();
    _pieces.clear();
    _rings.clear();
    _effectsRevision++;
    _bosses.clear();
    _startStage();
    _publishHeader();
    if (mounted) {
      setState(() {});
    }
  }

  void _startGameLoop() {
    _stopGameLoop();
    if (!mounted || _phase != GamePhase.playing) return;
    _frameStopwatch.start();
    _gameLoop.start(gameLoopInterval, _updateGame);
  }

  void _stopGameLoop() {
    _gameLoop.stop();
    _frameStopwatch
      ..stop()
      ..reset();
  }

  void _returnToMenu() {
    _stopGameLoop();
    _stageTimer?.cancel();
    _storeNavigationRevealTimer?.cancel();
    _stopwatch.stop();
    setState(() {
      _score = 0;
      _stage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
      _mainTab = MainTab.home;
      _storeNavigationVisible = true;
      _balloons.clear();
      _pieces.clear();
      _rings.clear();
      _bosses.clear();
    });
    _publishHeader();
  }

  void _recordResult() {
    if (_resultSaved) return;
    _resultSaved = true;
    _lastScore = _score;
    _isNewBest = ProgressStorage.saveScore(_score);
    _bestScore = ProgressStorage.bestScore();
  }

  void _pauseGame() {
    if (_phase != GamePhase.playing) return;
    _stopGameLoop();
    _stopwatch.stop();
    setState(() {
      _phase = GamePhase.paused;
    });
    _publishHeader();
  }

  void _resumeGame() {
    if (_phase != GamePhase.paused) return;
    _stopwatch.start();
    setState(() {
      _phase = GamePhase.playing;
    });
    _publishHeader();
    _startGameLoop();
  }

  Future<void> _confirmEndGame() async {
    if (_phase != GamePhase.playing) return;
    _pauseGame();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('게임 끝내기'),
        content: const Text('현재 게임을 끝내고 시작 화면으로 돌아갈까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('끝내기'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      _returnToMenu();
    } else {
      _resumeGame();
    }
  }

  void _startStage() {
    _stageTimer?.cancel();
    _phase = GamePhase.playing;
    _balloons.clear();
    _bosses.clear();

    if (_playArea == Size.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == GamePhase.playing && _balloons.isEmpty) {
          _startStage();
          setState(() {});
        }
      });
      return;
    }

    if (_stageConfig.isBoss) {
      _spawnBoss();
    } else {
      _spawnBalloons(_stageConfig.balloonCount);
    }
    _secondsLeft = _stageConfig.duration.inSeconds;
    _stopwatch
      ..reset()
      ..start();
    _publishHeader();
    _startGameLoop();
  }

  void _spawnBalloons(int count) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 48 + (_stage * 4.2) + _random.nextDouble() * 32;
      final size = 78 + _random.nextDouble() * 24;
      _balloons.add(
        Balloon(
          id: _nextId++,
          position: _randomPosition(size),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: _colors[_random.nextInt(_colors.length)],
          size: size,
          floatPhase: _random.nextDouble() * pi * 2,
          floatPower: 10 + _random.nextDouble() * 10,
          hp: _stageConfig.balloonHp,
          maxHp: _stageConfig.balloonHp,
        ),
      );
    }
  }

  void _spawnBoss() {
    final config = _stageConfig;
    final maxSize = _stage >= 20 ? 300.0 : 270.0;
    final minSize = _stage >= 20 ? 225.0 : 210.0;
    final size =
        min(_playArea.shortestSide * 0.62, maxSize).clamp(minSize, maxSize);
    for (var id = 0; id < config.bossCount; id++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = config.bossSpeed;
      _bosses.add(
        BossBalloon(
          id: id,
          position: _nonOverlappingBossPosition(size),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          size: size,
          maxHp: config.bossHp,
        ),
      );
    }
  }

  Offset _nonOverlappingBossPosition(double size) {
    for (var attempt = 0; attempt < 80; attempt++) {
      final candidate = _randomPosition(size);
      final candidateRect =
          Rect.fromLTWH(candidate.dx, candidate.dy, size, size);
      final overlaps = _bosses.any((boss) {
        final bossRect = Rect.fromLTWH(
          boss.position.dx,
          boss.position.dy,
          boss.size,
          boss.size,
        );
        return candidateRect.overlaps(bossRect.inflate(12));
      });
      if (!overlaps) return candidate;
    }
    final maxX = max(0.0, _playArea.width - size);
    final maxY = max(0.0, _playArea.height - size - 26);
    return _bosses.isEmpty ? Offset.zero : Offset(maxX, maxY);
  }

  Offset _randomPosition(double size) {
    final maxX = max(1.0, _playArea.width - size);
    final maxY = max(1.0, _playArea.height - size - 26);
    return Offset(_random.nextDouble() * maxX, _random.nextDouble() * maxY);
  }

  void _updateGame(Timer timer) {
    if (!mounted) return;

    final dt = calculateFrameDelta(_frameStopwatch.elapsed);
    _frameStopwatch
      ..reset()
      ..start();
    if (_phase == GamePhase.stageClear || _phase == GamePhase.bossClear) {
      _updateEffects(dt);
      setState(() {});
      return;
    }
    if (_phase != GamePhase.playing) return;

    _updateBalloons(dt);
    _updateBoss(dt);
    _updateEffects(dt);

    final remaining = _stageConfig.duration - _stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      _finishGame();
      return;
    }
    final secondsLeft = (remaining.inMilliseconds + 999) ~/ 1000;
    if (secondsLeft != _secondsLeft) {
      _secondsLeft = secondsLeft;
      _publishHeader();
    }
    setState(() {});
  }

  void _updateBalloons(double dt) {
    if (_phase != GamePhase.playing || _playArea == Size.zero) return;

    for (final balloon in _balloons) {
      balloon.floatPhase += dt * 2.4;
      final drift = Offset(0, sin(balloon.floatPhase) * balloon.floatPower);
      final next = balloon.position + (balloon.velocity * dt) + (drift * dt);
      balloon.position = _bounce(next, balloon.velocity, balloon.size, (v) {
        balloon.velocity = v;
      });
    }
  }

  void _updateBoss(double dt) {
    if (_phase != GamePhase.playing) return;

    for (final boss in _bosses) {
      boss.turnCooldown -= dt;
      if (boss.turnCooldown <= 0) {
        final speed = boss.velocity.distance;
        final angle = _random.nextDouble() * pi * 2;
        boss.velocity = Offset(cos(angle) * speed, sin(angle) * speed);
        final hpRatio = boss.hp / boss.maxHp;
        boss.turnCooldown = 0.24 + hpRatio * 0.38;
      }
      final next = boss.position + boss.velocity * dt;
      boss.position = _bounce(next, boss.velocity, boss.size, (velocity) {
        boss.velocity = velocity;
      });
    }
  }

  Offset _bounce(
    Offset next,
    Offset velocity,
    double size,
    ValueChanged<Offset> updateVelocity,
  ) {
    var x = next.dx;
    var y = next.dy;
    var vx = velocity.dx;
    var vy = velocity.dy;
    final maxX = max(0.0, _playArea.width - size);
    final maxY = max(0.0, _playArea.height - size - 26);

    if (x <= 0) {
      x = 0;
      vx = vx.abs();
    } else if (x >= maxX) {
      x = maxX;
      vx = -vx.abs();
    }

    if (y <= 0) {
      y = 0;
      vy = vy.abs();
    } else if (y >= maxY) {
      y = maxY;
      vy = -vy.abs();
    }

    updateVelocity(Offset(vx, vy));
    return Offset(x, y);
  }

  void _updateEffects(double dt) {
    if (advanceEffects(_pieces, _rings, dt)) _effectsRevision++;
  }

  void _popBalloon(Balloon balloon) {
    if (_phase != GamePhase.playing) return;

    if (balloon.hp > 1) {
      PopSound.playLightTap();
      setState(() {
        balloon.hp--;
        balloon.size *= 0.88;
      });
      return;
    }

    PopSound.play();
    final center =
        balloon.position + Offset(balloon.size / 2, balloon.size / 2);
    _spawnPieces(center, balloon.color, balloon.size, big: false);
    _spawnRing(center, balloon.color, balloon.size * 0.72);

    setState(() {
      final removed = _balloons.remove(balloon);
      if (!removed) return;
      balloon.hp = 0;
      if (_balloons.isEmpty) {
        _showStageClear();
      }
    });
    _publishHeader();
  }

  void _showStageClear() {
    _stopGameLoop();
    _stopwatch.stop();
    _score += _secondsLeft;
    _phase = GamePhase.stageClear;
    _publishHeader();
    _stageTimer?.cancel();
    _stageTimer = Timer(_stageClearDelay, () {
      if (!mounted || _phase != GamePhase.stageClear) return;
      setState(() {
        _stage++;
        _startStage();
      });
    });
  }

  void _hitBoss(BossBalloon boss) {
    if (_phase != GamePhase.playing || !_bosses.contains(boss)) return;

    PopSound.play();
    final center = boss.position + Offset(boss.size / 2, boss.size / 2);
    final hitColor = _bossColor(boss);
    _spawnPieces(center, hitColor, boss.size * 0.35, big: false);

    setState(() {
      boss.hp--;
      if (boss.hp <= 0) {
        _clearBoss(boss, center, hitColor);
        return;
      }
      boss.size *= 0.965;
      boss.velocity *= 1.075;
      final hpRatio = boss.hp / boss.maxHp;
      boss.turnCooldown = min(boss.turnCooldown, 0.18 + hpRatio * 0.28);
    });
    _publishHeader();
  }

  void _clearBoss(BossBalloon boss, Offset center, Color color) {
    final removed = _bosses.remove(boss);
    if (!removed) return;
    _score += 10;
    PopSound.playBossExplosion();
    _spawnPieces(center, color, 280, big: true);
    _spawnRing(center, const Color(0xFFFFD54F), 190);
    _spawnRing(center, const Color(0xFFFF5C8A), 250);
    if (_bosses.isNotEmpty) {
      _publishHeader();
      return;
    }

    _stopGameLoop();
    _stopwatch.stop();
    _score += _secondsLeft;
    _phase = GamePhase.bossClear;
    if (_stage == 10) {
      _secondSectionUnlocked = true;
      ProgressStorage.unlockSecondSection();
    }
    _publishHeader();
    _stageTimer?.cancel();
    _stageTimer = Timer(_bossClearDelay, () {
      if (!mounted || _phase != GamePhase.bossClear) return;
      setState(() {
        if (_stage == 10 && _sectionStartStage == 1) {
          _stage = 11;
          _startStage();
        } else {
          _completeGame();
        }
      });
    });
  }

  void _completeGame() {
    _stopGameLoop();
    _stageTimer?.cancel();
    _stopwatch.stop();
    _recordResult();
    _phase = GamePhase.completed;
    _pieces.clear();
    _rings.clear();
    _effectsRevision++;
    _publishHeader();
  }

  void _spawnPieces(Offset center, Color color, double sourceSize,
      {required bool big}) {
    final count = big ? 28 : 6 + _random.nextInt(3);
    final speedBase = big ? 250.0 : 145.0;
    for (var i = 0; i < count; i++) {
      final angle = (pi * 2 / count) * i + (_random.nextDouble() - 0.5) * 0.65;
      final speed = speedBase + _random.nextDouble() * (big ? 280 : 145);
      _pieces.add(
        PopPiece(
          position: center,
          velocity:
              Offset(cos(angle) * speed, sin(angle) * speed - (big ? 120 : 65)),
          color: Color.lerp(color, Colors.white, _random.nextDouble() * 0.18)!,
          size: (big ? 11 : 8) + _random.nextDouble() * (big ? 17 : 10),
          rotation: _random.nextDouble() * pi,
          spin: (_random.nextDouble() - 0.5) * 12,
          life: big
              ? 1.4 + _random.nextDouble() * 0.7
              : 0.82 + _random.nextDouble() * 0.35,
          maxLife: big ? 2.1 : 1.15,
        ),
      );
    }
    _effectsRevision++;
  }

  void _spawnRing(Offset center, Color color, double radius) {
    _rings.add(
      BurstRing(
        center: center,
        color: color,
        radius: radius,
        life: 0.38,
        maxLife: 0.38,
      ),
    );
    _effectsRevision++;
  }

  void _finishGame() {
    _stopGameLoop();
    _stageTimer?.cancel();
    _stopwatch.stop();
    _frameStopwatch.stop();
    _recordResult();
    setState(() {
      _secondsLeft = 0;
      _phase = GamePhase.gameOver;
      _balloons.clear();
      _bosses.clear();
    });
    _publishHeader();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopGameLoop();
    _stageTimer?.cancel();
    _storeNavigationRevealTimer?.cancel();
    _stopwatch.stop();
    _headerData.dispose();
    _stagePageController.dispose();
    super.dispose();
  }

  // Kept for the upcoming settings screen.
  // ignore: unused_element
  Future<void> _confirmProgressReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진행 초기화'),
        content: const Text('저장된 진행 상태를 초기화할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    ProgressStorage.clear();
    setState(() {
      _secondSectionUnlocked = false;
      _bestScore = 0;
      _lastScore = 0;
      _isNewBest = false;
      _score = 0;
      _stage = 1;
      _sectionStartStage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
    });
  }

  Widget _buildStartScreen() {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/sky_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/forest_back.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/ground_road.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          const Positioned.fill(child: NatureLeftLayer()),
          const Positioned.fill(child: NatureRightLayer()),
          const Positioned.fill(child: GrassFrontLayer()),
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MenuBalloonPainter(
                  progress: 0.35,
                  indices: [2, 3, 6, 7],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: HomeFloatingBalloons()),
          SafeArea(
            minimum: const EdgeInsets.all(4),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 520,
                    height: 950,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 5,
                          left: 10,
                          right: 10,
                          height: 38,
                          child: _mainTopOverlay(),
                        ),
                        Positioned(
                          top: 18,
                          left: 55,
                          right: 55,
                          height: 300,
                          child: _buildPoppopLogo(),
                        ),
                        Positioned(
                          top: 316,
                          left: 54,
                          right: 54,
                          height: 88,
                          child: _recordBoard(),
                        ),
                        Positioned(
                          top: 418,
                          left: 45,
                          right: 45,
                          height: 300,
                          child: PageView(
                            controller: _stagePageController,
                            onPageChanged: (page) =>
                                setState(() => _stagePage = page),
                            children: [
                              _stagePair(
                                leftTitle: '1 ~ 10',
                                rightTitle: '11 ~ 20',
                                leftColor: const Color(0xFFFF4F7B),
                                rightColor: const Color(0xFF7354E8),
                                leftTap: () => _startGame(1),
                                rightTap: _secondSectionUnlocked
                                    ? () => _startGame(11)
                                    : null,
                                rightLocked: !_secondSectionUnlocked,
                              ),
                              _stagePair(
                                leftTitle: '21 ~ 30',
                                rightTitle: '31 ~ 40',
                                leftColor: const Color(0xFF42B883),
                                rightColor: const Color(0xFF4D8EF7),
                                leftTap: null,
                                rightTap: null,
                                leftLocked: true,
                                rightLocked: true,
                              ),
                              _stagePair(
                                leftTitle: '41 ~ 50',
                                rightTitle: '51 ~ 60',
                                leftColor: const Color(0xFFFF9F43),
                                rightColor: const Color(0xFFE85D9E),
                                leftTap: null,
                                rightTap: null,
                                leftLocked: true,
                                rightLocked: true,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 727,
                          left: 0,
                          right: 0,
                          child: _pageIndicator(),
                        ),
                        Positioned(
                          top: 758,
                          left: 39,
                          right: 39,
                          height: 86,
                          child: _bottomMenu(selectedTab: MainTab.home),
                        ),
                        const Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Text(
                            'v0.6 UI REFRESH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF214D66),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.white,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: index == _stagePage ? 11 : 8,
            height: index == _stagePage ? 11 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == _stagePage
                  ? const Color(0xFFFF416C)
                  : Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x33004669)),
              boxShadow: const [
                BoxShadow(color: Color(0x33004669), offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      );

  Widget _mainTopOverlay() => Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _homeCoinHud(_homeCoinBalance),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _homeSettingsButton(),
          ),
        ],
      );

  Widget _homeCoinHud(int coins) => Container(
        key: const ValueKey('home-coin-hud'),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF23C7CAA), Color(0xF2245D8C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x88FFFFFF), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55003366),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFD43B),
              size: 25,
              shadows: [Shadow(color: Color(0x66A35A00), offset: Offset(0, 2))],
            ),
            const SizedBox(width: 6),
            Text(
              _formatCoinAmount(coins),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0x66002D51), offset: Offset(0, 2))
                ],
              ),
            ),
          ],
        ),
      );

  Widget _homeSettingsButton() => Material(
        color: const Color(0xF22D70A0),
        elevation: 4,
        shadowColor: const Color(0x55003366),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: const ValueKey('home-settings-button'),
          onTap: _onSettingsPressed,
          borderRadius: BorderRadius.circular(13),
          child: const SizedBox(
            width: 40,
            height: 38,
            child: Icon(Icons.settings_rounded, color: Colors.white, size: 26),
          ),
        ),
      );

  String _formatCoinAmount(int coins) {
    final digits = coins.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) result.write(',');
      result.write(digits[index]);
    }
    return result.toString();
  }

  Widget _buildPoppopLogo() => CustomPaint(
        painter: const LogoFestivalPainter(progress: 0.35),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 24,
              child: _logoLine(
                'POP',
                const [
                  Color(0xFFFFFF72),
                  Color(0xFFFFC400),
                  Color(0xFFFF8A00),
                ],
                const Color(0xFFD96500),
                isLowerLine: false,
              ),
            ),
            Positioned(
              top: 119,
              child: _logoLine(
                'POP',
                const [
                  Color(0xFFFFB5C2),
                  Color(0xFFFF5275),
                  Color(0xFFE91E63),
                ],
                const Color(0xFFAD174F),
                isLowerLine: true,
              ),
            ),
            Positioned(
              bottom: 7,
              width: 278,
              height: 55,
              child: CustomPaint(
                painter: const RibbonPainter(),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      '터치해서 터뜨려!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        shadows: [
                          Shadow(
                            color: Color(0xAA3E116F),
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _logoLine(String text, List<Color> colors, Color depthColor,
      {required bool isLowerLine}) {
    const style = TextStyle(
      height: 0.88,
      letterSpacing: -3,
      fontSize: 114,
      fontWeight: FontWeight.w900,
      fontFamily: 'Arial Rounded MT Bold',
      fontFamilyFallback: ['Arial', 'sans-serif'],
    );
    return SizedBox(
      width: 380,
      height: 120,
      child: Transform.scale(
        scaleX: 1.10,
        scaleY: 0.94,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final isCenter = index == 1;
            final top = isCenter ? 0.0 : (isLowerLine ? 10.0 : 12.0);
            final left = isLowerLine
                ? const [32.0, 126.0, 220.0][index]
                : const [42.0, 130.0, 218.0][index];
            final degrees = isCenter
                ? 0.0
                : index == 0
                    ? (isLowerLine ? -3.0 : -4.0)
                    : (isLowerLine ? 3.0 : 4.0);
            return Positioned(
              left: left,
              top: top,
              width: 120,
              height: 120,
              child: Transform.rotate(
                angle: degrees * pi / 180,
                child: _logoLetter(
                  text[index],
                  style,
                  colors,
                  depthColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _logoLetter(
    String letter,
    TextStyle style,
    List<Color> colors,
    Color depthColor,
  ) =>
      Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(6, 19),
            child: Text(
              letter,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 21
                  ..strokeJoin = StrokeJoin.round
                  ..strokeCap = StrokeCap.round
                  ..color = const Color(0xFF123C67),
                shadows: const [
                  Shadow(
                    color: Color(0x66001F3A),
                    offset: Offset(4, 8),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(3, 12),
            child: Text(
              letter,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 15
                  ..strokeJoin = StrokeJoin.round
                  ..strokeCap = StrokeCap.round
                  ..color = depthColor,
              ),
            ),
          ),
          Text(
            letter,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 16
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0x55002B4D),
                  offset: Offset(5, 13),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: const [0, 0.55, 1],
            ).createShader(bounds),
            child: Text(
              letter,
              style: style.copyWith(color: Colors.white),
            ),
          ),
          Transform.translate(
            offset: const Offset(-2, -4),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBFFFFFFF),
                  Color(0x32FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.32, 0.58],
              ).createShader(bounds),
              child: Text(
                letter,
                style: style.copyWith(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 23,
            left: 35,
            child: Container(
              width: 34,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _stagePair({
    required String leftTitle,
    required String rightTitle,
    required Color leftColor,
    required Color rightColor,
    required VoidCallback? leftTap,
    required VoidCallback? rightTap,
    bool leftLocked = false,
    bool rightLocked = false,
  }) =>
      Row(
        children: [
          Expanded(
            child: _stagePanel(
              title: leftTitle,
              subtitle:
                  leftTitle.startsWith('1 ') ? '기본 풍선 · 보스 도전!' : 'COMING SOON',
              color: leftColor,
              locked: leftLocked,
              onTap: leftTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _stagePanel(
              title: rightTitle,
              subtitle: rightTitle.startsWith('11 ')
                  ? '2회 터치 풍선 · 더블 보스!'
                  : 'COMING SOON',
              color: rightColor,
              locked: rightLocked,
              onTap: rightTap,
            ),
          ),
        ],
      );

  Widget _stagePanel({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool locked = false,
  }) {
    final panelColor = locked ? const Color(0xFF607DA8) : color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? const [Color(0xFFD6E2F2), Color(0xFF9DB3CB)]
                  : [
                      Color.lerp(panelColor, Colors.white, 0.76)!,
                      Color.lerp(panelColor, Colors.white, 0.36)!,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5525495C),
                blurRadius: 10,
                offset: Offset(0, 7),
              ),
              BoxShadow(
                color: Color(0x66FFFFFF),
                blurRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: StageCardLandscapePainter(
                      tint: panelColor,
                      locked: locked,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: panelColor,
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'STAGE',
                        style: TextStyle(
                          color: panelColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF244F68),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 82,
                        height: 98,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(78, 96),
                              painter: BalloonPainter(color: panelColor),
                            ),
                            if (locked)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xEFFFFFFF),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x55002F4D),
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF385B78),
                                  size: 34,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55002A43),
                              blurRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          key: ValueKey(
                            title.startsWith('1 ')
                                ? 'start-section-1'
                                : title.startsWith('11 ')
                                    ? 'start-section-2'
                                    : 'start-$title',
                          ),
                          onPressed: onTap,
                          icon: Icon(
                            locked
                                ? Icons.lock_rounded
                                : Icons.play_arrow_rounded,
                            size: 25,
                          ),
                          label: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(locked ? '잠김' : '시작하기'),
                              if (title.startsWith('1 ') ||
                                  title.startsWith('11 '))
                                Opacity(
                                  opacity: 0,
                                  child: Text(
                                    title.startsWith('1 ')
                                        ? '1~10 STAGE 시작'
                                        : locked
                                            ? '11~20 STAGE 시작 🔒'
                                            : '11~20 STAGE 시작',
                                  ),
                                ),
                            ],
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: panelColor,
                            disabledBackgroundColor: const Color(0xFF385B78),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (title.startsWith('1 '))
          Positioned(
            top: -7,
            left: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF416C),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55391B2B),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                '추천!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recordBoard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF7EC)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFFDF8), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55204A5F),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _recordTile('BEST SCORE', _bestScore, _isNewBest),
            Container(
              width: 1.5,
              height: 54,
              color: const Color(0xFFE6D8CB),
            ),
            _recordTile('LAST SCORE', _lastScore, false),
          ],
        ),
      );

  Widget _recordTile(String label, int score, bool isNew) => Expanded(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: label.startsWith('BEST')
                          ? const [Color(0xFFFFED58), Color(0xFFFF9800)]
                          : const [Color(0xFF8DEBFF), Color(0xFF2688E8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44003D63),
                        blurRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    label.startsWith('BEST')
                        ? Icons.emoji_events_rounded
                        : Icons.assignment_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF244C67),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.05,
                        color: Color(0xFF244C67),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isNew)
              Positioned(
                top: -5,
                right: -5,
                child: Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF416C),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x443A1230),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _bottomMenu({required MainTab selectedTab}) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                key: const ValueKey('home-nav-home'),
                icon: Icons.home_rounded,
                label: '홈',
                selected: selectedTab == MainTab.home,
                selectionKey: selectedTab == MainTab.home
                    ? const ValueKey('home-nav-selected-home')
                    : null,
                onTap: _onHomeMenuTap,
              ),
              _navItem(
                key: const ValueKey('home-nav-shop'),
                icon: Icons.storefront_rounded,
                label: '상점',
                selected: selectedTab == MainTab.store,
                selectionKey: selectedTab == MainTab.store
                    ? const ValueKey('home-nav-selected-store')
                    : null,
                onTap: _onShopMenuTap,
              ),
              _navItem(
                key: const ValueKey('home-nav-ranking'),
                icon: Icons.emoji_events_rounded,
                label: '랭킹',
                onTap: _onRankingMenuTap,
              ),
            ],
          ),
        ),
      );

  Widget _navItem({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Key? selectionKey,
  }) =>
      InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          key: selectionKey,
          width: 96,
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? const [Color(0xFFFF91B4), Color(0xFFFF4F7B)]
                  : const [Color(0xFFFFFFFF), Color(0xFFFFF5E8)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? const Color(0xFFFFD3E1) : const Color(0xFFFFFDF8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x66A92A54)
                    : const Color(0x4D17485F),
                blurRadius: 7,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF378BCA),
                size: 37,
                shadows: const [
                  Shadow(
                    color: Color(0x33002C4E),
                    offset: Offset(0, 3),
                    blurRadius: 3,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF244B62),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  shadows: selected
                      ? const [
                          Shadow(color: Color(0x55002C4E), offset: Offset(0, 1))
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      );

  void _onSettingsPressed() => _showComingSoon('설정 준비 중');

  void _onHomeMenuTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _storeNavigationRevealTimer?.cancel();
    if (_mainTab != MainTab.home) setState(() => _mainTab = MainTab.home);
  }

  void _onShopMenuTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _storeNavigationRevealTimer?.cancel();
    if (_mainTab != MainTab.store) {
      setState(() {
        _mainTab = MainTab.store;
        _storeNavigationVisible = true;
      });
    }
  }

  bool _onStoreScrollNotification(ScrollNotification notification) {
    if (_mainTab != MainTab.store) return false;
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _storeNavigationRevealTimer?.cancel();
      _setStoreNavigationVisible(true);
      return false;
    }
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        _storeNavigationRevealTimer?.cancel();
        _setStoreNavigationVisible(false);
      } else if (delta < 0) {
        _storeNavigationRevealTimer?.cancel();
        _setStoreNavigationVisible(true);
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _storeNavigationRevealTimer?.cancel();
        _setStoreNavigationVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        _storeNavigationRevealTimer?.cancel();
        _setStoreNavigationVisible(true);
      } else {
        _scheduleStoreNavigationReveal();
      }
    } else if (notification is ScrollEndNotification) {
      _scheduleStoreNavigationReveal();
    }
    return false;
  }

  void _setStoreNavigationVisible(bool visible) {
    if (!mounted || _storeNavigationVisible == visible) return;
    setState(() => _storeNavigationVisible = visible);
  }

  void _scheduleStoreNavigationReveal() {
    _storeNavigationRevealTimer?.cancel();
    _storeNavigationRevealTimer = Timer(const Duration(milliseconds: 950), () {
      if (mounted && _mainTab == MainTab.store) {
        _setStoreNavigationVisible(true);
      }
    });
  }

  void _onRankingMenuTap() => _showComingSoon('랭킹 준비 중');

  void _showComingSoon(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
  }

  Widget _buildShopScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 38, child: _mainTopOverlay()),
                const SizedBox(height: 10),
                const Text(
                  '상점',
                  key: ValueKey('store-title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF4F7B),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.white, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onStoreScrollNotification,
                    child: ListView(
                      key: const ValueKey('store-vertical-scroll'),
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 116),
                      children: [
                        _storeSection(
                          category: StoreCategory.balloon,
                          title: '풍선 모양',
                          icon: Icons.circle_outlined,
                        ),
                        _storeSection(
                          category: StoreCategory.popEffect,
                          title: '터짐 효과',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        _storeSection(
                          category: StoreCategory.background,
                          title: '배경',
                          icon: Icons.landscape_rounded,
                        ),
                        _storeSection(
                          category: StoreCategory.soundEffect,
                          title: '효과음',
                          icon: Icons.volume_up_rounded,
                        ),
                        _storeSection(
                          category: StoreCategory.music,
                          title: '배경음악',
                          icon: Icons.music_note_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 86,
              child: IgnorePointer(
                ignoring: !_storeNavigationVisible,
                child: AnimatedSlide(
                  key: const ValueKey('store-bottom-nav-slide'),
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutCubic,
                  offset: _storeNavigationVisible
                      ? Offset.zero
                      : const Offset(0, 1.18),
                  child: AnimatedOpacity(
                    key: const ValueKey('store-bottom-nav-opacity'),
                    duration: const Duration(milliseconds: 170),
                    opacity: _storeNavigationVisible ? 1 : 0,
                    child: _bottomMenu(selectedTab: MainTab.store),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeSection({
    required StoreCategory category,
    required String title,
    required IconData icon,
  }) =>
      StoreCategorySection(
        category: category,
        title: title,
        icon: icon,
        products: _storeProducts
            .where((product) => product.category == category)
            .toList(growable: false),
        onProductPressed: _onStoreProductPressed,
      );

  void _onStoreProductPressed(StoreProduct product) {
    final message = product.equipped
        ? '${product.name} 사용 중'
        : product.owned
            ? '${product.name} 적용 기능 준비 중'
            : '${product.name} 구매 기능 준비 중';
    _showComingSoon(message);
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == GamePhase.menu) {
      return _mainTab == MainTab.store
          ? _buildShopScreen()
          : _buildStartScreen();
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF77D5FF), Color(0xFFDDF7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _gameHeader,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final newSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    if (_playArea == Size.zero) {
                      _playArea = newSize;
                      if (_phase == GamePhase.playing &&
                          _balloons.isEmpty &&
                          _bosses.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              _phase == GamePhase.playing &&
                              _balloons.isEmpty &&
                              _bosses.isEmpty) {
                            setState(_startStage);
                          }
                        });
                      }
                    } else if (_playArea != newSize) {
                      _playArea = newSize;
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned.fill(child: PlaySky()),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              key: const ValueKey('effects-boundary'),
                              child: CustomPaint(
                                painter: EffectsPainter(
                                  pieces: _pieces,
                                  rings: _rings,
                                  revision: _effectsRevision,
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (final balloon in _balloons) _buildBalloon(balloon),
                        for (final boss in _bosses) _buildBoss(boss),
                        if (_phase == GamePhase.stageClear)
                          _buildCenterMessage('Stage Clear!', null),
                        if (_phase == GamePhase.bossClear)
                          _buildCenterMessage('BOSS CLEAR!', null),
                        if (_phase == GamePhase.paused) _buildPauseOverlay(),
                        if (_phase == GamePhase.completed)
                          _buildGameOver(completed: true),
                        if (_phase == GamePhase.gameOver) _buildGameOver(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalloon(Balloon balloon) {
    return Positioned(
      key: ValueKey(balloon.id),
      left: balloon.position.dx,
      top: balloon.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _popBalloon(balloon),
        child: RepaintBoundary(
          key: ValueKey('balloon-raster-${balloon.id}'),
          child: SizedBox(
            width: balloon.size,
            height: balloon.size + 26,
            child: CustomPaint(
              painter: BalloonPainter(color: _balloonColor(balloon)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoss(BossBalloon boss) {
    return Positioned(
      key: ValueKey('boss-balloon-${boss.id}'),
      left: boss.position.dx,
      top: boss.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _hitBoss(boss),
        child: RepaintBoundary(
          key: ValueKey('boss-raster-${boss.id}'),
          child: SizedBox(
            width: boss.size,
            height: boss.size + 32,
            child: CustomPaint(
              painter: BossBalloonPainter(
                color: _bossColor(boss),
                hp: boss.hp,
                maxHp: boss.maxHp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _balloonColor(Balloon balloon) => Color.lerp(
        balloon.color,
        const Color(0xFF3B246B),
        (balloon.maxHp - balloon.hp) / balloon.maxHp * 0.38,
      )!;

  Color _bossColor(BossBalloon boss) => Color.lerp(
        _stage >= 20
            ? (boss.id == 0 ? const Color(0xFFFF6B6B) : const Color(0xFF64B5F6))
            : const Color(0xFF7E57C2),
        _stage >= 20
            ? (boss.id == 0 ? const Color(0xFFB71C1C) : const Color(0xFF0D47A1))
            : const Color(0xFFFF3D67),
        (boss.maxHp - boss.hp) / boss.maxHp,
      )!;

  Widget _buildCenterMessage(String title, String? subtitle) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFFC857), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6B9D),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7E57C2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x88004D73),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '일시정지',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7E57C2),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('resume-button'),
                  onPressed: _resumeGame,
                  icon: const Icon(Icons.play_arrow_rounded, size: 30),
                  label: const Text('계속하기'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _returnToMenu,
                  icon: const Icon(Icons.home_rounded, size: 28),
                  label: const Text('시작 화면으로'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 58),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver({bool completed = false}) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66004D73),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFC857), width: 5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    completed ? '게임 완료!' : '시간 끝!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '최종 점수',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF456477),
                    ),
                  ),
                  Text(
                    '$_score점',
                    style: const TextStyle(
                      fontSize: 46,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7E57C2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildResultAction(
                        key: const ValueKey('result-retry-button'),
                        icon: Icons.refresh_rounded,
                        label: '다시',
                        onTap: () => _startGame(_stage),
                      ),
                      const SizedBox(width: 42),
                      _buildResultAction(
                        key: const ValueKey('result-home-button'),
                        icon: Icons.home_rounded,
                        label: '홈',
                        onTap: _returnToMenu,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultAction({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: const Color(0xFFFF6B9D),
            elevation: 5,
            shadowColor: const Color(0x557E57C2),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              key: key,
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Icon(icon, color: Colors.white, size: 38),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF456477),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreCategorySection extends StatelessWidget {
  const StoreCategorySection({
    super.key,
    required this.category,
    required this.title,
    required this.icon,
    required this.products,
    required this.onProductPressed,
  });

  final StoreCategory category;
  final String title;
  final IconData icon;
  final List<StoreProduct> products;
  final ValueChanged<StoreProduct> onProductPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 9),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4ED),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF4F7B), size: 21),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  key: ValueKey('store-category-${category.name}'),
                  style: const TextStyle(
                    color: Color(0xFF244F68),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 218,
            child: ListView.separated(
              key: ValueKey('store-products-${category.name}'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => StoreProductCard(
                product: products[index],
                onPressed: () => onProductPressed(products[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    required this.onPressed,
  });

  final StoreProduct product;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('store-product-${product.id}'),
      width: 158,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFFDF8), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33204A5F),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: _preview()),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF244F68),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            child: product.equipped
                ? const Text(
                    '보유 완료',
                    style: TextStyle(
                      color: Color(0xFF58A886),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : product.owned
                    ? const Text(
                        '보유 중',
                        style: TextStyle(
                          color: Color(0xFF7354E8),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFB300),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.price}',
                            style: const TextStyle(
                              color: Color(0xFF6B5A36),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton.icon(
              key: ValueKey('store-action-${product.id}'),
              onPressed: product.equipped ? null : onPressed,
              icon: Icon(
                product.equipped
                    ? Icons.check_circle_rounded
                    : product.owned
                        ? Icons.checkroom_rounded
                        : Icons.shopping_bag_rounded,
                size: 17,
              ),
              label: Text(
                product.equipped
                    ? '사용 중'
                    : product.owned
                        ? '사용하기'
                        : '구매',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                backgroundColor: product.owned
                    ? const Color(0xFF7354E8)
                    : const Color(0xFFFF5C8A),
                disabledBackgroundColor: const Color(0xFF66C6A5),
                disabledForegroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    switch (product.previewType) {
      case StorePreviewType.balloon:
        return Center(
          child: SizedBox(
            width: 58,
            height: 76,
            child: CustomPaint(
                painter: BalloonPainter(color: product.previewData)),
          ),
        );
      case StorePreviewType.effect:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: product.previewData, size: 66),
              const Positioned(
                right: 16,
                top: 11,
                child: Icon(Icons.bolt_rounded,
                    color: Color(0xFFFFC857), size: 29),
              ),
            ],
          ),
        );
      case StorePreviewType.background:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [product.previewData, const Color(0xFF85D86A)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.landscape_rounded, color: Colors.white, size: 48),
          ),
        );
      case StorePreviewType.sound:
        return Center(
          child: Icon(Icons.graphic_eq_rounded,
              color: product.previewData, size: 70),
        );
      case StorePreviewType.music:
        return Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: product.previewData.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.music_note_rounded,
                color: product.previewData, size: 48),
          ),
        );
    }
  }
}

class GameHeaderData {
  const GameHeaderData({
    required this.stage,
    required this.score,
    required this.remaining,
    required this.secondsLeft,
    required this.controlsEnabled,
  });

  final int stage;
  final int score;
  final int remaining;
  final int secondsLeft;
  final bool controlsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHeaderData &&
          stage == other.stage &&
          score == other.score &&
          remaining == other.remaining &&
          secondsLeft == other.secondsLeft &&
          controlsEnabled == other.controlsEnabled;

  @override
  int get hashCode =>
      Object.hash(stage, score, remaining, secondsLeft, controlsEnabled);
}

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.data,
    required this.onPause,
    required this.onEnd,
  });

  final ValueListenable<GameHeaderData> data;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('game-header-boundary'),
      child: ValueListenableBuilder<GameHeaderData>(
        valueListenable: data,
        builder: (context, value, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Column(
            children: [
              const Text(
                'POPPOP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Color(0x55006699),
                      offset: Offset(0, 3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${value.stage} STAGE',
                style: const TextStyle(
                  color: Color(0xFF5E35B1),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoPill('점수', '${value.score}', const Color(0xFFFFB300)),
                  const SizedBox(width: 10),
                  _infoPill(
                    '남은 풍선',
                    '${value.remaining}',
                    const Color(0xFF7E57C2),
                  ),
                  const SizedBox(width: 10),
                  _infoPill(
                    '시간',
                    '${value.secondsLeft}',
                    value.secondsLeft <= 5
                        ? Colors.redAccent
                        : const Color(0xFF26A69A),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('pause-button'),
                    onPressed: value.controlsEnabled ? onPause : null,
                    icon: const Icon(Icons.pause_rounded, size: 25),
                    label: const Text('일시정지'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(132, 50),
                      backgroundColor: const Color(0xFF7E57C2),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const ValueKey('end-button'),
                    onPressed: value.controlsEnabled ? onEnd : null,
                    icon: const Icon(Icons.stop_circle_rounded, size: 25),
                    label: const Text('끝내기'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      backgroundColor: const Color(0xFFFF7043),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(String label, String value, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22004666),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label  $value',
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class PlaySky extends StatelessWidget {
  const PlaySky({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      key: ValueKey('play-sky-boundary'),
      child: CustomPaint(painter: SkyPainter()),
    );
  }
}

class BalloonPainter extends CustomPainter {
  const BalloonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final balloonHeight = size.height - 26;
    final body = Rect.fromLTWH(3, 0, size.width - 6, balloonHeight - 9);
    canvas.drawOval(
      body.shift(const Offset(3, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.42),
        radius: 0.88,
        colors: [
          Color.lerp(color, Colors.white, 0.40)!,
          color,
          Color.lerp(color, Colors.black, 0.24)!,
        ],
        stops: const [0, 0.60, 1],
      ).createShader(body);
    canvas.drawOval(body, paint);
    canvas.drawOval(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final shine = Paint()..color = Colors.white.withValues(alpha: 0.70);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.22,
        balloonHeight * 0.15,
        size.width * 0.17,
        balloonHeight * 0.25,
      ),
      shine,
    );
    canvas.drawCircle(
      Offset(size.width * 0.36, balloonHeight * 0.13),
      size.width * 0.035,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    final knot = Path()
      ..moveTo(size.width / 2, balloonHeight - 11)
      ..lineTo(size.width / 2 - 8, balloonHeight + 5)
      ..lineTo(size.width / 2 + 8, balloonHeight + 5)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);

    final string = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final stringPath = Path()
      ..moveTo(size.width / 2, balloonHeight + 5)
      ..quadraticBezierTo(
        size.width * 0.68,
        balloonHeight + 15,
        size.width * 0.47,
        size.height,
      );
    canvas.drawPath(stringPath, string);
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) =>
      oldDelegate.color != color;
}

class BossBalloonPainter extends CustomPainter {
  const BossBalloonPainter({
    required this.color,
    required this.hp,
    required this.maxHp,
  });

  final Color color;
  final int hp;
  final int maxHp;

  @override
  void paint(Canvas canvas, Size size) {
    final balloonHeight = size.height - 32;
    final body = Rect.fromLTWH(5, 0, size.width - 10, balloonHeight - 14);
    final paint = Paint()..color = color;
    canvas.drawOval(body, paint);

    final shine = Paint()..color = Colors.white.withValues(alpha: 0.48);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.22,
        balloonHeight * 0.12,
        size.width * 0.17,
        balloonHeight * 0.24,
      ),
      shine,
    );

    final knot = Path()
      ..moveTo(size.width / 2, balloonHeight - 14)
      ..lineTo(size.width / 2 - 16, balloonHeight + 10)
      ..lineTo(size.width / 2 + 16, balloonHeight + 10)
      ..close();
    canvas.drawPath(knot, paint);

    final barWidth = size.width * 0.62;
    final barLeft = size.width * 0.19;
    final barTop = size.height - 16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, 11),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth * hp / maxHp, 11),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFFD54F),
    );
  }

  @override
  bool shouldRepaint(covariant BossBalloonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.hp != hp ||
      oldDelegate.maxHp != maxHp;
}

class EffectsPainter extends CustomPainter {
  const EffectsPainter({
    required this.pieces,
    required this.rings,
    required this.revision,
  });

  final List<PopPiece> pieces;
  final List<BurstRing> rings;
  final int revision;

  int get pieceCount => pieces.length;
  int get ringCount => rings.length;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    for (final ring in rings) {
      final progress = 1 - (ring.life / ring.maxLife).clamp(0.0, 1.0);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      ringPaint
        ..color = ring.color.withValues(alpha: opacity * 0.75)
        ..strokeWidth = 5 * opacity;
      canvas.drawCircle(
        ring.center,
        ring.radius * progress,
        ringPaint,
      );
    }

    final fillPaint = Paint();
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final piece in pieces) {
      final opacity = (piece.life / piece.maxLife).clamp(0.0, 1.0);
      final pieceSize = Size(piece.size, piece.size * 1.3);
      final center = piece.position + pieceSize.center(Offset.zero);
      final path = Path()
        ..moveTo(pieceSize.width * 0.50, 0)
        ..lineTo(pieceSize.width, pieceSize.height * 0.32)
        ..lineTo(pieceSize.width * 0.72, pieceSize.height)
        ..lineTo(pieceSize.width * 0.22, pieceSize.height * 0.82)
        ..lineTo(0, pieceSize.height * 0.24)
        ..close();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(piece.rotation);
      canvas.translate(-pieceSize.width / 2, -pieceSize.height / 2);
      fillPaint.color = piece.color.withValues(alpha: opacity);
      highlightPaint.color = Colors.white.withValues(alpha: opacity * 0.28);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, highlightPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant EffectsPainter oldDelegate) =>
      oldDelegate.revision != revision;
}

class LogoFestivalPainter extends CustomPainter {
  const LogoFestivalPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    canvas.drawCircle(
      center,
      size.width * 0.47,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.84),
            const Color(0x55FFF59D),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.47),
        ),
    );

    for (var i = 0; i < 10; i++) {
      final angle = i * pi * 2 / 10 + progress * 0.055;
      final inner = size.width * 0.16;
      final outer = size.width * (i.isEven ? 0.53 : 0.47);
      final path = Path()
        ..moveTo(
          center.dx + cos(angle - 0.105) * inner,
          center.dy + sin(angle - 0.105) * inner,
        )
        ..lineTo(
          center.dx + cos(angle) * outer,
          center.dy + sin(angle) * outer,
        )
        ..lineTo(
          center.dx + cos(angle + 0.105) * inner,
          center.dy + sin(angle + 0.105) * inner,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? const Color(0xFFFFF176) : Colors.white)
              .withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    const particles = [
      (0.05, 0.18, Color(0xFFFFE22E), 13.0),
      (0.91, 0.23, Color(0xFFFFE22E), 11.0),
      (0.12, 0.52, Color(0xFFFF6BA1), 7.0),
      (0.88, 0.58, Color(0xFF8D5CFF), 8.0),
      (0.22, 0.05, Color(0xFFFFFFFF), 5.0),
      (0.76, 0.07, Color(0xFFFFFFFF), 5.0),
      (0.03, 0.73, Color(0xFF68E8F4), 6.0),
      (0.97, 0.73, Color(0xFFFF8B52), 6.0),
    ];
    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final pulse = 0.82 + sin(progress * pi * 2 + i) * 0.18;
      final point = Offset(
        size.width * particle.$1,
        size.height * particle.$2,
      );
      _drawStar(canvas, point, particle.$4 * pulse, particle.$3);
    }

    _drawFirework(
      canvas,
      Offset(size.width * 0.10, size.height * 0.34),
      18,
      const Color(0xFFFFE13B),
    );
    _drawFirework(
      canvas,
      Offset(size.width * 0.90, size.height * 0.42),
      15,
      const Color(0xFFFF70A7),
    );

    for (var i = 0; i < 10; i++) {
      final angle = i * 2.4;
      final point = Offset(
        center.dx + cos(angle) * size.width * (0.33 + (i % 3) * 0.055),
        center.dy + sin(angle) * size.height * (0.31 + (i % 2) * 0.08),
      );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: i.isEven ? 5 : 9,
            height: i.isEven ? 13 : 5,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color = [
            const Color(0xFFFF4F83),
            const Color(0xFFFFE13B),
            const Color(0xFF7E57E8),
            const Color(0xFF58E0D1),
          ][i % 4],
      );
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = center + Offset(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x44003B62),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawFirework(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + progress * 0.08;
      final inner = center + Offset(cos(angle), sin(angle)) * radius * 0.45;
      final outer = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(inner, outer, paint);
      canvas.drawCircle(outer, 2.2, Paint()..color = Colors.white);
    }
    canvas.drawCircle(
      center,
      3.2,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant LogoFestivalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class RibbonPainter extends CustomPainter {
  const RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()..color = const Color(0x663A126F);
    final leftTail = Path()
      ..moveTo(24, 15)
      ..lineTo(0, 25)
      ..lineTo(17, 37)
      ..lineTo(13, 49)
      ..lineTo(52, 42)
      ..close();
    final rightTail = Path()
      ..moveTo(size.width - 24, 15)
      ..lineTo(size.width, 25)
      ..lineTo(size.width - 17, 37)
      ..lineTo(size.width - 13, 49)
      ..lineTo(size.width - 52, 42)
      ..close();
    canvas.drawPath(leftTail.shift(const Offset(0, 4)), shadow);
    canvas.drawPath(rightTail.shift(const Offset(0, 4)), shadow);
    canvas.drawPath(leftTail, Paint()..color = const Color(0xFF6E2FC1));
    canvas.drawPath(rightTail, Paint()..color = const Color(0xFF6E2FC1));

    final center = RRect.fromRectAndRadius(
      Rect.fromLTWH(25, 4, size.width - 50, 43),
      const Radius.circular(15),
    );
    canvas.drawRRect(center.shift(const Offset(0, 5)), shadow);
    canvas.drawRRect(
      center,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB75AEE), Color(0xFF7132CC)],
        ).createShader(center.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 8, size.width - 80, 7),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StageCardLandscapePainter extends CustomPainter {
  const StageCardLandscapePainter({
    required this.tint,
    required this.locked,
  });

  final Color tint;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.57;
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: locked
              ? const [Color(0x6699B7CE), Color(0x99738FA8)]
              : const [Color(0x667BCB7A), Color(0xAA4FAE5A)],
        ).createShader(Rect.fromLTWH(0, horizon, size.width, size.height)),
    );

    final hill = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.52,
        size.height * 0.69,
      )
      ..quadraticBezierTo(
        size.width * 0.77,
        size.height * 0.54,
        size.width,
        size.height * 0.67,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hill,
      Paint()
        ..color = locked ? const Color(0x886F91AA) : const Color(0xAA70C968),
    );

    final path = Path()
      ..moveTo(size.width * 0.47, horizon)
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.70,
        size.width * 0.37,
        size.height * 0.86,
        size.width * 0.28,
        size.height,
      )
      ..lineTo(size.width * 0.77, size.height)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.84,
        size.width * 0.57,
        size.height * 0.69,
        size.width * 0.53,
        horizon,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = locked ? const Color(0x558BA1B0) : const Color(0x77FFE09B),
    );

    for (var i = 0; i < 7; i++) {
      final x = (0.08 + i * 0.145) * size.width;
      final y = horizon + (i % 3) * 15;
      final scale = 0.55 + (i % 3) * 0.12;
      canvas.drawRect(
        Rect.fromLTWH(x - 2, y + 13 * scale, 4, 15 * scale),
        Paint()..color = const Color(0x99744C2C),
      );
      canvas.drawCircle(
        Offset(x, y + 8 * scale),
        14 * scale,
        Paint()
          ..color = locked ? const Color(0x887B95A5) : const Color(0xBB58B95D),
      );
      canvas.drawCircle(
        Offset(x - 7 * scale, y + 11 * scale),
        9 * scale,
        Paint()
          ..color = locked ? const Color(0x887B95A5) : const Color(0xBB7CD667),
      );
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant StageCardLandscapePainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.locked != locked;
}

class NatureLeftLayer extends StatefulWidget {
  const NatureLeftLayer({super.key});

  @override
  State<NatureLeftLayer> createState() => _NatureLeftLayerState();
}

class _NatureLeftLayerState extends State<NatureLeftLayer> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  late final ImageStreamListener _imageListener = ImageStreamListener(
    (imageInfo, _) {
      if (mounted) setState(() => _imageInfo = imageInfo);
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/images/nature_assets.png',
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _imageStream?.key) return;
    _imageStream?.removeListener(_imageListener);
    _imageStream = stream..addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageInfo = _imageInfo;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (imageInfo == null) return const SizedBox.expand();
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: NatureLeftPainter(image: imageInfo.image),
          );
        },
      ),
    );
  }
}

class NatureLeftPainter extends CustomPainter {
  const NatureLeftPainter({required this.image});

  final ui.Image image;

  static const _grassLarge = Rect.fromLTWH(118, 78, 333, 162);
  static const _grassStrip = Rect.fromLTWH(885, 136, 429, 103);
  static const _grassTuft = Rect.fromLTWH(1080, 664, 194, 78);

  static const _yellowFlower = Rect.fromLTWH(229, 308, 155, 124);
  static const _whiteFlowerPatch = Rect.fromLTWH(416, 318, 222, 121);
  static const _dandelionPatch = Rect.fromLTWH(630, 290, 255, 150);
  static const _pinkFlower = Rect.fromLTWH(229, 480, 166, 129);
  static const _blueFlowerPatch = Rect.fromLTWH(426, 502, 207, 106);
  static const _whiteSmallPatch = Rect.fromLTWH(649, 500, 213, 103);

  static const _rockGray = Rect.fromLTWH(199, 659, 203, 86);
  static const _rockBrown = Rect.fromLTWH(395, 666, 215, 78);
  static const _rockFlat = Rect.fromLTWH(600, 659, 281, 87);
  static const _rockCluster = Rect.fromLTWH(875, 660, 230, 86);

  static const _objects = <NatureObjectData>[
    // Rocks are painted first so nearby grass can bury their lower edges.
    NatureObjectData(_rockFlat, 0.018, 0.000, 0.052),
    NatureObjectData(_rockBrown, 0.095, 0.012, 0.039),
    NatureObjectData(_rockGray, 0.185, 0.054, 0.026),
    NatureObjectData(_rockCluster, 0.265, 0.104, 0.014),

    // Grass: dense foreground, then progressively smaller and sparser.
    NatureObjectData(_grassLarge, -0.035, -0.012, 0.155),
    NatureObjectData(_grassStrip, 0.055, -0.004, 0.125),
    NatureObjectData(_grassLarge, 0.125, 0.018, 0.100),
    NatureObjectData(_grassStrip, 0.165, 0.042, 0.078),
    NatureObjectData(_grassTuft, 0.215, 0.070, 0.060),
    NatureObjectData(_grassLarge, 0.258, 0.096, 0.043),
    NatureObjectData(_grassTuft, 0.292, 0.118, 0.030),
    NatureObjectData(_grassStrip, 0.322, 0.139, 0.021),
    NatureObjectData(_grassTuft, 0.347, 0.154, 0.014),

    // Flowers remain small accents among the grass.
    NatureObjectData(_yellowFlower, 0.025, 0.050, 0.028),
    NatureObjectData(_blueFlowerPatch, 0.075, 0.072, 0.023),
    NatureObjectData(_pinkFlower, 0.115, 0.054, 0.020),
    NatureObjectData(_whiteSmallPatch, 0.148, 0.090, 0.017),
    NatureObjectData(_yellowFlower, 0.185, 0.105, 0.014),
    NatureObjectData(_blueFlowerPatch, 0.218, 0.116, 0.012),
    NatureObjectData(_pinkFlower, 0.245, 0.128, 0.010),
    NatureObjectData(_dandelionPatch, 0.277, 0.137, 0.008),
    NatureObjectData(_whiteFlowerPatch, 0.305, 0.148, 0.0065),
    NatureObjectData(_yellowFlower, 0.331, 0.157, 0.005),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
    for (final object in _objects) {
      final visualWidth = size.width * object.width;
      if (visualWidth < 4.5) continue;
      final visualHeight =
          visualWidth * object.source.height / object.source.width;
      final destination = Rect.fromLTWH(
        size.width * object.left,
        size.height - size.height * object.bottom - visualHeight,
        visualWidth,
        visualHeight,
      );
      canvas.drawImageRect(image, object.source, destination, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NatureLeftPainter oldDelegate) =>
      oldDelegate.image != image;
}

class NatureObjectData {
  const NatureObjectData(this.source, this.left, this.bottom, this.width);

  final Rect source;
  final double left;
  final double bottom;
  final double width;
}

class NatureRightLayer extends StatefulWidget {
  const NatureRightLayer({super.key});

  @override
  State<NatureRightLayer> createState() => _NatureRightLayerState();
}

class _NatureRightLayerState extends State<NatureRightLayer> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  late final ImageStreamListener _imageListener = ImageStreamListener(
    (imageInfo, _) {
      if (mounted) setState(() => _imageInfo = imageInfo);
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/images/nature_assets.png',
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _imageStream?.key) return;
    _imageStream?.removeListener(_imageListener);
    _imageStream = stream..addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageInfo = _imageInfo;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (imageInfo == null) return const SizedBox.expand();
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: NatureRightPainter(image: imageInfo.image),
          );
        },
      ),
    );
  }
}

class NatureRightPainter extends CustomPainter {
  const NatureRightPainter({required this.image});

  final ui.Image image;

  static const _grassLarge = Rect.fromLTWH(118, 78, 333, 162);
  static const _grassStrip = Rect.fromLTWH(885, 136, 429, 103);
  static const _grassTuft = Rect.fromLTWH(1080, 664, 194, 78);

  static const _yellowFlower = Rect.fromLTWH(229, 308, 155, 124);
  static const _whiteFlowerPatch = Rect.fromLTWH(416, 318, 222, 121);
  static const _dandelionPatch = Rect.fromLTWH(630, 290, 255, 150);
  static const _pinkFlower = Rect.fromLTWH(229, 480, 166, 129);
  static const _blueFlowerPatch = Rect.fromLTWH(426, 502, 207, 106);
  static const _whiteSmallPatch = Rect.fromLTWH(649, 500, 213, 103);

  static const _rockGray = Rect.fromLTWH(199, 659, 203, 86);
  static const _rockBrown = Rect.fromLTWH(395, 666, 215, 78);
  static const _rockFlat = Rect.fromLTWH(600, 659, 281, 87);
  static const _rockCluster = Rect.fromLTWH(875, 660, 230, 86);

  static const _objects = <NatureRightObjectData>[
    // A different rock order and spacing from Nature Left.
    NatureRightObjectData(_rockGray, 0.015, -0.002, 0.058),
    NatureRightObjectData(_rockCluster, 0.105, 0.010, 0.042),
    NatureRightObjectData(_rockFlat, 0.205, 0.050, 0.028),
    NatureRightObjectData(_rockBrown, 0.295, 0.100, 0.015),

    // Broader foreground, tapering toward the right edge of the distant road.
    NatureRightObjectData(_grassStrip, -0.040, -0.014, 0.160),
    NatureRightObjectData(_grassLarge, 0.045, -0.006, 0.135),
    NatureRightObjectData(_grassTuft, 0.135, 0.014, 0.105),
    NatureRightObjectData(_grassLarge, 0.180, 0.038, 0.082),
    NatureRightObjectData(_grassStrip, 0.235, 0.065, 0.062),
    NatureRightObjectData(_grassTuft, 0.282, 0.090, 0.045),
    NatureRightObjectData(_grassStrip, 0.320, 0.113, 0.031),
    NatureRightObjectData(_grassLarge, 0.350, 0.135, 0.022),
    NatureRightObjectData(_grassTuft, 0.374, 0.150, 0.014),

    // Flower accents use a new sequence and overlap pattern.
    NatureRightObjectData(_whiteSmallPatch, 0.035, 0.045, 0.026),
    NatureRightObjectData(_dandelionPatch, 0.085, 0.068, 0.022),
    NatureRightObjectData(_yellowFlower, 0.145, 0.052, 0.019),
    NatureRightObjectData(_pinkFlower, 0.165, 0.087, 0.017),
    NatureRightObjectData(_whiteFlowerPatch, 0.205, 0.102, 0.014),
    NatureRightObjectData(_blueFlowerPatch, 0.245, 0.113, 0.012),
    NatureRightObjectData(_dandelionPatch, 0.275, 0.124, 0.010),
    NatureRightObjectData(_yellowFlower, 0.310, 0.136, 0.008),
    NatureRightObjectData(_pinkFlower, 0.345, 0.147, 0.006),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
    for (final object in _objects) {
      final visualWidth = size.width * object.width;
      if (visualWidth < 4.5) continue;
      final visualHeight =
          visualWidth * object.source.height / object.source.width;
      final destination = Rect.fromLTWH(
        size.width - size.width * object.right - visualWidth,
        size.height - size.height * object.bottom - visualHeight,
        visualWidth,
        visualHeight,
      );
      canvas.drawImageRect(image, object.source, destination, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NatureRightPainter oldDelegate) =>
      oldDelegate.image != image;
}

class NatureRightObjectData {
  const NatureRightObjectData(this.source, this.right, this.bottom, this.width);

  final Rect source;
  final double right;
  final double bottom;
  final double width;
}

class GrassFrontLayer extends StatefulWidget {
  const GrassFrontLayer({super.key});

  @override
  State<GrassFrontLayer> createState() => _GrassFrontLayerState();
}

class _GrassFrontLayerState extends State<GrassFrontLayer> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  late final ImageStreamListener _imageListener = ImageStreamListener(
    (imageInfo, _) {
      if (mounted) setState(() => _imageInfo = imageInfo);
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/images/nature_assets.png',
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _imageStream?.key) return;
    _imageStream?.removeListener(_imageListener);
    _imageStream = stream..addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageInfo = _imageInfo;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (imageInfo == null) return const SizedBox.expand();
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: GrassFrontPainter(image: imageInfo.image),
          );
        },
      ),
    );
  }
}

class GrassFrontPainter extends CustomPainter {
  const GrassFrontPainter({required this.image});

  final ui.Image image;

  static const _grassLarge = Rect.fromLTWH(118, 78, 333, 162);
  static const _grassStrip = Rect.fromLTWH(885, 136, 429, 103);
  static const _grassTuft = Rect.fromLTWH(1080, 664, 194, 78);

  static const _yellowFlower = Rect.fromLTWH(229, 308, 155, 124);
  static const _pinkFlower = Rect.fromLTWH(229, 480, 166, 129);
  static const _blueFlowerPatch = Rect.fromLTWH(426, 502, 207, 106);
  static const _whiteSmallPatch = Rect.fromLTWH(649, 500, 213, 103);

  static const _rockGray = Rect.fromLTWH(199, 659, 203, 86);
  static const _rockBrown = Rect.fromLTWH(395, 666, 215, 78);
  static const _rockCluster = Rect.fromLTWH(875, 660, 230, 86);

  static const _objects = <GrassFrontObjectData>[
    // Rocks sit behind nearby grass so their bases feel embedded in the ground.
    GrassFrontObjectData(_rockCluster, 0.060, -0.003, 0.030),
    GrassFrontObjectData(_rockBrown, 0.770, -0.002, 0.028),
    GrassFrontObjectData(_rockGray, 0.910, -0.004, 0.024),

    // Foreground grass: high at both edges and low around the open road.
    GrassFrontObjectData(_grassLarge, -0.035, -0.022, 0.155),
    GrassFrontObjectData(_grassStrip, 0.045, -0.018, 0.125),
    GrassFrontObjectData(_grassTuft, 0.145, -0.010, 0.090),
    GrassFrontObjectData(_grassLarge, 0.245, -0.004, 0.060),
    GrassFrontObjectData(_grassStrip, 0.350, 0.000, 0.032),
    GrassFrontObjectData(_grassTuft, 0.430, -0.002, 0.020),
    GrassFrontObjectData(_grassLarge, 0.555, -0.003, 0.020),
    GrassFrontObjectData(_grassStrip, 0.620, 0.000, 0.035),
    GrassFrontObjectData(_grassTuft, 0.700, -0.005, 0.060),
    GrassFrontObjectData(_grassLarge, 0.785, -0.012, 0.095),
    GrassFrontObjectData(_grassTuft, 0.865, -0.018, 0.120),
    GrassFrontObjectData(_grassLarge, 0.945, -0.024, 0.145),

    // Four restrained flower accents are mixed into, rather than above, grass.
    GrassFrontObjectData(_yellowFlower, 0.090, 0.035, 0.018),
    GrassFrontObjectData(_blueFlowerPatch, 0.195, 0.028, 0.014),
    GrassFrontObjectData(_whiteSmallPatch, 0.730, 0.030, 0.016),
    GrassFrontObjectData(_pinkFlower, 0.875, 0.038, 0.015),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
    for (final object in _objects) {
      final visualWidth = size.width * object.width;
      if (visualWidth < 4.5) continue;
      final visualHeight =
          visualWidth * object.source.height / object.source.width;
      final destination = Rect.fromLTWH(
        size.width * object.left,
        size.height - size.height * object.bottom - visualHeight,
        visualWidth,
        visualHeight,
      );
      canvas.drawImageRect(image, object.source, destination, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GrassFrontPainter oldDelegate) =>
      oldDelegate.image != image;
}

class GrassFrontObjectData {
  const GrassFrontObjectData(this.source, this.left, this.bottom, this.width);

  final Rect source;
  final double left;
  final double bottom;
  final double width;
}

class HomeFloatingBalloons extends StatefulWidget {
  const HomeFloatingBalloons({super.key});

  @override
  State<HomeFloatingBalloons> createState() => _HomeFloatingBalloonsState();
}

class _HomeFloatingBalloonsState extends State<HomeFloatingBalloons>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _movingIndices = [0, 1, 4, 5];
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
      return;
    }
    _controller.stop(canceled: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final index in _movingIndices)
                  _HomeFloatingBalloon(
                    index: index,
                    area: area,
                    animation: _controller,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeFloatingBalloon extends StatelessWidget {
  const _HomeFloatingBalloon({
    required this.index,
    required this.area,
    required this.animation,
  });

  final int index;
  final Size area;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final diameter = MenuBalloonPainter.diameterFor(area, index);
    final center = MenuBalloonPainter.centerFor(area, index, 0.35);
    final canvasWidth = diameter * 1.6;
    final canvasHeight = diameter * 2.45;
    final amplitudes = <double>[6, 8, 7, 10];
    final cycles = <double>[2, 3, 2, 3];
    final phaseOffsets = <double>[0.0, 1.3, 2.6, 4.1];
    final slot = _HomeFloatingBalloonsState._movingIndices.indexOf(index);

    return Positioned(
      left: center.dx - canvasWidth / 2,
      top: center.dy - diameter * 0.65,
      width: canvasWidth,
      height: canvasHeight,
      child: AnimatedBuilder(
        animation: animation,
        child: RepaintBoundary(
          key: ValueKey('home-floating-balloon-$index'),
          child: CustomPaint(
            painter: MenuBalloonShapePainter(index: index),
          ),
        ),
        builder: (context, child) {
          final dy = sin(
                animation.value * pi * 2 * cycles[slot] + phaseOffsets[slot],
              ) *
              amplitudes[slot];
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
      ),
    );
  }
}

class MenuBalloonShapePainter extends CustomPainter {
  const MenuBalloonShapePainter({required this.index});

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = size.width / 1.6;
    MenuBalloonPainter.drawBalloon(
      canvas,
      Offset(size.width / 2, diameter * 0.65),
      diameter,
      MenuBalloonPainter._colors[index],
      index,
    );
  }

  @override
  bool shouldRepaint(covariant MenuBalloonShapePainter oldDelegate) =>
      oldDelegate.index != index;
}

class MenuBalloonPainter extends CustomPainter {
  const MenuBalloonPainter({
    required this.progress,
    this.indices = const [0, 1, 2, 3, 4, 5, 6, 7],
  });

  final double progress;
  final List<int> indices;

  static const _colors = [
    Color(0xFFFF4F83),
    Color(0xFF8157F2),
    Color(0xFFFFBE2E),
    Color(0xFF35C978),
    Color(0xFF3E9BFF),
    Color(0xFFFF784F),
    Color(0xFFFF63C4),
    Color(0xFF7B5AEF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final i in indices) {
      drawBalloon(
        canvas,
        centerFor(size, i, progress),
        diameterFor(size, i),
        _colors[i],
        i,
      );
    }
  }

  static double diameterFor(Size size, int index) =>
      (42.0 + (index % 3) * 14) * (size.width / 520).clamp(.72, 1.2);

  static Offset centerFor(Size size, int index, double progress) {
    final leftSide = index.isEven;
    final xBase = size.width *
        (leftSide ? 0.045 + (index % 3) * 0.025 : 0.955 - (index % 3) * 0.025);
    final wave = sin(progress * pi * 2 + index * 1.7) * size.width * 0.022;
    final travel = (progress * (0.18 + index * 0.012) + index * 0.121) % 1;
    return Offset(xBase + wave, size.height * (1.08 - travel * 1.16));
  }

  static void drawBalloon(
    Canvas canvas,
    Offset center,
    double diameter,
    Color color,
    int index,
  ) {
    final body = Rect.fromCenter(
      center: center,
      width: diameter,
      height: diameter * 1.22,
    );
    canvas.drawOval(
      body.shift(Offset(0, diameter * 0.10)),
      Paint()
        ..color = const Color(0x33002E4D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.42),
          radius: 0.83,
          colors: [
            Color.lerp(color, Colors.white, 0.36)!,
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(body),
    );
    canvas.drawOval(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, diameter * 0.035),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        body.left + diameter * 0.19,
        body.top + diameter * 0.14,
        diameter * 0.17,
        diameter * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      Offset(body.left + diameter * 0.39, body.top + diameter * 0.12),
      diameter * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    final knot = Path()
      ..moveTo(center.dx, body.bottom - 2)
      ..lineTo(center.dx - diameter * 0.10, body.bottom + diameter * 0.14)
      ..lineTo(center.dx + diameter * 0.10, body.bottom + diameter * 0.14)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
    final string = Path()
      ..moveTo(center.dx, body.bottom + diameter * 0.12)
      ..cubicTo(
        center.dx + (index.isEven ? 12 : -12),
        body.bottom + diameter * 0.45,
        center.dx - (index.isEven ? 8 : -8),
        body.bottom + diameter * 0.72,
        center.dx,
        body.bottom + diameter,
      );
    canvas.drawPath(
      string,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant MenuBalloonPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !listEquals(oldDelegate.indices, indices);
}

class MenuSceneryPainter extends CustomPainter {
  const MenuSceneryPainter({required this.progress});

  final double progress;

  static const _colors = [
    Color(0xFFFF4F83),
    Color(0xFF8157F2),
    Color(0xFFFFBE2E),
    Color(0xFF35C978),
    Color(0xFF3E9BFF),
    Color(0xFFFF784F),
    Color(0xFFFF63C4),
    Color(0xFF7B5AEF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.655;
    _drawForestSilhouette(canvas, size, horizon);

    final distantHill = Path()
      ..moveTo(0, size.height * 0.745)
      ..quadraticBezierTo(
        size.width * 0.17,
        size.height * 0.665,
        size.width * 0.37,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.61,
        size.height * 0.635,
        size.width,
        size.height * 0.715,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      distantHill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9CDB79), Color(0xFF74C95A)],
        ).createShader(
          Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
        ),
    );

    final treeScale = size.width / 520;
    _drawTree(
      canvas,
      Offset(size.width * 0.10, size.height * 0.715),
      treeScale * 1.48,
      muted: true,
    );
    _drawTree(
      canvas,
      Offset(size.width * 0.23, size.height * 0.705),
      treeScale * 1.10,
      muted: true,
    );
    _drawTree(
      canvas,
      Offset(size.width * 0.77, size.height * 0.695),
      treeScale * 1.32,
      muted: true,
    );
    _drawTree(
      canvas,
      Offset(size.width * 0.91, size.height * 0.72),
      treeScale * 1.62,
      muted: true,
    );

    final middleHill = Path()
      ..moveTo(0, size.height * 0.835)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.735,
        size.width * 0.52,
        size.height * 0.815,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.715,
        size.width,
        size.height * 0.795,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      middleHill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF85D86A), Color(0xFF6DB84F)],
        ).createShader(
          Rect.fromLTWH(0, size.height * 0.71, size.width, size.height * 0.29),
        ),
    );

    final nearHill = Path()
      ..moveTo(0, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.81,
        size.width * 0.46,
        size.height * 0.885,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.79,
        size.width,
        size.height * 0.865,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      nearHill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF74C95A), Color(0xFF55AD47)],
        ).createShader(
          Rect.fromLTWH(0, size.height * 0.79, size.width, size.height * 0.21),
        ),
    );

    final road = Path()
      ..moveTo(size.width * 0.488, horizon)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.73,
        size.width * 0.58,
        size.height * 0.79,
        size.width * 0.445,
        size.height * 0.865,
      )
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.91,
        size.width * 0.31,
        size.height * 0.96,
        size.width * 0.255,
        size.height,
      )
      ..lineTo(size.width * 0.745, size.height)
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.945,
        size.width * 0.64,
        size.height * 0.90,
        size.width * 0.585,
        size.height * 0.855,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.78,
        size.width * 0.53,
        size.height * 0.72,
        size.width * 0.512,
        horizon,
      )
      ..close();
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFC69A60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(5, size.width * 0.012)
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEBD2A7), Color(0xFFDDBB87)],
        ).createShader(
          Rect.fromLTWH(
            size.width * 0.24,
            horizon,
            size.width * 0.52,
            size.height - horizon,
          ),
        ),
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, size.width * 0.005),
    );

    _drawGrassTexture(canvas, size);
    const clusters = [
      (0.055, 0.875, 0.88, 7),
      (0.175, 0.935, 1.08, 10),
      (0.315, 0.865, 0.72, 6),
      (0.695, 0.875, 0.76, 7),
      (0.825, 0.925, 1.08, 11),
      (0.935, 0.845, 0.82, 8),
    ];
    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      _drawFlowerCluster(
        canvas,
        Offset(size.width * cluster.$1, size.height * cluster.$2),
        treeScale * cluster.$3,
        cluster.$4,
        i,
      );
    }

    for (var i = 0; i < 8; i++) {
      final diameter =
          (42.0 + (i % 3) * 14) * (size.width / 520).clamp(.72, 1.2);
      final leftSide = i.isEven;
      final xBase = size.width *
          (leftSide ? 0.045 + (i % 3) * 0.025 : 0.955 - (i % 3) * 0.025);
      final wave = sin(progress * pi * 2 + i * 1.7) * size.width * 0.022;
      final travel = (progress * (0.18 + i * 0.012) + i * 0.121) % 1;
      final y = size.height * (1.08 - travel * 1.16);
      final center = Offset(xBase + wave, y);
      _drawBalloon(canvas, center, diameter, _colors[i], i);
    }
  }

  void _drawForestSilhouette(Canvas canvas, Size size, double horizon) {
    final backPaint = Paint()..color = const Color(0xFF4F8460);
    final frontPaint = Paint()..color = const Color(0xFF3F7652);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        horizon + size.height * 0.018,
        size.width,
        size.height * 0.09,
      ),
      frontPaint,
    );
    for (var layer = 0; layer < 2; layer++) {
      final count = layer == 0 ? 17 : 14;
      final paint = layer == 0 ? backPaint : frontPaint;
      for (var i = 0; i < count; i++) {
        final x = size.width * ((i + (layer == 0 ? 0.2 : 0.65)) / count);
        final radius = size.width * (0.034 + ((i * 7 + layer * 3) % 4) * 0.006);
        final y = horizon +
            size.height * (layer == 0 ? 0.004 : 0.023) -
            radius * 0.46;
        canvas.drawRect(
          Rect.fromLTWH(
            x - radius * 0.10,
            y,
            radius * 0.20,
            radius * 1.85,
          ),
          Paint()..color = const Color(0x88635443),
        );
        canvas.drawCircle(Offset(x, y), radius, paint);
        canvas.drawCircle(
          Offset(x - radius * 0.62, y + radius * 0.24),
          radius * 0.72,
          paint,
        );
        canvas.drawCircle(
          Offset(x + radius * 0.62, y + radius * 0.20),
          radius * 0.70,
          paint,
        );
      }
    }
  }

  void _drawTree(
    Canvas canvas,
    Offset base,
    double scale, {
    bool muted = false,
  }) {
    final trunkColor =
        muted ? const Color(0xFF886B4B) : const Color(0xFF8F613C);
    final darkLeaf = muted ? const Color(0xFF5F9660) : const Color(0xFF3D9846);
    final midLeaf = muted ? const Color(0xFF75A76B) : const Color(0xFF4EAD50);
    final lightLeaf = muted ? const Color(0xFF89B778) : const Color(0xFF75CC5C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.dx - 5 * scale,
          base.dy - 38 * scale,
          10 * scale,
          42 * scale,
        ),
        Radius.circular(5 * scale),
      ),
      Paint()..color = trunkColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.dx - 2.5 * scale,
          base.dy - 36 * scale,
          2.5 * scale,
          35 * scale,
        ),
        Radius.circular(2 * scale),
      ),
      Paint()..color = Colors.white.withValues(alpha: muted ? 0.08 : 0.16),
    );
    canvas.drawCircle(
      base + Offset(0, -53 * scale),
      28 * scale,
      Paint()..color = midLeaf,
    );
    canvas.drawCircle(
      base + Offset(-21 * scale, -44 * scale),
      20 * scale,
      Paint()..color = lightLeaf,
    );
    canvas.drawCircle(
      base + Offset(22 * scale, -43 * scale),
      21 * scale,
      Paint()..color = darkLeaf,
    );
    canvas.drawCircle(
      base + Offset(-11 * scale, -68 * scale),
      19 * scale,
      Paint()..color = lightLeaf,
    );
    canvas.drawCircle(
      base + Offset(15 * scale, -66 * scale),
      18 * scale,
      Paint()..color = midLeaf,
    );
  }

  void _drawGrassTexture(Canvas canvas, Size size) {
    const grassColors = [
      Color(0xFF3F9E43),
      Color(0xFF6DB84F),
      Color(0xFF85D86A),
      Color(0xFF4EAC47),
    ];
    for (var i = 0; i < 54; i++) {
      final xRatio = (i * 0.173 + 0.03) % 1;
      final yRatio = 0.78 + (i * 0.067 % 0.215);
      final perspective = ((yRatio - 0.78) / 0.215).clamp(0.0, 1.0);
      final roadCenter =
          0.50 + sin(perspective * pi * 1.55) * 0.075 * perspective;
      final roadHalf = 0.025 + perspective * 0.225;
      if ((xRatio - roadCenter).abs() < roadHalf) continue;

      final origin = Offset(size.width * xRatio, size.height * yRatio);
      final blade = (3.0 + perspective * 8.0) * size.width / 520;
      final paint = Paint()
        ..color = grassColors[i % grassColors.length].withValues(alpha: 0.72)
        ..strokeWidth = max(1, blade * 0.18)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        origin,
        origin + Offset(-blade * 0.42, -blade),
        paint,
      );
      canvas.drawLine(
        origin,
        origin + Offset(blade * 0.48, -blade * 0.86),
        paint,
      );
      if (i % 4 == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: origin + Offset(blade * 0.65, -blade * 0.62),
            width: blade,
            height: blade * 0.48,
          ),
          Paint()..color = grassColors[(i + 1) % grassColors.length],
        );
      }
    }
  }

  void _drawFlowerCluster(
    Canvas canvas,
    Offset base,
    double scale,
    int count,
    int seed,
  ) {
    final swayDegrees = sin(progress * pi * 2 + seed * 1.4) * 1.6;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(swayDegrees * pi / 180);
    const flowerColors = [
      Color(0xFFFF78B5),
      Color(0xFFFFDA45),
      Color(0xFFB88AF3),
      Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < count; i++) {
      final column = i % 4;
      final row = i ~/ 4;
      final x = (column - 1.5) * 13 * scale + sin(i * 2.1 + seed) * 4 * scale;
      final groundY = row * 5 * scale;
      final stemHeight = (18 + (i * 7 % 12)) * scale;
      final stemPaint = Paint()
        ..color = const Color(0xFF4D9E43)
        ..strokeWidth = max(1.2, 1.7 * scale)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x + sin(i + seed) * 2 * scale, groundY - stemHeight),
        stemPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            x + (i.isEven ? 4 : -4) * scale,
            groundY - stemHeight * 0.48,
          ),
          width: 8 * scale,
          height: 4 * scale,
        ),
        Paint()..color = const Color(0xFF67B950),
      );

      final center = Offset(
        x + sin(i + seed) * 2 * scale,
        groundY - stemHeight,
      );
      final petals = 5 + (i + seed) % 4;
      final petalRadius = (2.8 + (i % 3) * 0.45) * scale;
      final petalPaint = Paint()..color = flowerColors[(i + seed) % 4];
      for (var p = 0; p < petals; p++) {
        final angle = p * pi * 2 / petals;
        canvas.drawCircle(
          center +
              Offset(
                cos(angle) * petalRadius * 1.45,
                sin(angle) * petalRadius * 1.45,
              ),
          petalRadius,
          petalPaint,
        );
      }
      canvas.drawCircle(
        center,
        petalRadius * 0.72,
        Paint()..color = const Color(0xFFFFA928),
      );
    }
    canvas.restore();
  }

  void _drawBalloon(
    Canvas canvas,
    Offset center,
    double diameter,
    Color color,
    int index,
  ) {
    final body = Rect.fromCenter(
      center: center,
      width: diameter,
      height: diameter * 1.22,
    );
    canvas.drawOval(
      body.shift(Offset(0, diameter * 0.10)),
      Paint()
        ..color = const Color(0x33002E4D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.42),
          radius: 0.83,
          colors: [
            Color.lerp(color, Colors.white, 0.36)!,
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(body),
    );
    canvas.drawOval(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, diameter * 0.035),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        body.left + diameter * 0.19,
        body.top + diameter * 0.14,
        diameter * 0.17,
        diameter * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      Offset(body.left + diameter * 0.39, body.top + diameter * 0.12),
      diameter * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    final knot = Path()
      ..moveTo(center.dx, body.bottom - 2)
      ..lineTo(center.dx - diameter * 0.10, body.bottom + diameter * 0.14)
      ..lineTo(center.dx + diameter * 0.10, body.bottom + diameter * 0.14)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
    final string = Path()
      ..moveTo(center.dx, body.bottom + diameter * 0.12)
      ..cubicTo(
        center.dx + (index.isEven ? 12 : -12),
        body.bottom + diameter * 0.45,
        center.dx - (index.isEven ? 8 : -8),
        body.bottom + diameter * 0.72,
        center.dx,
        body.bottom + diameter,
      );
    canvas.drawPath(
      string,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant MenuSceneryPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class SkyPainter extends CustomPainter {
  const SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    _cloud(
      canvas,
      Offset(size.width * 0.15, size.height * 0.18),
      1.0,
      cloudPaint,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.78, size.height * 0.36),
      0.8,
      cloudPaint,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.33, size.height * 0.72),
      0.65,
      cloudPaint,
    );
  }

  void _cloud(Canvas canvas, Offset center, double scale, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 120 * scale, height: 45 * scale),
      paint,
    );
    canvas.drawCircle(
      center + Offset(-30 * scale, -15 * scale),
      27 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(16 * scale, -22 * scale),
      35 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(48 * scale, -8 * scale),
      22 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
