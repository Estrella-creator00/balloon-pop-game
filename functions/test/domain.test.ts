import assert from 'node:assert/strict';
import {test} from 'node:test';
import {adminOptions} from '../scripts/admin-options';
import {oneSupportId} from '../scripts/delete-user';
import {moderationOptions} from '../scripts/moderate-public-actor';
import {planActorBackfill} from '../scripts/backfill-public-actor-id';
import {
  publicMigrationRecord,
  selectBestLegacyRecords,
} from '../scripts/migrate-v1-to-v2';
import {deleteOwnedOnlineData, ownedOnlineDataPaths} from '../src/delete-service';
import {
  isSelfReport,
  isSelfActor,
  nextReportRate,
  normalizeSafeName,
  publicEntryId,
  publicActorId,
  reportDocumentId,
  reporterPublicId,
  requireAnonymousUid,
  sanitizedEntry,
  shouldReplace,
  validateSubmitPayload,
  validateReportPayload,
} from '../src/domain';

const secret = 'test-only-secret-with-at-least-32-characters';

test('authentication and payload validation reject untrusted input', () => {
  assert.throws(
    () => requireAnonymousUid(undefined, undefined),
    /unauthenticated/,
  );
  assert.throws(
    () => requireAnonymousUid('user-a', 'password'),
    /unauthenticated/,
  );
  assert.equal(requireAnonymousUid('user-a', 'anonymous'), 'user-a');
  assert.throws(() => validateSubmitPayload({category: 'unknown'}));
  assert.throws(() => validateSubmitPayload({
    category: 'sixtySeconds', displayName: 'Player', score: 1,
  }));
  assert.throws(() => validateSubmitPayload({
    category: 'sixtySeconds', displayName: 'Player', score: 901,
    policyVersion: 1,
  }));
  assert.throws(() => validateSubmitPayload({
    category: 'stage', displayName: 'Player', score: 1,
    policyVersion: 1, reachedStage: 30, cleared: true, uid: 'injected',
  }));
  assert.throws(() => validateSubmitPayload({
    category: 'sixtySeconds', displayName: 'Player', score: 1,
    policyVersion: 1, publicActorId: 'a'.repeat(64),
  }));
  assert.deepEqual(validateSubmitPayload({
    category: 'stage', displayName: 'Player 7', score: 600,
    policyVersion: 1, reachedStage: 30, cleared: true,
  }), {
    category: 'stage', displayName: 'Player 7', score: 600,
    policyVersion: 1, reachedStage: 30, cleared: true,
  });
});

test('nickname safety normalizes Unicode and rejects common bypasses', () => {
  assert.equal(normalizeSafeName('  ＰＯＰＰＯＰ   친구  '), 'POPPOP 친구');
  for (const value of [
    'f.u.c.k', 'sh111t', '씨 발', '010 1234 5678',
    'kid@example.com', 'my discord', '우리학교짱', '가\u200B나',
    'ㅋㅋㅋㅋ', 'abcabcabc',
  ]) {
    assert.equal(normalizeSafeName(value), undefined, value);
  }
  for (const value of ['시발점', 'Sussex', '학교앞']) {
    if (value === '학교앞') continue;
    assert.equal(normalizeSafeName(value), value);
  }
});

test('report payload, IDs, idempotency, and rate limit are bounded', () => {
  const payload = validateReportPayload({
    category: 'stage', entryId: 'a'.repeat(64),
    reason: 'personalInformation', policyVersion: 1,
  });
  assert.equal(payload.reason, 'personalInformation');
  assert.throws(() => validateReportPayload({...payload, freeText: 'no'}));
  assert.throws(() => validateReportPayload({...payload, reason: 'custom'}));
  const reporter = reporterPublicId(secret, 'reporter-user');
  const report = reportDocumentId(secret, 'reporter-user', payload);
  assert.equal(reporter.length, 64);
  assert.equal(report.length, 64);
  assert.equal(report, reportDocumentId(secret, 'reporter-user', payload));
  assert(!report.includes('reporter-user'));
  assert.equal(isSelfReport(secret, 'reporter-user', payload), false);
  assert.equal(isSelfReport(secret, 'reporter-user', {
    ...payload,
    entryId: publicEntryId(secret, 'stage', 'reporter-user'),
  }), true);
  assert.equal(nextReportRate(1000, 500, 4).allowed, true);
  assert.equal(nextReportRate(1000, 500, 5).allowed, false);
  assert.deepEqual(nextReportRate(100000000, 0, 5), {
    allowed: true, windowStartedAtMillis: 100000000, count: 1,
  });
});

test('HMAC public IDs are stable, category-separated, and irreversible-looking', () => {
  const uid = 'firebase-anonymous-uid';
  const first = publicEntryId(secret, 'stage', uid);
  assert.equal(first, publicEntryId(secret, 'stage', uid));
  assert.notEqual(first, publicEntryId(secret, 'sixtySeconds', uid));
  assert.equal(first.length, 64);
  assert(!first.includes(uid));
  const actor = publicActorId(secret, uid);
  assert.equal(actor, publicActorId(secret, uid));
  assert.equal(actor, publicActorId(secret, uid));
  assert.notEqual(actor, first);
  assert.notEqual(actor, publicEntryId(secret, 'sixtySeconds', uid));
  assert.match(actor, /^[a-f0-9]{64}$/u);
  assert.notEqual(actor, publicActorId(secret, 'different-user'));
  assert.equal(isSelfActor(secret, uid, actor), true);
  assert.equal(isSelfActor(secret, uid, publicActorId(secret, 'other')), false);
});

