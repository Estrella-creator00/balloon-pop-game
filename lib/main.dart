import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'audio/pop_sound.dart';
import 'balloon_background.dart';
import 'balloon_skin_catalog.dart';
import 'coin_purchase_page.dart';
import 'dev/dev_coin_tool.dart';
import 'gameplay/game_canvas.dart';
import 'gameplay/game_draw_geometry.dart';
import 'gameplay/game_hit_tester.dart';
import 'gameplay/game_render_state.dart';
import 'gameplay/game_sprite_cache.dart';
import 'onboarding_page.dart';
import 'ranking/ranking_page.dart';
import 'services/coin_service.dart';
import 'services/haptic_service.dart';
import 'services/purchase_service.dart';
import 'services/settings_service.dart';
import 'settings_page.dart';
import 'storage/progress_storage.dart';

void main() {
  runApp(const BalloonPopApp());
}

class BalloonPopApp extends StatefulWidget {
  const BalloonPopApp({
    super.key,
    this.stage30SwapRollForTest,
    this.toolHitDeltaForTest,
    this.gameplayRendererMode = defaultGameplayRendererMode,
  });

  @visibleForTesting
  final double Function()? stage30SwapRollForTest;

  @visibleForTesting
  final double? toolHitDeltaForTest;

  final GameplayRendererMode gameplayRendererMode;

  @override
  State<BalloonPopApp> createState() => _BalloonPopAppState();
}

class _BalloonPopAppState extends State<BalloonPopApp> {
  late bool _nicknameOnboardingCompleted;

  @override
  void initState() {
    super.initState();
    SettingsService.applyStoredPreferences();
    _nicknameOnboardingCompleted = SettingsService.nicknameOnboardingCompleted;
  }

  void _completeNicknameOnboarding() {
    if (!mounted) return;
    setState(() => _nicknameOnboardingCompleted = true);
  }

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
      home: _nicknameOnboardingCompleted
          ? BalloonGamePage(
              stage30SwapRollForTest: widget.stage30SwapRollForTest,
              toolHitDeltaForTest: widget.toolHitDeltaForTest,
              gameplayRendererMode: widget.gameplayRendererMode,
            )
          : NicknameOnboardingPage(onCompleted: _completeNicknameOnboarding),
    );
  }
}

enum GamePhase {
  menu,
  stageIntro,
  playing,
  paused,
  stageClear,
  bossClear,
  completed,
  gameOver,
}

enum MainTab { home, store, event, ranking }

/// Internal screen identifiers used by development requests and documentation.
/// These values are not rendered in the user interface.
abstract final class ScreenIds {
  static const String nicknameOnboarding = 'ON-01';
  static const String home = 'H-01';
  static const String shopCategories = 'S-01';
  static const String shopProductList = 'S-02';
  static const String event = 'E-01';
  static const String ranking = 'R-01';
  static const String settings = 'SET-01';
  static const String nicknameEdit = 'SET-02';
  static const String terms = 'SET-03';
  static const String privacy = 'SET-04';
  static const String contact = 'SET-05';
  static const String dataReset = 'SET-06';
  static const String gameplay = 'G-01';
  static const String gameResult = 'G-02';
  static const String coinPurchase = 'C-01';

  static const Map<String, String> names = {
    nicknameOnboarding: '최초 닉네임 설정 화면',
    home: '홈 화면',
    shopCategories: '상점 카테고리 화면',
    shopProductList: '상점 상품 목록 화면',
    event: '이벤트 화면',
    ranking: '주간 랭킹 화면',
    settings: '설정 화면',
    nicknameEdit: '닉네임 변경 팝업',
    terms: '이용약관 화면',
    privacy: '개인정보처리방침 화면',
    contact: '문의하기 화면',
    dataReset: '데이터 초기화 확인 팝업',
    gameplay: '게임 플레이 화면',
    gameResult: '게임 완료 및 게임오버 화면',
    coinPurchase: '코인 충전 화면',
  };
}

enum StoreCategory {
  balloon,
  popEffect,
  background,
  soundEffect,
  music,
  limited,
}

enum StorePreviewType { balloon, effect, background, sound, music }

enum StoreProductFilter { all, owned, unowned, limited }

const storeProductsPerPage = 8;

int storeRarityPageCount(int productCount) =>
    max(1, (productCount + storeProductsPerPage - 1) ~/ storeProductsPerPage);

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
    this.shortName,
    this.locked = false,
    this.limited = false,
    this.rarity = BalloonRarity.common,
    this.badge = BalloonBadge.none,
  });

  factory StoreProduct.fromBalloonSkin(BalloonSkinDefinition definition) =>
      StoreProduct(
        id: definition.id,
        category: StoreCategory.balloon,
        name: definition.displayName,
        price: definition.price,
        owned: definition.initiallyOwned,
        equipped: definition.isDefault,
        previewType: StorePreviewType.balloon,
        previewData: definition.previewColor,
        rarity: definition.rarity,
        badge: BalloonSkinCatalog.badgeFor(definition),
      );

  final String id;
  final StoreCategory category;
  final String name;
  final int price;
  final bool owned;
  final bool equipped;
  final StorePreviewType previewType;
  final Color previewData;
  final String? shortName;
  final bool locked;
  final bool limited;
  final BalloonRarity rarity;
  final BalloonBadge badge;

  String get displayName => shortName ?? name;

  StoreProduct copyWith({bool? owned, bool? equipped}) => StoreProduct(
        id: id,
        category: category,
        name: name,
        price: price,
        owned: owned ?? this.owned,
        equipped: equipped ?? this.equipped,
        previewType: previewType,
        previewData: previewData,
        shortName: shortName,
        locked: locked,
        limited: limited,
        rarity: rarity,
        badge: badge,
      );
}

class Balloon implements BasicBalloonRenderView {
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
    this.skinId = 'balloon-default',
    this.isFake = false,
    this.visualVariant = 0,
    this.specialVisual = false,
    this.impactVisual = 0,
    this.exitProgress = 0,
    this.exitVelocity = Offset.zero,
  });

  @override
  final int id;
  @override
  Offset position;
  Offset velocity;
  @override
  final Color color;
  @override
  double size;
  double floatPhase;
  final double floatPower;
  int hp;
  final int maxHp;
  final String skinId;
  final bool isFake;
  final int visualVariant;
  final bool specialVisual;
  double impactVisual;
  double exitProgress;
  Offset exitVelocity;

  @override
  Color get displayColor {
    final damageColor = BalloonSkinCatalog.defaultSkin.colorAtDamage(
      color,
      maxHp == 0 ? 0 : (maxHp - hp) / maxHp,
      isBoss: false,
    );
    return isFake ? fakeBalloonColor(damageColor) : damageColor;
  }

  @override
  double get opacity => isFake ? fakeBalloonOpacity : 1;

  late final BalloonSkinDefinition _skin =
      BalloonSkinCatalog.byIdOrDefault(skinId);
  late final List<double>? _cachedSpriteColorMatrix =
      _imageSpriteColorMatrix(_skin, color, isFake: isFake);
  late final List<double>? _cachedSpriteDetailColorMatrix =
      _imageSpriteDetailColorMatrix(_skin, isFake: isFake);
  late final bool _cachedPreserveMochiDetails =
      _shouldPreserveMochiDetails(_skin, color, isFake: isFake);

  @override
  String? get spriteAssetPath => _skin.rendererType == BalloonRendererType.image
      ? _skin.assetForVariant(visualVariant)
      : null;
  @override
  List<double>? get spriteColorMatrix => _cachedSpriteColorMatrix;
  @override
  List<double>? get spriteDetailColorMatrix => _cachedSpriteDetailColorMatrix;
  @override
  bool get preserveMochiDetails => _cachedPreserveMochiDetails;
  @override
  Offset get visualOffset =>
      _skin.idleAnimation == BalloonIdleAnimationType.ghostTail
          ? Offset(sin(floatPhase) * 1.4, cos(floatPhase) * 2.2)
          : Offset.zero;
  @override
  double get visualRotation =>
      _skin.idleAnimation == BalloonIdleAnimationType.ghostTail
          ? sin(floatPhase * 0.7) * 0.018
          : 0;
  @override
  double get visualScale =>
      isExiting ? (1 - exitProgress * 0.42).clamp(0.58, 1.0) : 1;
  @override
  double get spriteOpacity =>
      opacity *
      (_skin.idleAnimation == BalloonIdleAnimationType.ghostTail ? 0.86 : 1);

  bool get isExiting => exitProgress > 0;
}

class BossBalloon {
  BossBalloon({
    required this.id,
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxHp,
    this.skinId = 'balloon-default',
    this.skinColor,
    this.isFake = false,
    this.turnIntervalOffset = 0,
    double initialTurnCooldown = 0.65,
    this.visualVariant = 0,
    this.specialVisual = false,
    this.visualPhase = 0,
    this.impactVisual = 0,
  }) : turnCooldown = initialTurnCooldown;

  final int id;
  Offset position;
  Offset velocity;
  double size;
  final int maxHp;
  final String skinId;
  final Color? skinColor;
  bool isFake;
  late int hp = maxHp;
  final double turnIntervalOffset;
  double turnCooldown;
  final int visualVariant;
  final bool specialVisual;
  double visualPhase;
  double impactVisual;
}

class _BossRenderView implements BossBalloonRenderView {
  _BossRenderView({
    required this.boss,
    required this.hpOf,
    required this.maxHpOf,
    required this.colorOf,
  });

  final BossBalloon boss;
  final int Function(BossBalloon) hpOf;
  final int Function(BossBalloon) maxHpOf;
  final Color Function(BossBalloon) colorOf;

  @override
  int get id => boss.id;
  @override
  Offset get position => boss.position;
  @override
  double get size => boss.size;
  @override
  Color get displayColor {
    final color = colorOf(boss);
    return boss.isFake ? fakeBalloonColor(color) : color;
  }

  @override
  double get opacity => boss.isFake ? fakeBalloonOpacity : 1;
  @override
  int get hp => hpOf(boss);
  @override
  int get maxHp => maxHpOf(boss);
  @override
  bool get showHealthBar => !boss.isFake;

  late final BalloonSkinDefinition _skin =
      BalloonSkinCatalog.byIdOrDefault(boss.skinId);
  late final Color _skinColor = colorOf(boss);
  late final List<double>? _normalSpriteColorMatrix =
      _imageSpriteColorMatrix(_skin, _skinColor, isFake: false);
  late final List<double>? _fakeSpriteColorMatrix =
      _imageSpriteColorMatrix(_skin, _skinColor, isFake: true);
  late final List<double>? _normalSpriteDetailColorMatrix =
      _imageSpriteDetailColorMatrix(_skin, isFake: false);
  late final List<double>? _fakeSpriteDetailColorMatrix =
      _imageSpriteDetailColorMatrix(_skin, isFake: true);
  late final bool _normalPreserveMochiDetails =
      _shouldPreserveMochiDetails(_skin, _skinColor, isFake: false);
  late final bool _fakePreserveMochiDetails =
      _shouldPreserveMochiDetails(_skin, _skinColor, isFake: true);

  @override
  String? get spriteAssetPath => _skin.rendererType == BalloonRendererType.image
      ? _skin.assetForVariant(boss.visualVariant)
      : null;
  @override
  List<double>? get spriteColorMatrix =>
      boss.isFake ? _fakeSpriteColorMatrix : _normalSpriteColorMatrix;
  @override
  List<double>? get spriteDetailColorMatrix => boss.isFake
      ? _fakeSpriteDetailColorMatrix
      : _normalSpriteDetailColorMatrix;
  @override
  bool get preserveMochiDetails =>
      boss.isFake ? _fakePreserveMochiDetails : _normalPreserveMochiDetails;
  @override
  Offset get visualOffset =>
      _skin.idleAnimation == BalloonIdleAnimationType.ghostTail
          ? Offset(
              sin(boss.visualPhase) * 1.4,
              cos(boss.visualPhase) * 2.2,
            )
          : Offset.zero;
  @override
  double get visualRotation =>
      _skin.idleAnimation == BalloonIdleAnimationType.ghostTail
          ? sin(boss.visualPhase * 0.7) * 0.018
          : 0;
  @override
  double get visualScale => 1;
  @override
  double get spriteOpacity =>
      opacity *
      (_skin.idleAnimation == BalloonIdleAnimationType.ghostTail ? 0.86 : 1);
}

List<double>? _imageSpriteColorMatrix(
  BalloonSkinDefinition definition,
  Color color, {
  required bool isFake,
}) {
  if (definition.rendererType != BalloonRendererType.image) return null;
  if (definition.imageColorMode == BalloonImageColorMode.original) {
    return isFake ? BalloonSkinArtwork.fakeToneMatrix : null;
  }
  if (BalloonSkinArtwork.usesOriginalAsset(definition, color) && !isFake) {
    return null;
  }
  return BalloonSkinArtwork.visualColorMatrix(
    definition,
    color,
    isFake: isFake,
  );
}

List<double>? _imageSpriteDetailColorMatrix(
  BalloonSkinDefinition definition, {
  required bool isFake,
}) =>
    definition.imageDetailMask == BalloonImageDetailMask.mochiFace && isFake
        ? BalloonSkinArtwork.fakeToneMatrix
        : null;

bool _shouldPreserveMochiDetails(
  BalloonSkinDefinition definition,
  Color color, {
  required bool isFake,
}) =>
    definition.imageDetailMask == BalloonImageDetailMask.mochiFace &&
    (isFake || !BalloonSkinArtwork.usesOriginalAsset(definition, color));

const stage30BossSwapChance = 0.50;
const stage30BossMaxSpeed = 220.0;

/// Stage 30 owns one shared HP pool and only swaps the roles of its two
/// existing boss entities. Supplying the roll keeps swap/no-swap behavior
/// deterministic in tests without changing production randomness.
class Stage30BossState {
  Stage30BossState({this.maxHp = 12, this.realBossId = 0}) : hp = maxHp;

  final int maxHp;
  int hp;
  int realBossId;

  bool isFakeBoss(int bossId) => bossId != realBossId;

  bool registerRealHit(double swapRoll) {
    if (hp <= 0) return false;
    hp--;
    if (hp == 0 || swapRoll >= stage30BossSwapChance) return false;
    realBossId = realBossId == 0 ? 1 : 0;
    return true;
  }
}

void applyStage30BossRoles(List<BossBalloon> bosses, Stage30BossState state) {
  for (final boss in bosses) {
    boss.isFake = state.isFakeBoss(boss.id);
  }
}

BossBalloon? closestStage30BossForTap(
  Iterable<BossBalloon> bosses,
  Offset point,
) {
  BossBalloon? closest;
  var closestDistance = double.infinity;
  for (final boss in bosses) {
    final touchBounds = Rect.fromLTWH(
      boss.position.dx,
      boss.position.dy,
      boss.size,
      boss.size + 32,
    );
    if (!touchBounds.contains(point)) continue;
    final center = boss.position + Offset(boss.size / 2, boss.size / 2);
    final distance = (point - center).distanceSquared;
    // Later entries are painted above earlier entries, so an exact-distance
    // tie follows the visible z-order while ordinary overlaps pick the nearer
    // center.
    if (distance <= closestDistance) {
      closest = boss;
      closestDistance = distance;
    }
  }
  return closest;
}

Offset stage30CappedBossVelocity(Offset velocity) {
  final speed = velocity.distance;
  if (speed == 0) return velocity;
  final nextSpeed = min(speed, stage30BossMaxSpeed);
  return velocity * (nextSpeed / speed);
}

Offset stage30AcceleratedBossVelocity(Offset velocity) =>
    stage30CappedBossVelocity(velocity * 1.075);

Offset nextBossPosition(BossBalloon boss, double dt) =>
    boss.position + boss.velocity * dt;

class StageConfig {
  const StageConfig({
    required this.stage,
    required this.isBoss,
    required this.balloonCount,
    required this.requiredHits,
    required this.duration,
    required this.bossHp,
    required this.bossSpeed,
    required this.bossCount,
    required this.fakeBalloonCount,
  });

  final int stage;
  final bool isBoss;
  final int balloonCount;

  /// Number of taps required to pop a normal balloon in this stage.
  ///
  /// Keep this separate from boss HP and fake-balloon handling so later
  /// stage tiers cannot accidentally inherit multi-hit behavior.
  final int requiredHits;
  final Duration duration;
  final int bossHp;
  final double bossSpeed;
  final int bossCount;
  final int fakeBalloonCount;

  bool get hasFakeBalloons => fakeBalloonCount > 0;

  static const firstFakeBalloonStage = 21;
  static const lastFakeBalloonStage = 29;
  static const lastImplementedStage = 30;
  static const fakeBalloonRequiredHits = 1;

  /// Returns the next contiguous playable stage, or `null` when the current
  /// run has reached the last implemented stage. Boss stages use this same
  /// progression rule, so adding Stage 30/31 only requires extending the
  /// implemented range and stage configuration.
  static int? nextStageAfter(int currentStage) =>
      currentStage < lastImplementedStage ? currentStage + 1 : null;

  static int normalBalloonRequiredHitsForStage(int stage) {
    if (stage >= 11 && stage <= 19) return 2;
    if ((stage >= 1 && stage <= 9) ||
        (stage >= firstFakeBalloonStage && stage <= lastFakeBalloonStage)) {
      return 1;
    }

    // Boss stages do not spawn normal balloons. Preserve their historical
    // tier value without allowing it to leak into Stages 21-29.
    return (stage - 1) ~/ 10 + 1;
  }

  factory StageConfig.forStage(int stage) {
    if (stage < 1 || stage > lastImplementedStage) {
      throw RangeError.range(stage, 1, lastImplementedStage, 'stage');
    }
    final isBoss = stage % 10 == 0;
    final tier = (stage - 1) ~/ 10;
    final positionInTier = (stage - 1) % 10 + 1;
    final timeGroup = (positionInTier - 1) ~/ 3;
    final isRealFakeBossStage = stage == 30;

    return StageConfig(
      stage: stage,
      isBoss: isBoss,
      balloonCount: isBoss ? 0 : positionInTier + 1,
      requiredHits: normalBalloonRequiredHitsForStage(stage),
      duration: Duration(
        seconds: isRealFakeBossStage
            ? 18
            : (isBoss ? 8 + tier * 2 : 10 + tier * 2 + timeGroup * 5),
      ),
      bossHp: isRealFakeBossStage ? 12 : (isBoss ? 10 + tier * 5 : 0),
      // Stage 30 reuses the established Stage 20 boss movement feel rather
      // than introducing another tier-speed jump for its role-swap gimmick.
      bossSpeed: isRealFakeBossStage
          ? 105 * pow(1.2, 1).toDouble()
          : (isBoss ? 105 * pow(1.2, tier).toDouble() : 0),
      bossCount: isRealFakeBossStage ? 2 : (isBoss ? tier + 1 : 0),
      fakeBalloonCount:
          stage >= firstFakeBalloonStage && stage <= lastFakeBalloonStage
              ? 2
              : 0,
    );
  }
}

const homeStageCardsPerPage = 2;
const homeStagesPerCard = 10;
const homeStagePageCount = 3;

int homeStagePageForProgress(
  int nextPlayableStage, {
  int pageCount = homeStagePageCount,
}) {
  if (pageCount <= 1) return 0;
  final normalizedStage = max(1, nextPlayableStage);
  final page =
      (normalizedStage - 1) ~/ (homeStagesPerCard * homeStageCardsPerPage);
  return page.clamp(0, pageCount - 1).toInt();
}

enum EffectPieceShape { shard, heart, mist, gel, pickaxe, fork }

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
    this.shape = EffectPieceShape.shard,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double rotation;
  final double spin;
  double life;
  final double maxLife;
  final EffectPieceShape shape;
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

class FloatingTextFeedback {
  FloatingTextFeedback({
    required this.center,
    required this.text,
    required this.color,
    required this.life,
    required this.maxLife,
  });

  final Offset center;
  final String text;
  final Color color;
  double life;
  final double maxLife;
}

bool advanceEffects(
  List<PopPiece> pieces,
  List<BurstRing> rings,
  double dt, {
  List<FloatingTextFeedback>? feedbacks,
}) {
  if (pieces.isEmpty && rings.isEmpty && (feedbacks?.isEmpty ?? true)) {
    return false;
  }
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

  if (feedbacks != null) {
    for (final feedback in feedbacks) {
      feedback.life -= dt;
    }
    feedbacks.removeWhere((feedback) => feedback.life <= 0);
  }
  return true;
}

