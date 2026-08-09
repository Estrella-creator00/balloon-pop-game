import 'package:flutter/material.dart';

import 'balloon_background.dart';

enum BalloonRarity { common, rare, heroic, legendary }

enum BalloonRendererType {
  painted,
  image,
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

enum BalloonPopEffectType { shards, hearts, mist, gel, crystal, cream }

enum BalloonPopSoundType { basic, heart, ghost, crackle, crystal, cream }

enum BalloonIdleAnimationType {
  none,
  spin,
  ghostTail,
  slimeSquish,
  glow,
  breathe
}

enum BalloonSpecialBehavior { none, watermelonVariant, onePercentSpin }

enum BalloonImageDetailMask { none, mochiFace }

enum BalloonBadge { none, newItem, popular, event, recommended }

@immutable
class BalloonSkinDefinition {
  const BalloonSkinDefinition({
    required this.id,
    required this.displayName,
    required this.price,
    required this.rarity,
    required this.rendererType,
    required this.colorPalette,
    required this.popEffectType,
    required this.popSoundType,
    required this.isDefault,
    required this.supportsBossSkin,
    required this.shopOrder,
    required this.previewColor,
    this.description,
    this.assetPath,
    this.badge = BalloonBadge.none,
    this.avoidImmediateColorRepeat = false,
    this.damageTint = const Color(0xFF3B246B),
    this.normalDamageTintStrength = 0.38,
    this.bossDamageTintStrength = 0.62,
    this.initiallyOwned = false,
    this.background = BalloonBackgroundType.none,
    this.idleAnimation = BalloonIdleAnimationType.none,
    this.specialBehavior = BalloonSpecialBehavior.none,
    this.visualVariantCount = 1,
    this.specialSpawnChance = 0,
    this.imageDetailMask = BalloonImageDetailMask.none,
  });

  final String id;
  final String displayName;
  final String? description;
  final int price;
  final BalloonRarity rarity;
  final BalloonRendererType rendererType;
  final String? assetPath;
  final List<Color> colorPalette;
  final BalloonPopEffectType popEffectType;
  final BalloonPopSoundType popSoundType;
  final BalloonIdleAnimationType idleAnimation;
  final BalloonSpecialBehavior specialBehavior;
  final int visualVariantCount;
  final double specialSpawnChance;
  final BalloonImageDetailMask imageDetailMask;
  final bool isDefault;
  final BalloonBadge badge;
  final bool supportsBossSkin;
  final int shopOrder;
  final Color previewColor;
  final bool avoidImmediateColorRepeat;
  final Color damageTint;
  final double normalDamageTintStrength;
  final double bossDamageTintStrength;
  final bool initiallyOwned;
  final BalloonBackgroundType background;

  bool get showsDescription =>
      rarity != BalloonRarity.common && description != null;

  Color colorAtDamage(Color base, double progress, {required bool isBoss}) {
    final strength = isBoss ? bossDamageTintStrength : normalDamageTintStrength;
    final target = Color.lerp(base, damageTint, strength)!;
    return Color.lerp(base, target, progress.clamp(0.0, 1.0))!;
  }

  int chooseVisualVariant(double randomValue) {
    if (visualVariantCount <= 1) return 0;
    return (randomValue.clamp(0.0, 0.999999) * visualVariantCount).floor();
  }

  bool chooseSpecialSpawn(double randomValue) =>
      specialSpawnChance > 0 && randomValue < specialSpawnChance;
}

/// Single source of truth for shop, preview, gameplay, Boss, effects and sound.
/// NEW BALLOON: register one definition here; add an enum implementation only
/// when it needs genuinely new vector art, effect, sound or background.
abstract final class BalloonSkinCatalog {
  static const defaultId = 'balloon-default';

  static const _basicPalette = <Color>[
    Color(0xFFFF5C8A),
    Color(0xFFFFC857),
    Color(0xFF5CD6C0),
    Color(0xFF8B7CF6),
    Color(0xFFFF8A5B),
    Color(0xFF54A8FF),
    Color(0xFFFF7FDB),
  ];
  static const _heartPalette = <Color>[
    Color(0xFFFF5C8A),
    Color(0xFFFF4D67),
    Color(0xFFA77BFF),
    Color(0xFF5EE4C0),
    Color(0xFF5CC8FF),
    Color(0xFFFFD75A),
  ];
  static const _rabbitPalette = <Color>[
    Color(0xFFFF91B8),
    Color(0xFFFFD982),
    Color(0xFF91CAFF),
    Color(0xFFC5A0FF),
    Color(0xFF8FE1D0),
  ];
  static const _ghostPalette = <Color>[
    Color(0xFFC9B7FF),
    Color(0xFFAFE5FF),
    Color(0xFFAEEEDC),
    Color(0xFFFFC3DD),
  ];
  static const _slimePalette = <Color>[
    Color(0xFF6EEB83),
    Color(0xFF42D9C8),
    Color(0xFF65A7FF),
    Color(0xFFA979FF),
    Color(0xFFFFA44F),
    Color(0xFFFF79B8),
  ];
  static const _crystalPalette = <Color>[
    Color(0xFF4C8DFF),
    Color(0xFF9A67FF),
    Color(0xFF39C98A),
    Color(0xFFFF5574),
  ];