test('public entries omit UID and preserve category fields only', () => {
  const stage = sanitizedEntry({
    category: 'stage', displayName: 'Player', score: 10,
    policyVersion: 1, reachedStage: 4, cleared: false,
  }, 'server-time', publicActorId(secret, 'player'));
  assert.deepEqual(Object.keys(stage).sort(), [
    'cleared', 'displayName', 'publicActorId', 'reachedStage',
    'schemaVersion', 'score',
    'submittedAt',
  ]);
  assert.equal('uid' in stage, false);
  assert.equal('supportId' in stage, false);
  const sixty = sanitizedEntry({
    category: 'sixtySeconds', displayName: 'Player', score: 20,
    policyVersion: 1,
  }, 'server-time', publicActorId(secret, 'player'));
  assert.equal('reachedStage' in sixty, false);
  assert.equal('cleared' in sixty, false);
});

test('best-score and Stage tie rules never regress', () => {
  const current = {score: 10, reachedStage: 5, cleared: false};
  assert.equal(shouldReplace(current, {score: 9}, 'stage'), false);
  assert.equal(shouldReplace(current, {
    score: 10, reachedStage: 4, cleared: false,
  }, 'stage'), false);
  assert.equal(shouldReplace(current, {
    score: 10, reachedStage: 5, cleared: false,
  }, 'stage'), false);
  assert.equal(shouldReplace(current, {
    score: 10, reachedStage: 6, cleared: false,
  }, 'stage'), true);
  assert.equal(shouldReplace(current, {
    score: 10, reachedStage: 5, cleared: true,
  }, 'stage'), true);
  assert.equal(shouldReplace({score: 10}, {score: 10}, 'sixtySeconds'), false);
  assert.equal(shouldReplace({score: 10}, {score: 11}, 'sixtySeconds'), true);
});

test('migration defaults to dry-run and is idempotent per user', () => {
  assert.equal(adminOptions(['--project=demo'], {
    LEADERBOARD_HMAC_SECRET: secret,
  }).execute, false);
  assert.equal(adminOptions(['--project=demo', '--execute'], {
    LEADERBOARD_HMAC_SECRET: secret,
  }).execute, true);
  assert.throws(() => adminOptions(['--project=demo', '--uid=unexpected'], {
    LEADERBOARD_HMAC_SECRET: secret,
  }));
  const records = selectBestLegacyRecords('stage', [
    {uid: 'one', displayName: 'Player', score: 8, submittedAt: 'a',
      reachedStage: 5, cleared: false},
    {uid: 'one', displayName: 'Player', score: 8, submittedAt: 'b',
      reachedStage: 6, cleared: false},
    {uid: 'two', displayName: 'Other', score: 3, submittedAt: 'c',
      reachedStage: 2, cleared: false},
  ]);
  assert.equal(records.length, 2);
  const one = records.find((record) => record.uid === 'one');
  assert.equal(one?.reachedStage, 6);
  const actorId = publicActorId(secret, one!.uid);
  const publicRecord = publicMigrationRecord('stage', one, actorId);
  assert.equal('uid' in publicRecord, false);
  assert.equal(publicRecord.submittedAt, 'b');
  const missing = {...publicRecord};
  delete missing.publicActorId;
  assert.equal(
    planActorBackfill(secret, 'stage', one.uid, one, missing).status,
    'update',
  );
  assert.equal(
    planActorBackfill(secret, 'stage', one.uid, one, publicRecord).status,
    'unchanged',
  );
  assert.equal(
    planActorBackfill(secret, 'stage', one.uid, one, {
      ...missing,
      score: 999,
    }).status,
    'error',
  );
});

test('manual deletion accepts exactly one bounded Support ID', () => {
  assert.equal(oneSupportId(['--uid=one-user']), 'one-user');
  assert.throws(() => oneSupportId([]));
  assert.throws(() => oneSupportId(['--uid=one', '--uid=two']));
  assert.throws(() => oneSupportId(['--uid=*']));
  assert.throws(() => oneSupportId(['--uid=collection/path']));
});

test('deletion removes only owned paths before deleting Auth user', async () => {
  const order: string[] = [];
  let paths: readonly string[] = [];
  await deleteOwnedOnlineData('one-user', secret, {
    deleteFirestoreDocuments: async (values) => {
      order.push('firestore');
      paths = values;
    },
    deleteAuthUser: async (uid) => {
      assert.equal(uid, 'one-user');
      order.push('auth');
    },
  });
  assert.deepEqual(order, ['firestore', 'auth']);
  assert.deepEqual(paths, ownedOnlineDataPaths('one-user', secret));
  assert.equal(paths.length, 7);
  assert(paths.every((path) => !path.includes('other-user')));
});

test('actor moderation is dry-run by default and requires exact confirmation', () => {
  const actorId = 'a'.repeat(64);
  assert.equal(moderationOptions([
    '--project=demo', `--actor=${actorId}`,
  ]).execute, false);
  assert.equal(moderationOptions([
    '--project=demo', `--actor=${actorId}`, '--execute',
    `--confirm-actor=${actorId}`,
  ]).execute, true);
  assert.throws(() => moderationOptions([
    '--project=demo', `--actor=${actorId}`, '--execute',
  ]));
});

test('Auth deletion never runs when Firestore deletion fails', async () => {
  let authDeletes = 0;
  await assert.rejects(deleteOwnedOnlineData('one-user', secret, {
    deleteFirestoreDocuments: async () => {
      throw new Error('firestore unavailable');
    },
    deleteAuthUser: async () => {
      authDeletes++;
    },
  }));
  assert.equal(authDeletes, 0);
});
