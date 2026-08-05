import '../storage/progress_storage.dart';
import 'coin_service.dart';

enum PurchaseResult { success, insufficientCoins, alreadyOwned, unavailable }

enum EquipResult { success, alreadyEquipped, notOwned }

/// Coordinates persistent product ownership and coin payment.
abstract final class PurchaseService {
  static Set<String> get ownedProductIds => ProgressStorage.ownedProductIds();

  static bool isOwned(String productId, {required bool initiallyOwned}) =>
      initiallyOwned || ownedProductIds.contains(productId);

  static PurchaseResult purchase({
    required String productId,
    required int price,
    required bool initiallyOwned,
    bool locked = false,
  }) {
    if (locked) return PurchaseResult.unavailable;
    if (isOwned(productId, initiallyOwned: initiallyOwned)) {
      return PurchaseResult.alreadyOwned;
    }
    if (CoinService.balance < price) return PurchaseResult.insufficientCoins;
    return ProgressStorage.tryPurchaseProduct(productId, price)
        ? PurchaseResult.success
        : PurchaseResult.unavailable;
  }

  static String equippedProductId(
    String category, {
    required String defaultProductId,
  }) =>
      ProgressStorage.equippedProductId(category) ?? defaultProductId;

  static EquipResult equip({
    required String category,
    required String productId,
    required bool initiallyOwned,
  }) {
    if (!isOwned(productId, initiallyOwned: initiallyOwned)) {
      return EquipResult.notOwned;
    }
    if (ProgressStorage.equippedProductId(category) == productId) {
      return EquipResult.alreadyEquipped;
    }
    ProgressStorage.setEquippedProductId(category, productId);
    return EquipResult.success;
  }
}
