import 'package:flutter/foundation.dart';

@immutable
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.coinAmount,
  });

  final String id;
  final int coinAmount;
}

/// Store product identifiers and their local coin entitlement mapping.
/// Prices always come from Google Play or the App Store.
const coinPackages = <CoinPackage>[
  CoinPackage(id: 'coin_300', coinAmount: 300),
  CoinPackage(id: 'coin_700', coinAmount: 700),
  CoinPackage(id: 'coin_1500', coinAmount: 1500),
  CoinPackage(id: 'coin_3500', coinAmount: 3500),
];