/// Shared visual-effect factory used by gameplay and the shop preview.
void addBalloonPopEffect({
  required BalloonSkinDefinition definition,
  required List<PopPiece> pieces,
  required Random random,
  required Offset center,
  required Color color,
  required double sourceSize,
  required bool big,
}) {
  switch (definition.popEffectType) {
    case BalloonPopEffectType.shards:
      addBalloonShardPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: color,
        big: big,
      );
    case BalloonPopEffectType.hearts:
      addBalloonHeartPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: color,
        sourceSize: sourceSize,
        big: big,
      );
    case BalloonPopEffectType.mist:
      addThemedPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: color.withValues(alpha: 0.72),
        big: big,
        shape: EffectPieceShape.mist,
      );
    case BalloonPopEffectType.gel:
      addThemedPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: color,
        big: big,
        shape: EffectPieceShape.gel,
      );
    case BalloonPopEffectType.crystal:
      addThemedPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: color,
        big: big,
        shape: EffectPieceShape.shard,
      );
    case BalloonPopEffectType.cream:
      addThemedPieces(
        pieces: pieces,
        random: random,
        center: center,
        color: const Color(0xFFFFE47A),
        big: big,
        shape: EffectPieceShape.gel,
      );
  }
}

void addThemedPieces({
  required List<PopPiece> pieces,
  required Random random,
  required Offset center,
  required Color color,
  required bool big,
  required EffectPieceShape shape,
  EffectPieceShape? tool,
}) {
  final count = big ? 18 : 7;
  for (var i = 0; i < count; i++) {
    final angle = pi * 2 * i / count + (random.nextDouble() - 0.5) * 0.45;
    final speed = (big ? 230 : 120) + random.nextDouble() * (big ? 180 : 95);
    pieces.add(
      PopPiece(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 55),
        color: color,
        size: (big ? 12 : 8) + random.nextDouble() * (big ? 13 : 7),
        rotation: random.nextDouble() * pi,
        spin: (random.nextDouble() - 0.5) * 9,
        life: big ? 1.15 : 0.72,
        maxLife: big ? 1.15 : 0.72,
        shape: shape,
      ),
    );
  }
  if (tool != null) {
    pieces.add(
      PopPiece(
        position: center - const Offset(44, 20),
        velocity: const Offset(145, 25),
        color: tool == EffectPieceShape.pickaxe
            ? const Color(0xFF785548)
            : const Color(0xFFB0BEC5),
        size: big ? 29 : 22,
        rotation: -0.7,
        spin: 4.5,
        life: 0.28,
        maxLife: 0.28,
        shape: tool,
      ),
    );
  }
}

void addBalloonShardPieces({
  required List<PopPiece> pieces,
  required Random random,
  required Offset center,
  required Color color,
  required bool big,
}) {
  final count = big ? 28 : 6 + random.nextInt(3);
  final speedBase = big ? 250.0 : 145.0;
  for (var i = 0; i < count; i++) {
    final angle = (pi * 2 / count) * i + (random.nextDouble() - 0.5) * 0.65;
    final speed = speedBase + random.nextDouble() * (big ? 280 : 145);
    pieces.add(
      PopPiece(
        position: center,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed - (big ? 120 : 65),
        ),
        color: Color.lerp(color, Colors.white, random.nextDouble() * 0.18)!,
        size: (big ? 11 : 8) + random.nextDouble() * (big ? 17 : 10),
        rotation: random.nextDouble() * pi,
        spin: (random.nextDouble() - 0.5) * 12,
        life: big
            ? 1.4 + random.nextDouble() * 0.7
            : 0.82 + random.nextDouble() * 0.35,
        maxLife: big ? 2.1 : 1.15,
      ),
    );
  }
}

void addBalloonHeartPieces({
  required List<PopPiece> pieces,
  required Random random,
  required Offset center,
  required Color color,
  required double sourceSize,
  required bool big,
}) {
  final count = big ? 28 : 5;
  final speedBase = big ? 250.0 : 125.0;
  for (var i = 0; i < count; i++) {
    final angle = (pi * 2 / count) * i -
        pi * 0.82 +
        (random.nextDouble() - 0.5) * (big ? 0.35 : 0.12);
    final speed = speedBase + random.nextDouble() * (big ? 280.0 : 85.0);
    pieces.add(
      PopPiece(
        position: center,
        velocity: Offset(
          cos(angle) * speed,
          sin(angle) * speed - (big ? 120 : 55),
        ),
        color: Color.lerp(color, Colors.white, 0.12)!,
        size: big
            ? 12 + random.nextDouble() * 16
            : sourceSize * (0.105 + random.nextDouble() * 0.035),
        rotation: random.nextDouble() * pi,
        spin: (random.nextDouble() - 0.5) * (big ? 12 : 8),
        life: big
            ? 1.4 + random.nextDouble() * 0.7
            : 0.72 + random.nextDouble() * 0.18,
        maxLife: big ? 2.1 : 0.9,
        shape: EffectPieceShape.heart,
      ),
    );
  }
}

void addBalloonBurstRing({
  required List<BurstRing> rings,
  required Offset center,
  required Color color,
  required double radius,
}) {
  rings.add(
    BurstRing(
      center: center,
      color: color,
      radius: radius,
      life: 0.38,
      maxLife: 0.38,
    ),
  );
}

/// Shared sound dispatch used by gameplay and the shop preview.
void playBalloonPopSound(
  BalloonSkinDefinition definition, {
  required bool boss,
}) {
  final assetPath = definition.popSoundAssetPath;
  if (assetPath != null) {
    PopSound.playAsset(assetPath);
    if (boss) PopSound.playBossExplosion();
    return;
  }
  switch (definition.popSoundType) {
    case BalloonPopSoundType.basic:
      boss ? PopSound.playBossExplosion() : PopSound.play();
    case BalloonPopSoundType.heart:
      PopSound.playHeart();
      if (boss) PopSound.playBossExplosion();
    case BalloonPopSoundType.ghost:
      PopSound.playGhost();
      if (boss) PopSound.playBossExplosion();
    case BalloonPopSoundType.crackle:
      PopSound.playCrackle();
      if (boss) PopSound.playBossExplosion();
    case BalloonPopSoundType.crystal:
      PopSound.playCrystal();
      if (boss) PopSound.playBossExplosion();
    case BalloonPopSoundType.cream:
      PopSound.playCream();
      if (boss) PopSound.playBossExplosion();
  }
}

class AssetVisualEffect {
  AssetVisualEffect({
    required this.assetPath,
    required this.center,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.life,
    required this.maxLife,
    this.cacheWidth = 320,
    this.paintLayer = AssetEffectPaintLayer.shared,
  });

  final String assetPath;
  Offset center;
  Offset velocity;
  final double size;
  double rotation;
  final double spin;
  double life;
  final double maxLife;
  final int cacheWidth;
  final AssetEffectPaintLayer paintLayer;
}

enum AssetEffectPaintLayer {
  legendaryTools,
  shared,
  gemiShards,
  gemiScreenCrack,
  shushuBurst,
  shushuWallLeft,
  shushuWallRight,
  shushuFront,
}

@immutable
class LegendaryToolVisual {
  const LegendaryToolVisual({
    required this.assetPath,
    required this.topLeft,
    required this.pivot,
    required this.size,
    required this.rotation,
    required this.opacity,
    this.spriteScale = 1,
  });

  final String assetPath;
  final Offset topLeft;
  final Offset pivot;
  final double size;
  final double rotation;
  final double opacity;
  final double spriteScale;
}

void addGemiShardAssetEffects({
  required List<AssetVisualEffect> effects,
  required Random random,
  required String assetPath,
  required Offset center,
  required double sourceSize,
  required int count,
}) {
  for (var index = 0; index < count; index++) {
    final angle = pi * 2 * index / count + random.nextDouble() * 0.8;
    final speed = 75 + random.nextDouble() * 65;
    effects.add(
      AssetVisualEffect(
        assetPath: assetPath,
        center: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 18),
        size: sourceSize * (0.20 + random.nextDouble() * 0.08),
        rotation: random.nextDouble() * pi * 2,
        spin: (random.nextDouble() - 0.5) * 5,
        life: 0.48,
        maxLife: 0.48,
        cacheWidth: 128,
        paintLayer: AssetEffectPaintLayer.gemiShards,
      ),
    );
  }
}

bool advanceAssetVisualEffects(List<AssetVisualEffect> effects, double dt) {
  if (effects.isEmpty) return false;
  for (final effect in effects) {
    effect.life -= dt;
    effect.center += effect.velocity * dt;
    effect.rotation += effect.spin * dt;
  }
  effects.removeWhere((effect) => effect.life <= 0);
  return true;
}

/// Draws every transient PNG effect in one canvas layer. This avoids creating
/// an Image/Transform/Opacity subtree (and a potential compositing layer) for
/// every GEMI shard and SHUSHU cream particle.
class AssetEffectsCanvas extends StatefulWidget {
  const AssetEffectsCanvas({
    super.key,
    required this.effects,
    required this.revision,
    this.preloadAssets = const <String, int>{},
    this.toolVisuals = const <LegendaryToolVisual>[],
    this.toolRevision = 0,
  });

  final List<AssetVisualEffect> effects;
  final int revision;
  final Map<String, int> preloadAssets;
  final List<LegendaryToolVisual> toolVisuals;
  final int toolRevision;

  int get effectCount => effects.length;
  int effectsForAsset(String assetPath) =>
      effects.where((effect) => effect.assetPath == assetPath).length;

  @override
  State<AssetEffectsCanvas> createState() => _AssetEffectsCanvasState();
}

final Map<String, Map<String, int>> _legendaryEffectPreloadCache =
    <String, Map<String, int>>{};

Map<String, int> legendaryEffectPreloadAssets(
  BalloonSkinDefinition definition,
) {
  if (definition.rarity != BalloonRarity.legendary) {
    return const <String, int>{};
  }
  return _legendaryEffectPreloadCache.putIfAbsent(definition.id, () {
    final result = <String, int>{};
    void add(String? path, int width) {
      if (path != null) result[path] = width;
    }

    add(definition.hitToolAssetPath, 256);
    add(definition.burstAssetPath, 320);
    add(definition.wallSplatAssetPath, 320);
    add(definition.screenSplatAssetPath, 320);
    if (definition.runtimeShardAssetPaths.isEmpty) {
      add(definition.shardAssetPath, 128);
    } else {
      for (final path in definition.runtimeShardAssetPaths.values) {
        add(path, 128);
      }
    }
    add(definition.screenCrackAssetPath, 320);
    if (definition.background == BalloonBackgroundType.crystalCave) {
      add(BalloonBackgroundRegistry.crystalImpactGlowAssetPath, 423);
    }
    return Map<String, int>.unmodifiable(result);
  });
}

String? gemiShardAssetForColor(
  BalloonSkinDefinition definition,
  Color color,
) =>
    definition.runtimeShardAssetPaths[color.toARGB32()] ??
    definition.shardAssetPath;

class _AssetEffectsCanvasState extends State<AssetEffectsCanvas> {
  final Map<String, _ResolvedEffectImage> _images =
      <String, _ResolvedEffectImage>{};
  final Map<String, ImageStream> _streams = <String, ImageStream>{};
  final Map<String, ImageStreamListener> _listeners =
      <String, ImageStreamListener>{};
  int _imageRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveMissingImages();
  }

  @override
  void didUpdateWidget(covariant AssetEffectsCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveMissingImages();
  }

  void _resolveMissingImages() {
    var needsResolution = false;
    for (final path in widget.preloadAssets.keys) {
      if (!_streams.containsKey(path)) {
        needsResolution = true;
        break;
      }
    }
    if (!needsResolution) {
      for (final effect in widget.effects) {
        if (!_streams.containsKey(effect.assetPath)) {
          needsResolution = true;
          break;
        }
      }
    }
    if (!needsResolution) {
      for (final tool in widget.toolVisuals) {
        if (!_streams.containsKey(tool.assetPath)) {
          needsResolution = true;
          break;
        }
      }
    }
    if (!needsResolution) return;
    final configuration = createLocalImageConfiguration(context);
    for (final entry in widget.preloadAssets.entries) {
      _resolveImage(entry.key, entry.value, configuration);
    }
    for (final effect in widget.effects) {
      _resolveImage(effect.assetPath, effect.cacheWidth, configuration);
    }
    for (final tool in widget.toolVisuals) {
      _resolveImage(tool.assetPath, 256, configuration);
    }
  }

  void _resolveImage(
    String assetPath,
    int cacheWidth,
    ImageConfiguration configuration,
  ) {
    if (_streams.containsKey(assetPath)) return;
    final provider = ResizeImage(AssetImage(assetPath), width: cacheWidth);
    final stream = provider.resolve(configuration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((image, _) {
      if (!mounted) {
        image.dispose();
        return;
      }
      final previous = _images[assetPath];
      _images[assetPath] = _ResolvedEffectImage(image);
      _imageRevision++;
      previous?.imageInfo.dispose();
      setState(() {});
    });
    _streams[assetPath] = stream;
    _listeners[assetPath] = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    for (final entry in _streams.entries) {
      final listener = _listeners[entry.key];
      if (listener != null) entry.value.removeListener(listener);
    }
    for (final image in _images.values) {
      image.imageInfo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effects.isEmpty && widget.toolVisuals.isEmpty) {
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final layer in AssetEffectPaintLayer.values)
              _buildPaintLayer(layer, viewport),
          ],
        );
      },
    );
  }

  Widget _buildPaintLayer(AssetEffectPaintLayer layer, Size viewport) {
    final bounds = layer == AssetEffectPaintLayer.legendaryTools
        ? legendaryToolPaintBounds(widget.toolVisuals, viewport)
        : assetEffectPaintBounds(widget.effects, viewport, layer);
    if (bounds.isEmpty) return const SizedBox.shrink();
    return Positioned.fromRect(
      rect: bounds,
      child: RepaintBoundary(
        key: ValueKey('asset-effects-paint-boundary-${layer.name}'),
        child: CustomPaint(
          key: ValueKey('asset-effects-canvas-${layer.name}'),
          painter: _AssetEffectsPainter(
            effects: widget.effects,
            toolVisuals: widget.toolVisuals,
            images: _images,
            paintLayer: layer,
            origin: bounds.topLeft,
            revision: widget.revision,
            imageRevision: _imageRevision,
            toolRevision: widget.toolRevision,
          ),
        ),
      ),
    );
  }
}

class _ResolvedEffectImage {
  _ResolvedEffectImage(this.imageInfo)
      : sourceRect = Rect.fromLTWH(
          0,
          0,
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        ),
        aspectRatio = imageInfo.image.width / imageInfo.image.height;

  final ImageInfo imageInfo;
  final Rect sourceRect;
  final double aspectRatio;
}

Rect assetEffectPaintBounds(
  List<AssetVisualEffect> effects,
  Size viewport,
  AssetEffectPaintLayer paintLayer,
) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final effect in effects) {
    if (effect.paintLayer != paintLayer) continue;
    // A rotated square reaches sqrt(2) / 2 of its side from the center.
    final radius = effect.size * 0.71 + 2;
    left = min(left, effect.center.dx - radius);
    top = min(top, effect.center.dy - radius);
    right = max(right, effect.center.dx + radius);
    bottom = max(bottom, effect.center.dy + radius);
  }
  if (!left.isFinite || viewport.isEmpty) return Rect.zero;
  return Rect.fromLTRB(
    left.clamp(0.0, viewport.width),
    top.clamp(0.0, viewport.height),
    right.clamp(0.0, viewport.width),
    bottom.clamp(0.0, viewport.height),
  );
}

Rect legendaryToolPaintBounds(
  List<LegendaryToolVisual> tools,
  Size viewport,
) {
  if (tools.isEmpty || viewport.isEmpty) return Rect.zero;
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final tool in tools) {
    final pivot = tool.topLeft + tool.pivot;
    final farX = max(tool.pivot.dx, tool.size - tool.pivot.dx);
    final farY = max(tool.pivot.dy, tool.size - tool.pivot.dy);
    final radius = sqrt(farX * farX + farY * farY) * tool.spriteScale + 2;
    left = min(left, pivot.dx - radius);
    top = min(top, pivot.dy - radius);
    right = max(right, pivot.dx + radius);
    bottom = max(bottom, pivot.dy + radius);
  }
  return Rect.fromLTRB(
    left.clamp(0.0, viewport.width),
    top.clamp(0.0, viewport.height),
    right.clamp(0.0, viewport.width),
    bottom.clamp(0.0, viewport.height),
  );
}

final List<Color> _effectAlphaColors = List<Color>.generate(
  256,
  (alpha) => Color.fromARGB(alpha, 255, 255, 255),
  growable: false,
);

class _AssetEffectsPainter extends CustomPainter {
  const _AssetEffectsPainter({
    required this.effects,
    required this.toolVisuals,
    required this.images,
    required this.paintLayer,
    required this.origin,
    required this.revision,
    required this.imageRevision,
    required this.toolRevision,
  });

  final List<AssetVisualEffect> effects;
  final List<LegendaryToolVisual> toolVisuals;
  final Map<String, _ResolvedEffectImage> images;
  final AssetEffectPaintLayer paintLayer;
  final Offset origin;
  final int revision;
  final int imageRevision;
  final int toolRevision;

  static final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _spritePaint;
    if (paintLayer == AssetEffectPaintLayer.legendaryTools) {
      for (final tool in toolVisuals) {
        final resolved = images[tool.assetPath];
        if (resolved == null) continue;
        final alpha = (tool.opacity * 255).round().clamp(0, 255);
        paint
          ..color = _effectAlphaColors[alpha]
          ..colorFilter = null;
        final drawSize = tool.size * tool.spriteScale;
        final aspectRatio = resolved.aspectRatio;
        final destinationWidth =
            aspectRatio >= 1 ? drawSize : drawSize * aspectRatio;
        final destinationHeight =
            aspectRatio >= 1 ? drawSize / aspectRatio : drawSize;
        final destination = Rect.fromCenter(
          center: Offset(tool.size / 2, tool.size / 2),
          width: destinationWidth,
          height: destinationHeight,
        );
        canvas
          ..save()
          ..translate(
            tool.topLeft.dx + tool.pivot.dx - origin.dx,
            tool.topLeft.dy + tool.pivot.dy - origin.dy,
          )
          ..rotate(tool.rotation)
          ..translate(-tool.pivot.dx, -tool.pivot.dy)
          ..drawImageRect(
            resolved.imageInfo.image,
            resolved.sourceRect,
            destination,
            paint,
          )
          ..restore();
      }
      return;
    }
    for (final effect in effects) {
      if (effect.paintLayer != paintLayer) continue;
      final resolved = images[effect.assetPath];
      if (resolved == null) continue;
      final opacity = (effect.life / effect.maxLife).clamp(0.0, 1.0);
      final alpha = (opacity * 255).round().clamp(0, 255);
      paint
        ..color = _effectAlphaColors[alpha]
        ..colorFilter = null;
      final image = resolved.imageInfo.image;
      final aspectRatio = resolved.aspectRatio;
      final destinationWidth =
          aspectRatio >= 1 ? effect.size : effect.size * aspectRatio;
      final destinationHeight =
          aspectRatio >= 1 ? effect.size / aspectRatio : effect.size;
      final destination = Rect.fromCenter(
        center: Offset.zero,
        width: destinationWidth,
        height: destinationHeight,
      );
      canvas
        ..save()
        ..translate(
          effect.center.dx - origin.dx,
          effect.center.dy - origin.dy,
        )
        ..rotate(effect.rotation)
        ..drawImageRect(image, resolved.sourceRect, destination, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AssetEffectsPainter oldDelegate) =>
      oldDelegate.revision != revision ||
      oldDelegate.imageRevision != imageRevision ||
      oldDelegate.toolRevision != toolRevision;
}

@immutable
class ShushuForkMotion {
  const ShushuForkMotion({required this.offset, required this.angle});

  final Offset offset;
  final double angle;
}

ShushuForkMotion shushuForkMotion(int approach, double progress) {
  const starts = <Offset>[Offset(0, -88), Offset(-72, -72), Offset(72, -72)];
  const endAngles = <double>[-2.72, 2.78, -1.94];
  const angleLeads = <double>[0.14, -0.16, 0.16];
  final index = approach.clamp(0, 2);
  final eased = progress.clamp(0.0, 1.0);
  return ShushuForkMotion(
    offset: Offset.lerp(starts[index], Offset.zero, eased)!,
    angle: endAngles[index] + angleLeads[index] * (1 - eased),
  );
}

class PendingToolHit {
  PendingToolHit.balloon({
    required this.balloon,
    required this.definition,
    this.toolApproach = 0,
  }) : boss = null;

  PendingToolHit.boss({
    required this.boss,
    required this.definition,
    this.toolApproach = 0,
  }) : balloon = null;

  static const impactTime = 0.14;
  static const totalTime = 0.24;

  final Balloon? balloon;
  final BossBalloon? boss;
  final BalloonSkinDefinition definition;
  final int toolApproach;
  double elapsed = 0;
  bool impactApplied = false;

