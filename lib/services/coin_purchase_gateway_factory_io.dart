import 'dart:io';

import 'coin_purchase_gateway.dart';
import 'coin_purchase_gateway_in_app_purchase.dart';

CoinPurchaseGateway createPlatformCoinPurchaseGateway() {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const DisabledCoinPurchaseGateway();
  }
  return InAppPurchaseCoinGateway();
}
