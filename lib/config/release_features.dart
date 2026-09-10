/// Compile-time release switches that cannot be changed remotely or by users.
abstract final class ReleaseFeatures {
  /// POPPOP launches as a free app without real-money coin purchases.
  ///
  /// Keep the purchase implementation behind this switch for a later release
  /// after store products and server-side receipt verification are configured.
  static const bool cashCoinPurchasesEnabled = false;
}
