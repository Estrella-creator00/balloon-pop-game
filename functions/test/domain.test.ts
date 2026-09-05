import assert from 'node:assert/strict';
import {test} from 'node:test';
import {adminOptions} from '../scripts/admin-options';
import {oneSupportId} from '../scripts/delete-user';
import {
  publicMigrationRecord,
  selectBestLegacyRecords,
} from '../scripts/migrate-v1-to-v2';
import {deleteOwnedOnlineData, ownedOnlineDataPaths} from '../src/delete-service';
import {
  publicEntryId,
  requireAnonymousUid,
  sanitizedEntry,
  shouldReplace,
  validateSubmitPayload,
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
    category: 'sixtySeconds', displayName: ' Player', score: 1,
  }));
  assert.throws(() => validateSubmitPayload({
    category: 'sixtySeconds', displayName: 'Player', score: 901,
  }));
  assert.throws(() => validateSubmitPayload({
    category: 'stage', displayName: 'Player', score: 1,
    reachedStage: 30, cleared: true, uid: 'injected',
  }));
  assert.deepEqual(validateSubmitPayload({
    category: 'stage', displayName: 'Player 7', score: 600,
    reachedStage: 30, cleared: true,
  }), {
    category: 'stage', displayName: 'Player 7', score: 600,
    reachedStage: 30, cleared: true,
  });
});

test('HMAC public IDs are stable, category-separated, and irreversible-looking', () => {
  const uid = 'firebase-anonymous-uid';
  const first = publicEntryId(secret, 'stage', uid);
  assert.equal(first, publicEntryId(secret, 'stage', uid));
  assert.notEqual(first, publicEntryId(secret, 'sixtySeconds', uid));
  assert.equal(first.length, 64);
  assert(!first.includes(uid));
});

test('public entries omit UID and preserve category fields only', () => {
  const stage = sanitizedEntry({
    category: 'stage', displayName: 'Player', score: 10,
    reachedStage: 4, cleared: false,
  }, 'server-time');
  assert.deepEqual(Object.keys(stage).sort(), [
    'cleared', 'displayName', 'reachedStage', 'schemaVersion', 'score',
    'submittedAt',
  ]);
  assert.equal('uid' in stage, false);
  assert.equal('supportId' in stage, false);
  const sixty = sanitizedEntry({
    category: 'sixtySeconds', displayName: 'Player', score: 20,
  }, 'server-time');
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
  const publicRecord = publicMigrationRecord('stage', one!);
  assert.equal('uid' in publicRecord, false);
  assert.equal(publicRecord.submittedAt, 'b');
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
  assert.equal(paths.length, 5);
  assert(paths.every((path) => !path.includes('other-user')));
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
