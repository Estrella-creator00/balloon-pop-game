import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import 'coin_purchase_gateway.dart';

final class InAppPurchaseCoinGateway implements CoinPurchaseGateway {
  InAppPurchaseCoinGateway({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};

  @override
  Stream<List<StorePurchaseEvent>> get purchaseStream =>
      _store.purchaseStream.map(
        (events) => events.map(_mapPurchase).toList(growable: false),
      );

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<StoreProductQuery> queryProducts(Set<String> productIds) async {
    final response = await _store.queryProductDetails(productIds);
    _products
      ..clear()
      ..addEntries(
        response.productDetails.map((product) => MapEntry(product.id, product)),
      );
    if (response.error != null) throw StateError(response.error!.code);
    return StoreProductQuery(
      offers: response.productDetails
          .map(
            (product) => StoreProductOffer(
              productId: product.id,
              localizedPrice: product.price,
            ),
          )
          .toList(growable: false),
      notFoundProductIds: response.notFoundIDs.toSet(),
    );
  }

  @override
  Future<bool> buyConsumable(String productId) async {
    final product = _products[productId];
    if (product == null) return false;
    return _store.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: false,
    );
  }

  StorePurchaseEvent _mapPurchase(PurchaseDetails purchase) {
    return StorePurchaseEvent(
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
      status: switch (purchase.status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
        PurchaseStatus.error => StorePurchaseStatus.failed,
      },
      serverVerificationData: purchase.verificationData.serverVerificationData,
      verificationSource: purchase.verificationData.source,
      errorCode: purchase.error?.code,
      complete: () async {
        if (Platform.isAndroid &&
            (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored)) {
          final android = _store
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
          final result = await android.consumePurchase(purchase);
          if (result.responseCode != BillingResponse.ok) {
            throw StateError('Store could not finalize the consumable.');
          }
        }
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
      },
    );
  }
}