  Offset get center {
    final targetBalloon = balloon;
    if (targetBalloon != null) {
      return targetBalloon.position +
          Offset(targetBalloon.size / 2, targetBalloon.size / 2);
    }
    final targetBoss = boss!;
    return targetBoss.position +
        Offset(targetBoss.size / 2, targetBoss.size / 2);
  }
}

LegendaryToolVisual legendaryToolVisual({
  required BalloonSkinDefinition definition,
  required Offset targetCenter,
  required int approach,
  required double easedProgress,
  required double opacity,
  required double size,
  required Offset gemiStart,
  required Offset gemiEnd,
}) {
  final isFork = definition.popEffectType == BalloonPopEffectType.cream;
  final forkMotion = shushuForkMotion(approach, easedProgress);
  final offset = isFork
      ? forkMotion.offset
      : Offset.lerp(gemiStart, gemiEnd, easedProgress)!;
  final angle = isFork ? forkMotion.angle : -1.12 + 1.04 * easedProgress;
  final center = targetCenter + offset;
  final topLeft = isFork
      ? Offset(center.dx - size * 0.35, center.dy - size * 0.05)
      : Offset(center.dx - size / 2, center.dy - size / 2);
  return LegendaryToolVisual(
    assetPath: definition.hitToolAssetPath!,
    topLeft: topLeft,
    pivot: isFork ? Offset(size * 0.35, size * 0.05) : Offset(size / 2, size),
    size: size,
    rotation: angle,
    opacity: opacity,
    spriteScale: isFork ? 1 : 1.045,
  );
}

LegendaryToolVisual pendingToolVisual(PendingToolHit hit) {
  final swingProgress =
      (hit.elapsed / PendingToolHit.impactTime).clamp(0.0, 1.0);
  final eased = Curves.easeInCubic.transform(swingProgress);
  final fade = hit.elapsed <= PendingToolHit.impactTime
      ? 1.0
      : ((PendingToolHit.totalTime - hit.elapsed) /
              (PendingToolHit.totalTime - PendingToolHit.impactTime))
          .clamp(0.0, 1.0);
  final isFork = hit.definition.popEffectType == BalloonPopEffectType.cream;
  return legendaryToolVisual(
    definition: hit.definition,
    targetCenter: hit.center,
    approach: hit.toolApproach,
    easedProgress: eased,
    opacity: fade,
    size: isFork ? 100 : 116,
    gemiStart: const Offset(-68, -30),
    gemiEnd: const Offset(0, 55),
  );
}

@immutable
class StageIntroDefinition {
  const StageIntroDefinition({
    required this.title,
    required this.headline,
    required this.rules,
  });

  final String title;
  final String headline;
  final List<String> rules;
}

const stageIntroDefinitions = <int, StageIntroDefinition>{
  11: StageIntroDefinition(
    title: 'STAGE 11–20',
    headline: '단단한 풍선 등장!',
    rules: ['풍선마다 2번 터치', '빠르게 모두 터뜨리기'],
  ),
  21: StageIntroDefinition(
    title: 'STAGE 21–30',
    headline: '가짜 풍선 등장!',
    rules: ['가짜 풍선 터치 금지', '진짜 풍선만 터뜨리기'],
  ),
  31: StageIntroDefinition(
    title: 'STAGE 31–40',
    headline: '분열 풍선 등장!',
    rules: ['터뜨리면 작은 풍선으로 분열', '분열된 풍선까지 모두 터뜨리기'],
  ),
  41: StageIntroDefinition(
    title: 'STAGE 41–50',
    headline: '숫자 풍선 등장!',
    rules: ['풍선에 숫자 표시', '숫자 순서대로 터뜨리기'],
  ),
};

bool playBalloonHitSound(BalloonSkinDefinition definition) {
  final assetPath = definition.hitSoundAssetPath;
  if (assetPath == null) return false;
  PopSound.playAsset(assetPath);
  return true;
}

const gameLoopInterval = Duration(milliseconds: 33);
const maxFrameDeltaSeconds = 0.05;

double calculateFrameDelta(Duration elapsed) =>
    (elapsed.inMicroseconds / Duration.microsecondsPerSecond).clamp(
      0.0,
      maxFrameDeltaSeconds,
    );

typedef PeriodicTimerFactory = Timer Function(
    Duration interval, void Function(Timer timer) callback);

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
  const BalloonGamePage({
    super.key,
    this.stage30SwapRollForTest,
    this.toolHitDeltaForTest,
    this.gameplayRendererMode = defaultGameplayRendererMode,
  });

  @visibleForTesting
  final double Function()? stage30SwapRollForTest;

  @visibleForTesting
  final double? toolHitDeltaForTest;

  final GameplayRendererMode gameplayRendererMode;

  @override
  State<BalloonGamePage> createState() => _BalloonGamePageState();
}

