import 'package:flutter/material.dart';
import 'l10n/l10n.dart';

import 'audio/pop_sound.dart';
import 'coin/coin_package.dart';
import 'services/coin_purchase_service.dart';
import 'services/coin_service.dart';

// C-01 코인 충전 화면
class CoinPurchasePage extends StatelessWidget {
  const CoinPurchasePage({
    super.key,
    this.purchaseService = const DisabledCoinPurchaseService(),
    this.packages = coinPackages,
  });

  final CoinPurchaseService purchaseService;
  final List<CoinPackage> packages;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                key: const ValueKey('coin-package-list'),
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
                itemCount: packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CoinPackageCard(
                  package: packages[index],
                  onTap: () {
                    PopSound.playUiClick();
                    _requestPurchase(context, packages[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPurchase(
    BuildContext context,
    CoinPackage package,
  ) async {
    if (!package.enabled) return;
    final result = await purchaseService.purchase(package);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.status == CoinPurchaseStatus.unavailable
                ? context.l10n.purchaseComingSoon
                : result.message,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFC928),
            size: 26,
          ),
          const SizedBox(width: 8),
          Text(
            _formatNumber(balance),
            style: const TextStyle(
              color: Color(0xFF244B62),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
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
  const _CoinPackageCard({required this.package, required this.onTap});

  final CoinPackage package;
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
        onTap: package.enabled ? onTap : null,
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
                  color: const Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44B71E5C),
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  package.displayPrice,
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
