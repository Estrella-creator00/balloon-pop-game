# Google Play Data safety draft

This draft must be rechecked against the production build and the current Play
Console questionnaire before submission.

- **User IDs:** Collected only when the optional online ranking is used. Firebase
  Authentication processes an anonymous UID privately. Public ranking entries
  contain only a non-reversible HMAC `publicActorId`, shared between that
  account's Stage and 60-second entries for user blocking and safety review.
- **User-generated content:** A nickname and game record are sent when the user
  chooses online ranking. Private reports contain a fixed reason, target public
  entry/actor IDs, nickname snapshot, timestamps, review state, and a one-way
  reporter identifier.
- **Purpose:** App functionality, fraud/abuse prevention, account management,
  and user safety only. The actor identifier is not used for identity discovery,
  advertising, cross-app tracking, analytics, or profiling.
- **Optionality:** Online ranking can be disabled with a parent PIN; local play
  remains available. The user's hidden-actor list remains only on the device and
  is not uploaded.
- **Deletion:** Delete Online Data removes the anonymous Auth account, owned
  ranking entries, reporter-side records, and the actor moderation record.
  Reports submitted by others about a former public entry may remain for safety
  review until their 180-day expiry.
- **Not used:** Advertising, Analytics, and Crashlytics SDKs are not present.

This treatment is consistent with the privacy policy: anonymous UID and HMAC
actor ID are reported as user identifiers, even though neither reveals a real
identity and raw UID/Support ID is never placed in public documents.
