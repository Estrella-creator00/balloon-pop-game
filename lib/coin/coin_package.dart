import 'package:flutter/foundation.dart';

@immutable
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.coinAmount,
    required this.priceWon,
    required this.displayPrice,
    this.bonusCoin = 0,
    this.badge,
    this.enabled = true,
  });

  final String id;
  final int coinAmount;
  final int priceWon;
  final String displayPrice;
  final int bonusCoin;
  final String? badge;
  final bool enabled;
}

/// C-01 상품과 가격은 이 목록 한 곳에서만 관리한다.
const coinPackages = <CoinPackage>[
  CoinPackage(
    id: 'coin_300',
    coinAmount: 300,
    priceWon: 1500,
    displayPrice: '₩1,500',
  ),
  CoinPackage(
    id: 'coin_700',
    coinAmount: 700,
    priceWon: 3000,
    displayPrice: '₩3,000',
  ),
  CoinPackage(
    id: 'coin_1500',
    coinAmount: 1500,
    priceWon: 5900,
    displayPrice: '₩5,900',
  ),
  CoinPackage(
    id: 'coin_3500',
    coinAmount: 3500,
    priceWon: 11900,
    displayPrice: '₩11,900',
  ),
];
