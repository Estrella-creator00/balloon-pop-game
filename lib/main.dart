import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
      title: '풍선 팡팡',
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

class BalloonGamePage extends StatefulWidget {
  const BalloonGamePage({super.key});

  @override
  State<BalloonGamePage> createState() => _BalloonGamePageState();
}

class _BalloonGamePageState extends State<BalloonGamePage>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 16);
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
  final List<Balloon> _balloons = [];
  final List<PopPiece> _pieces = [];
  final List<BurstRing> _rings = [];
  Timer? _timer;
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

  StageConfig get _stageConfig => StageConfig.forStage(_stage);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondSectionUnlocked = ProgressStorage.isSecondSectionUnlocked();
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
    _timer?.cancel();
    _stageTimer?.cancel();
    _stopwatch.reset();
    _nextId = 0;
    _score = 0;
    _sectionStartStage = startStage;
    _stage = startStage;
    _secondsLeft = StageConfig.forStage(startStage).duration.inSeconds;
    _phase = GamePhase.playing;
    _balloons.clear();
    _pieces.clear();
    _rings.clear();
    _bosses.clear();
    _startStage();
    _timer = Timer.periodic(_tick, _updateGame);
    if (mounted) {
      setState(() {});
    }
  }

  void _returnToMenu() {
    _timer?.cancel();
    _stageTimer?.cancel();
    _stopwatch.stop();
    setState(() {
      _score = 0;
      _stage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
      _balloons.clear();
      _pieces.clear();
      _rings.clear();
      _bosses.clear();
    });
  }

  void _pauseGame() {
    if (_phase != GamePhase.playing) return;
    _stopwatch.stop();
    setState(() {
      _phase = GamePhase.paused;
    });
  }

  void _resumeGame() {
    if (_phase != GamePhase.paused) return;
    _stopwatch.start();
    setState(() {
      _phase = GamePhase.playing;
    });
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

    final dt = _tick.inMilliseconds / 1000;
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
    setState(() {
      _secondsLeft = secondsLeft;
    });
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
    const gravity = 520.0;
    for (final piece in _pieces) {
      piece.life -= dt;
      piece.velocity =
          Offset(piece.velocity.dx, piece.velocity.dy + gravity * dt);
      piece.position += piece.velocity * dt;
      piece.rotation += piece.spin * dt;
    }
    _pieces.removeWhere((piece) => piece.life <= 0);

    for (final ring in _rings) {
      ring.life -= dt;
    }
    _rings.removeWhere((ring) => ring.life <= 0);
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
  }

  void _showStageClear() {
    _stopwatch.stop();
    _score += _secondsLeft;
    _phase = GamePhase.stageClear;
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
  }

  void _clearBoss(BossBalloon boss, Offset center, Color color) {
    final removed = _bosses.remove(boss);
    if (!removed) return;
    _score += 10;
    PopSound.playBossExplosion();
    _spawnPieces(center, color, 280, big: true);
    _spawnRing(center, const Color(0xFFFFD54F), 190);
    _spawnRing(center, const Color(0xFFFF5C8A), 250);
    if (_bosses.isNotEmpty) return;

    _stopwatch.stop();
    _score += _secondsLeft;
    _phase = GamePhase.bossClear;
    if (_stage == 10) {
      _secondSectionUnlocked = true;
      ProgressStorage.unlockSecondSection();
    }
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
    _timer?.cancel();
    _stageTimer?.cancel();
    _stopwatch.stop();
    _phase = GamePhase.completed;
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
  }

  void _finishGame() {
    _timer?.cancel();
    _stageTimer?.cancel();
    _stopwatch.stop();
    setState(() {
      _secondsLeft = 0;
      _phase = GamePhase.gameOver;
      _balloons.clear();
      _bosses.clear();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stageTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

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
      _score = 0;
      _stage = 1;
      _sectionStartStage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
    });
  }

  Widget _buildStartScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF77D5FF), Color(0xFFDDF7FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33004D73),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎈 풍선 팡팡 🎈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF5C8A),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _menuButton(
                      label: '1~10 STAGE 시작',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _startGame(1),
                    ),
                    const SizedBox(height: 16),
                    _menuButton(
                      label: _secondSectionUnlocked
                          ? '11~20 STAGE 시작'
                          : '11~20 STAGE 시작 🔒',
                      icon: _secondSectionUnlocked
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                      onPressed:
                          _secondSectionUnlocked ? () => _startGame(11) : null,
                    ),
                    if (!_secondSectionUnlocked) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '10 STAGE 보스를 먼저 클리어하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF607D8B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _confirmProgressReset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('진행 초기화'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
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
        ),
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 30),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 68),
        backgroundColor: const Color(0xFFFF5C8A),
        disabledBackgroundColor: const Color(0xFFB0BEC5),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == GamePhase.menu) {
      return _buildStartScreen();
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
              _buildHeader(),
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
                        const Positioned.fill(
                          child: CustomPaint(painter: SkyPainter()),
                        ),
                        for (final ring in _rings) _buildRing(ring),
                        for (final piece in _pieces) _buildPiece(piece),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          const Text(
            '🎈 풍선 팡팡 🎈',
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
            '$_stage STAGE',
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
              _infoPill('점수', '$_score', const Color(0xFFFFB300)),
              const SizedBox(width: 10),
              _infoPill(
                '남은 풍선',
                '${_bosses.isNotEmpty ? _bosses.length : _balloons.length}',
                const Color(0xFF7E57C2),
              ),
              const SizedBox(width: 10),
              _infoPill(
                '시간',
                '$_secondsLeft',
                _secondsLeft <= 5 ? Colors.redAccent : const Color(0xFF26A69A),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                key: const ValueKey('pause-button'),
                onPressed: _phase == GamePhase.playing ? _pauseGame : null,
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
                onPressed: _phase == GamePhase.playing ? _confirmEndGame : null,
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

  Widget _buildBalloon(Balloon balloon) {
    return Positioned(
      key: ValueKey(balloon.id),
      left: balloon.position.dx,
      top: balloon.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _popBalloon(balloon),
        child: SizedBox(
          width: balloon.size,
          height: balloon.size + 26,
          child: CustomPaint(
            painter: BalloonPainter(color: _balloonColor(balloon)),
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

  Widget _buildPiece(PopPiece piece) {
    final opacity = (piece.life / piece.maxLife).clamp(0.0, 1.0);
    return Positioned(
      left: piece.position.dx,
      top: piece.position.dy,
      child: Transform.rotate(
        angle: piece.rotation,
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(
            size: Size(piece.size, piece.size * 1.3),
            painter: PopPiecePainter(color: piece.color),
          ),
        ),
      ),
    );
  }

  Widget _buildRing(BurstRing ring) {
    final progress = 1 - (ring.life / ring.maxLife).clamp(0.0, 1.0);
    final size = ring.radius * progress * 2;
    return Positioned(
      left: ring.center.dx - size / 2,
      top: ring.center.dy - size / 2,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(size, size),
          painter: BurstRingPainter(color: ring.color, progress: progress),
        ),
      ),
    );
  }

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
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
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
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6B9D),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '최종 점수',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF456477),
                  ),
                ),
                Text(
                  '$_score점',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7E57C2),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _startGame(_sectionStartStage),
                  icon: const Icon(Icons.refresh_rounded, size: 30),
                  label: const Text(
                    '다시 시작',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _returnToMenu,
                  icon: const Icon(Icons.home_rounded, size: 28),
                  label: const Text(
                    '시작 화면으로 돌아가기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
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
}

class BalloonPainter extends CustomPainter {
  const BalloonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final balloonHeight = size.height - 26;
    final body = Rect.fromLTWH(3, 0, size.width - 6, balloonHeight - 9);
    final paint = Paint()..color = color;
    canvas.drawOval(body, paint);

    final shade = Paint()..color = Colors.black.withValues(alpha: 0.06);
    canvas.drawOval(body.shift(const Offset(4, 6)), shade);
    canvas.drawOval(body, paint);

    final shine = Paint()..color = Colors.white.withValues(alpha: 0.50);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.22,
        balloonHeight * 0.15,
        size.width * 0.17,
        balloonHeight * 0.25,
      ),
      shine,
    );

    final knot = Path()
      ..moveTo(size.width / 2, balloonHeight - 11)
      ..lineTo(size.width / 2 - 8, balloonHeight + 5)
      ..lineTo(size.width / 2 + 8, balloonHeight + 5)
      ..close();
    canvas.drawPath(knot, paint);

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

class PopPiecePainter extends CustomPainter {
  const PopPiecePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.50, 0)
      ..lineTo(size.width, size.height * 0.32)
      ..lineTo(size.width * 0.72, size.height)
      ..lineTo(size.width * 0.22, size.height * 0.82)
      ..lineTo(0, size.height * 0.24)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant PopPiecePainter oldDelegate) =>
      oldDelegate.color != color;
}

class BurstRingPainter extends CustomPainter {
  const BurstRingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * opacity;
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2, paint);
  }

  @override
  bool shouldRepaint(covariant BurstRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
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
