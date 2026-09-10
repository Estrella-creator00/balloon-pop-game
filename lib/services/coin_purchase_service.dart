import 'dart:async';

import 'package:flutter/foundation.dart';

import '../coin/coin_package.dart';
import '../config/release_features.dart';
import '../storage/progress_storage.dart';
import 'coin_purchase_gateway.dart';
import 'coin_purchase_gateway_factory.dart';

enum CoinPurchaseStatus {
  idle,
  loading,
  ready,
  unavailable,
  productNotFound,
  purchasing,
  pending,
  cancelled,
  failed,
  verificationFailed,
  completed,
}

@immutable
class CoinPurchaseSnapshot {
  const CoinPurchaseSnapshot({
    this.status = CoinPurchaseStatus.idle,
    this.offers = const <String, StoreProductOffer>{},
    this.notFoundProductIds = const <String>{},
    this.busyProductId,
    this.eventSerial = 0,
  });

  final CoinPurchaseStatus status;
  final Map<String, StoreProductOffer> offers;
  final Set<String> notFoundProductIds;
  final String? busyProductId;
  final int eventSerial;

  CoinPurchaseSnapshot copyWith({
    CoinPurchaseStatus? status,
    Map<String, StoreProductOffer>? offers,
    Set<String>? notFoundProductIds,
    String? busyProductId,
    bool clearBusyProductId = false,
    bool publishEvent = false,
  }) {
    return CoinPurchaseSnapshot(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      notFoundProductIds: notFoundProductIds ?? this.notFoundProductIds,
      busyProductId:
          clearBusyProductId ? null : (busyProductId ?? this.busyProductId),
      eventSerial: eventSerial + (publishEvent ? 1 : 0),
    );
  }
}

class PurchaseVerificationRequest {
  const PurchaseVerificationRequest({
    required this.productId,
    required this.serverVerificationData,
    required this.verificationSource,
    this.purchaseId,
  });

  final String productId;
  final String serverVerificationData;
  final String verificationSource;
  final String? purchaseId;
}

enum PurchaseVerificationStatus {
  approved,
  alreadyGranted,
  rejected,
  retryLater
}

class PurchaseVerificationResult {
  const PurchaseVerificationResult._({
    required this.status,
    this.grantId,
    this.coinAmount,
  });

  const PurchaseVerificationResult.approved({
    required String grantId,
    required int coinAmount,
  }) : this._(
          status: PurchaseVerificationStatus.approved,
          grantId: grantId,
          coinAmount: coinAmount,
        );

  const PurchaseVerificationResult.alreadyGranted()
      : this._(status: PurchaseVerificationStatus.alreadyGranted);
  const PurchaseVerificationResult.rejected()
      : this._(status: PurchaseVerificationStatus.rejected);
  const PurchaseVerificationResult.retryLater()
      : this._(status: PurchaseVerificationStatus.retryLater);

  final PurchaseVerificationStatus status;
  final String? grantId;
  final int? coinAmount;
}

abstract interface class CoinPurchaseVerifier {
  bool get isConfigured;
  Future<PurchaseVerificationResult> verify(
      PurchaseVerificationRequest request);
}

class UnconfiguredCoinPurchaseVerifier implements CoinPurchaseVerifier {
  const UnconfiguredCoinPurchaseVerifier();

  @override
  bool get isConfigured => false;

  @override
  Future<PurchaseVerificationResult> verify(
    PurchaseVerificationRequest request,
  ) async =>
      const PurchaseVerificationResult.retryLater();
}

abstract interface class VerifiedCoinGrantSink {
  Future<bool> grantOnce({required String grantId, required int coinAmount});
}

class ProgressStorageVerifiedCoinGrantSink implements VerifiedCoinGrantSink {
  const ProgressStorageVerifiedCoinGrantSink();

  @override
  Future<bool> grantOnce(
      {required String grantId, required int coinAmount}) async {
    return ProgressStorage.applyVerifiedCoinGrant(grantId, coinAmount);
  }
}

class CoinPurchaseService extends ChangeNotifier {
  CoinPurchaseService({
    required CoinPurchaseGateway gateway,
    required CoinPurchaseVerifier verifier,
    required VerifiedCoinGrantSink grantSink,
    this.packages = coinPackages,
    bool enabled = true,
  })  : _gateway = gateway,
        _verifier = verifier,
        _grantSink = grantSink,
        _enabled = enabled;

  factory CoinPurchaseService.platform({
    CoinPurchaseVerifier verifier = const UnconfiguredCoinPurchaseVerifier(),
  }) {
    return CoinPurchaseService(
      gateway: createPlatformCoinPurchaseGateway(),
      verifier: verifier,
      grantSink: const ProgressStorageVerifiedCoinGrantSink(),
      enabled: ReleaseFeatures.cashCoinPurchasesEnabled,
    );
  }

  final CoinPurchaseGateway _gateway;
  final CoinPurchaseVerifier _verifier;
  final VerifiedCoinGrantSink _grantSink;
  final bool _enabled;
  final List<CoinPackage> packages;
  final Set<String> _processingTransactions = <String>{};
  StreamSubscription<List<StorePurchaseEvent>>? _subscription;
  Future<void>? _startFuture;
  bool _closed = false;
  CoinPurchaseSnapshot _snapshot = const CoinPurchaseSnapshot();

