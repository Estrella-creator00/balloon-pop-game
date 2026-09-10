import 'coin_purchase_gateway.dart';

CoinPurchaseGateway createPlatformCoinPurchaseGateway() =>
    const DisabledCoinPurchaseGateway();
