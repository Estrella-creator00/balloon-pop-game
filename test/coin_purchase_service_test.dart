import 'dart:async';

import 'package:balloon_pop_game/coin/coin_package.dart';
import 'package:balloon_pop_game/config/release_features.dart';
import 'package:balloon_pop_game/services/coin_purchase_gateway.dart';
import 'package:balloon_pop_game/services/coin_purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free release never subscribes to or calls the store gateway', () async {
    final gateway = _FakeGateway(offers: _allOffers());
    final service = CoinPurchaseService(
      gateway: gateway,
      verifier: _FakeVerifier(
        const PurchaseVerificationResult.approved(
          grantId: 'unused-grant',
          coinAmount: 300,
        ),
      ),
      grantSink: _FakeGrantSink(),
      enabled: ReleaseFeatures.cashCoinPurchasesEnabled,
    );

    expect(ReleaseFeatures.cashCoinPurchasesEnabled, false);
    await service.start();
    expect(service.snapshot.status, CoinPurchaseStatus.unavailable);
    expect(gateway.purchaseStreamReads, 0);
    expect(gateway.availabilityChecks, 0);
    expect(gateway.queriedIds, isNull);
    expect(
      await service.purchase(coinPackages.first),
      CoinPurchaseStatus.unavailable,
    );
    expect(gateway.buyCount, 0);
    await service.close();
  });

  test('queries all consumable products and keeps store-localized prices',
      () async {
    final gateway = _FakeGateway(
      offers: const [
        StoreProductOffer(productId: 'coin_300', localizedPrice: r'$0.99'),
        StoreProductOffer(productId: 'coin_700', localizedPrice: '€2.49'),
      ],
      missing: const {'coin_1500', 'coin_3500'},
    );
    final service = _service(gateway: gateway);

    await service.start();

    expect(gateway.queriedIds, coinPackages.map((item) => item.id).toSet());
    expect(service.snapshot.offers['coin_300']!.localizedPrice, r'$0.99');
    expect(service.snapshot.offers['coin_700']!.localizedPrice, '€2.49');
    expect(service.snapshot.notFoundProductIds, {'coin_1500', 'coin_3500'});
    await service.close();
  });

  test('unavailable store and unconfigured verifier never start purchases',
      () async {
    final unavailable = _FakeGateway(available: false);
    final unavailableService = _service(gateway: unavailable);
    await unavailableService.start();
    expect(unavailableService.snapshot.status, CoinPurchaseStatus.unavailable);
    expect(await unavailableService.purchase(coinPackages.first),
        CoinPurchaseStatus.unavailable);
    expect(unavailable.buyCount, 0);

    final gateway = _FakeGateway(offers: _allOffers());
    final service = CoinPurchaseService(
      gateway: gateway,
      verifier: const UnconfiguredCoinPurchaseVerifier(),
      grantSink: _FakeGrantSink(),
    );
    await service.start();
    expect(service.snapshot.status, CoinPurchaseStatus.ready);
    expect(await service.purchase(coinPackages.first),
        CoinPurchaseStatus.unavailable);
    expect(gateway.buyCount, 0);
    await unavailableService.close();
    await service.close();
  });

  test('prevents double taps and exposes pending, cancelled, and failed states',
      () async {
    final gateway = _FakeGateway(offers: _allOffers());
    final service = _service(gateway: gateway);
    await service.start();

    final first = service.purchase(coinPackages.first);
    final second = service.purchase(coinPackages.first);
    expect(await first, CoinPurchaseStatus.purchasing);
    expect(await second, CoinPurchaseStatus.unavailable);
    expect(gateway.buyCount, 1);

    gateway.emit(_event(StorePurchaseStatus.pending));
    await _flush();
    expect(service.snapshot.status, CoinPurchaseStatus.pending);
    gateway.emit(_event(StorePurchaseStatus.cancelled));
    await _flush();
    expect(service.snapshot.status, CoinPurchaseStatus.cancelled);

    await service.purchase(coinPackages.first);
    gateway.emit(_event(StorePurchaseStatus.failed));
    await _flush();
    expect(service.snapshot.status, CoinPurchaseStatus.failed);
    await service.close();
  });

  test('grants only after verification and ignores duplicate delivery',
      () async {
    final gateway = _FakeGateway(offers: _allOffers());
    final sink = _FakeGrantSink();
    final verifier = _FakeVerifier(
      const PurchaseVerificationResult.approved(
        grantId: 'grant-transaction-1',
        coinAmount: 300,
      ),
    );
    final service = _service(
      gateway: gateway,
      verifier: verifier,
      sink: sink,
    );
    await service.start();
    await service.purchase(coinPackages.first);

    final event = _event(StorePurchaseStatus.purchased);
    gateway.emit(event);
    gateway.emit(event);
    await _flush();
    await _flush();

    expect(verifier.calls, 1);
    expect(sink.totalCoins, 300);
    expect(sink.grantCalls, 1);
    expect(service.snapshot.status, CoinPurchaseStatus.completed);
    await service.close();
  });

  test('verification rejection, wrong entitlement, and retry leave coins alone',
      () async {
    for (final result in <PurchaseVerificationResult>[
      const PurchaseVerificationResult.rejected(),
      const PurchaseVerificationResult.retryLater(),
      const PurchaseVerificationResult.approved(
        grantId: 'wrong-entitlement',
        coinAmount: 700,
      ),
    ]) {
      final gateway = _FakeGateway(offers: _allOffers());
      final sink = _FakeGrantSink();
      final service = _service(
        gateway: gateway,
        verifier: _FakeVerifier(result),
        sink: sink,
      );
      await service.start();
      await service.purchase(coinPackages.first);
      gateway.emit(_event(StorePurchaseStatus.purchased));
      await _flush();
      expect(service.snapshot.status, CoinPurchaseStatus.verificationFailed);
      expect(sink.totalCoins, 0);
      await service.close();
    }
  });
}