  CoinPurchaseSnapshot get snapshot => _snapshot;
  bool get verificationConfigured => _enabled && _verifier.isConfigured;

  Future<void> start() => _startFuture ??= _start();

  Future<void> _start() async {
    if (_closed) return;
    if (!_enabled) {
      _publish(_snapshot.copyWith(status: CoinPurchaseStatus.unavailable));
      return;
    }
    _subscription = _gateway.purchaseStream.listen(
      _handlePurchaseEvents,
      onError: (_) => _publish(_snapshot.copyWith(
        status: CoinPurchaseStatus.failed,
        clearBusyProductId: true,
        publishEvent: true,
      )),
    );
    _publish(_snapshot.copyWith(status: CoinPurchaseStatus.loading));
    try {
      if (!await _gateway.isAvailable()) {
        _publish(_snapshot.copyWith(status: CoinPurchaseStatus.unavailable));
        return;
      }
      final query = await _gateway.queryProducts(
        packages.map((package) => package.id).toSet(),
      );
      final offers = <String, StoreProductOffer>{
        for (final offer in query.offers) offer.productId: offer,
      };
      _publish(_snapshot.copyWith(
        status: offers.isEmpty
            ? CoinPurchaseStatus.productNotFound
            : CoinPurchaseStatus.ready,
        offers: Map.unmodifiable(offers),
        notFoundProductIds: Set.unmodifiable(query.notFoundProductIds),
      ));
    } catch (_) {
      _publish(_snapshot.copyWith(status: CoinPurchaseStatus.unavailable));
    }
  }

  bool canPurchase(CoinPackage package) =>
      !_closed &&
      _enabled &&
      _verifier.isConfigured &&
      _snapshot.status != CoinPurchaseStatus.loading &&
      _snapshot.busyProductId == null &&
      _snapshot.offers.containsKey(package.id);

  Future<CoinPurchaseStatus> purchase(CoinPackage package) async {
    await start();
    if (!canPurchase(package)) return CoinPurchaseStatus.unavailable;
    _publish(_snapshot.copyWith(
      status: CoinPurchaseStatus.purchasing,
      busyProductId: package.id,
      publishEvent: true,
    ));
    try {
      final started = await _gateway.buyConsumable(package.id);
      if (started) return CoinPurchaseStatus.purchasing;
    } catch (_) {
      // A generic localized error is published below. Store details are not logged.
    }
    _publish(_snapshot.copyWith(
      status: CoinPurchaseStatus.failed,
      clearBusyProductId: true,
      publishEvent: true,
    ));
    return CoinPurchaseStatus.failed;
  }

  Future<void> _handlePurchaseEvents(List<StorePurchaseEvent> events) async {
    for (final event in events) {
      if (_closed) return;
      switch (event.status) {
        case StorePurchaseStatus.pending:
          _publish(_snapshot.copyWith(
            status: CoinPurchaseStatus.pending,
            busyProductId: event.productId,
            publishEvent: true,
          ));
        case StorePurchaseStatus.cancelled:
          await event.complete();
          _finish(event, CoinPurchaseStatus.cancelled);
        case StorePurchaseStatus.failed:
          await event.complete();
          _finish(event, CoinPurchaseStatus.failed);
        case StorePurchaseStatus.purchased:
        case StorePurchaseStatus.restored:
          await _verifyAndGrant(event);
      }
    }
  }

  Future<void> _verifyAndGrant(StorePurchaseEvent event) async {
    CoinPackage? package;
    for (final candidate in packages) {
      if (candidate.id == event.productId) package = candidate;
    }
    if (package == null || !_verifier.isConfigured) {
      _finish(event, CoinPurchaseStatus.verificationFailed);
      return;
    }
    final transactionKey = event.purchaseId ??
        '${event.productId}:${event.serverVerificationData.hashCode}';
    if (!_processingTransactions.add(transactionKey)) return;
    try {
      final result = await _verifier.verify(PurchaseVerificationRequest(
        productId: event.productId,
        purchaseId: event.purchaseId,
        serverVerificationData: event.serverVerificationData,
        verificationSource: event.verificationSource,
      ));
      if (result.status == PurchaseVerificationStatus.alreadyGranted) {
        await event.complete();
        _finish(event, CoinPurchaseStatus.completed);
        return;
      }
      final valid = result.status == PurchaseVerificationStatus.approved &&
          result.grantId?.isNotEmpty == true &&
          result.coinAmount == package.coinAmount;
      if (!valid) {
        _finish(event, CoinPurchaseStatus.verificationFailed);
        return;
      }
      await _grantSink.grantOnce(
        grantId: result.grantId!,
        coinAmount: result.coinAmount!,
      );
      await event.complete();
      _finish(event, CoinPurchaseStatus.completed);
    } catch (_) {
      _finish(event, CoinPurchaseStatus.verificationFailed);
    } finally {
      _processingTransactions.remove(transactionKey);
    }
  }

  void _finish(StorePurchaseEvent event, CoinPurchaseStatus status) {
    _publish(_snapshot.copyWith(
      status: status,
      clearBusyProductId: true,
      publishEvent: true,
    ));
  }

  void _publish(CoinPurchaseSnapshot next) {
    if (_closed) return;
    _snapshot = next;
    notifyListeners();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}
