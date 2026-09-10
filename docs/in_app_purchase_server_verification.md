# Consumable coin purchase verification

POPPOP uses the official Flutter `in_app_purchase` plugin for the Android and
iOS store clients. The app never treats a `purchased` stream event as proof of
payment. The free launch build fixes
`ReleaseFeatures.cashCoinPurchasesEnabled` to `false`, so it does not show a
coin-pack route, construct the platform purchase gateway, subscribe to the
purchase stream, query products, or call purchase/restore/receipt APIs. This
flag is compile-time code and has no remote or user-controlled override.

The implementation below is intentionally retained for a future release. Coin
packs must remain disabled until both the release flag is deliberately changed
in source and a production `CoinPurchaseVerifier` is configured.

## Server contract required before enabling purchases

The verifier must receive the authenticated POPPOP user/session plus these
ephemeral values over TLS; none may be logged or stored in application local
storage:

- platform (`verificationSource`)
- product ID
- store purchase/transaction ID when supplied
- `serverVerificationData` (Google purchase token or Apple signed transaction)

The server must verify the token with Google Play Developer API or Apple App
Store Server API, check bundle/package ID, product ID, purchase state, quantity,
environment, and ownership, and reject replayed/refunded/revoked transactions.
It must map only `coin_300`, `coin_700`, `coin_1500`, and `coin_3500` to the
authoritative coin amounts in this repository.

Verification and claiming a transaction must be atomic and idempotent. The
response is either a first-time `approved` result containing the exact coin
amount and an opaque, stable grant ID, `alreadyGranted`, a permanent rejection,
or a retryable failure. The client persists only the opaque grant ID as a
second duplicate guard and never persists the receipt or purchase token.

Only after an `approved` response does the existing `ProgressStorage` coin
balance receive the coins. The store transaction is finalized after that local
grant. A retryable verification failure is deliberately left unfinished so it
can be verified again; no test or automatic approval path exists in release
code.

## Store setup still required

- Create the four products as consumables in Google Play Console and App Store
  Connect using the exact IDs above.
- Configure service credentials only on the verification server, never in the
  app or repository.
- Implement the production verifier endpoint and authentication, refund and
  revocation handling, monitoring without raw tokens, and reconciliation for a
  crash between server approval and local persistence.
- Test with Play license testers and StoreKit/App Store sandbox accounts before
  enabling `CoinPurchaseVerifier.isConfigured`.

Prices displayed by the app come only from each store's localized
`ProductDetails.price`. POPPOP has no restore button because every listed item
is consumable.
