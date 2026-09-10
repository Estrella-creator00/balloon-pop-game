enum StorePurchaseStatus { pending, purchased, restored, cancelled, failed }

class StoreProductOffer {
  const StoreProductOffer({
    required this.productId,
    required this.localizedPrice,
  });

  final String productId;
  final String localizedPrice;
}

class StoreProductQuery {
  const StoreProductQuery({
    required this.offers,
    this.notFoundProductIds = const <String>{},
  });

  final List<StoreProductOffer> offers;
  final Set<String> notFoundProductIds;
}

class StorePurchaseEvent {
  const StorePurchaseEvent({
    required this.productId,
    required this.status,
    required this.serverVerificationData,
    required this.verificationSource,
    required this.complete,
    this.purchaseId,
    this.errorCode,
  });

  final String productId;
  final StorePurchaseStatus status;
  final String serverVerificationData;
  final String verificationSource;
  final String? purchaseId;
  final String? errorCode;
  final Future<void> Function() complete;
}

abstract interface class CoinPurchaseGateway {
  Stream<List<StorePurchaseEvent>> get purchaseStream;

  Future<bool> isAvailable();

  Future<StoreProductQuery> queryProducts(Set<String> productIds);

  Future<bool> buyConsumable(String productId);
}

class DisabledCoinPurchaseGateway implements CoinPurchaseGateway {
  const DisabledCoinPurchaseGateway();

  @override
  Stream<List<StorePurchaseEvent>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<StoreProductQuery> queryProducts(Set<String> productIds) async =>
      StoreProductQuery(offers: const [], notFoundProductIds: productIds);

  @override
  Future<bool> buyConsumable(String productId) async => false;
}
