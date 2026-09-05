# Firebase ranking v2 rollout

This runbook is intentionally non-executable documentation. Substitute the
target project explicitly at each step. Never commit the HMAC secret or service
account credentials.

## Cost and safety prerequisites

Cloud Functions 2nd gen and Secret Manager can require the Blaze plan and may
incur invocation, compute, Firestore, logging, and secret-access charges. Stop
before deployment unless an owner has approved billing and a budget alert.

1. **Enable Blaze.** Confirm the exact Firebase project in the console, review
   billing terms, and enable Blaze. **Stop:** project or owner is ambiguous.
   **Rollback:** unlink billing before any deployment if no paid resource has
   been used.
2. **Set budget alerts.** Add a low initial Google Cloud budget and notification
   recipients. **Stop:** alerts cannot be verified. **Rollback:** none needed;
   keep alerts enabled.
3. **Create the Functions secret.** Set `LEADERBOARD_HMAC_SECRET` to a new,
   random value of at least 32 characters through Firebase Secret Manager.
   **Stop:** the value is printed, copied into a file, or shared insecurely.
   **Rollback:** destroy the exposed version and create a new value before any
   migration.
4. **Deploy Functions.** Build and test locally, then deploy only
   `submitLeaderboard`, `getMyLeaderboardEntry`, and `deleteOnlineData` to the
   explicitly selected project. **Stop:** region, project, runtime, secret
   binding, or callable authentication differs from this repository.
   **Rollback:** restore the previous Functions revision or delete only these
   new callable functions before clients use v2.
5. **Deploy transition rules.** Deploy `firestore.rules`, which preserves v1
   client access temporarily and exposes signed-in, read-only v2 entries.
   **Stop:** emulator tests fail or the diff changes unrelated collections.
   **Rollback:** redeploy the previously exported production rules.
6. **Run migration dry-run.** With Application Default Credentials and the same
   secret version used by Functions, run the migration without `--execute` and
   with an explicit project argument. **Stop:** project, source counts, invalid
   record count, or credentials are unexpected. **Rollback:** no writes occur.
7. **Run migration execute once.** Add `--execute` only after approving the dry
   run. It creates sanitized v2 documents and does not delete v1. **Stop:** any
   error count is non-zero. **Rollback:** keep v1 authoritative; remove only v2
   documents created by this controlled migration if necessary.
8. **Compare v1 and v2.** Compare collection counts and sampled best scores,
   reached stages, clear flags, timestamps, and names without exporting UIDs.
   Confirm no v2 field or path reveals UID/Support ID. **Stop:** any mismatch or
   identifier exposure. **Rollback:** do not release the v2 app; v1 remains.
9. **Release the Flutter v2 app.** Publish a build that reads v2 and submits via
   callable Functions. **Stop:** staged rollout cannot load both leaderboards,
   pending retry fails, or callable errors rise. **Rollback:** halt rollout and
   restore the previous app while transition rules still support v1.
10. **Verify both categories.** With dedicated test users, submit and read one
    STAGE and one 60-second result, including Stage tie/clear improvement and a
    lower-score no-op. **Stop:** duplicate documents, score regression, or raw
    identifiers appear. **Rollback:** halt the app rollout and Functions.
11. **Run migration execute again.** Repeat the identical migration to capture
    late v1 writes and prove idempotency. **Stop:** duplicates or regressions
    occur. **Rollback:** v1 is still retained and can remain authoritative.
12. **Deploy final rules.** After the supported v1 client window ends, deploy
    `firestore.final.rules` (for example with `firebase.final.json`) to deny all
    v1 client access and keep v2 server-write-only. **Stop:** active supported
    clients still require v1 or emulator tests fail. **Rollback:** redeploy the
    transition rules while investigating.
13. **Verify in-app deletion.** A dedicated test user should delete online data;
    verify v1/v2/private Firestore records disappear before Auth deletion,
    local game data remains, and no account is recreated until ranking is used.
    **Stop:** partial deletion or pending resubmission occurs. **Rollback:** stop
    exposing the deletion action and keep email-assisted deletion available;
    deleted data itself cannot be restored.
14. **Set v1 retention and deletion date.** Document a retention period, legal
    review, backup implications, final count, and approval before deleting v1.
    **Stop:** rollback/support window or deletion authority is unclear.
    **Rollback:** postpone deletion; never use an unbounded delete command.

The admin deletion script accepts exactly one Support ID, defaults to dry-run,
and requires both an explicit project and `--execute` for writes. Neither admin
script should be run from an untrusted workstation or against production as
part of normal application deployment.