  static const definitions = <BalloonSkinDefinition>[
    BalloonSkinDefinition(
      id: defaultId,
      displayName: '기본 풍선',
      price: 0,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.painted,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: true,
      supportsBossSkin: true,
      shopOrder: 0,
      previewColor: Color(0xFFFF5C8A),
      initiallyOwned: true,
    ),
    BalloonSkinDefinition(
      id: 'balloon-heart',
      displayName: '하트',
      price: 100,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/heart_balloon.png',
      colorPalette: _heartPalette,
      popEffectType: BalloonPopEffectType.hearts,
      popSoundType: BalloonPopSoundType.heart,
      isDefault: false,
      badge: BalloonBadge.newItem,
      supportsBossSkin: true,
      shopOrder: 1,
      previewColor: Color(0xFFFF5C8A),
      avoidImmediateColorRepeat: true,
    ),
    BalloonSkinDefinition(
      id: 'balloon-star',
      displayName: '별',
      price: 200,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.star,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 2,
      previewColor: Color(0xFFFFC857),
    ),
    BalloonSkinDefinition(
      id: 'balloon-flower',
      displayName: '꽃',
      price: 200,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.flower,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 3,
      previewColor: Color(0xFFFF7FDB),
    ),
    BalloonSkinDefinition(
      // Keep the legacy rabbit ID so existing ownership/equipment survives.
      id: 'balloon-rabbit', displayName: '모찌', price: 500,
      description: '겁은 많지만 호기심은 누구보다 많아요.',
      rarity: BalloonRarity.rare, rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/mochi_balloon.png',
      colorPalette: _rabbitPalette, popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic, isDefault: false,
      supportsBossSkin: true, shopOrder: 4, previewColor: Color(0xFFFF91B8),
      avoidImmediateColorRepeat: true,
      imageDetailMask: BalloonImageDetailMask.mochiFace,
    ),
    BalloonSkinDefinition(
      id: 'balloon-wari',
      displayName: '와리',
      price: 600,
      description: '오늘은 어떤 모습으로 나타날지 아무도 몰라요.',
      rarity: BalloonRarity.rare,
      rendererType: BalloonRendererType.watermelon,
      colorPalette: <Color>[Color(0xFFFF5E67)],
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 5,
      previewColor: Color(0xFFFF5E67),
      specialBehavior: BalloonSpecialBehavior.watermelonVariant,
      visualVariantCount: 3,
    ),
    BalloonSkinDefinition(
      id: 'balloon-kicks',
      displayName: '킥스',
      price: 700,
      description: '평소엔 얌전하지만 가끔 혼자 신이 납니다.',
      rarity: BalloonRarity.rare,
      rendererType: BalloonRendererType.soccer,
      colorPalette: <Color>[Color(0xFFF8FAFC)],
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 6,
      previewColor: Color(0xFFF8FAFC),
      idleAnimation: BalloonIdleAnimationType.spin,
      specialBehavior: BalloonSpecialBehavior.onePercentSpin,
      specialSpawnChance: 0.01,
    ),
    BalloonSkinDefinition(
      id: 'balloon-boo',
      displayName: '부우',
      price: 1000,
      description: '조용히 떠다니는 걸 제일 좋아해요.',
      rarity: BalloonRarity.heroic,
      rendererType: BalloonRendererType.ghost,
      colorPalette: _ghostPalette,
      popEffectType: BalloonPopEffectType.mist,
      popSoundType: BalloonPopSoundType.ghost,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 7,
      previewColor: Color(0xFFC9B7FF),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.ghostTail,
    ),
    BalloonSkinDefinition(
      id: 'balloon-jello',
      displayName: '젤로',
      price: 1500,
      description: '말랑해 보여도 건드리면 빠지직!',
      rarity: BalloonRarity.heroic,
      rendererType: BalloonRendererType.slime,
      colorPalette: _slimePalette,
      popEffectType: BalloonPopEffectType.gel,
      popSoundType: BalloonPopSoundType.crackle,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 8,
      previewColor: Color(0xFF6EEB83),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.slimeSquish,
    ),
    BalloonSkinDefinition(
      id: 'balloon-lumen',
      displayName: '루멘',
      price: 5000,
      description: '깊은 동굴에서 발견된 정체불명의 수정.',
      rarity: BalloonRarity.legendary,
      rendererType: BalloonRendererType.crystal,
      colorPalette: _crystalPalette,
      popEffectType: BalloonPopEffectType.crystal,
      popSoundType: BalloonPopSoundType.crystal,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 9,
      previewColor: Color(0xFF4C8DFF),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.glow,
      background: BalloonBackgroundType.crystalCave,
    ),
    BalloonSkinDefinition(
      id: 'balloon-chouchou',
      displayName: '슈슈',
      price: 5000,
      description: '절대로 포크로 찌르지 마세요.',
      rarity: BalloonRarity.legendary,
      rendererType: BalloonRendererType.creamPuff,
      colorPalette: <Color>[Color(0xFFD99542)],
      popEffectType: BalloonPopEffectType.cream,
      popSoundType: BalloonPopSoundType.cream,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 10,
      previewColor: Color(0xFFD99542),
      idleAnimation: BalloonIdleAnimationType.breathe,
      background: BalloonBackgroundType.creamCafe,
    ),
  ];

  static final Map<String, BalloonSkinDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };
  static final List<BalloonSkinDefinition> shopDefinitions = List.unmodifiable(
    [...definitions]..sort((a, b) => a.shopOrder.compareTo(b.shopOrder)),
  );

  static BalloonSkinDefinition get defaultSkin => _byId[defaultId]!;
  static BalloonSkinDefinition byIdOrDefault(String? id) =>
      _byId[id] ?? defaultSkin;
  static bool get hasUniqueIds => _byId.length == definitions.length;
}
