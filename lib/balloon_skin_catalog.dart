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
  breathe,
}

enum BalloonSpecialBehavior { none, watermelonVariant, onePercentSpin }

enum BalloonExitAnimationType { none, kickAway }

enum BalloonImageDetailMask { none, mochiFace }

enum BalloonImageColorMode { hueShift, grayscaleTint, original }

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
    this.imageColorMode = BalloonImageColorMode.hueShift,
    this.variantAssetPaths = const <String>[],
    this.hitToolAssetPath,
    this.hitSoundAssetPath,
    this.popSoundAssetPath,
    this.burstAssetPath,
    this.wallSplatAssetPath,
    this.screenSplatAssetPath,
    this.shardAssetPath,
    this.screenCrackAssetPath,
    this.screenCrackChance = 0,
    this.exitAnimation = BalloonExitAnimationType.none,
    this.runtimeColorAssetPaths = const <int, String>{},
    this.runtimeFakeColorAssetPaths = const <int, String>{},
    this.runtimeShardAssetPaths = const <int, String>{},
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
  final BalloonImageColorMode imageColorMode;
  final List<String> variantAssetPaths;
  final String? hitToolAssetPath;
  final String? hitSoundAssetPath;
  final String? popSoundAssetPath;
  final String? burstAssetPath;
  final String? wallSplatAssetPath;
  final String? screenSplatAssetPath;
  final String? shardAssetPath;
  final String? screenCrackAssetPath;
  final double screenCrackChance;
  final BalloonExitAnimationType exitAnimation;
  final Map<int, String> runtimeColorAssetPaths;
  final Map<int, String> runtimeFakeColorAssetPaths;
  final Map<int, String> runtimeShardAssetPaths;
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

  bool get showsDescription => description?.isNotEmpty ?? false;

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

  String? assetForVariant(int variant) {
    if (variantAssetPaths.isEmpty) return assetPath;
    return variantAssetPaths[variant % variantAssetPaths.length];
  }
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
      supportsBossSkin: true,
      shopOrder: 1,
      previewColor: Color(0xFFFF5C8A),
      avoidImmediateColorRepeat: true,
    ),
    BalloonSkinDefinition(
      id: 'balloon-star',
      displayName: '별',
      description: '조용하지만 은근 튀는 편',
      price: 200,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_star_asset.png',
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
      description: '화사하고 기분파',
      price: 200,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_flower_asset.png',
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 3,
      previewColor: Color(0xFF6FA7FF),
    ),
    BalloonSkinDefinition(
      // Keep the legacy rabbit ID so existing ownership/equipment survives.
      id: 'balloon-rabbit',
      displayName: '모찌',
      price: 500,
      description: '겁 많고 호기심 많음',
      rarity: BalloonRarity.rare,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/mochi_balloon.png',
      colorPalette: _rabbitPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 4,
      previewColor: Color(0xFFFF91B8),
      avoidImmediateColorRepeat: true,
      imageDetailMask: BalloonImageDetailMask.mochiFace,
    ),
    BalloonSkinDefinition(
      id: 'balloon-wari',
      displayName: '와리',
      price: 600,
      description: '시원하고 자유분방함',
      rarity: BalloonRarity.rare,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_wari_halfmoon_asset.png',
      variantAssetPaths: <String>[
        'assets/images/balloon_wari_halfmoon_asset.png',
        'assets/images/balloon_wari_triangle_asset.png',
        'assets/images/balloon_wari_round_asset.png',
      ],
      imageColorMode: BalloonImageColorMode.original,
      colorPalette: <Color>[Color(0xFFFF5E67)],
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 5,
      previewColor: Color(0xFFFF5E67),
      specialBehavior: BalloonSpecialBehavior.watermelonVariant,
      visualVariantCount: 3,
      popSoundAssetPath: 'assets/sounds/wari_watermelon_bite.mp3.mp3',
    ),
    BalloonSkinDefinition(
      id: 'balloon-kicks',
      displayName: '킥스',
      price: 700,
      description: '활발하고 승부욕 강함',
      rarity: BalloonRarity.rare,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_kicks_asset.png',
      imageColorMode: BalloonImageColorMode.grayscaleTint,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 6,
      previewColor: Color(0xFFF8FAFC),
      idleAnimation: BalloonIdleAnimationType.none,
      hitSoundAssetPath: 'assets/sounds/kicks_soccer_kick.mp3.mp3',
      exitAnimation: BalloonExitAnimationType.kickAway,
    ),
    BalloonSkinDefinition(
      id: 'balloon-boo',
      displayName: '부우',
      price: 1000,
      description: '장난기 많고 살짝 겁쟁이',
      rarity: BalloonRarity.heroic,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_boo_asset.png',
      colorPalette: _ghostPalette,
      popEffectType: BalloonPopEffectType.mist,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 7,
      previewColor: Color(0xFFC9B7FF),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.ghostTail,
      popSoundAssetPath: 'assets/sounds/boo_ghost_woo_short.mp3.mp3',
    ),
    BalloonSkinDefinition(
      id: 'balloon-jello',
      displayName: '머기',
      price: 1500,
      description: '예민하고 까칠함',
      rarity: BalloonRarity.heroic,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_muggy_handle_alpha_asset.png',
      colorPalette: _slimePalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      popSoundAssetPath: 'assets/sounds/mugi_break_short.mp3.mp3',
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 8,
      previewColor: Color(0xFFB7CF86),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.none,
    ),
    BalloonSkinDefinition(
      id: 'balloon-lumen',
      displayName: '제미',
      price: 5000,
      description: '차갑고 단단함',
      rarity: BalloonRarity.legendary,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_gemi_asset.png',
      colorPalette: _crystalPalette,
      popEffectType: BalloonPopEffectType.crystal,
      popSoundType: BalloonPopSoundType.crystal,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 9,
      previewColor: Color(0xFF9A67FF),
      avoidImmediateColorRepeat: true,
      idleAnimation: BalloonIdleAnimationType.glow,
      background: BalloonBackgroundType.crystalCave,
      hitToolAssetPath: 'assets/images/gemi_pickaxe_glow_runtime.png',
      hitSoundAssetPath: 'assets/images/gemi_pickaxe_hit.mp3.mp3',
      popSoundAssetPath: 'assets/images/gemi_break.mp3.mp3',
      shardAssetPath: 'assets/images/gemi_shard_runtime.png',
      screenCrackAssetPath: 'assets/images/gemi_screen_crack.png.png',
      screenCrackChance: 0.28,
      runtimeColorAssetPaths: <int, String>{
        0xFF4C8DFF: 'assets/images/gemi_body_blue_runtime.png',
        0xFF9A67FF: 'assets/images/gemi_body_purple_runtime.png',
        0xFF39C98A: 'assets/images/gemi_body_green_runtime.png',
        0xFFFF5574: 'assets/images/gemi_body_red_runtime.png',
      },
      runtimeFakeColorAssetPaths: <int, String>{
        0xFF4C8DFF: 'assets/images/gemi_body_blue_fake_runtime.png',
        0xFF9A67FF: 'assets/images/gemi_body_purple_fake_runtime.png',
        0xFF39C98A: 'assets/images/gemi_body_green_fake_runtime.png',
        0xFFFF5574: 'assets/images/gemi_body_red_fake_runtime.png',
      },
      runtimeShardAssetPaths: <int, String>{
        0xFF4C8DFF: 'assets/images/gemi_shard_blue_runtime.png',
        0xFF9A67FF: 'assets/images/gemi_shard_purple_runtime.png',
        0xFF39C98A: 'assets/images/gemi_shard_green_runtime.png',
        0xFFFF5574: 'assets/images/gemi_shard_red_runtime.png',
      },
    ),
    BalloonSkinDefinition(
      id: 'balloon-chouchou',
      displayName: '슈슈',
      price: 5000,
      description: '달콤하고 엉뚱함',
      rarity: BalloonRarity.legendary,
      rendererType: BalloonRendererType.image,
      assetPath: 'assets/images/balloon_shushu_asset.png',
      imageColorMode: BalloonImageColorMode.original,
      colorPalette: <Color>[Color(0xFFD99542)],
      popEffectType: BalloonPopEffectType.cream,
      popSoundType: BalloonPopSoundType.cream,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 10,
      previewColor: Color(0xFFD99542),
      idleAnimation: BalloonIdleAnimationType.breathe,
      background: BalloonBackgroundType.creamCafe,
      hitToolAssetPath: 'assets/images/shushu_fork_asset.png',
      hitSoundAssetPath: 'assets/images/shushu_fork_hit.mp3.mp3',
      popSoundAssetPath: 'assets/images/shushu_cream_burst.mp3.mp3',
      burstAssetPath: 'assets/images/shushu_cream_burst_asset.png',
      wallSplatAssetPath: 'assets/images/shushu_cream_wall_asset.png',
      screenSplatAssetPath: 'assets/images/shushu_cream_screen_asset.png',
    ),
  ];

  static final Map<String, BalloonSkinDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };
  static final List<BalloonSkinDefinition> shopDefinitions = List.unmodifiable(
    [...definitions]..sort((a, b) => a.shopOrder.compareTo(b.shopOrder)),
  );

  /// Release-content badge targets. Update this set only when the shop's
  /// NEW lineup changes; product order and saved IDs stay untouched.
  static const newItemIds = <String>{
    'balloon-star',
    'balloon-flower',
    'balloon-wari',
    'balloon-kicks',
    'balloon-boo',
    'balloon-jello',
    'balloon-lumen',
    'balloon-chouchou',
  };

  static BalloonBadge badgeFor(BalloonSkinDefinition definition) =>
      newItemIds.contains(definition.id)
          ? BalloonBadge.newItem
          : definition.badge;

  static BalloonSkinDefinition get defaultSkin => _byId[defaultId]!;
  static BalloonSkinDefinition byIdOrDefault(String? id) =>
      _byId[id] ?? defaultSkin;
  static bool get hasUniqueIds => _byId.length == definitions.length;
}
