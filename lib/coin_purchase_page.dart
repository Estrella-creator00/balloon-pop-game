import 'package:flutter/material.dart';
import 'l10n/l10n.dart';

import 'audio/pop_sound.dart';
import 'coin/coin_package.dart';
import 'config/release_features.dart';
import 'services/coin_purchase_gateway.dart';
import 'services/coin_purchase_service.dart';
import 'services/coin_service.dart';

// C-01 코인 충전 화면
class CoinPurchasePage extends StatefulWidget {
  const CoinPurchasePage({
    super.key,
    this.purchaseService,
    this.packages = coinPackages,
  });

  final CoinPurchaseService? purchaseService;
  final List<CoinPackage> packages;

  @override
  State<CoinPurchasePage> createState() => _CoinPurchasePageState();
}

class _CoinPurchasePageState extends State<CoinPurchasePage> {
  CoinPurchaseService? _purchaseService;
  bool _ownsService = false;
  int _lastEventSerial = 0;

  @override
  void initState() {
    super.initState();
    if (!ReleaseFeatures.cashCoinPurchasesEnabled) return;
    _ownsService = widget.purchaseService == null;
    _purchaseService = widget.purchaseService ?? CoinPurchaseService.platform();
    _lastEventSerial = _purchaseService!.snapshot.eventSerial;
    _purchaseService!.addListener(_onPurchaseChanged);
    _purchaseService!.start();
  }

  @override
  void dispose() {
    _purchaseService?.removeListener(_onPurchaseChanged);
    if (_ownsService) _purchaseService?.dispose();
    super.dispose();
  }

  void _onPurchaseChanged() {
    if (!mounted) return;
    final snapshot = _purchaseService!.snapshot;
    setState(() {});
    if (snapshot.eventSerial == _lastEventSerial) return;
    _lastEventSerial = snapshot.eventSerial;
    final message = _eventMessage(context, snapshot.status);
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (!ReleaseFeatures.cashCoinPurchasesEnabled) {
      return const SizedBox.shrink(key: ValueKey('coin-purchase-disabled'));
    }
    final purchaseService = _purchaseService!;
    return Scaffold(
      key: const ValueKey('coin-purchase-page'),
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const ValueKey('coin-purchase-back'),
                      onPressed: () {
                        PopSound.playUiClick();
                        Navigator.of(context).pop();
                      },
                      tooltip: context.l10n.back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF285A78),
                    ),
                  ),
                  Text(
                    context.l10n.coinPurchase,
                    style: TextStyle(
                      color: Color(0xFF244B62),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _CoinBalanceCard(balance: CoinService.balance),
            const SizedBox(height: 10),
            _PurchaseAvailability(
              snapshot: purchaseService.snapshot,
              verificationConfigured: purchaseService.verificationConfigured,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                key: const ValueKey('coin-package-list'),
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
                itemCount: widget.packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CoinPackageCard(
                  package: widget.packages[index],
                  offer: purchaseService
                      .snapshot.offers[widget.packages[index].id],
                  loading: purchaseService.snapshot.status ==
                      CoinPurchaseStatus.loading,
                  busy: purchaseService.snapshot.busyProductId ==
                      widget.packages[index].id,
                  enabled: purchaseService.canPurchase(widget.packages[index]),
                  onTap: () {
                    PopSound.playUiClick();
                    purchaseService.purchase(widget.packages[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _eventMessage(BuildContext context, CoinPurchaseStatus status) {
    return switch (status) {
      CoinPurchaseStatus.purchasing => context.l10n.purchaseInProgress,
      CoinPurchaseStatus.pending => context.l10n.purchasePending,
      CoinPurchaseStatus.cancelled => context.l10n.purchaseCancelled,
      CoinPurchaseStatus.failed => context.l10n.purchaseFailed,
      CoinPurchaseStatus.verificationFailed =>
        context.l10n.purchaseVerificationFailed,
      CoinPurchaseStatus.completed => context.l10n.purchaseCompleted,
      _ => null,
    };
  }
}

class _PurchaseAvailability extends StatelessWidget {
  const _PurchaseAvailability({
    required this.snapshot,
    required this.verificationConfigured,
  });

  final CoinPurchaseSnapshot snapshot;
  final bool verificationConfigured;

  @override
  Widget build(BuildContext context) {
    final text = switch (snapshot.status) {
      CoinPurchaseStatus.loading => context.l10n.purchaseLoading,
      CoinPurchaseStatus.unavailable => context.l10n.purchaseStoreUnavailable,
      CoinPurchaseStatus.productNotFound =>
        context.l10n.purchaseProductsNotRegistered,
      _ when !verificationConfigured =>
        context.l10n.purchaseVerificationUnavailable,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        key: const ValueKey('coin-purchase-status'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5D7483),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CoinBalanceCard extends StatelessWidget {
  const _CoinBalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('coin-purchase-balance'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3375B5D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F315D76),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFC928),
            size: 26,
          ),
          Text(
            _formatNumber(balance),
            style: const TextStyle(
              color: Color(0xFF244B62),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            context.l10n.ownedCoins,
            style: TextStyle(
              color: Color(0xFF6E8492),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackageCard extends StatelessWidget {
  const _CoinPackageCard({
    required this.package,
    required this.offer,
    required this.enabled,
    required this.loading,
    required this.busy,
    required this.onTap,
  });

  final CoinPackage package;
  final StoreProductOffer? offer;
  final bool enabled;
  final bool loading;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x26315D76),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('coin-package-${package.id}'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x3375B5D6)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5C8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: Color(0xFFFFB800),
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  context.l10n.coins(_formatNumber(package.coinAmount)),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF244B62),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 82, minHeight: 42),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: enabled || busy
                      ? const Color(0xFFFF6B9D)
                      : const Color(0xFFAAB8C0),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44B71E5C),
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        loading
                            ? context.l10n.purchaseLoadingShort
                            : offer?.localizedPrice ??
                                context.l10n.purchasePriceUnavailable,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write(',');
    result.write(digits[index]);
  }
  return result.toString();
}
