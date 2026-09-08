import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {FieldValue, getFirestore} from 'firebase-admin/firestore';
import {
  actorModerationCollection,
  categories,
  isPublicActorId,
  publicCollections,
} from '../src/domain';

type Options = {projectId: string; actorId: string; execute: boolean};

export function moderationOptions(argv: string[]): Options {
  const projectId = argv.find((value) => value.startsWith('--project='))
    ?.slice('--project='.length) ?? '';
  const actorId = argv.find((value) => value.startsWith('--actor='))
    ?.slice('--actor='.length) ?? '';
  const execute = argv.includes('--execute');
  const confirmation = argv.find((value) => value.startsWith('--confirm-actor='))
    ?.slice('--confirm-actor='.length);
  const allowed = argv.every((value) =>
    value === '--execute' || value.startsWith('--project=') ||
    value.startsWith('--actor=') || value.startsWith('--confirm-actor='));
  if (!allowed || !projectId || !isPublicActorId(actorId) ||
      (execute && confirmation !== actorId)) {
    throw new Error(
      'Use --project=<id> --actor=<64-hex-id>; execute also requires '
      + '--execute --confirm-actor=<same-id>.',
    );
  }
  return {projectId, actorId, execute};
}

async function main(): Promise<void> {
  const options = moderationOptions(process.argv.slice(2));
  initializeApp({projectId: options.projectId, credential: applicationDefault()});
  const database = getFirestore();
  const matches = [];
  for (const category of categories) {
    const snapshot = await database.collection(publicCollections[category])
      .where('publicActorId', '==', options.actorId)
      .get();
    matches.push(...snapshot.docs.map((document) => document.ref));
  }
  console.log(JSON.stringify({
    project: options.projectId,
    mode: options.execute ? 'EXECUTE' : 'DRY RUN',
    matchingPublicEntries: matches.length,
  }));
  if (!options.execute) return;
  const batch = database.batch();
  batch.set(database.collection(actorModerationCollection).doc(options.actorId), {
    status: 'blocked',
    reasonCode: 'safety-review',
    reviewedAt: FieldValue.serverTimestamp(),
  });
  for (const reference of matches) batch.delete(reference);
  await batch.commit();
}

if (require.main === module) {
  main().catch(() => {
    console.error('Moderation failed. No private identifiers were logged.');
    process.exitCode = 1;
  });
}
