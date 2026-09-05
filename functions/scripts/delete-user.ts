import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {adminOptions} from './admin-options';
import {legacyCollections, publicCollections, publicEntryId} from '../src/domain';

async function main(): Promise<void> {
  const arguments_ = process.argv.slice(2);
  const options = adminOptions(arguments_, process.env, true);
  const uid = oneSupportId(arguments_);
  initializeApp({projectId: options.projectId, credential: applicationDefault()});
  console.log(`Project: ${options.projectId}`);
  console.log(`Mode: ${options.execute ? 'EXECUTE' : 'DRY RUN'}`);
  console.log('Scope: one authenticated user; identifier intentionally redacted.');
  if (!options.execute) return;

  const database = getFirestore();
  const batch = database.batch();
  for (const category of ['stage', 'sixtySeconds'] as const) {
    batch.delete(database.collection(legacyCollections[category]).doc(uid));
    batch.delete(database.collection(publicCollections[category])
      .doc(publicEntryId(options.secret, category, uid)));
  }
  batch.delete(database.collection('ranking_private').doc(uid));
  await batch.commit();
  await getAuth().deleteUser(uid);
  console.log('Deletion completed for one redacted user.');
}

export function oneSupportId(arguments_: string[]): string {
  const uidArguments = arguments_.filter((value) => value.startsWith('--uid='));
  const uid = uidArguments[0]?.slice('--uid='.length) ?? '';
  if (uidArguments.length !== 1 ||
      !uid || uid.length > 128 ||
      uid.includes('*') || uid.includes(',') || uid.includes('/')) {
    throw new Error('Exactly one --uid=<support-id> is required.');
  }
  return uid;
}

if (require.main === module) {
  main().catch(() => {
    console.error('Deletion failed. No user identifier was logged.');
    process.exitCode = 1;
  });
}
