import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {after, before, test} from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

let transitionEnvironment: RulesTestEnvironment;
let finalEnvironment: RulesTestEnvironment;

before(async () => {
  transitionEnvironment = await initializeTestEnvironment({
    projectId: 'demo-poppop-transition',
    firestore: {
      host: '127.0.0.1',
      port: 8088,
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
  finalEnvironment = await initializeTestEnvironment({
    projectId: 'demo-poppop-final',
    firestore: {
      host: '127.0.0.1',
      port: 8088,
      rules: readFileSync('../firestore.final.rules', 'utf8'),
    },
  });
});

after(async () => {
  await transitionEnvironment.cleanup();
  await finalEnvironment.cleanup();
});

async function seed(environment: RulesTestEnvironment): Promise<void> {
  await environment.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    await database.doc('leaderboards_stage_v2/public-stage').set({
      displayName: 'Player', score: 10, reachedStage: 3, cleared: false,
      submittedAt: new Date(), schemaVersion: 2,
    });
    await database.doc('leaderboards_stage_v1/user-a').set({
      uid: 'user-a', displayName: 'Player', score: 9, reachedStage: 2,
      cleared: false, submittedAt: new Date(), schemaVersion: 1,
    });
  });
}

test('transition rules allow signed-in v2 reads and deny client writes', async () => {
  await transitionEnvironment.clearFirestore();
  await seed(transitionEnvironment);
  const signedIn = transitionEnvironment
    .authenticatedContext('user-a').firestore();
  const anonymous = transitionEnvironment.unauthenticatedContext().firestore();
  await assertSucceeds(signedIn.doc('leaderboards_stage_v2/public-stage').get());
  await assertSucceeds(signedIn.collection('leaderboards_stage_v2').limit(100).get());
  await assertFails(signedIn.collection('leaderboards_stage_v2').limit(101).get());
  await assertFails(anonymous.doc('leaderboards_stage_v2/public-stage').get());
  await assertFails(signedIn.doc('leaderboards_stage_v2/injected').set({score: 99}));
  await assertFails(signedIn.doc('leaderboards_stage_v2/public-stage').delete());
  await assertSucceeds(signedIn.doc('leaderboards_stage_v1/user-a').get());
});

test('final rules block v1 clients while retaining read-only v2', async () => {
  await finalEnvironment.clearFirestore();
  await seed(finalEnvironment);
  const signedIn = finalEnvironment.authenticatedContext('user-a').firestore();
  await assertSucceeds(signedIn.doc('leaderboards_stage_v2/public-stage').get());
  await assertFails(signedIn.doc('leaderboards_stage_v1/user-a').get());
  await assertFails(signedIn.doc('ranking_private/user-a').get());
  await assertFails(signedIn.doc('leaderboards_60s_v2/injected').set({score: 1}));
  assert.ok(true);
});
