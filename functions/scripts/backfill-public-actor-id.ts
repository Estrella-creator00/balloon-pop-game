import {createHash} from 'node:crypto';
import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {adminOptions} from './admin-options';
import {legacyRecord, publicMigrationRecord} from './migrate-v1-to-v2';
import {
  categories,
  isPublicActorId,
  legacyCollections,
  publicActorId,
  publicCollections,
  publicEntryId,
  RankingCategory,
} from '../src/domain';

export type ActorBackfillPlan =
  | {status: 'update'; actorId: string; protectedDigest: string}
  | {status: 'unchanged'; actorId: string; protectedDigest: string}
  | {status: 'error'; reason: string};

export function planActorBackfill(
  secret: string,
  category: RankingCategory,
  uid: string,
  legacyValue: unknown,
  publicValue: unknown,
): ActorBackfillPlan {
  const legacy = legacyRecord(category, legacyValue);
  if (!legacy) return {status: 'error', reason: 'invalid-v1'};
  if (!isObject(publicValue)) return {status: 'error', reason: 'missing-v2'};
  const actorId = publicActorId(secret, uid);
  const expected = publicMigrationRecord(category, legacy, actorId);
  const allowed = new Set(Object.keys(expected));
  if (Object.keys(publicValue).some((key) => !allowed.has(key))) {
    return {status: 'error', reason: 'unexpected-v2-field'};
  }
  const protectedCurrent = {...publicValue};
  delete protectedCurrent.publicActorId;
  const protectedExpected = {...expected};
  delete protectedExpected.publicActorId;
  const currentDigest = stableDigest(protectedCurrent);
  if (currentDigest !== stableDigest(protectedExpected)) {
    return {status: 'error', reason: 'v1-v2-mismatch'};
  }
  if (publicValue.publicActorId === undefined) {
    return {status: 'update', actorId, protectedDigest: currentDigest};
  }
  if (publicValue.publicActorId !== actorId ||
      !isPublicActorId(publicValue.publicActorId)) {
    return {status: 'error', reason: 'actor-id-conflict'};
  }
  return {status: 'unchanged', actorId, protectedDigest: currentDigest};
}

export function stableDigest(value: unknown): string {
  return createHash('sha256').update(stableJson(value)).digest('hex');
}

function stableJson(value: unknown): string {
  if (value !== null && typeof value === 'object' &&
      typeof (value as {toMillis?: unknown}).toMillis === 'function') {
    return JSON.stringify((value as {toMillis: () => number}).toMillis());
  }
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (isObject(value)) {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${stableJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

async function main(): Promise<void> {
  const options = adminOptions(process.argv.slice(2), process.env);
  initializeApp({projectId: options.projectId, credential: applicationDefault()});
  const database = getFirestore();
  console.log(`Project: ${options.projectId}`);
  console.log(`Mode: ${options.execute ? 'EXECUTE' : 'DRY RUN'}`);

  for (const category of categories) {
    const source = await database.collection(legacyCollections[category]).get();
    const sourceDigestBefore = stableDigest(source.docs.map((document) => ({
      id: document.id,
      data: document.data(),
    })));
    let updates = 0;
    let unchanged = 0;
    let errors = 0;
    for (const document of source.docs) {
      const uid = typeof document.get('uid') === 'string'
        ? document.get('uid') as string
        : document.id;
      const target = database.collection(publicCollections[category])
        .doc(publicEntryId(options.secret, category, uid));
      const snapshot = await target.get();
      const plan = planActorBackfill(
        options.secret,
        category,
        uid,
        {...document.data(), uid},
        snapshot.exists ? snapshot.data() : undefined,
      );
      if (plan.status === 'error') {
        errors++;
        continue;
      }
      if (plan.status === 'unchanged') {
        unchanged++;
        continue;
      }
      updates++;
      if (options.execute) {
        await target.update({publicActorId: plan.actorId});
        const verified = await target.get();
        const verifiedPlan = planActorBackfill(
          options.secret,
          category,
          uid,
          {...document.data(), uid},
          verified.data(),
        );
        if (verifiedPlan.status !== 'unchanged' ||
            verifiedPlan.protectedDigest !== plan.protectedDigest) {
          throw new Error('Post-write digest verification failed.');
        }
      }
    }
    const sourceAfter = await database.collection(legacyCollections[category]).get();
    const sourceDigestAfter = stableDigest(sourceAfter.docs.map((document) => ({
      id: document.id,
      data: document.data(),
    })));
    if (sourceDigestBefore !== sourceDigestAfter) {
      throw new Error('Legacy source digest changed.');
    }
    console.log(JSON.stringify({
      category,
      sourceCount: source.size,
      updates,
      unchanged,
      errors,
      legacyDigestUnchanged: true,
    }));
    if (errors > 0) process.exitCode = 1;
  }
}

if (require.main === module) {
  main().catch(() => {
    console.error('Actor ID backfill failed. No user identifiers were logged.');
    process.exitCode = 1;
  });
}
