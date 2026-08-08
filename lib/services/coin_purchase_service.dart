import '../coin/coin_package.dart';

enum CoinPurchaseStatus { unavailable }

class CoinPurchaseResult {
  const CoinPurchaseResult({
    required this.status,
    required this.message,
  });

  final CoinPurchaseStatus status;
  final String message;
}

abstract interface class CoinPurchaseService {
  Future<CoinPurchaseResult> purchase(CoinPackage package);
}

/// 결제 미연동 단계의 구현체다. CoinService/ProgressStorage를 참조하지
/// 않으므로 호출해도 로컬 코인을 지급하거나 변경할 수 없다.
class DisabledCoinPurchaseService implements CoinPurchaseService {
  const DisabledCoinPurchaseService();

  @override
  Future<CoinPurchaseResult> purchase(CoinPackage package) async {
    return const CoinPurchaseResult(
      status: CoinPurchaseStatus.unavailable,
      message: '결제 기능 준비 중입니다.',
    );
  }
}