class _BalloonGamePageState extends State<BalloonGamePage>
    with WidgetsBindingObserver {
  static final List<StoreProduct> _storeProducts = [
    ...BalloonSkinCatalog.shopDefinitions.map(StoreProduct.fromBalloonSkin),
    StoreProduct(
      id: 'pop-default',
      category: StoreCategory.popEffect,
      name: '기본 효과',
      price: 0,
      owned: true,
      equipped: true,
      previewType: StorePreviewType.effect,
      previewData: Color(0xFFFFC857),
    ),
    StoreProduct(
      id: 'pop-a',
      category: StoreCategory.popEffect,
      name: '특별 효과 A',
      price: 300,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.effect,
      previewData: Color(0xFFFF6B9D),
    ),
    StoreProduct(
      id: 'pop-b',
      category: StoreCategory.popEffect,
      name: '특별 효과 B',
      price: 700,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.effect,
      previewData: Color(0xFF7E57C2),
    ),
    StoreProduct(
      id: 'background-default',
      category: StoreCategory.background,
      name: '기본 배경',
      price: 0,
      owned: true,
      equipped: true,
      previewType: StorePreviewType.background,
      previewData: Color(0xFF56CCFF),
    ),
    StoreProduct(
      id: 'background-a',
      category: StoreCategory.background,
      name: '특별 배경 A',
      price: 800,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.background,
      previewData: Color(0xFF85D86A),
    ),
    StoreProduct(
      id: 'background-b',
      category: StoreCategory.background,
      name: '특별 배경 B',
      price: 1200,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.background,
      previewData: Color(0xFFFFA45B),
    ),
    StoreProduct(
      id: 'sound-default',
      category: StoreCategory.soundEffect,
      name: '기본 POP',
      price: 0,
      owned: true,
      equipped: true,
      previewType: StorePreviewType.sound,
      previewData: Color(0xFF42B8E8),
    ),
    StoreProduct(
      id: 'sound-a',
      category: StoreCategory.soundEffect,
      name: '특별 효과음 A',
      price: 300,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.sound,
      previewData: Color(0xFF5CD6C0),
    ),
    StoreProduct(
      id: 'sound-b',
      category: StoreCategory.soundEffect,
      name: '특별 효과음 B',
      price: 500,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.sound,
      previewData: Color(0xFFFF8A5B),
    ),
    StoreProduct(
      id: 'music-default',
      category: StoreCategory.music,
      name: '기본 음악',
      price: 0,
      owned: true,
      equipped: true,
      previewType: StorePreviewType.music,
      previewData: Color(0xFF7354E8),
    ),
    StoreProduct(
      id: 'music-a',
      category: StoreCategory.music,
      name: '특별 음악 A',
      price: 700,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.music,
      previewData: Color(0xFFFF6D9A),
    ),
    StoreProduct(
      id: 'music-b',
      category: StoreCategory.music,
      name: '특별 음악 B',
      price: 1000,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.music,
      previewData: Color(0xFFFFB300),
    ),
  ];
  static const _stageClearDelay = Duration(milliseconds: 400);
  static const _bossClearDelay = Duration(seconds: 1);
  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _frameStopwatch = Stopwatch();
  final List<Balloon> _balloons = [];
  final List<PopPiece> _pieces = [];
  final List<BurstRing> _rings = [];
  final List<FloatingTextFeedback> _feedbacks = [];
  final List<AssetVisualEffect> _assetEffects = [];
  final List<PendingToolHit> _pendingToolHits = [];
  final ValueNotifier<int> _gameplayFrame = ValueNotifier<int>(0);
  final ValueNotifier<int> _effectsFrame = ValueNotifier<int>(0);
  final GameSpriteCache _gameSpriteCache = GameSpriteCache();
  late final GameRenderState<Balloon> _gameRenderState;
  final ValueNotifier<double> _crystalBackgroundPulse = ValueNotifier<double>(
    0,
  );
  int _effectsRevision = 0;
  final SinglePeriodicGameLoop _gameLoop = SinglePeriodicGameLoop();
  final CoinRewardSession _coinRewardSession = CoinRewardSession();
  Timer? _stageTimer;
  Size _playArea = Size.zero;
  int _nextId = 0;
  final Map<String, int> _lastBalloonColorIndexes = <String, int>{};
  final Map<String, int> _lastBossColorIndexes = <String, int>{};
  int _score = 0;
  int _stage = 1;
  int _secondsLeft = 15;
  Duration _stageTimePenalty = Duration.zero;
  GamePhase _phase = GamePhase.menu;
  final List<BossBalloon> _bosses = [];
  final List<_BossRenderView> _bossRenderViews = [];
  Stage30BossState? _stage30BossState;
  bool _secondSectionUnlocked = false;
  int _bestScore = 0;
  int _lastScore = 0;
  int _coinBalance = 0;
  int _earnedCoins = 0;
  Set<String> _ownedProductIds = <String>{};
  Map<StoreCategory, String> _equippedProductIds = <StoreCategory, String>{};
  final DevCoinTapGate _devCoinTapGate = DevCoinTapGate();
  bool _devCoinDialogOpen = false;
  bool _isNewBest = false;
  bool _resultSaved = false;
  MainTab _mainTab = MainTab.home;
  bool _storeNavigationVisible = true;
  StoreProductFilter _storeProductFilter = StoreProductFilter.all;
  late final PageController _stagePageController;
  late final ValueNotifier<GameHeaderData> _headerData;
  late final Widget _gameHeader;
  int _stagePage = 0;
  bool _initialAssetsPrecached = false;
  bool _stageAdvanceScheduled = false;
  bool _introTargetPlayable = true;

  StageConfig get _stageConfig => StageConfig.forStage(_stage);

  @override
  void initState() {
    super.initState();
    _gameRenderState = GameRenderState<Balloon>(
      basicBalloons: _balloons,
      bosses: _bossRenderViews,
    );
    WidgetsBinding.instance.addObserver(this);
    _secondSectionUnlocked = ProgressStorage.isSecondSectionUnlocked();
    _bestScore = ProgressStorage.bestScore();
    _lastScore = ProgressStorage.lastScore();
    _coinBalance = CoinService.balance;
    SettingsService.applyStoredPreferences();
    PopSound.preloadSharedAssets();
    _ownedProductIds = PurchaseService.ownedProductIds;
    _equippedProductIds = _loadEquippedProductIds();
    for (final definition in BalloonSkinCatalog.definitions) {
      final sounds = <String?>[
        definition.hitSoundAssetPath,
        definition.popSoundAssetPath,
      ];
      for (final sound in sounds) {
        if (sound != null) PopSound.preloadAsset(sound);
      }
    }
    _stagePage = homeStagePageForProgress(ProgressStorage.nextPlayableStage());
    _stagePageController = PageController(initialPage: _stagePage);
    _headerData = ValueNotifier(_createHeaderData());
    _gameHeader = GameHeader(
      data: _headerData,
      onPause: _onPausePressed,
      onEnd: _onEndPressed,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialAssetsPrecached) return;
    _initialAssetsPrecached = true;
    _precacheSkinAssets(_equippedBalloonSkin);
  }

  void _precacheSkinAssets(BalloonSkinDefinition definition) {
    final paths = <String, int>{};
    final spriteWidth = phase4ACanvasSkinIds.contains(definition.id)
        ? GameSpriteResolution.normal.cacheWidth
        : 512;
    void add(String? path, int width) {
      if (path != null) paths[path] = width;
    }

    if (definition.runtimeColorAssetPaths.isEmpty) {
      add(definition.assetPath, spriteWidth);
    } else {
      for (final path in definition.runtimeColorAssetPaths.values) {
        add(path, spriteWidth);
      }
      for (final path in definition.runtimeFakeColorAssetPaths.values) {
        add(path, spriteWidth);
      }
    }
    for (final path in definition.variantAssetPaths) {
      add(path, spriteWidth);
    }
    add(definition.hitToolAssetPath, 256);
    add(definition.burstAssetPath, 320);
    add(definition.wallSplatAssetPath, 320);
    add(definition.screenSplatAssetPath, 320);
    if (definition.runtimeShardAssetPaths.isEmpty) {
      add(definition.shardAssetPath, 128);
    } else {
      for (final path in definition.runtimeShardAssetPaths.values) {
        add(path, 128);
      }
    }
    add(definition.screenCrackAssetPath, 320);
    add(
      BalloonBackgroundRegistry.gameplayAssetPathFor(definition.background),
      720,
    );
    for (final entry in paths.entries) {
      precacheImage(
        ResizeImage(AssetImage(entry.key), width: entry.value),
        context,
      );
    }
    _prepareCanvasSkinSprites(
      definition,
      GameSpriteResolution.normal,
      precache: false,
    );
  }

  Set<String> _canvasSpritePaths(BalloonSkinDefinition definition) => <String>{
        if (definition.assetPath != null) definition.assetPath!,
        ...definition.variantAssetPaths,
      };

  void _prepareCanvasSkinSprites(
    BalloonSkinDefinition definition,
    GameSpriteResolution resolution, {
    bool precache = true,
  }) {
    if (!phase4ACanvasSkinIds.contains(definition.id)) return;
    final paths = _canvasSpritePaths(definition);
    if (paths.isEmpty) return;
    final configuration = createLocalImageConfiguration(context);
    if (precache) {
      for (final path in paths) {
        precacheImage(
          ResizeImage(
            AssetImage(path),
            width: resolution.cacheWidth,
            allowUpscaling: false,
          ),
          context,
        );
      }
    }
    _gameSpriteCache.prepare(
      paths,
      configuration,
      resolution: resolution,
    );
  }

  Map<StoreCategory, String> _loadEquippedProductIds() {
    final result = <StoreCategory, String>{};
    for (final category in StoreCategory.values) {
      final defaults = _storeProducts.where(
        (product) => product.category == category && product.equipped,
      );
      if (defaults.isEmpty) continue;
      final defaultProduct = defaults.first;
      final selectedId = PurchaseService.equippedProductId(
        category.name,
        defaultProductId: defaultProduct.id,
      );
      final matches = _storeProducts.where(
        (product) => product.category == category && product.id == selectedId,
      );
      final selected = matches.isEmpty ? defaultProduct : matches.first;
      final isOwned = selected.owned || _ownedProductIds.contains(selected.id);
      result[category] = isOwned ? selected.id : defaultProduct.id;
    }
    return result;
  }

  GameHeaderData _createHeaderData() => GameHeaderData(
        stage: _stage,
        score: _score,
        remaining: _bosses.isNotEmpty ? _bosses.length : _normalBalloonCount,
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
    _stopwatch.reset();
    _nextId = 0;
    _lastBalloonColorIndexes.clear();
    _lastBossColorIndexes.clear();
    _score = 0;
    _earnedCoins = 0;
    _coinRewardSession.reset();
    _resultSaved = false;
    _isNewBest = false;
    _stage = startStage;
    _secondsLeft = StageConfig.forStage(startStage).duration.inSeconds;
    _phase = GamePhase.playing;
    _balloons.clear();
    _pieces.clear();
    _rings.clear();
    _assetEffects.clear();
    _pendingToolHits.clear();
    _feedbacks.clear();
    _notifyEffectsChanged();
    _clearBosses();
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
    _stopwatch.stop();
    final stagePage = homeStagePageForProgress(
      ProgressStorage.nextPlayableStage(),
    );
    setState(() {
      _score = 0;
      _stage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
      _mainTab = MainTab.home;
      _storeProductFilter = StoreProductFilter.all;
      _storeNavigationVisible = true;
      _stagePage = stagePage;
      _balloons.clear();
      _pieces.clear();
      _rings.clear();
      _assetEffects.clear();
      _pendingToolHits.clear();
      _feedbacks.clear();
      _clearBosses();
    });
    _scheduleStagePageJump(stagePage);
    _publishHeader();
  }

  void _scheduleStagePageJump(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stagePageController.hasClients) return;
      _stagePageController.jumpToPage(page);
    });
  }

  void _recordResult() {
    if (_resultSaved) return;
    _resultSaved = true;
    _earnedCoins = _coinRewardSession.grantForScore(_score);
    _coinBalance = CoinService.balance;
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

  void _onPausePressed() {
    PopSound.playUiClick();
    _pauseGame();
  }

  void _onEndPressed() {
    PopSound.playUiClick();
    _confirmEndGame();
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
    _stageAdvanceScheduled = false;
    _phase = GamePhase.playing;
    _balloons.clear();
    _clearBosses();
    _stage30BossState = null;
    _pendingToolHits.clear();
    _crystalBackgroundPulse.value = 0;

    if (_playArea == Size.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == GamePhase.playing && _balloons.isEmpty) {
          _startStage();
          setState(() {});
        }
      });
      return;
    }

    _feedbacks.clear();
    _stageTimePenalty = Duration.zero;

    final bossSkin = _bossSkinFor(_equippedBalloonSkin);
    if (_stageConfig.isBoss || _stage % 10 == 9) {
      _prepareCanvasSkinSprites(bossSkin, GameSpriteResolution.boss);
    }

    if (_stageConfig.isBoss) {
      _spawnBoss();
      PopSound.playBossAppear();
    } else {
      _spawnBalloons(_stageConfig.balloonCount);
      _spawnFakeBalloons(_stageConfig.fakeBalloonCount);
    }
    _secondsLeft = _stageConfig.duration.inSeconds;
    _stopwatch
      ..reset()
      ..start();
    _publishHeader();
    _startGameLoop();
  }

  void _spawnBalloons(int count) {
    _spawnBalloonGroup(count, isFake: false);
  }

  void _spawnFakeBalloons(int count) {
    _spawnBalloonGroup(count, isFake: true);
  }

  void _spawnBalloonGroup(int count, {required bool isFake}) {
    final skin = _equippedBalloonSkin;
    final requiredHits = isFake
        ? StageConfig.fakeBalloonRequiredHits
        : _stageConfig.requiredHits;
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 48 + (_stage * 4.2) + _random.nextDouble() * 32;
      final size = 78 + _random.nextDouble() * 24;
      _balloons.add(
        Balloon(
          id: _nextId++,
          position: _randomPosition(size),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: _nextSkinColor(skin, boss: false),
          size: size,
          floatPhase: _random.nextDouble() * pi * 2,
          floatPower: 10 + _random.nextDouble() * 10,
          hp: requiredHits,
          maxHp: requiredHits,
          skinId: skin.id,
          isFake: isFake,
          visualVariant: skin.chooseVisualVariant(_random.nextDouble()),
          specialVisual: skin.chooseSpecialSpawn(_random.nextDouble()),
        ),
      );
    }
  }

  int get _normalBalloonCount =>
      _balloons.where((balloon) => !balloon.isFake).length;

  Duration get _remainingStageDuration =>
      _stageConfig.duration - _stopwatch.elapsed - _stageTimePenalty;

  BalloonSkinDefinition get _equippedBalloonSkin =>
      BalloonSkinCatalog.byIdOrDefault(
        _equippedProductIds[StoreCategory.balloon],
      );

  BalloonSkinDefinition _bossSkinFor(BalloonSkinDefinition equipped) =>
      equipped.supportsBossSkin ? equipped : BalloonSkinCatalog.defaultSkin;

  Color _nextSkinColor(BalloonSkinDefinition skin, {required bool boss}) {
    final palette = skin.colorPalette;
    final previousIndexes =
        boss ? _lastBossColorIndexes : _lastBalloonColorIndexes;
    final previous = previousIndexes[skin.id] ?? -1;
    var next = _random.nextInt(palette.length);
    if (skin.avoidImmediateColorRepeat &&
        palette.length > 1 &&
        next == previous) {
      next = (next + 1 + _random.nextInt(palette.length - 1)) % palette.length;
    }
    previousIndexes[skin.id] = next;
    return palette[next];
  }

  void _spawnBoss() {
    final config = _stageConfig;
    final skin = _bossSkinFor(_equippedBalloonSkin);
    final maxSize = _stage >= 20 ? 300.0 : 270.0;
    final minSize = _stage >= 20 ? 225.0 : 210.0;
    final size = min(
      _playArea.shortestSide * 0.62,
      maxSize,
    ).clamp(minSize, maxSize);
    if (_stage == 30) {
      _stage30BossState = Stage30BossState(maxHp: config.bossHp);
    }
    double? previousStage30Angle;
    for (var id = 0; id < config.bossCount; id++) {
      var angle = _random.nextDouble() * pi * 2;
      if (_stage == 30 && previousStage30Angle != null) {
        final angleDifference = atan2(
          sin(angle - previousStage30Angle),
          cos(angle - previousStage30Angle),
        ).abs();
        if (angleDifference < pi / 3) {
          angle = (angle + pi / 2) % (pi * 2);
        }
      }
      if (_stage == 30) previousStage30Angle = angle;
      final speed = config.bossSpeed;
      final boss = BossBalloon(
        id: id,
        position: _nonOverlappingBossPosition(size),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: size,
        maxHp: config.bossHp,
        skinId: skin.id,
        skinColor: _nextSkinColor(skin, boss: true),
        isFake: _stage30BossState?.isFakeBoss(id) ?? false,
        turnIntervalOffset: _stage == 30 ? (id == 0 ? -0.055 : 0.055) : 0,
        initialTurnCooldown: _stage == 30
            ? 0.52 + id * 0.17 + _random.nextDouble() * 0.08
            : 0.65,
        visualVariant: skin.chooseVisualVariant(_random.nextDouble()),
        specialVisual: skin.chooseSpecialSpawn(_random.nextDouble()),
        visualPhase: _random.nextDouble() * pi * 2,
      );
      _bosses.add(boss);
      _bossRenderViews.add(
        _BossRenderView(
          boss: boss,
          hpOf: _currentBossHp,
          maxHpOf: _currentBossMaxHp,
          colorOf: (candidate) => _bossColor(
            candidate,
            BalloonSkinCatalog.byIdOrDefault(candidate.skinId),
          ),
        ),
      );
    }
  }

  int _currentBossHp(BossBalloon boss) => _stage30BossState?.hp ?? boss.hp;

  int _currentBossMaxHp(BossBalloon boss) =>
      _stage30BossState?.maxHp ?? boss.maxHp;

  void _clearBosses() {
    _bosses.clear();
    _bossRenderViews.clear();
  }

  Offset _nonOverlappingBossPosition(double size) {
    for (var attempt = 0; attempt < 80; attempt++) {
      final candidate = _randomPosition(size);
      final candidateRect = Rect.fromLTWH(
        candidate.dx,
        candidate.dy,
        size,
        size,
      );
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
    _updatePendingToolHits(widget.toolHitDeltaForTest ?? dt);
    if (_phase == GamePhase.stageClear || _phase == GamePhase.bossClear) {
      _updateEffects(dt);
      _gameplayFrame.value++;
      return;
    }
    if (_phase != GamePhase.playing) return;

    _updateBalloons(dt);
    _updateBoss(dt);
    _updateEffects(dt);

    final remaining = _remainingStageDuration;
    if (remaining <= Duration.zero) {
      _finishGame();
      return;
    }
    final secondsLeft = (remaining.inMilliseconds + 999) ~/ 1000;
    if (secondsLeft != _secondsLeft) {
      _secondsLeft = secondsLeft;
      _publishHeader();
    }
    _gameplayFrame.value++;
  }

  void _updateBalloons(double dt) {
    if (_phase != GamePhase.playing || _playArea == Size.zero) return;

    final completedExits = <Balloon>[];
    for (final balloon in _balloons) {
      if (balloon.isExiting) {
        balloon.exitProgress += dt / 0.24;
        balloon.position += balloon.exitVelocity * dt;
        if (balloon.exitProgress >= 1) completedExits.add(balloon);
        continue;
      }
      balloon.impactVisual = max(0, balloon.impactVisual - dt * 6);
      balloon.floatPhase += dt * 2.4;
      final drift = Offset(0, sin(balloon.floatPhase) * balloon.floatPower);
      final next = balloon.position + (balloon.velocity * dt) + (drift * dt);
      balloon.position = _bounce(next, balloon.velocity, balloon.size, (v) {
        if (v != balloon.velocity) balloon.impactVisual = 1;
        balloon.velocity = v;
      });
    }
    for (final balloon in completedExits) {
      _completeKickExit(balloon);
    }
  }

  void _updateBoss(double dt) {
    if (_phase != GamePhase.playing) return;

    for (final boss in _bosses) {
      boss.visualPhase += dt * 2.2;
      boss.impactVisual = max(0, boss.impactVisual - dt * 6);
      boss.turnCooldown -= dt;
      if (boss.turnCooldown <= 0) {
        final speed = boss.velocity.distance;
        final angle = _random.nextDouble() * pi * 2;
        boss.velocity = Offset(cos(angle) * speed, sin(angle) * speed);
        final hpRatio = _currentBossHp(boss) / _currentBossMaxHp(boss);
        boss.turnCooldown = max(
          0.12,
          0.24 + hpRatio * 0.38 + boss.turnIntervalOffset,
        );
      }
      final next = nextBossPosition(boss, dt);
      boss.position = _bounce(next, boss.velocity, boss.size, (velocity) {
        if (velocity != boss.velocity) boss.impactVisual = 1;
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

  bool _queueToolHit({
    Balloon? balloon,
    BossBalloon? boss,
    required BalloonSkinDefinition definition,
  }) {
    if (definition.hitToolAssetPath == null) return false;
    final alreadyPending = _pendingToolHits.any(
      (hit) => identical(hit.balloon, balloon) && identical(hit.boss, boss),
    );
    if (alreadyPending) return true;
    final toolApproach = definition.popEffectType == BalloonPopEffectType.cream
        ? _random.nextInt(3)
        : 0;
    setState(() {
      _pendingToolHits.add(
        balloon != null
            ? PendingToolHit.balloon(
                balloon: balloon,
                definition: definition,
                toolApproach: toolApproach,
              )
            : PendingToolHit.boss(
                boss: boss!,
                definition: definition,
                toolApproach: toolApproach,
              ),
      );
    });
    return true;
  }

  void _updatePendingToolHits(double dt) {
    if (_pendingToolHits.isEmpty) return;
    for (final hit in _pendingToolHits) {
      hit.elapsed += dt;
      if (!hit.impactApplied && hit.elapsed >= PendingToolHit.impactTime) {
        hit.impactApplied = true;
        final balloon = hit.balloon;
        if (balloon != null) {
          _applyBalloonHit(balloon, hit.definition);
        } else {
          _applyBossHit(hit.boss!, hit.definition);
        }
      }
    }
    _pendingToolHits.removeWhere(
      (hit) => hit.elapsed >= PendingToolHit.totalTime,
    );
  }

  void _notifyEffectsChanged() {
    _effectsRevision++;
    _effectsFrame.value++;
  }

  void _updateEffects(double dt) {
    var changed = advanceEffects(_pieces, _rings, dt, feedbacks: _feedbacks);
    changed = advanceAssetVisualEffects(_assetEffects, dt) || changed;
    final nextCrystalPulse = max(0.0, _crystalBackgroundPulse.value - dt * 4.8);
    if (nextCrystalPulse != _crystalBackgroundPulse.value) {
      _crystalBackgroundPulse.value = nextCrystalPulse;
    }
    if (changed) {
      _notifyEffectsChanged();
    }
  }

  void _popBalloon(Balloon balloon) {
    if (_phase != GamePhase.playing) return;

    if (balloon.isFake) {
      _hitFakeBalloon(balloon);
      return;
    }

    final skin = BalloonSkinCatalog.byIdOrDefault(balloon.skinId);
    if (balloon.isExiting) return;
    if (balloon.hp <= 1 &&
        skin.exitAnimation == BalloonExitAnimationType.kickAway) {
      _startKickExit(balloon, skin);
      return;
    }
    if (_queueToolHit(balloon: balloon, definition: skin)) return;
    _applyBalloonHit(balloon, skin);
  }

  void _applyBalloonHit(Balloon balloon, BalloonSkinDefinition skin) {
    if (_phase != GamePhase.playing || !_balloons.contains(balloon)) return;
    final center =
        balloon.position + Offset(balloon.size / 2, balloon.size / 2);
    if (balloon.hp > 1) {
      if (!playBalloonHitSound(skin)) PopSound.playLightTap();
      _spawnGemiShards(skin, center, balloon.size, balloon.color, count: 2);
      _registerLegendaryBackgroundImpact(skin, finalHit: false);
      void applyHit() {
        balloon.hp--;
        balloon.size *= 0.88;
      }

      if (_usesCanvasPlayfield) {
        applyHit();
      } else {
        setState(applyHit);
      }
      return;
    }

    HapticService.shortImpact();
    playBalloonHitSound(skin);
    _registerLegendaryBackgroundImpact(skin, finalHit: true);
    _playSkinPopSound(skin, boss: false);
    _spawnSkinPopEffect(skin, center, balloon.color, balloon.size, big: false);
    _spawnRing(center, balloon.color, balloon.size * 0.72);

    final isCanvasNonFinalPop = _usesCanvasPlayfield && _normalBalloonCount > 1;
    if (isCanvasNonFinalPop) {
      _balloons.remove(balloon);
      balloon.hp = 0;
    } else {
      setState(() {
        final removed = _balloons.remove(balloon);
        if (!removed) return;
        balloon.hp = 0;
        if (_normalBalloonCount == 0) {
          _balloons.removeWhere((candidate) => candidate.isFake);
          _showStageClear();
        }
      });
    }
    _publishHeader();
  }

  void _startKickExit(Balloon balloon, BalloonSkinDefinition skin) {
    if (_phase != GamePhase.playing || !_balloons.contains(balloon)) return;
    HapticService.shortImpact();
    playBalloonHitSound(skin);
    final center =
        balloon.position + Offset(balloon.size / 2, balloon.size / 2);
    var direction = center - _playArea.center(Offset.zero);
    if (direction.distanceSquared < 1) {
      final angle = _random.nextDouble() * pi * 2;
      direction = Offset(cos(angle), sin(angle));
    } else {
      direction /= direction.distance;
    }
    final exitDistance = _playArea.longestSide + balloon.size * 2;
    void beginExit() {
      balloon.exitProgress = 0.0001;
      balloon.exitVelocity = direction * (exitDistance / 0.24);
    }

    if (_usesCanvasPlayfield) {
      beginExit();
    } else {
      setState(beginExit);
    }
  }

  void _completeKickExit(Balloon balloon) {
    if (!_balloons.remove(balloon)) return;
    balloon.hp = 0;
    if (_normalBalloonCount == 0) {
      _balloons.removeWhere((candidate) => candidate.isFake);
      _showStageClear();
    }
    _publishHeader();
  }

  void _hitFakeBalloon(Balloon balloon) {
    if (_phase != GamePhase.playing || !_balloons.remove(balloon)) return;

    _applyFakeHitPenalty(
      balloon.position + Offset(balloon.size / 2, balloon.size / 2),
    );
  }

  void _hitFakeBoss(BossBalloon boss) {
    if (_phase != GamePhase.playing || !_bosses.contains(boss)) return;

    _applyFakeHitPenalty(boss.position + Offset(boss.size / 2, boss.size / 2));
  }

  void _applyFakeHitPenalty(Offset center) {
    HapticService.shortImpact();
    PopSound.playFake();
    _stageTimePenalty += const Duration(seconds: 2);
    _feedbacks.add(
      FloatingTextFeedback(
        center: center,
        text: '-2초',
        color: const Color(0xFFE53935),
        life: 0.72,
        maxLife: 0.72,
      ),
    );
    _notifyEffectsChanged();

    final remaining = _remainingStageDuration;
    if (remaining <= Duration.zero) {
      _finishGame();
      return;
    }

    _secondsLeft = (remaining.inMilliseconds + 999) ~/ 1000;
    if (!_usesCanvasPlayfield) setState(() {});
    _publishHeader();
  }

  void _showStageClear() {
    if (_stageAdvanceScheduled) return;
    _stageAdvanceScheduled = true;
    _stopGameLoop();
    _stopwatch.stop();
    _score += _secondsLeft;
    _saveNextPlayableStage();
    _phase = GamePhase.stageClear;
    if (_usesCanvasPlayfield) _gameplayFrame.value++;
    _publishHeader();
    _stageTimer?.cancel();
    _stageTimer = Timer(_stageClearDelay, () {
      if (!mounted || _phase != GamePhase.stageClear) return;
      setState(_advanceRunAfterClear);
    });
  }

  void _saveNextPlayableStage() {
    final nextStage = StageConfig.nextStageAfter(_stage);
    if (nextStage != null) {
      ProgressStorage.advanceNextPlayableStage(nextStage);
    }
  }

  void _advanceRunAfterClear() {
    final nextStage = StageConfig.nextStageAfter(_stage);
    final boundaryStage = _stage + 1;
    if (stageIntroDefinitions.containsKey(boundaryStage)) {
      _introTargetPlayable = nextStage == boundaryStage;
      _stage = boundaryStage;
      if (_introTargetPlayable) {
        _secondsLeft = StageConfig.forStage(boundaryStage).duration.inSeconds;
      }
      _phase = GamePhase.stageIntro;
      _pendingToolHits.clear();
      _stageAdvanceScheduled = false;
      _publishHeader();
      return;
    }

    if (nextStage == null) {
      _completeGame();
      return;
    }

    _stage = nextStage;
    _startStage();
  }

  void _dismissStageIntro() {
    if (_phase != GamePhase.stageIntro) return;
    PopSound.playUiClick();
    if (_introTargetPlayable) {
      setState(_startStage);
    } else {
      setState(() {
        _stage = StageConfig.lastImplementedStage;
        _completeGame();
      });
    }
  }

  void _hitBoss(BossBalloon boss) {
    if (_phase != GamePhase.playing || !_bosses.contains(boss)) return;

    if (boss.isFake) {
      _hitFakeBoss(boss);
      return;
    }

    final skin = BalloonSkinCatalog.byIdOrDefault(boss.skinId);
    if (_queueToolHit(boss: boss, definition: skin)) return;
    _applyBossHit(boss, skin);
  }

  void _applyBossHit(BossBalloon boss, BalloonSkinDefinition skin) {
    if (_phase != GamePhase.playing || !_bosses.contains(boss)) return;
    HapticService.shortImpact();
    final center = boss.position + Offset(boss.size / 2, boss.size / 2);
    if (!playBalloonHitSound(skin)) PopSound.play();
    final hitColor = _bossColor(boss, skin);
    final finalHit = _currentBossHp(boss) <= 1;
    if (!finalHit) {
      _spawnGemiShards(skin, center, boss.size, hitColor, count: 2);
    }
    _registerLegendaryBackgroundImpact(skin, finalHit: finalHit);
    if (skin.shardAssetPath == null) {
      _spawnPieces(center, hitColor, boss.size * 0.35, big: false);
    }

    void applyHit() {
      final sharedState = _stage30BossState;
      if (sharedState != null) {
        final swapRoll =
            widget.stage30SwapRollForTest?.call() ?? _random.nextDouble();
        final swapped = sharedState.registerRealHit(swapRoll);
        if (sharedState.hp <= 0) {
          _clearStage30Boss(boss, center, hitColor);
          return;
        }

        final hpRatio = sharedState.hp / sharedState.maxHp;
        for (final candidate in _bosses) {
          candidate.size *= 0.965;
          candidate.velocity = stage30AcceleratedBossVelocity(
            candidate.velocity,
          );
          candidate.turnCooldown = min(
            candidate.turnCooldown,
            max(0.10, 0.18 + hpRatio * 0.28 + candidate.turnIntervalOffset),
          );
        }
        if (swapped) {
          applyStage30BossRoles(_bosses, sharedState);
        }
        return;
      }

      boss.hp--;
      if (boss.hp <= 0) {
        _clearBoss(boss, center, hitColor);
        return;
      }
      boss.size *= 0.965;
      boss.velocity *= 1.075;
      final hpRatio = boss.hp / boss.maxHp;
      boss.turnCooldown = min(boss.turnCooldown, 0.18 + hpRatio * 0.28);
    }

    if (_usesCanvasPlayfield && !finalHit) {
      applyHit();
    } else {
      setState(applyHit);
    }
    _publishHeader();
  }

  void _hitStage30BossAt(TapUpDetails details) {
    if (_stage != 30 || _phase != GamePhase.playing) return;
    final boss = closestStage30BossForTap(_bosses, details.localPosition);
    if (boss != null) _hitBoss(boss);
  }

  void _clearStage30Boss(BossBalloon boss, Offset center, Color color) {
    if (_stage30BossState == null) return;
    final skin = BalloonSkinCatalog.byIdOrDefault(boss.skinId);
    final sourceSize = boss.size;
    _clearBosses();
    _stage30BossState = null;
    _score += 10;
    _playSkinPopSound(skin, boss: true);
    _spawnSkinPopEffect(skin, center, color, sourceSize, big: true);
    _spawnRing(center, const Color(0xFFFFD54F), 190);
    _spawnRing(center, const Color(0xFFFF5C8A), 250);
    _finishBossStageClear();
  }

  void _clearBoss(BossBalloon boss, Offset center, Color color) {
    final removed = _bosses.remove(boss);
    if (!removed) return;
    _bossRenderViews.removeWhere((view) => identical(view.boss, boss));
    _score += 10;
    final skin = BalloonSkinCatalog.byIdOrDefault(boss.skinId);
    _playSkinPopSound(skin, boss: true);
    _spawnSkinPopEffect(skin, center, color, boss.size, big: true);
    _spawnRing(center, const Color(0xFFFFD54F), 190);
    _spawnRing(center, const Color(0xFFFF5C8A), 250);
    if (_bosses.isNotEmpty) {
      _publishHeader();
      return;
    }

    _finishBossStageClear();
  }

  void _finishBossStageClear() {
    if (_stageAdvanceScheduled) return;
    _stageAdvanceScheduled = true;
    _stopGameLoop();
    _stopwatch.stop();
    _score += _secondsLeft;
    PopSound.playBossClear();
    _phase = GamePhase.bossClear;
    if (_usesCanvasPlayfield) _gameplayFrame.value++;
    if (_stage == 10) {
      _secondSectionUnlocked = true;
      ProgressStorage.unlockSecondSection();
    }
    _saveNextPlayableStage();
    _publishHeader();
    _stageTimer?.cancel();
    _stageTimer = Timer(_bossClearDelay, () {
      if (!mounted || _phase != GamePhase.bossClear) return;
      setState(_advanceRunAfterClear);
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
    _assetEffects.clear();
    _pendingToolHits.clear();
    _feedbacks.clear();
    _notifyEffectsChanged();
    _publishHeader();
  }

  void _spawnPieces(
    Offset center,
    Color color,
    double sourceSize, {
    required bool big,
  }) {
    addBalloonShardPieces(
      pieces: _pieces,
      random: _random,
      center: center,
      color: color,
      big: big,
    );
    _notifyEffectsChanged();
  }

  void _spawnSkinPopEffect(
    BalloonSkinDefinition skin,
    Offset center,
    Color color,
    double sourceSize, {
    required bool big,
  }) {
    if (skin.shardAssetPath == null) {
      addBalloonPopEffect(
        definition: skin,
        pieces: _pieces,
        random: _random,
        center: center,
        color: color,
        sourceSize: sourceSize,
        big: big,
      );
    }
    _spawnSkinAssetPopEffects(skin, center, sourceSize, color, big: big);
    _notifyEffectsChanged();
  }

  void _spawnGemiShards(
    BalloonSkinDefinition skin,
    Offset center,
    double sourceSize,
    Color color, {
    required int count,
  }) {
    final path = gemiShardAssetForColor(skin, color);
    if (path == null) return;
    addGemiShardAssetEffects(
      effects: _assetEffects,
      random: _random,
      assetPath: path,
      center: center,
      sourceSize: sourceSize,
      count: count,
    );
    _notifyEffectsChanged();
  }

  void _registerLegendaryBackgroundImpact(
    BalloonSkinDefinition skin, {
    required bool finalHit,
  }) {
    if (skin.background != BalloonBackgroundType.crystalCave) return;
    _crystalBackgroundPulse.value =
        finalHit ? 1 : max(_crystalBackgroundPulse.value, 0.55);
  }

  void _spawnSkinAssetPopEffects(
    BalloonSkinDefinition skin,
    Offset center,
    double sourceSize,
    Color color, {
    required bool big,
  }) {
    if (skin.shardAssetPath != null) {
      _spawnGemiShards(skin, center, sourceSize, color, count: big ? 12 : 8);
    }

    final crackPath = skin.screenCrackAssetPath;
    if (crackPath != null &&
        _playArea != Size.zero &&
        _random.nextDouble() < skin.screenCrackChance) {
      _assetEffects.add(
        AssetVisualEffect(
          assetPath: crackPath,
          center: Offset(
            _playArea.width * (0.18 + _random.nextDouble() * 0.64),
            _playArea.height * (0.18 + _random.nextDouble() * 0.58),
          ),
          velocity: Offset.zero,
          size: 105 + _random.nextDouble() * 45,
          rotation: (_random.nextDouble() - 0.5) * 0.65,
          spin: 0,
          life: 0.72,
          maxLife: 0.72,
          paintLayer: AssetEffectPaintLayer.gemiScreenCrack,
        ),
      );
    }

    final burstPath = skin.burstAssetPath;
    if (burstPath != null) {
      final count = big ? 8 : 5;
      for (var index = 0; index < count; index++) {
        final angle = pi * 2 * index / count + _random.nextDouble() * 0.35;
        final speed = (big ? 115 : 72) + _random.nextDouble() * 45;
        _assetEffects.add(
          AssetVisualEffect(
            assetPath: burstPath,
            center: center,
            velocity: Offset(cos(angle) * speed, sin(angle) * speed - 25),
            size: (big ? sourceSize * 0.16 : sourceSize * 0.22) +
                _random.nextDouble() * 18,
            rotation: _random.nextDouble() * pi * 2,
            spin: (_random.nextDouble() - 0.5) * 3,
            life: 0.52,
            maxLife: 0.52,
            paintLayer: AssetEffectPaintLayer.shushuBurst,
          ),
        );
      }
    }

    final wallPath = skin.wallSplatAssetPath;
    if (wallPath != null && _playArea != Size.zero) {
      final count = 2 + _random.nextInt(3);
      for (var index = 0; index < count; index++) {
        final leftEdge = index.isEven;
        _assetEffects.add(
          AssetVisualEffect(
            assetPath: wallPath,
            center: Offset(
              leftEdge ? 4 : _playArea.width - 4,
              45 + _random.nextDouble() * max(1, _playArea.height - 90),
            ),
            velocity: Offset.zero,
            size: 48 + _random.nextDouble() * 24,
            rotation: leftEdge ? 0 : pi,
            spin: 0,
            life: 1.15,
            maxLife: 1.15,
            paintLayer: leftEdge
                ? AssetEffectPaintLayer.shushuWallLeft
                : AssetEffectPaintLayer.shushuWallRight,
          ),
        );
      }
    }

    final screenPath = skin.screenSplatAssetPath;
    if (screenPath != null && _playArea != Size.zero) {
      final count = 1 + _random.nextInt(2);
      for (var index = 0; index < count; index++) {
        _assetEffects.add(
          AssetVisualEffect(
            assetPath: screenPath,
            center: Offset(
              _playArea.width * (0.22 + _random.nextDouble() * 0.56),
              _playArea.height * (0.20 + _random.nextDouble() * 0.56),
            ),
            velocity: Offset.zero,
            size: 42 + _random.nextDouble() * 18,
            rotation: _random.nextDouble() * pi * 2,
            spin: 0,
            life: 0.92,
            maxLife: 0.92,
            paintLayer: AssetEffectPaintLayer.shushuFront,
          ),
        );
      }
    }
  }

  void _playSkinPopSound(BalloonSkinDefinition skin, {required bool boss}) {
    // Sound-pack selection can override this dispatch point in a later update.
    playBalloonPopSound(skin, boss: boss);
  }

  void _spawnRing(Offset center, Color color, double radius) {
    addBalloonBurstRing(
      rings: _rings,
      center: center,
      color: color,
      radius: radius,
    );
    _notifyEffectsChanged();
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
      _clearBosses();
      _feedbacks.clear();
    });
    _publishHeader();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopGameLoop();
    _stageTimer?.cancel();
    _stopwatch.stop();
    _headerData.dispose();
    _gameplayFrame.dispose();
    _effectsFrame.dispose();
    _gameSpriteCache.dispose();
    _crystalBackgroundPulse.dispose();
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

    SettingsService.resetAllData();
    _reloadAfterAllDataReset();
  }

  void _reloadAfterAllDataReset() {
    if (!mounted) return;
    setState(() {
      _secondSectionUnlocked = false;
      _bestScore = 0;
      _lastScore = 0;
      _coinBalance = 0;
      _earnedCoins = 0;
      _ownedProductIds = <String>{};
      _equippedProductIds = _loadEquippedProductIds();
      _isNewBest = false;
      _score = 0;
      _stage = 1;
      _secondsLeft = 10;
      _phase = GamePhase.menu;
      _stagePage = 0;
    });
    _scheduleStagePageJump(0);
  }

  // H-01 홈 화면
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
                          child: _mainTopOverlay(
                            enableDevCoinTap: true,
                            showCoinAddButton: true,
                          ),
                        ),
                        Positioned(
                          top: 18,
                          left: 55,
                          right: 55,
                          height: 300,
                          child: IgnorePointer(child: _buildPoppopLogo()),
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
                                leftTap: () => _startGame(21),
                                rightTap: null,
                                leftLocked: false,
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

  Widget _mainTopOverlay({
    bool enableDevCoinTap = false,
    bool showCoinAddButton = false,
  }) =>
      Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const ValueKey('home-coin-dev-tap-target'),
                  behavior: HitTestBehavior.opaque,
                  onTap: enableDevCoinTap ? _onDevCoinTap : null,
                  child: _homeCoinHud(_coinBalance),
                ),
                if (showCoinAddButton) ...[
                  const SizedBox(width: 5),
                  _coinAddButton(),
                ],
              ],
            ),
          ),
          Align(alignment: Alignment.centerRight, child: _homeSettingsButton()),
        ],
      );

  Widget _coinAddButton() => Material(
        color: const Color(0xFFFF6B9D),
        elevation: 3,
        shadowColor: const Color(0x44B71E5C),
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('home-coin-add-button'),
          onTap: _openCoinPurchasePage,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      );

  // C-01 코인 충전 화면
  Future<void> _openCoinPurchasePage() async {
    PopSound.playUiClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const CoinPurchasePage()),
    );
    if (!mounted) return;
    setState(() => _coinBalance = CoinService.balance);
  }

  // TEMP DEV TOOL - remove before production release.
  void _onDevCoinTap() {
    if (_devCoinDialogOpen || _mainTab != MainTab.home) return;
    if (_devCoinTapGate.registerTap(DateTime.now())) {
      _showDevCoinPasswordDialog();
    }
  }

  // TEMP DEV TOOL - remove before production release.
  Future<void> _showDevCoinPasswordDialog() async {
    if (_devCoinDialogOpen || !mounted) return;
    _devCoinDialogOpen = true;
    final controller = TextEditingController();
    var submitted = false;
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('개발자 테스트'),
        content: TextField(
          key: const ValueKey('dev-coin-password-input'),
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: '비밀번호', counterText: ''),
        ),
        actions: [
          TextButton(
            key: const ValueKey('dev-coin-cancel'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const ValueKey('dev-coin-confirm'),
            onPressed: () {
              if (submitted) return;
              submitted = true;
              Navigator.pop(dialogContext, controller.text);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    controller.dispose();
    _devCoinDialogOpen = false;
    _devCoinTapGate.reset();
    if (!mounted || password == null) return;
    if (password != tempDevCoinPassword) {
      _showComingSoon('비밀번호가 올바르지 않습니다.');
      return;
    }
    setState(() {
      _coinBalance = CoinService.addCoins(tempDevCoinGrantAmount);
    });
    _showComingSoon('테스트 코인 10,000개가 추가되었습니다.');
  }

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
                const [Color(0xFFFFFF72), Color(0xFFFFC400), Color(0xFFFF8A00)],
                const Color(0xFFD96500),
                isLowerLine: false,
              ),
            ),
            Positioned(
              top: 119,
              child: _logoLine(
                'POP',
                const [Color(0xFFFFB5C2), Color(0xFFFF5275), Color(0xFFE91E63)],
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

  Widget _logoLine(
    String text,
    List<Color> colors,
    Color depthColor, {
    required bool isLowerLine,
  }) {
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
                child: _logoLetter(text[index], style, colors, depthColor),
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
            child: Text(letter, style: style.copyWith(color: Colors.white)),
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
                  Color(0x00FFFFFF)
                ],
                stops: [0, 0.32, 0.58],
              ).createShader(bounds),
              child: Text(letter, style: style.copyWith(color: Colors.white)),
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
              subtitle: leftTitle.startsWith('1 ')
                  ? '기본 풍선 · 보스 도전!'
                  : leftTitle.startsWith('21 ')
                      ? '가짜 풍선을 터뜨리지 마세요!'
                      : 'COMING SOON',
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
          key: ValueKey('stage-card-$title'),
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
            border: Border.all(color: const Color(0x99FFFFFF), width: 1.5),
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
            borderRadius: BorderRadius.circular(22.5),
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
                            Shadow(color: Colors.white, offset: Offset(0, 2)),
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
                          fontSize: 12,
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
                                    : title.startsWith('21 ')
                                        ? 'start-section-3'
                                        : 'start-$title',
                          ),
                          onPressed: onTap == null
                              ? null
                              : () {
                                  PopSound.playUiClick();
                                  onTap();
                                },
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
            _recordTile('최고 기록', _bestScore, _isNewBest, isBest: true),
            Container(width: 1.5, height: 54, color: const Color(0xFFE6D8CB)),
            _recordTile('최근 기록', _lastScore, false, isBest: false),
          ],
        ),
      );

  Widget _recordTile(
    String label,
    int score,
    bool isNew, {
    required bool isBest,
  }) =>
      Expanded(
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
                      colors: isBest
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
                    isBest
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
                        fontSize: 30,
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
          key: const ValueKey('main-bottom-navigation-bar'),
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
                key: const ValueKey('home-nav-event'),
                icon: Icons.celebration_rounded,
                label: '이벤트',
                selected: selectedTab == MainTab.event,
                selectionKey: selectedTab == MainTab.event
                    ? const ValueKey('home-nav-selected-event')
                    : null,
                onTap: _onEventMenuTap,
              ),
              _navItem(
                key: const ValueKey('home-nav-ranking'),
                icon: Icons.emoji_events_rounded,
                label: '랭킹',
                selected: selectedTab == MainTab.ranking,
                selectionKey: selectedTab == MainTab.ranking
                    ? const ValueKey('home-nav-selected-ranking')
                    : null,
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
        onTap: () {
          PopSound.playUiClick();
          onTap();
        },
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
                          Shadow(
                              color: Color(0x55002C4E), offset: Offset(0, 1)),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      );

  // SET-01 설정 화면. H-01과 S-02가 이 진입점을 함께 사용한다.
  Future<void> _onSettingsPressed() async {
    PopSound.playUiClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            SettingsPage(onDataReset: _reloadAfterAllDataReset),
      ),
    );
  }

  void _onHomeMenuTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_mainTab != MainTab.home) {
      final stagePage = homeStagePageForProgress(
        ProgressStorage.nextPlayableStage(),
      );
      setState(() {
        _mainTab = MainTab.home;
        _storeProductFilter = StoreProductFilter.all;
        _stagePage = stagePage;
      });
      _scheduleStagePageJump(stagePage);
    }
  }

  void _onShopMenuTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_mainTab != MainTab.store) {
      setState(() {
        _mainTab = MainTab.store;
        _storeProductFilter = StoreProductFilter.all;
        _storeNavigationVisible = true;
      });
    }
  }

  void _onEventMenuTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_mainTab != MainTab.event) {
      setState(() {
        _mainTab = MainTab.event;
        _storeProductFilter = StoreProductFilter.all;
      });
    }
  }

  bool _onStoreScrollNotification(ScrollNotification notification) {
    if (_mainTab != MainTab.store) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _setStoreNavigationVisible(true);
      return false;
    }
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        _setStoreNavigationVisible(false);
      } else if (delta < 0) {
        _setStoreNavigationVisible(true);
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _setStoreNavigationVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        _setStoreNavigationVisible(true);
      }
    }
    return false;
  }

  void _setStoreNavigationVisible(bool visible) {
    if (!mounted || _storeNavigationVisible == visible) return;
    setState(() => _storeNavigationVisible = visible);
  }

  Future<void> _onRankingMenuTap() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            WeeklyRankingPage(currentNickname: SettingsService.nickname),
      ),
    );
  }

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

  double _homeChromeScale(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableWidth = media.size.width -
        max(media.padding.left, 4) -
        max(media.padding.right, 4);
    final availableHeight = media.size.height -
        max(media.padding.top, 4) -
        max(media.padding.bottom, 4);
    return min(1.0, min(availableWidth / 520, availableHeight / 950));
  }

  Widget _scaledHomeChrome({
    required double scale,
    required double width,
    required double height,
    required Widget child,
  }) =>
      SizedBox(
        width: width * scale,
        height: height * scale,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(width: width, height: height, child: child),
        ),
      );

  // S-02 상점 상품 목록 화면. S-01은 더 이상 진입 경로에 사용되지 않는다.
  Widget _buildShopScreen() => _buildStoreCategoryDetail(StoreCategory.balloon);

  List<StoreProduct> _filteredStoreProducts(StoreCategory category) {
    return _storeProducts.map(_currentStoreProduct).where((product) {
      if (product.category != category) return false;
      return switch (_storeProductFilter) {
        StoreProductFilter.all => true,
        StoreProductFilter.owned => product.owned,
        StoreProductFilter.unowned => !product.owned,
        StoreProductFilter.limited => product.limited,
      };
    }).toList(growable: false);
  }

  StoreProduct _currentStoreProduct(StoreProduct product) {
    final owned = product.owned || _ownedProductIds.contains(product.id);
    final equipped = _equippedProductIds[product.category] == product.id;
    return owned == product.owned && equipped == product.equipped
        ? product
        : product.copyWith(owned: owned, equipped: equipped);
  }

  // S-02 상점 상품 목록 화면
  Widget _buildStoreCategoryDetail(StoreCategory category) {
    final homeChromeScale = _homeChromeScale(context);
    final products = _filteredStoreProducts(category);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Center(
                    child: _scaledHomeChrome(
                      scale: homeChromeScale,
                      width: 500,
                      height: 38,
                      child: _mainTopOverlay(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                StoreProductFilterBar(
                  selected: _storeProductFilter,
                  onSelected: (filter) => setState(() {
                    _storeProductFilter = filter;
                    _storeNavigationVisible = true;
                  }),
                ),
                Expanded(
                  child: products.isEmpty && category != StoreCategory.balloon
                      ? const Center(
                          child: Text(
                            '표시할 상품이 없습니다',
                            key: ValueKey('store-products-empty'),
                            style: TextStyle(
                              color: Color(0xFF6E8492),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          key: const ValueKey('store-detail-scroll'),
                          onNotification: _onStoreScrollNotification,
                          child: _buildStoreProductList(
                            category,
                            products,
                            homeChromeScale,
                          ),
                        ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 86 * homeChromeScale,
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
                    child: Center(
                      child: _scaledHomeChrome(
                        scale: homeChromeScale,
                        width: 442,
                        height: 86,
                        child: _bottomMenu(selectedTab: MainTab.store),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProductList(
    StoreCategory category,
    List<StoreProduct> products,
    double homeChromeScale,
  ) {
    final bottomPadding = 86 * homeChromeScale + 24;
    if (category != StoreCategory.balloon) {
      return GridView.builder(
        key: const ValueKey('store-product-grid'),
        padding: EdgeInsets.fromLTRB(6, 8, 6, bottomPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return StoreProductCard(
            product: product,
            onPressed: () => _showBalloonPreview(product),
          );
        },
      );
    }

    final productsByRarity = <BalloonRarity, List<StoreProduct>>{
      for (final rarity in BalloonRarity.values)
        rarity: products
            .where((product) => product.rarity == rarity)
            .toList(growable: false),
    };
    return ListView(
      key: const ValueKey('store-product-grid'),
      padding: EdgeInsets.fromLTRB(6, 6, 6, bottomPadding),
      children: [
        for (final rarity in BalloonRarity.values) ...[
          BalloonRaritySectionHeader(rarity: rarity),
          _buildStoreRarityProducts(rarity, productsByRarity[rarity]!),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStoreRarityProducts(
    BalloonRarity rarity,
    List<StoreProduct> products,
  ) {
    Widget productGrid(int pageIndex, String keySuffix) => GridView.builder(
          key: ValueKey('store-rarity-grid-${rarity.name}-$keySuffix'),
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: storeProductsPerPage,
          itemBuilder: (context, slot) {
            final productIndex = pageIndex * storeProductsPerPage + slot;
            if (productIndex >= products.length) {
              return StoreComingSoonCard(rarity: rarity, slot: productIndex);
            }
            final product = products[productIndex];
            return StoreProductCard(
              product: product,
              onPressed: () => _showBalloonPreview(product),
            );
          },
        );

    if (products.length <= storeProductsPerPage) {
      return productGrid(0, 'single');
    }

    final pageCount = storeRarityPageCount(products.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalSpacing = 6.0;
        const verticalSpacing = 8.0;
        const horizontalPadding = 4.0;
        final cardWidth =
            (constraints.maxWidth - horizontalPadding - horizontalSpacing * 3) /
                4;
        final pageHeight = cardWidth / 0.78 * 2 + verticalSpacing + 2;
        return SizedBox(
          height: pageHeight,
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: const {
                ui.PointerDeviceKind.touch,
                ui.PointerDeviceKind.mouse,
                ui.PointerDeviceKind.trackpad,
                ui.PointerDeviceKind.stylus,
              },
            ),
            child: PageView.builder(
              key: ValueKey('store-rarity-pages-${rarity.name}'),
              physics: const PageScrollPhysics(),
              itemCount: pageCount,
              itemBuilder: (context, pageIndex) =>
                  productGrid(pageIndex, 'page-$pageIndex'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBalloonPreview(StoreProduct product) async {
    if (product.category != StoreCategory.balloon || product.locked) return;
    PopSound.playUiClick();
    final definition = BalloonSkinCatalog.byIdOrDefault(product.id);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '풍선 미리보기 닫기',
      barrierColor: const Color(0x660D2940),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) => BalloonPreviewDialog(
        definition: definition,
        productProvider: () => _currentStoreProduct(product),
        onAction: () {
          _onStoreProductPressed(_currentStoreProduct(product));
        },
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  void _onStoreProductPressed(StoreProduct product) {
    if (product.owned) {
      final result = PurchaseService.equip(
        category: product.category.name,
        productId: product.id,
        initiallyOwned: product.owned,
      );
      switch (result) {
        case EquipResult.success:
          PopSound.playShopEquip();
          _precacheSkinAssets(BalloonSkinCatalog.byIdOrDefault(product.id));
          setState(() {
            _equippedProductIds[product.category] = product.id;
          });
          _showComingSoon('${product.name} 사용 중');
        case EquipResult.alreadyEquipped:
          return;
        case EquipResult.notOwned:
          _showComingSoon('보유하지 않은 상품입니다.');
      }
      return;
    }

    final result = PurchaseService.purchase(
      productId: product.id,
      price: product.price,
      initiallyOwned: product.owned,
      locked: product.locked,
    );
    switch (result) {
      case PurchaseResult.success:
        PopSound.playShopPurchase();
        setState(() {
          _coinBalance = CoinService.balance;
          _ownedProductIds = PurchaseService.ownedProductIds;
        });
        _showComingSoon('${product.name} 구매 완료!');
      case PurchaseResult.insufficientCoins:
        _showComingSoon('코인이 부족해요!');
      case PurchaseResult.alreadyOwned:
        _showComingSoon('이미 보유한 상품입니다.');
      case PurchaseResult.unavailable:
        _showComingSoon('현재 구매할 수 없는 상품입니다.');
    }
  }

  // E-01 이벤트 화면 / R-01 랭킹 화면
  Widget _buildMainPlaceholder({
    required MainTab tab,
    required String message,
  }) {
    final homeChromeScale = _homeChromeScale(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Center(
                    child: _scaledHomeChrome(
                      scale: homeChromeScale,
                      width: 500,
                      height: 38,
                      child: _mainTopOverlay(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      message,
                      key: ValueKey('${tab.name}-coming-soon'),
                      style: const TextStyle(
                        color: Color(0xFF47677A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 86 * homeChromeScale + 8),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 86 * homeChromeScale,
              child: Center(
                child: _scaledHomeChrome(
                  scale: homeChromeScale,
                  width: 442,
                  height: 86,
                  child: _bottomMenu(selectedTab: tab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == GamePhase.menu) {
      return switch (_mainTab) {
        MainTab.home => _buildStartScreen(),
        MainTab.store => _buildShopScreen(),
        MainTab.event => _buildMainPlaceholder(
            tab: MainTab.event,
            message: '이벤트 준비 중',
          ),
        MainTab.ranking => _buildMainPlaceholder(
            tab: MainTab.ranking,
            message: '랭킹 준비 중',
          ),
      };
    }
    // G-01 게임 플레이 화면
    final equippedSkin = _equippedBalloonSkin;
    final hasDedicatedBackground =
        equippedSkin.background != BalloonBackgroundType.none;
    return Scaffold(
      body: Stack(
        children: [
          if (hasDedicatedBackground)
            Positioned.fill(
              child: GameBalloonBackground(
                definition: equippedSkin,
                crystalPulseListenable:
                    equippedSkin.background == BalloonBackgroundType.crystalCave
                        ? _crystalBackgroundPulse
                        : null,
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: hasDedicatedBackground
                  ? null
                  : const BoxDecoration(
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
                          if (_usesCanvasPlayfield) {
                            return _buildCanvasPlayfield(
                              !hasDedicatedBackground
                                  ? Positioned.fill(
                                      child: GameBalloonBackground(
                                        definition: equippedSkin,
                                      ),
                                    )
                                  : null,
                            );
                          }
                          return ValueListenableBuilder<int>(
                            valueListenable: _gameplayFrame,
                            child: !hasDedicatedBackground
                                ? Positioned.fill(
                                    child: GameBalloonBackground(
                                      definition: equippedSkin,
                                    ),
                                  )
                                : null,
                            builder: (context, frame, staticBackground) =>
                                Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (staticBackground != null) staticBackground,
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: RepaintBoundary(
                                      key: const ValueKey('effects-boundary'),
                                      child: CustomPaint(
                                        painter: EffectsPainter(
                                          pieces: _pieces,
                                          rings: _rings,
                                          feedbacks: _feedbacks,
                                          revision: _effectsRevision,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                for (final balloon in _balloons)
                                  _buildBalloon(balloon),
                                for (final boss in _bosses) _buildBoss(boss),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: AssetEffectsCanvas(
                                      key: const ValueKey(
                                        'asset-effects-boundary',
                                      ),
                                      effects: _assetEffects,
                                      revision: _effectsRevision,
                                      preloadAssets:
                                          legendaryEffectPreloadAssets(
                                        equippedSkin,
                                      ),
                                      toolVisuals: [
                                        for (final hit in _pendingToolHits)
                                          pendingToolVisual(hit),
                                      ],
                                      toolRevision: frame,
                                    ),
                                  ),
                                ),
                                if (_stage == 30 && _phase == GamePhase.playing)
                                  Positioned.fill(
                                    key: const ValueKey(
                                      'stage-30-boss-hit-layer',
                                    ),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapUp: _hitStage30BossAt,
                                    ),
                                  ),
                                if (_phase == GamePhase.stageIntro)
                                  _buildStageIntro(),
                                if (_phase == GamePhase.stageClear)
                                  _buildCenterMessage('Stage Clear!', null),
                                if (_phase == GamePhase.bossClear)
                                  _buildCenterMessage('BOSS CLEAR!', null),
                                if (_phase == GamePhase.paused)
                                  _buildPauseOverlay(),
                                if (_phase == GamePhase.completed)
                                  _buildGameOver(completed: true),
                                if (_phase == GamePhase.gameOver)
                                  _buildGameOver(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _usesCanvasPlayfield {
    if (!gameplayCanvasStageEnabled(
      mode: widget.gameplayRendererMode,
      stage: _stage,
    )) {
      return false;
    }
    final skin = _equippedBalloonSkin;
    final supportedSkinIds =
        widget.gameplayRendererMode == GameplayRendererMode.canvasPhase4A
            ? phase4ACanvasSkinIds
            : const <String>{BalloonSkinCatalog.defaultId};
    return supportedSkinIds.contains(skin.id) &&
        _balloons
            .every((balloon) => supportedSkinIds.contains(balloon.skinId)) &&
        _bosses.every((boss) => supportedSkinIds.contains(boss.skinId));
  }

  Widget _buildCanvasPlayfield(Widget? staticBackground) => Stack(
        clipBehavior: Clip.none,
        children: [
          if (staticBackground != null) staticBackground,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                key: const ValueKey('effects-boundary'),
                child: CustomPaint(
                  painter: EffectsPainter(
                    pieces: _pieces,
                    rings: _rings,
                    feedbacks: _feedbacks,
                    revision: _effectsRevision,
                    repaint: _effectsFrame,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: PersistentGameCanvas<Balloon>(
              key: const ValueKey('phase-1-persistent-game-canvas'),
              renderState: _gameRenderState,
              frameListenable: _gameplayFrame,
              spriteCache: _gameSpriteCache,
              onPointerDown: _hitCanvasBalloonAt,
            ),
          ),
          if (_phase == GamePhase.stageIntro) _buildStageIntro(),
          if (_phase == GamePhase.stageClear)
            _buildCenterMessage('Stage Clear!', null),
          if (_phase == GamePhase.bossClear)
            _buildCenterMessage('BOSS CLEAR!', null),
          if (_phase == GamePhase.paused) _buildPauseOverlay(),
          if (_phase == GamePhase.completed) _buildGameOver(completed: true),
          if (_phase == GamePhase.gameOver) _buildGameOver(),
        ],
      );

  void _hitCanvasBalloonAt(PointerDownEvent event) {
    if (!phase1CanvasInputEnabled(
      isPlaying: _phase == GamePhase.playing,
      canvasActive: _usesCanvasPlayfield,
    )) {
      return;
    }
    if (_bosses.isNotEmpty) {
      final boss = _stage == 30
          ? closestStage30BossForTap(_bosses, event.localPosition)
          : GameHitTester.topmostBossAt(
              _bossRenderViews,
              event.localPosition,
            )?.boss;
      if (boss != null) {
        _hitBoss(boss);
        if (_phase == GamePhase.playing) {
          _gameplayFrame.value++;
        }
      }
      return;
    }
    final balloon = GameHitTester.topmostBasicBalloonAt(
      _balloons,
      event.localPosition,
    );
    if (balloon != null) {
      _popBalloon(balloon);
      if (_phase == GamePhase.playing) {
        _gameplayFrame.value++;
      }
    }
  }

  Widget _buildBalloon(Balloon balloon) {
    final skin = BalloonSkinCatalog.byIdOrDefault(balloon.skinId);
    return Positioned(
      key: balloon.isFake
          ? ValueKey('fake-balloon-${balloon.id}')
          : ValueKey(balloon.id),
      left: balloon.position.dx,
      top: balloon.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _popBalloon(balloon),
        child: RepaintBoundary(
          key: ValueKey('balloon-raster-${balloon.id}'),
          child: Transform.scale(
            scale: balloon.isExiting
                ? (1 - balloon.exitProgress * 0.42).clamp(0.58, 1.0)
                : 1,
            child: SizedBox(
              width: balloon.size,
              height: balloon.size + 26,
              child: BalloonSkinRenderer(
                key: ValueKey(
                  '${balloon.isFake ? 'fake-' : ''}balloon-skin-${balloon.id}',
                ),
                definition: skin,
                color: _balloonColor(balloon, skin),
                isFake: balloon.isFake,
                visualVariant: balloon.visualVariant,
                specialVisual: balloon.specialVisual,
                animationPhase: balloon.floatPhase,
                collisionImpact: balloon.impactVisual,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoss(BossBalloon boss) {
    final skin = BalloonSkinCatalog.byIdOrDefault(boss.skinId);
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
            child: BalloonSkinRenderer(
              key: ValueKey('boss-skin-${boss.id}'),
              definition: skin,
              color: _bossColor(boss, skin),
              isBoss: true,
              hp: _currentBossHp(boss),
              maxHp: _currentBossMaxHp(boss),
              isFake: boss.isFake,
              showBossHealthBar: !boss.isFake,
              visualVariant: boss.visualVariant,
              specialVisual: boss.specialVisual,
              animationPhase: boss.visualPhase,
              collisionImpact: boss.impactVisual,
            ),
          ),
        ),
      ),
    );
  }

  Color _balloonColor(Balloon balloon, BalloonSkinDefinition skin) {
    if (skin.rendererType == BalloonRendererType.image) {
      return balloon.color;
    }
    return skin.colorAtDamage(
      balloon.color,
      (balloon.maxHp - balloon.hp) / balloon.maxHp,
      isBoss: false,
    );
  }

  Color _bossColor(BossBalloon boss, BalloonSkinDefinition skin) {
    final maxHp = _currentBossMaxHp(boss);
    final progress = (maxHp - _currentBossHp(boss)) / maxHp;
    if (skin.rendererType != BalloonRendererType.painted) {
      return boss.skinColor ?? skin.previewColor;
    }
    return Color.lerp(
      _stage >= 20
          ? (boss.id == 0 ? const Color(0xFFFF6B6B) : const Color(0xFF64B5F6))
          : const Color(0xFF7E57C2),
      _stage >= 20
          ? (boss.id == 0 ? const Color(0xFFB71C1C) : const Color(0xFF0D47A1))
          : const Color(0xFFFF3D67),
      progress,
    )!;
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

  Widget _buildStageIntro() {
    final definition = stageIntroDefinitions[_stage]!;
    return Positioned.fill(
      key: const ValueKey('stage-intro-overlay'),
      child: ColoredBox(
        color: const Color(0x660D2940),
        child: Center(
          child: Container(
            key: ValueKey('stage-intro-$_stage'),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  definition.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7354E8),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  definition.headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF4F7B),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                for (final rule in definition.rules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '• $rule',
                      style: const TextStyle(
                        color: Color(0xFF3F5F70),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 13),
                FilledButton(
                  key: const ValueKey('stage-intro-next'),
                  onPressed: _dismissStageIntro,
                  child: const Text('다음 단계 ▶'),
                ),
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
                  onPressed: () {
                    PopSound.playUiClick();
                    _resumeGame();
                  },
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
                  onPressed: () {
                    PopSound.playUiClick();
                    _returnToMenu();
                  },
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

  // G-02 게임 완료 및 게임오버 화면
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
                  const SizedBox(height: 6),
                  Row(
                    key: const ValueKey('result-earned-coins'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFB300),
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '+$_earnedCoins COINS',
                        style: const TextStyle(
                          color: Color(0xFFFFA000),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
              onTap: () {
                PopSound.playUiClick();
                onTap();
              },
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

class StoreProductFilterBar extends StatelessWidget {
  const StoreProductFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final StoreProductFilter selected;
  final ValueChanged<StoreProductFilter> onSelected;

  static const _items = <(StoreProductFilter, String)>[
    (StoreProductFilter.all, '전체'),
    (StoreProductFilter.owned, '보유'),
    (StoreProductFilter.unowned, '미보유'),
    (StoreProductFilter.limited, '한정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18204A5F),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in _items)
            Expanded(
              child: InkWell(
                key: ValueKey('store-filter-${item.$1.name}'),
                onTap: () {
                  PopSound.playUiClick();
                  onSelected(item.$1);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == item.$1
                        ? const Color(0xFFFFD8E5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: selected == item.$1
                          ? const Color(0xFFFF4F7B)
                          : const Color(0xFF526B79),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension BalloonRarityStyle on BalloonRarity {
  String get label => switch (this) {
        BalloonRarity.common => '일반',
        BalloonRarity.rare => '희귀',
        BalloonRarity.heroic => '영웅',
        BalloonRarity.legendary => '전설',
      };

  String get symbol => switch (this) {
        BalloonRarity.common => '⭐',
        BalloonRarity.rare => '🔵',
        BalloonRarity.heroic => '🟣',
        BalloonRarity.legendary => '🟠',
      };

  Color get color => switch (this) {
        BalloonRarity.common => const Color(0xFF49A969),
        BalloonRarity.rare => const Color(0xFF378DE5),
        BalloonRarity.heroic => const Color(0xFF8A55D8),
        BalloonRarity.legendary => const Color(0xFFF09136),
      };
}

class BalloonRaritySectionHeader extends StatelessWidget {
  const BalloonRaritySectionHeader({super.key, required this.rarity});

  final BalloonRarity rarity;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey('store-rarity-header-${rarity.name}'),
        padding: const EdgeInsets.fromLTRB(3, 8, 3, 7),
        child: Row(
          children: [
            Text(rarity.symbol, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              rarity.label,
              style: TextStyle(
                color: rarity.color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class BalloonRarityBadge extends StatelessWidget {
  const BalloonRarityBadge({super.key, required this.rarity});

  final BalloonRarity rarity;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('store-rarity-badge-${rarity.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: rarity.color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          rarity.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class StoreComingSoonCard extends StatelessWidget {
  const StoreComingSoonCard({
    super.key,
    required this.rarity,
    required this.slot,
  });

  final BalloonRarity rarity;
  final int slot;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('store-placeholder-${rarity.name}-$slot'),
        decoration: BoxDecoration(
          color: const Color(0xFFE7EDF1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E0E5)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, color: Color(0xFF9BAAB2), size: 22),
            SizedBox(height: 5),
            Text(
              'Coming Soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF83939C),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

extension BalloonBadgeLabel on BalloonBadge {
  String get label => switch (this) {
        BalloonBadge.none => '',
        BalloonBadge.newItem => 'NEW',
        BalloonBadge.popular => 'HOT',
        BalloonBadge.event => 'EVENT',
        BalloonBadge.recommended => '추천',
      };
}

class StoreProductBadge extends StatelessWidget {
  const StoreProductBadge({super.key, required this.badge});

  final BalloonBadge badge;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('store-product-badge-${badge.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4F7B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          badge.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

/// One data-driven preview for every real balloon product.
///
/// The same [BalloonSkinRenderer], palette, effect factory, and sound dispatch
/// used by gameplay are reused here. Preview playback never invokes gameplay,
/// score, coin-reward, stage, HP, or haptic code.
class BalloonPreviewDialog extends StatefulWidget {
  const BalloonPreviewDialog({
    super.key,
    required this.definition,
    required this.productProvider,
    required this.onAction,
  });

  final BalloonSkinDefinition definition;
  final StoreProduct Function() productProvider;
  final VoidCallback onAction;

  @override
  State<BalloonPreviewDialog> createState() => _BalloonPreviewDialogState();
}

class _BalloonPreviewDialogState extends State<BalloonPreviewDialog>
    with TickerProviderStateMixin {
  static const _previewSize = Size(250, 220);
  static const _balloonSize = Size(150, 176);
  static const _visibleDuration = Duration(milliseconds: 1000);
  static const _effectDuration = Duration(milliseconds: 1150);

  final Random _random = Random();
  final List<PopPiece> _pieces = [];
  final List<BurstRing> _rings = [];
  final List<AssetVisualEffect> _assetEffects = [];
  late final AnimationController _effectController;
  late final AnimationController _idleController;
  Timer? _cycleTimer;
  Duration _lastEffectElapsed = Duration.zero;
  late Color _color;
  bool _balloonVisible = true;
  bool _impactApplied = false;
  int _effectsRevision = 0;
  late int _visualVariant;
  late bool _specialVisual;
  int _toolApproach = 0;

  @override
  void initState() {
    super.initState();
    _color = widget.definition.previewColor;
    _visualVariant = widget.definition.chooseVisualVariant(
      _random.nextDouble(),
    );
    _specialVisual = widget.definition.chooseSpecialSpawn(_random.nextDouble());
    _toolApproach = _random.nextInt(3);
    _effectController =
        AnimationController(vsync: this, duration: _effectDuration)
          ..addListener(_advanceEffects)
          ..addStatusListener(_onEffectStatus);
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _schedulePop();
  }

  void _schedulePop() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer(_visibleDuration, _playPop);
  }

  void _playPop() {
    if (!mounted) return;
    final hasTool = widget.definition.hitToolAssetPath != null;
    setState(() {
      _balloonVisible = hasTool;
      _impactApplied = false;
    });
    if (!hasTool) _applyPreviewImpact();
    _lastEffectElapsed = Duration.zero;
    _effectController.forward(from: 0);
  }

  void _applyPreviewImpact() {
    if (_impactApplied) return;
    _impactApplied = true;
    setState(() {
      _balloonVisible = false;
      final shardPath = gemiShardAssetForColor(widget.definition, _color);
      if (shardPath != null) {
        addGemiShardAssetEffects(
          effects: _assetEffects,
          random: _random,
          assetPath: shardPath,
          center: _previewSize.center(Offset.zero),
          sourceSize: _balloonSize.width,
          count: 8,
        );
      } else {
        addBalloonPopEffect(
          definition: widget.definition,
          pieces: _pieces,
          random: _random,
          center: _previewSize.center(Offset.zero),
          color: _color,
          sourceSize: _balloonSize.width,
          big: false,
        );
      }
      addBalloonBurstRing(
        rings: _rings,
        center: _previewSize.center(Offset.zero),
        color: _color,
        radius: _balloonSize.width * 0.72,
      );
      _effectsRevision++;
    });
    // Preview sound only: no haptic and no gameplay action is invoked here.
    playBalloonHitSound(widget.definition);
    playBalloonPopSound(widget.definition, boss: false);
  }

  void _advanceEffects() {
    final elapsed = _effectController.lastElapsedDuration ?? Duration.zero;
    final delta = elapsed - _lastEffectElapsed;
    _lastEffectElapsed = elapsed;
    if (widget.definition.hitToolAssetPath != null &&
        !_impactApplied &&
        _effectController.value >=
            PendingToolHit.impactTime /
                (_effectDuration.inMilliseconds / 1000)) {
      _applyPreviewImpact();
    }
    final dt = calculateFrameDelta(delta);
    final painterChanged = advanceEffects(_pieces, _rings, dt);
    final assetChanged = advanceAssetVisualEffects(_assetEffects, dt);
    if (painterChanged || assetChanged) {
      _effectsRevision++;
    }
  }

  void _onEffectStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _pieces.clear();
    _rings.clear();
    _assetEffects.clear();
    setState(() {
      _effectsRevision++;
      _color = _nextPaletteColor();
      _visualVariant = widget.definition.chooseVisualVariant(
        _random.nextDouble(),
      );
      _specialVisual = widget.definition.chooseSpecialSpawn(
        _random.nextDouble(),
      );
      _toolApproach = _random.nextInt(3);
      _balloonVisible = true;
    });
    _schedulePop();
  }

  Color _nextPaletteColor() {
    final palette = widget.definition.colorPalette;
    if (palette.length <= 1) return palette.first;
    final currentIndex = palette.indexOf(_color);
    var nextIndex = _random.nextInt(palette.length);
    if (nextIndex == currentIndex) {
      nextIndex = (nextIndex + 1) % palette.length;
    }
    return palette[nextIndex];
  }

  List<LegendaryToolVisual> _previewToolVisuals() {
    final definition = widget.definition;
    if (definition.hitToolAssetPath == null ||
        !_effectController.isAnimating ||
        _effectController.value > 0.22) {
      return const <LegendaryToolVisual>[];
    }
    final impactValue =
        PendingToolHit.impactTime / (_effectDuration.inMilliseconds / 1000);
    final progress = Curves.easeInCubic.transform(
      (_effectController.value / impactValue).clamp(0.0, 1.0),
    );
    final isFork = definition.popEffectType == BalloonPopEffectType.cream;
    return <LegendaryToolVisual>[
      legendaryToolVisual(
        definition: definition,
        targetCenter: _previewSize.center(Offset.zero),
        approach: _toolApproach,
        easedProgress: progress,
        opacity: 1,
        size: isFork ? 96 : 112,
        gemiStart: const Offset(-56, -32),
        gemiEnd: const Offset(0, 45),
      ),
    ];
  }

  void _handleAction() {
    widget.onAction();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _effectController
      ..removeListener(_advanceEffects)
      ..removeStatusListener(_onEffectStatus)
      ..dispose();
    _idleController.dispose();
    _pieces.clear();
    _rings.clear();
    _assetEffects.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productProvider();
    return SafeArea(
      child: Dialog(
        key: const ValueKey('balloon-preview-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.white,
            elevation: 12,
            shadowColor: const Color(0x553B246B),
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          widget.definition.displayName,
                          key: const ValueKey('balloon-preview-name'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFF4F7B),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('balloon-preview-close'),
                        onPressed: () {
                          PopSound.playUiClick();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF526B79),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  Text(
                    widget.definition.rarity.label,
                    key: const ValueKey('balloon-preview-rarity'),
                    style: TextStyle(
                      color: widget.definition.rarity.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (widget.definition.showsDescription) ...[
                    const SizedBox(height: 5),
                    Text(
                      widget.definition.description!,
                      key: const ValueKey('balloon-preview-description'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF526B79),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    widget.definition.price == 0
                        ? '기본 보유'
                        : '${widget.definition.price} coin',
                    key: const ValueKey('balloon-preview-price'),
                    style: const TextStyle(
                      color: Color(0xFFD99000),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: _previewSize.width,
                    height: _previewSize.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: ClipRect(
                            child: BalloonBackgroundRenderer(
                              key: const ValueKey('balloon-preview-background'),
                              background: widget.definition.background,
                              // The dialog's white Material remains the stage
                              // for skins without a dedicated background.
                              fallback: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        if (_balloonVisible)
                          SizedBox(
                            key: const ValueKey('balloon-preview-renderer'),
                            width: _balloonSize.width,
                            height: _balloonSize.height,
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _idleController,
                                builder: (context, _) => BalloonSkinRenderer(
                                  definition: widget.definition,
                                  color: _color,
                                  visualVariant: _visualVariant,
                                  specialVisual: _specialVisual,
                                  animationPhase:
                                      _idleController.value * pi * 2,
                                ),
                              ),
                            ),
                          ),
                        if (widget.definition.burstAssetPath != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _effectController,
                                builder: (context, _) {
                                  final progress = _effectController.value;
                                  if (!_effectController.isAnimating ||
                                      progress < 0.10 ||
                                      progress > 0.48) {
                                    return const SizedBox.shrink();
                                  }
                                  final fade = ((0.48 - progress) / 0.38).clamp(
                                    0.0,
                                    1.0,
                                  );
                                  return Center(
                                    child: Opacity(
                                      opacity: fade,
                                      child: Transform.scale(
                                        scale: 0.55 + progress,
                                        child: SizedBox.square(
                                          dimension: 118,
                                          child: Image.asset(
                                            widget.definition.burstAssetPath!,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.low,
                                            cacheWidth: 320,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _effectController,
                              builder: (context, _) {
                                final toolVisuals = _previewToolVisuals();
                                return AssetEffectsCanvas(
                                  key: const ValueKey(
                                    'balloon-preview-asset-effects',
                                  ),
                                  effects: _assetEffects,
                                  revision: _effectsRevision,
                                  preloadAssets: legendaryEffectPreloadAssets(
                                    widget.definition,
                                  ),
                                  toolVisuals: toolVisuals,
                                  toolRevision:
                                      (_effectController.value * 10000).round(),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _effectController,
                                builder: (context, _) => CustomPaint(
                                  key: const ValueKey(
                                    'balloon-preview-effects',
                                  ),
                                  painter: EffectsPainter(
                                    pieces: _pieces,
                                    rings: _rings,
                                    revision: _effectsRevision,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _actionButton(product),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(StoreProduct product) {
    if (product.equipped) {
      return FilledButton.icon(
        key: const ValueKey('balloon-preview-action'),
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('사용 중'),
      );
    }
    if (product.owned) {
      return FilledButton(
        key: const ValueKey('balloon-preview-action'),
        onPressed: _handleAction,
        child: const Text('사용하기'),
      );
    }
    return FilledButton.icon(
      key: const ValueKey('balloon-preview-action'),
      onPressed: _handleAction,
      icon: const Icon(Icons.monetization_on_rounded),
      label: Text('${product.price} 구매'),
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
    return Material(
      color: Colors.white,
      elevation: product.equipped ? 3 : 1.5,
      shadowColor: const Color(0x33204A5F),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        // This public card key identifies the actual mobile tap surface. Keep
        // purchase/equip actions inside BalloonPreviewDialog, never here.
        key: ValueKey('store-product-${product.id}'),
        onTap: product.locked ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: ValueKey('store-action-${product.id}'),
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: product.equipped
                  ? const Color(0xFF8EDCB7)
                  : const Color(0xFFE8EEF2),
              width: product.equipped ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: product.locked ? _lockedPreview() : _preview(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.locked ? '???' : product.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: product.locked
                            ? const Color(0xFF87949C)
                            : const Color(0xFF244F68),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(height: 15, child: _status()),
                  ],
                ),
              ),
              if (product.category == StoreCategory.balloon)
                Positioned(
                  left: 0,
                  top: 0,
                  child: BalloonRarityBadge(rarity: product.rarity),
                ),
              if (product.badge != BalloonBadge.none)
                Positioned(
                  right: 0,
                  top: 0,
                  child: StoreProductBadge(badge: product.badge),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status() {
    if (product.locked) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, color: Color(0xFF98A3AA), size: 10),
          SizedBox(width: 2),
          Text(
            '잠김',
            style: TextStyle(
              color: Color(0xFF87949C),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }
    if (product.equipped) {
      return const Text(
        '사용 중',
        style: TextStyle(
          color: Color(0xFF35A978),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    if (product.owned) {
      return const Text(
        '사용하기',
        style: TextStyle(
          color: Color(0xFF7354E8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.monetization_on_rounded,
          color: Color(0xFFFFB300),
          size: 11,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${product.price}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B5A36),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _lockedPreview() => const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE1E5E8),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.question_mark_rounded,
              color: Color(0xFF98A3AA),
              size: 22,
            ),
          ),
        ),
      );

  Widget _preview() {
    switch (product.previewType) {
      case StorePreviewType.balloon:
        final definition = BalloonSkinCatalog.byIdOrDefault(product.id);
        return Center(
          child: SizedBox(
            width: 48,
            height: 56,
            child: BalloonSkinRenderer(
              definition: definition,
              color: definition.previewColor,
            ),
          ),
        );
      case StorePreviewType.effect:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: product.previewData,
                size: 34,
              ),
              const Positioned(
                right: 5,
                top: 2,
                child: Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFFC857),
                  size: 17,
                ),
              ),
            ],
          ),
        );
      case StorePreviewType.background:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [product.previewData, const Color(0xFF85D86A)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.landscape_rounded, color: Colors.white, size: 28),
          ),
        );
      case StorePreviewType.sound:
        return Center(
          child: Icon(
            Icons.graphic_eq_rounded,
            color: product.previewData,
            size: 36,
          ),
        );
      case StorePreviewType.music:
        return Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: product.previewData.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: product.previewData,
              size: 25,
            ),
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

/// G-01 background entry point. The equipped skin supplies only data; the
/// shared renderer decides whether to keep [PlaySky] or show a registered
/// dedicated background.
class GameBalloonBackground extends StatelessWidget {
  const GameBalloonBackground({
    super.key,
    required this.definition,
    this.crystalPulse = 0,
    this.crystalPulseListenable,
  });

  final BalloonSkinDefinition definition;
  final double crystalPulse;
  final ValueListenable<double>? crystalPulseListenable;

  @override
  Widget build(BuildContext context) => BalloonBackgroundRenderer(
        key: const ValueKey('game-balloon-background'),
        background: definition.background,
        fallback: const PlaySky(),
        crystalPulse: crystalPulse,
        crystalPulseListenable: crystalPulseListenable,
        cacheWidth: 720,
        assetPathOverride: BalloonBackgroundRegistry.gameplayAssetPathFor(
          definition.background,
        ),
      );
}

/// Shared rendering entry point used by shop previews, normal balloons,
/// and Stage 10/20 bosses. Product IDs are never checked here.
class BalloonSkinRenderer extends StatelessWidget {
  const BalloonSkinRenderer({
    super.key,
    required this.definition,
    required this.color,
    this.isBoss = false,
    this.hp = 1,
    this.maxHp = 1,
    this.isFake = false,
    this.showBossHealthBar = true,
    this.visualVariant = 0,
    this.specialVisual = false,
    this.animationPhase = 0,
    this.collisionImpact = 0,
  });

  final BalloonSkinDefinition definition;
  final Color color;
  final bool isBoss;
  final int hp;
  final int maxHp;
  final bool isFake;
  final bool showBossHealthBar;
  final int visualVariant;
  final bool specialVisual;
  final double animationPhase;
  final double collisionImpact;

  @override
  Widget build(BuildContext context) {
    late final Widget visual;
    if (definition.rendererType == BalloonRendererType.painted) {
      final displayColor = isFake ? fakeBalloonColor(color) : color;
      visual = CustomPaint(
        painter: isBoss
            ? BossBalloonPainter(
                color: displayColor,
                hp: hp,
                maxHp: maxHp,
                showHealthBar: showBossHealthBar,
              )
            : BalloonPainter(color: displayColor),
      );
    } else {
      final displayColor = isFake ? fakeBalloonColor(color) : color;
      Widget skinVisual = switch (definition.rendererType) {
        BalloonRendererType.image => BalloonSkinArtwork(
            definition: definition,
            color: color,
            isFake: isFake,
            visualVariant: visualVariant,
          ),
        BalloonRendererType.star => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.star,
              color: displayColor,
            ),
          ),
        BalloonRendererType.flower => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.flower,
              color: displayColor,
            ),
          ),
        BalloonRendererType.rabbit => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.rabbit,
              color: displayColor,
            ),
          ),
        BalloonRendererType.watermelon => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.watermelon,
              color: displayColor,
              variant: visualVariant,
            ),
          ),
        BalloonRendererType.soccer => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.soccer,
              color: displayColor,
            ),
          ),
        BalloonRendererType.ghost => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.ghost,
              color: displayColor,
              phase: animationPhase,
            ),
          ),
        BalloonRendererType.slime => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.slime,
              color: displayColor,
              phase: animationPhase,
            ),
          ),
        BalloonRendererType.crystal => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.crystal,
              color: displayColor,
              phase: animationPhase,
              damageProgress: isBoss && maxHp > 0 ? 1 - hp / maxHp : 0,
            ),
          ),
        BalloonRendererType.creamPuff => CustomPaint(
            painter: ShapedBalloonPainter(
              shape: BalloonShape.creamPuff,
              color: displayColor,
              phase: animationPhase,
              damageProgress: isBoss && maxHp > 0 ? 1 - hp / maxHp : 0,
            ),
          ),
        BalloonRendererType.painted => throw StateError(
            'Painted balloons are handled by the common painted branch.',
          ),
      };
      final shouldSpin =
          definition.idleAnimation == BalloonIdleAnimationType.spin;
      if (shouldSpin) {
        skinVisual = Transform.rotate(
          angle: animationPhase * 0.65,
          child: skinVisual,
        );
      } else if (definition.idleAnimation ==
          BalloonIdleAnimationType.ghostTail) {
        skinVisual = Transform.translate(
          offset: Offset(sin(animationPhase) * 1.4, cos(animationPhase) * 2.2),
          child: Transform.rotate(
            angle: sin(animationPhase * 0.7) * 0.018,
            child: skinVisual,
          ),
        );
      } else if (definition.idleAnimation ==
          BalloonIdleAnimationType.slimeSquish) {
        final squash = sin(animationPhase) * 0.045 + collisionImpact * 0.10;
        skinVisual = Transform.scale(
          scaleX: 1 + squash,
          scaleY: 1 - squash,
          child: skinVisual,
        );
      } else if (definition.idleAnimation == BalloonIdleAnimationType.breathe) {
        skinVisual = Transform.scale(
          scale: 1 + sin(animationPhase) * 0.018,
          child: skinVisual,
        );
      }
      if (definition.idleAnimation == BalloonIdleAnimationType.ghostTail) {
        skinVisual = Opacity(opacity: 0.86, child: skinVisual);
      }
      visual = !isBoss
          ? skinVisual
          : Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 32,
                  child: skinVisual,
                ),
                if (showBossHealthBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 5,
                    child: _BossHealthBar(hp: hp, maxHp: maxHp),
                  ),
              ],
            );
    }

    // Fake balloons share every skin's normal renderer and palette. A single
    // final-stage treatment makes all current and future definitions look
    // slightly faded without introducing skin-specific fake implementations.
    final usesPrecomposedFake = isFake &&
        definition.runtimeFakeColorAssetPaths.containsKey(color.toARGB32());
    return isFake && !usesPrecomposedFake
        ? Opacity(opacity: fakeBalloonOpacity, child: visual)
        : visual;
  }
}

class BalloonSkinArtwork extends StatelessWidget {
  const BalloonSkinArtwork({
    super.key,
    required this.definition,
    required this.color,
    this.isFake = false,
    this.visualVariant = 0,
  });

  final BalloonSkinDefinition definition;
  final Color color;
  final bool isFake;
  final int visualVariant;

  @override
  Widget build(BuildContext context) {
    Widget assetImage([String? path]) => Image.asset(
          path ?? definition.assetForVariant(visualVariant)!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          cacheWidth: 512,
        );

    final colorKey = color.toARGB32();
    final runtimeAsset = (isFake
        ? definition.runtimeFakeColorAssetPaths
        : definition.runtimeColorAssetPaths)[colorKey];
    if (runtimeAsset != null) return assetImage(runtimeAsset);

    if (definition.imageDetailMask == BalloonImageDetailMask.mochiFace) {
      if (usesOriginalAsset(definition, color) && !isFake) {
        return Center(
          child: AspectRatio(aspectRatio: 398 / 512, child: assetImage()),
        );
      }
      final tintedBody = ColorFiltered(
        key: const ValueKey('mochi-tinted-body'),
        colorFilter: ColorFilter.matrix(
          visualColorMatrix(definition, color, isFake: isFake),
        ),
        child: assetImage(),
      );
      Widget originalDetails = assetImage();
      if (isFake) {
        originalDetails = ColorFiltered(
          colorFilter: ColorFilter.matrix(_fakeToneMatrix),
          child: originalDetails,
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: 398 / 512,
          child: Stack(
            fit: StackFit.expand,
            children: [
              tintedBody,
              ClipPath(
                key: const ValueKey('mochi-detail-overlay'),
                clipper: const _MochiDetailClipper(),
                child: originalDetails,
              ),
            ],
          ),
        ),
      );
    }

    final image = assetImage();
    if (definition.imageColorMode == BalloonImageColorMode.original) {
      if (!isFake) return image;
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_fakeToneMatrix),
        child: image,
      );
    }
    if (usesOriginalAsset(definition, color) && !isFake) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(
        visualColorMatrix(definition, color, isFake: isFake),
      ),
      child: image,
    );
  }

  static List<double> visualColorMatrix(
    BalloonSkinDefinition definition,
    Color color, {
    required bool isFake,
  }) {
    final base = colorMatrix(definition, color);
    return isFake ? _composeColorMatrices(_fakeToneMatrix, base) : base;
  }

  static final _fakeToneMatrix = saturationBrightnessColorMatrix(
    saturation: fakeBalloonSaturationFactor,
    brightness: fakeBalloonBrightnessFactor,
  );

  static List<double> get fakeToneMatrix => _fakeToneMatrix;

  static List<double> _composeColorMatrices(
    List<double> after,
    List<double> before,
  ) {
    final result = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        for (var index = 0; index < 4; index++) {
          result[row * 5 + column] +=
              after[row * 5 + index] * before[index * 5 + column];
        }
      }
      result[row * 5 + 4] = after[row * 5 + 4];
      for (var index = 0; index < 4; index++) {
        result[row * 5 + 4] += after[row * 5 + index] * before[index * 5 + 4];
      }
    }
    return result;
  }

  /// The catalog preview color is the reference artwork color. Returning the
  /// raw asset here guarantees pixel-identical pink in shop, normal-play, and
  /// boss rendering.
  static bool usesOriginalAsset(
    BalloonSkinDefinition definition,
    Color color,
  ) =>
      definition.previewColor.toARGB32() == color.toARGB32();

  /// Rotates only hue for non-reference variants. There is no opacity, black
  /// overlay, or brightness scaling, so the source highlight and shading are
  /// retained and the source alpha remains untouched.
  static List<double> colorMatrix(
    BalloonSkinDefinition definition,
    Color color,
  ) {
    if (definition.imageColorMode == BalloonImageColorMode.grayscaleTint) {
      final red = color.r;
      final green = color.g;
      final blue = color.b;
      return <double>[
        0.213 * red,
        0.715 * red,
        0.072 * red,
        0,
        0,
        0.213 * green,
        0.715 * green,
        0.072 * green,
        0,
        0,
        0.213 * blue,
        0.715 * blue,
        0.072 * blue,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];
    }
    final sourceHue = HSLColor.fromColor(definition.previewColor).hue;
    final targetHue = HSLColor.fromColor(color).hue;
    final degrees = (targetHue - sourceHue + 540) % 360 - 180;
    final radians = degrees * pi / 180;
    final cosine = cos(radians);
    final sine = sin(radians);
    return <double>[
      0.213 + cosine * 0.787 - sine * 0.213,
      0.715 - cosine * 0.715 - sine * 0.715,
      0.072 - cosine * 0.072 + sine * 0.928,
      0,
      0,
      0.213 - cosine * 0.213 + sine * 0.143,
      0.715 + cosine * 0.285 + sine * 0.140,
      0.072 - cosine * 0.072 - sine * 0.283,
      0,
      0,
      0.213 - cosine * 0.213 - sine * 0.787,
      0.715 - cosine * 0.715 + sine * 0.715,
      0.072 + cosine * 0.928 + sine * 0.072,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// Preserves only the eyes and pink nose from the supplied artwork. The body,
/// inner ears, and cheeks stay on the hue-shifted layer so they change as one
/// color family, while source-white highlights remain white through the hue
/// matrix. Coordinates never affect hit testing.
class _MochiDetailClipper extends CustomClipper<Path> {
  const _MochiDetailClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    void oval(double left, double top, double width, double height) {
      path.addOval(
        Rect.fromLTWH(
          size.width * left,
          size.height * top,
          size.width * width,
          size.height * height,
        ),
      );
    }

    // Dark eyes, including their white catchlights.
    oval(0.33, 0.52, 0.08, 0.09);
    oval(0.59, 0.52, 0.08, 0.09);
    // Keep the original pink nose without restoring nearby cheek/body pixels.
    path.addPolygon([
      Offset(size.width * 0.47, size.height * 0.59),
      Offset(size.width * 0.53, size.height * 0.59),
      Offset(size.width * 0.50, size.height * 0.63),
    ], true);
    return path;
  }

  @override
  bool shouldReclip(covariant _MochiDetailClipper oldClipper) => false;
}

const fakeBalloonSaturationFactor = 0.78;
const fakeBalloonBrightnessFactor = 0.97;
const fakeBalloonOpacity = 0.35;

List<double> saturationBrightnessColorMatrix({
  required double saturation,
  required double brightness,
}) {
  final inverse = 1 - saturation;
  const redLuminance = 0.213;
  const greenLuminance = 0.715;
  const blueLuminance = 0.072;
  return <double>[
    (redLuminance * inverse + saturation) * brightness,
    greenLuminance * inverse * brightness,
    blueLuminance * inverse * brightness,
    0,
    0,
    redLuminance * inverse * brightness,
    (greenLuminance * inverse + saturation) * brightness,
    blueLuminance * inverse * brightness,
    0,
    0,
    redLuminance * inverse * brightness,
    greenLuminance * inverse * brightness,
    (blueLuminance * inverse + saturation) * brightness,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

Color fakeBalloonColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation(
        (hsl.saturation * fakeBalloonSaturationFactor).clamp(0.0, 1.0),
      )
      .withLightness(
        (hsl.lightness * fakeBalloonBrightnessFactor).clamp(0.0, 1.0),
      )
      .toColor();
}

class _BossHealthBar extends StatelessWidget {
  const _BossHealthBar({required this.hp, required this.maxHp});

  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final fraction = bossHealthFraction(hp, maxHp);
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.62,
        child: Container(
          height: 11,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            key: const ValueKey('boss-health-fill'),
            widthFactor: fraction,
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFD54F),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double bossHealthFraction(int hp, int maxHp) {
  if (maxHp <= 0) return 0;
  return (hp / maxHp).clamp(0.0, 1.0);
}

enum BalloonShape {
  star,
  flower,
  rabbit,
  watermelon,
  soccer,
  ghost,
  slime,
  crystal,
  creamPuff,
}

/// Lightweight vector artwork shared by shop, preview, gameplay, Boss, and
/// Fake rendering. Gameplay bounds and hit testing stay outside this painter.
class ShapedBalloonPainter extends CustomPainter {
  const ShapedBalloonPainter({
    required this.shape,
    required this.color,
    this.variant = 0,
    this.phase = 0,
    this.damageProgress = 0,
  });

  final BalloonShape shape;
  final Color color;
  final int variant;
  final double phase;
  final double damageProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyBottom = size.height * 0.86;
    final bodyPath = switch (shape) {
      BalloonShape.star => _starPath(size.width, bodyBottom),
      BalloonShape.flower => _flowerPath(size.width, bodyBottom),
      BalloonShape.rabbit => _rabbitPath(size.width, bodyBottom),
      BalloonShape.watermelon => _watermelonPath(
          size.width,
          bodyBottom,
          variant,
        ),
      BalloonShape.soccer => _soccerPath(size.width, bodyBottom),
      BalloonShape.ghost => _ghostPath(size.width, bodyBottom, phase),
      BalloonShape.slime => _slimePath(size.width, bodyBottom),
      BalloonShape.crystal => _crystalPath(size.width, bodyBottom),
      BalloonShape.creamPuff => _creamPuffPath(size.width, bodyBottom),
    };
    final bodyBounds = bodyPath.getBounds();

    canvas.save();
    canvas.translate(2, 3);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.34, -0.42),
        radius: 0.92,
        colors: [
          Color.lerp(color, Colors.white, 0.43)!,
          color,
          Color.lerp(color, Colors.black, 0.22)!,
        ],
        stops: const [0, 0.61, 1],
      ).createShader(bodyBounds);
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, size.width * 0.018),
    );

    // Details and highlights are clipped to the silhouette. This fixes the
    // previous star/rabbit white highlights protruding beyond their outlines.
    canvas.save();
    canvas.clipPath(bodyPath);
    switch (shape) {
      case BalloonShape.rabbit:
        _paintRabbitDetails(canvas, size, bodyBottom);
      case BalloonShape.flower:
        _paintFlowerDetails(canvas, size, bodyBottom);
      case BalloonShape.watermelon:
        _paintWatermelonDetails(canvas, size, bodyBottom, variant);
      case BalloonShape.soccer:
        _paintSoccerDetails(canvas, size, bodyBottom);
      case BalloonShape.ghost:
        _paintFace(canvas, size, bodyBottom, mouth: false);
      case BalloonShape.slime:
        _paintFace(canvas, size, bodyBottom, mouth: true);
      case BalloonShape.crystal:
        _paintCrystalFacets(canvas, size, bodyBottom);
      case BalloonShape.creamPuff:
        _paintCreamDetails(canvas, size, bodyBottom);
      case BalloonShape.star:
        break;
    }

    final shine = Paint()..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.25,
        bodyBottom * 0.20,
        size.width * 0.11,
        bodyBottom * 0.16,
      ),
      shine,
    );
    canvas.drawCircle(
      Offset(size.width * 0.38, bodyBottom * 0.18),
      size.width * 0.025,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.restore();

    final knotTop = bodyBottom * 0.84;
    final knot = Path()
      ..moveTo(size.width / 2, knotTop)
      ..lineTo(size.width * 0.42, bodyBottom * 0.97)
      ..lineTo(size.width * 0.58, bodyBottom * 0.97)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);

    final stringPath = Path()
      ..moveTo(size.width / 2, bodyBottom * 0.97)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.93,
        size.width * 0.48,
        size.height,
      );
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = const Color(0xFF666666)
        ..strokeWidth = max(1.0, size.width * 0.012)
        ..style = PaintingStyle.stroke,
    );
  }

  Path _starPath(double width, double height) {
    final center = Offset(width / 2, height * 0.43);
    final outerRadius = min(width * 0.46, height * 0.45);
    final innerRadius = outerRadius * 0.47;
    final points = <Offset>[];
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -pi / 2 + index * pi / 5;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      points.add(point);
    }
    final path = Path();
    final firstMidpoint = Offset.lerp(points.last, points.first, 0.5)!;
    path.moveTo(firstMidpoint.dx, firstMidpoint.dy);
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final next = points[(index + 1) % points.length];
      final midpoint = Offset.lerp(point, next, 0.5)!;
      path.quadraticBezierTo(point.dx, point.dy, midpoint.dx, midpoint.dy);
    }
    return path..close();
  }

  Path _flowerPath(double width, double height) {
    final path = Path();
    final center = Offset(width * 0.5, height * 0.45);
    final petalRadius = width * 0.19;
    for (var i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * pi * 2 / 5;
      final petal = center + Offset(cos(angle), sin(angle)) * width * 0.25;
      path.addOval(Rect.fromCircle(center: petal, radius: petalRadius));
    }
    path.addOval(Rect.fromCircle(center: center, radius: width * 0.22));
    return path;
  }

  Path _watermelonPath(double width, double height, int variant) {
    switch (variant % 3) {
      case 0:
        return Path()
          ..moveTo(width * 0.12, height * 0.42)
          ..quadraticBezierTo(
            width * 0.5,
            height * 0.90,
            width * 0.88,
            height * 0.42,
          )
          ..quadraticBezierTo(
            width * 0.5,
            height * 0.18,
            width * 0.12,
            height * 0.42,
          )
          ..close();
      case 1:
        return Path()
          ..moveTo(width * 0.50, height * 0.10)
          ..quadraticBezierTo(
            width * 0.54,
            height * 0.10,
            width * 0.88,
            height * 0.75,
          )
          ..quadraticBezierTo(
            width * 0.50,
            height * 0.91,
            width * 0.12,
            height * 0.75,
          )
          ..quadraticBezierTo(
            width * 0.46,
            height * 0.10,
            width * 0.50,
            height * 0.10,
          )
          ..close();
      default:
        return Path()
          ..addOval(
            Rect.fromLTWH(
              width * 0.10,
              height * 0.08,
              width * 0.80,
              height * 0.78,
            ),
          );
    }
  }

  Path _soccerPath(double width, double height) => Path()
    ..addOval(
      Rect.fromLTWH(width * 0.08, height * 0.05, width * 0.84, height * 0.82),
    );

  Path _ghostPath(double width, double height, double phase) {
    final wave = sin(phase) * width * 0.018;
    return Path()
      ..moveTo(width * 0.14, height * 0.78)
      ..lineTo(width * 0.14, height * 0.40)
      ..cubicTo(
        width * 0.14,
        height * 0.12,
        width * 0.32,
        height * 0.02,
        width * 0.50,
        height * 0.02,
      )
      ..cubicTo(
        width * 0.72,
        height * 0.02,
        width * 0.86,
        height * 0.19,
        width * 0.86,
        height * 0.42,
      )
      ..lineTo(width * 0.86, height * 0.79)
      ..quadraticBezierTo(
        width * 0.75,
        height * 0.68 + wave,
        width * 0.65,
        height * 0.82,
      )
      ..quadraticBezierTo(
        width * 0.53,
        height * 0.69 - wave,
        width * 0.43,
        height * 0.82,
      )
      ..quadraticBezierTo(
        width * 0.31,
        height * 0.69 + wave,
        width * 0.14,
        height * 0.78,
      )
      ..close();
  }

  Path _slimePath(double width, double height) => Path()
    ..moveTo(width * 0.11, height * 0.78)
    ..cubicTo(
      width * 0.13,
      height * 0.48,
      width * 0.24,
      height * 0.12,
      width * 0.50,
      height * 0.08,
    )
    ..cubicTo(
      width * 0.76,
      height * 0.12,
      width * 0.87,
      height * 0.48,
      width * 0.89,
      height * 0.78,
    )
    ..quadraticBezierTo(
      width * 0.50,
      height * 0.91,
      width * 0.11,
      height * 0.78,
    )
    ..close();

  Path _crystalPath(double width, double height) => Path()
    ..moveTo(width * 0.50, height * 0.02)
    ..lineTo(width * 0.82, height * 0.25)
    ..lineTo(width * 0.72, height * 0.76)
    ..lineTo(width * 0.50, height * 0.91)
    ..lineTo(width * 0.24, height * 0.73)
    ..lineTo(width * 0.16, height * 0.27)
    ..close();

  Path _creamPuffPath(double width, double height) => Path()
    ..moveTo(width * 0.12, height * 0.63)
    ..cubicTo(
      width * 0.08,
      height * 0.43,
      width * 0.20,
      height * 0.28,
      width * 0.34,
      height * 0.30,
    )
    ..cubicTo(
      width * 0.36,
      height * 0.12,
      width * 0.58,
      height * 0.07,
      width * 0.65,
      height * 0.27,
    )
    ..cubicTo(
      width * 0.82,
      height * 0.22,
      width * 0.94,
      height * 0.43,
      width * 0.87,
      height * 0.61,
    )
    ..cubicTo(
      width * 0.93,
      height * 0.79,
      width * 0.69,
      height * 0.88,
      width * 0.51,
      height * 0.83,
    )
    ..cubicTo(
      width * 0.31,
      height * 0.90,
      width * 0.06,
      height * 0.79,
      width * 0.12,
      height * 0.63,
    )
    ..close();

  Path _rabbitPath(double width, double height) => Path()
    ..moveTo(width * 0.50, height * 0.86)
    ..cubicTo(
      width * 0.24,
      height * 0.86,
      width * 0.10,
      height * 0.70,
      width * 0.13,
      height * 0.51,
    )
    ..cubicTo(
      width * 0.15,
      height * 0.39,
      width * 0.23,
      height * 0.34,
      width * 0.31,
      height * 0.31,
    )
    ..cubicTo(
      width * 0.23,
      height * 0.18,
      width * 0.22,
      height * 0.02,
      width * 0.31,
      height * 0.01,
    )
    ..cubicTo(
      width * 0.41,
      0,
      width * 0.42,
      height * 0.20,
      width * 0.40,
      height * 0.34,
    )
    ..cubicTo(
      width * 0.46,
      height * 0.31,
      width * 0.54,
      height * 0.31,
      width * 0.60,
      height * 0.34,
    )
    ..cubicTo(
      width * 0.58,
      height * 0.20,
      width * 0.59,
      0,
      width * 0.69,
      height * 0.01,
    )
    ..cubicTo(
      width * 0.78,
      height * 0.02,
      width * 0.77,
      height * 0.18,
      width * 0.69,
      height * 0.31,
    )
    ..cubicTo(
      width * 0.77,
      height * 0.34,
      width * 0.85,
      height * 0.39,
      width * 0.87,
      height * 0.51,
    )
    ..cubicTo(
      width * 0.90,
      height * 0.70,
      width * 0.76,
      height * 0.86,
      width * 0.50,
      height * 0.86,
    )
    ..close();

  void _paintFlowerDetails(Canvas canvas, Size size, double bodyBottom) {
    final center = Offset(size.width * 0.5, bodyBottom * 0.45);
    canvas.drawCircle(
      center,
      size.width * 0.17,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF5A3), Color(0xFFFFC94D)],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.17),
        ),
    );
  }

  void _paintWatermelonDetails(
    Canvas canvas,
    Size size,
    double bodyBottom,
    int variant,
  ) {
    final green = Paint()
      ..color = const Color(0xFF43A85B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(4, size.width * 0.08)
      ..strokeCap = StrokeCap.round;
    if (variant % 3 == 0) {
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * 0.12,
          bodyBottom * 0.18,
          size.width * 0.76,
          bodyBottom * 0.62,
        ),
        0.18,
        pi - 0.36,
        false,
        green,
      );
    } else if (variant % 3 == 1) {
      canvas.drawLine(
        Offset(size.width * 0.18, bodyBottom * 0.74),
        Offset(size.width * 0.82, bodyBottom * 0.74),
        green,
      );
    } else {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.12,
          bodyBottom * 0.10,
          size.width * 0.76,
          bodyBottom * 0.72,
        ),
        green,
      );
    }
    final seedPaint = Paint()..color = const Color(0xFF3C2529);
    for (final point in const [
      Offset(0.38, 0.42),
      Offset(0.58, 0.39),
      Offset(0.48, 0.58),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * point.dx, bodyBottom * point.dy),
          width: size.width * 0.04,
          height: size.width * 0.075,
        ),
        seedPaint,
      );
    }
  }

  void _paintSoccerDetails(Canvas canvas, Size size, double bodyBottom) {
    final center = Offset(size.width * 0.5, bodyBottom * 0.43);
    final radius = size.width * 0.13;
    final black = Paint()..color = const Color(0xFF263238);
    Path pentagon(Offset c, double r) {
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final angle = -pi / 2 + i * pi * 2 / 5;
        final point = c + Offset(cos(angle), sin(angle)) * r;
        i == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      return path..close();
    }

    canvas.drawPath(pentagon(center, radius), black);
    for (var i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * pi * 2 / 5;
      final edge = center + Offset(cos(angle), sin(angle)) * size.width * 0.33;
      canvas.drawPath(pentagon(edge, radius * 0.62), black);
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * radius,
        edge - Offset(cos(angle), sin(angle)) * radius * 0.55,
        Paint()
          ..color = const Color(0xFF455A64)
          ..strokeWidth = max(1.2, size.width * 0.018),
      );
    }
  }

  void _paintFace(
    Canvas canvas,
    Size size,
    double bodyBottom, {
    required bool mouth,
  }) {
    final face = Paint()..color = const Color(0xFF4C4358);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.39, bodyBottom * 0.43),
        width: size.width * 0.045,
        height: size.width * 0.075,
      ),
      face,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.61, bodyBottom * 0.43),
        width: size.width * 0.045,
        height: size.width * 0.075,
      ),
      face,
    );
    if (mouth) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, bodyBottom * 0.54),
          width: size.width * 0.15,
          height: size.width * 0.09,
        ),
        0.15,
        pi - 0.3,
        false,
        Paint()
          ..color = const Color(0xFF4C4358)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.4, size.width * 0.018),
      );
    }
  }

  void _paintCrystalFacets(Canvas canvas, Size size, double bodyBottom) {
    final center = Offset(size.width * 0.5, bodyBottom * 0.46);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.38 + sin(phase).abs() * 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.width * 0.018);
    canvas.drawLine(Offset(size.width * 0.5, bodyBottom * 0.03), center, line);
    canvas.drawLine(Offset(size.width * 0.18, bodyBottom * 0.27), center, line);
    canvas.drawLine(Offset(size.width * 0.73, bodyBottom * 0.75), center, line);
    if (damageProgress > 0) {
      final crack = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, size.width * 0.012);
      final branches = (damageProgress * 5).ceil().clamp(1, 5);
      for (var i = 0; i < branches; i++) {
        final start = center + Offset((i - 2) * size.width * 0.018, i * 2);
        canvas.drawLine(
          start,
          start +
              Offset(
                (i.isEven ? -1 : 1) * size.width * 0.12,
                bodyBottom * (0.10 + i * 0.025),
              ),
          crack,
        );
      }
    }
  }

  void _paintCreamDetails(Canvas canvas, Size size, double bodyBottom) {
    final cream = Paint()..color = const Color(0xFFFFF0A8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.20,
          bodyBottom * 0.57,
          size.width * 0.60,
          bodyBottom * 0.17,
        ),
        Radius.circular(size.width * 0.08),
      ),
      cream,
    );
    final crease = Paint()
      ..color = const Color(0xFF9C5B29).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.width * 0.018);
    for (final x in const [0.32, 0.5, 0.68]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * x, bodyBottom * 0.40),
          width: size.width * 0.18,
          height: bodyBottom * 0.24,
        ),
        0.4,
        1.8,
        false,
        crease,
      );
    }
    if (damageProgress > 0) {
      final drops = (damageProgress * 4).ceil().clamp(1, 4);
      for (var i = 0; i < drops; i++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.34 + i * 0.11),
            bodyBottom * (0.72 + (i.isEven ? 0.02 : 0.06)),
          ),
          size.width * 0.025,
          Paint()..color = const Color(0xFFFFE88F),
        );
      }
    }
  }

  void _paintRabbitDetails(Canvas canvas, Size size, double bodyBottom) {
    final innerEar = Paint()
      ..color = Color.lerp(color, Colors.white, 0.48)!.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, size.width * 0.045)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.315, bodyBottom * 0.08),
      Offset(size.width * 0.35, bodyBottom * 0.27),
      innerEar,
    );
    canvas.drawLine(
      Offset(size.width * 0.685, bodyBottom * 0.08),
      Offset(size.width * 0.65, bodyBottom * 0.27),
      innerEar,
    );

    final facePaint = Paint()..color = const Color(0xFF584454);
    canvas.drawCircle(
      Offset(size.width * 0.40, bodyBottom * 0.56),
      max(1.2, size.width * 0.025),
      facePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.60, bodyBottom * 0.56),
      max(1.2, size.width * 0.025),
      facePaint,
    );
    final nose = Path()
      ..moveTo(size.width * 0.50, bodyBottom * 0.62)
      ..lineTo(size.width * 0.47, bodyBottom * 0.66)
      ..lineTo(size.width * 0.53, bodyBottom * 0.66)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFB95B78));
  }

  @override
  bool shouldRepaint(covariant ShapedBalloonPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.variant != variant ||
      ((shape == BalloonShape.ghost || shape == BalloonShape.crystal) &&
          oldDelegate.phase != phase) ||
      ((shape == BalloonShape.crystal || shape == BalloonShape.creamPuff) &&
          oldDelegate.damageProgress != damageProgress);
}

class BalloonPainter extends CustomPainter {
  const BalloonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => drawBasicBalloon(canvas, size, color);

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) =>
      oldDelegate.color != color;
}

class BossBalloonPainter extends CustomPainter {
  const BossBalloonPainter({
    required this.color,
    required this.hp,
    required this.maxHp,
    this.showHealthBar = true,
  });

  final Color color;
  final int hp;
  final int maxHp;
  final bool showHealthBar;

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

    if (showHealthBar) {
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
          Rect.fromLTWH(
            barLeft,
            barTop,
            barWidth * bossHealthFraction(hp, maxHp),
            11,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BossBalloonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.hp != hp ||
      oldDelegate.maxHp != maxHp ||
      oldDelegate.showHealthBar != showHealthBar;
}

class EffectsPainter extends CustomPainter {
  EffectsPainter({
    required this.pieces,
    required this.rings,
    required this.revision,
    this.feedbacks = const <FloatingTextFeedback>[],
    super.repaint,
  });

  final List<PopPiece> pieces;
  final List<BurstRing> rings;
  final List<FloatingTextFeedback> feedbacks;
  final int revision;
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint();
  final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  int get pieceCount => pieces.length;
  int get heartPieceCount =>
      pieces.where((piece) => piece.shape == EffectPieceShape.heart).length;
  int get ringCount => rings.length;
  int get feedbackCount => feedbacks.length;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ring in rings) {
      final progress = 1 - (ring.life / ring.maxLife).clamp(0.0, 1.0);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      _ringPaint
        ..color = ring.color.withValues(alpha: opacity * 0.75)
        ..strokeWidth = 5 * opacity;
      canvas.drawCircle(ring.center, ring.radius * progress, _ringPaint);
    }

    for (final piece in pieces) {
      final opacity = (piece.life / piece.maxLife).clamp(0.0, 1.0);
      final pieceSize = Size(piece.size, piece.size * 1.3);
      final center = piece.position + pieceSize.center(Offset.zero);
      final path = switch (piece.shape) {
        EffectPieceShape.heart => _heartPath(pieceSize),
        EffectPieceShape.mist || EffectPieceShape.gel => Path()
          ..addOval(Offset.zero & pieceSize),
        EffectPieceShape.pickaxe => Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                pieceSize.width * 0.42,
                0,
                pieceSize.width * 0.16,
                pieceSize.height,
              ),
              const Radius.circular(2),
            ),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, pieceSize.width, pieceSize.height * 0.20),
              const Radius.circular(3),
            ),
          ),
        EffectPieceShape.fork => Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                pieceSize.width * 0.42,
                pieceSize.height * 0.20,
                pieceSize.width * 0.16,
                pieceSize.height * 0.80,
              ),
              const Radius.circular(2),
            ),
          )
          ..addRect(
            Rect.fromLTWH(
              0,
              0,
              pieceSize.width * 0.18,
              pieceSize.height * 0.42,
            ),
          )
          ..addRect(
            Rect.fromLTWH(
              pieceSize.width * 0.41,
              0,
              pieceSize.width * 0.18,
              pieceSize.height * 0.42,
            ),
          )
          ..addRect(
            Rect.fromLTWH(
              pieceSize.width * 0.82,
              0,
              pieceSize.width * 0.18,
              pieceSize.height * 0.42,
            ),
          ),
        EffectPieceShape.shard => Path()
          ..moveTo(pieceSize.width * 0.50, 0)
          ..lineTo(pieceSize.width, pieceSize.height * 0.32)
          ..lineTo(pieceSize.width * 0.72, pieceSize.height)
          ..lineTo(pieceSize.width * 0.22, pieceSize.height * 0.82)
          ..lineTo(0, pieceSize.height * 0.24)
          ..close(),
      };

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(piece.rotation);
      canvas.translate(-pieceSize.width / 2, -pieceSize.height / 2);
      _fillPaint.color = piece.color.withValues(alpha: opacity * piece.color.a);
      _highlightPaint.color = Colors.white.withValues(alpha: opacity * 0.28);
      canvas.drawPath(path, _fillPaint);
      canvas.drawPath(path, _highlightPaint);
      canvas.restore();
    }

    for (final feedback in feedbacks) {
      final progress = (1 - feedback.life / feedback.maxLife).clamp(0.0, 1.0);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final painter = TextPainter(
        text: TextSpan(
          text: feedback.text,
          style: TextStyle(
            color: feedback.color.withValues(alpha: opacity),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: opacity * 0.85),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        feedback.center -
            Offset(painter.width / 2, painter.height / 2 + progress * 24),
      );
    }
  }

  Path _heartPath(Size size) => Path()
    ..moveTo(size.width * 0.5, size.height)
    ..cubicTo(
      size.width * 0.38,
      size.height * 0.82,
      0,
      size.height * 0.58,
      0,
      size.height * 0.28,
    )
    ..cubicTo(0, 0, size.width * 0.36, 0, size.width * 0.5, size.height * 0.2)
    ..cubicTo(
      size.width * 0.64,
      0,
      size.width,
      0,
      size.width,
      size.height * 0.28,
    )
    ..cubicTo(
      size.width,
      size.height * 0.58,
      size.width * 0.62,
      size.height * 0.82,
      size.width * 0.5,
      size.height,
    )
    ..close();

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
        ..lineTo(center.dx + cos(angle) * outer, center.dy + sin(angle) * outer)
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
      final point = Offset(size.width * particle.$1, size.height * particle.$2);
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

  void _drawFirework(Canvas canvas, Offset center, double radius, Color color) {
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
  const StageCardLandscapePainter({required this.tint, required this.locked});

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
          colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
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

  late final ImageStreamListener _imageListener = ImageStreamListener((
    imageInfo,
    _,
  ) {
    if (mounted) setState(() => _imageInfo = imageInfo);
  });

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

  late final ImageStreamListener _imageListener = ImageStreamListener((
    imageInfo,
    _,
  ) {
    if (mounted) setState(() => _imageInfo = imageInfo);
  });

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

  late final ImageStreamListener _imageListener = ImageStreamListener((
    imageInfo,
    _,
  ) {
    if (mounted) setState(() => _imageInfo = imageInfo);
  });

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
          child: CustomPaint(painter: MenuBalloonShapePainter(index: index)),
        ),
        builder: (context, child) {
          final dy = sin(
                animation.value * pi * 2 * cycles[slot] + phaseOffsets[slot],
              ) *
              amplitudes[slot];
          return Transform.translate(offset: Offset(0, dy), child: child);
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
          Rect.fromLTWH(
            0,
            size.height * 0.71,
            size.width,
            size.height * 0.29,
          ),
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
          Rect.fromLTWH(
            0,
            size.height * 0.79,
            size.width,
            size.height * 0.21,
          ),
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
          Rect.fromLTWH(x - radius * 0.10, y, radius * 0.20, radius * 1.85),
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
      canvas.drawLine(origin, origin + Offset(-blade * 0.42, -blade), paint);
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
