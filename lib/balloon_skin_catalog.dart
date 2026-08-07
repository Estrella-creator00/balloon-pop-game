import 'package:flutter/material.dart';

import 'balloon_background.dart';

enum BalloonRarity { common, rare, epic, legendary }

enum BalloonRendererType { painted, image }

enum BalloonPopEffectType { shards, hearts }

enum BalloonPopSoundType { basic, heart }

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
    this.assetPath,
    this.badge = BalloonBadge.none,
    this.avoidImmediateColorRepeat = false,
    this.damageTint = const Color(0xFF3B246B),
    this.normalDamageTintStrength = 0.38,
    this.bossDamageTintStrength = 0.62,
    this.initiallyOwned = false,
    this.background = BalloonBackgroundType.none,
  });

  final String id;
  final String displayName;
  final int price;
  final BalloonRarity rarity;
  final BalloonRendererType rendererType;
  final String? assetPath;
  final List<Color> colorPalette;
  final BalloonPopEffectType popEffectType;
  final BalloonPopSoundType popSoundType;
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

  Color colorAtDamage(Color base, double progress, {required bool isBoss}) {
    final strength = isBoss ? bossDamageTintStrength : normalDamageTintStrength;
    final target = Color.lerp(base, damageTint, strength)!;
    return Color.lerp(base, target, progress.clamp(0.0, 1.0))!;
  }
}

/// Single source of truth for balloon shop, rendering, effects, and sounds.
///
/// NEW BALLOON: add one definition here, add its optimized transparent asset,
/// then implement a new effect/sound enum case only when the skin needs one.
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
      background: BalloonBackgroundType.none,
    ),
    BalloonSkinDefinition(
      id: 'balloon-heart',
      displayName: '하트 풍선',
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
      background: BalloonBackgroundType.none,
    ),
    // Existing products retain their IDs and initial ownership behavior.
    BalloonSkinDefinition(
      id: 'balloon-a',
      displayName: '특별 풍선 A',
      price: 500,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.painted,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: false,
      shopOrder: 2,
      previewColor: Color(0xFF54A8FF),
    ),
    BalloonSkinDefinition(
      id: 'balloon-b',
      displayName: '특별 풍선 B',
      price: 700,
      rarity: BalloonRarity.common,
      rendererType: BalloonRendererType.painted,
      colorPalette: _basicPalette,
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: false,
      shopOrder: 3,
      previewColor: Color(0xFF8B7CF6),
      initiallyOwned: true,
    ),
  ];

  static final Map<String, BalloonSkinDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };

  static final List<BalloonSkinDefinition> shopDefinitions = List.unmodifiable(
    [...definitions]
      ..sort((left, right) => left.shopOrder.compareTo(right.shopOrder)),
  );

  static BalloonSkinDefinition get defaultSkin => _byId[defaultId]!;

  static BalloonSkinDefinition byIdOrDefault(String? id) =>
      _byId[id] ?? defaultSkin;

  static bool get hasUniqueIds => _byId.length == definitions.length;
}
