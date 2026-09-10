import 'dart:io';

import '../config/release_features.dart';
import 'coin_purchase_gateway.dart';
import 'coin_purchase_gateway_in_app_purchase.dart';

CoinPurchaseGateway createPlatformCoinPurchaseGateway() {
  if (!ReleaseFeatures.cashCoinPurchasesEnabled ||
      (!Platform.isAndroid && !Platform.isIOS)) {
    return const DisabledCoinPurchaseGateway();
  }
  return InAppPurchaseCoinGateway();
}