List<StoreProductOffer> _allOffers() => coinPackages
    .map((item) => StoreProductOffer(
          productId: item.id,
          localizedPrice: 'localized-${item.id}',
        ))
    .toList();

CoinPurchaseService _service({
  required _FakeGateway gateway,
  CoinPurchaseVerifier? verifier,
  _FakeGrantSink? sink,
}) {
  return CoinPurchaseService(
    gateway: gateway,
    verifier: verifier ??
        _FakeVerifier(
          const PurchaseVerificationResult.approved(
            grantId: 'default-grant-id',
            coinAmount: 300,
          ),
        ),
    grantSink: sink ?? _FakeGrantSink(),
  );
}

StorePurchaseEvent _event(StorePurchaseStatus status) => StorePurchaseEvent(
      productId: 'coin_300',
      purchaseId: 'purchase-1',
      status: status,
      serverVerificationData: 'private-receipt-for-test',
      verificationSource: 'test',
      complete: () async {},
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeGateway implements CoinPurchaseGateway {
  _FakeGateway({
    this.available = true,
    this.offers = const [],
    this.missing = const {},
  });

  final bool available;
  final List<StoreProductOffer> offers;
  final Set<String> missing;
  final StreamController<List<StorePurchaseEvent>> _events =
      StreamController<List<StorePurchaseEvent>>.broadcast();
  Set<String>? queriedIds;
  int buyCount = 0;
  int purchaseStreamReads = 0;
  int availabilityChecks = 0;

  @override
  Stream<List<StorePurchaseEvent>> get purchaseStream {
    purchaseStreamReads++;
    return _events.stream;
  }

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<StoreProductQuery> queryProducts(Set<String> productIds) async {
    queriedIds = productIds;
    return StoreProductQuery(offers: offers, notFoundProductIds: missing);
  }

  @override
  Future<bool> buyConsumable(String productId) async {
    buyCount++;
    return true;
  }

  void emit(StorePurchaseEvent event) => _events.add([event]);
}

class _FakeVerifier implements CoinPurchaseVerifier {
  _FakeVerifier(this.result);

  final PurchaseVerificationResult result;
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<PurchaseVerificationResult> verify(
    PurchaseVerificationRequest request,
  ) async {
    calls++;
    return result;
  }
}

class _FakeGrantSink implements VerifiedCoinGrantSink {
  final Set<String> _grants = {};
  int totalCoins = 0;
  int grantCalls = 0;

  @override
  Future<bool> grantOnce(
      {required String grantId, required int coinAmount}) async {
    grantCalls++;
    if (!_grants.add(grantId)) return false;
    totalCoins += coinAmount;
    return true;
  }
}
