import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {adminOptions} from './admin-options';
import {
  comparableEntry,
  legacyCollections,
  publicCollections,
  publicEntryId,
  RankingCategory,
  shouldReplace,
  validateSubmitPayload,
} from '../src/domain';

type LegacyRecord = {
  uid: string;
  displayName: string;
  score: number;
  submittedAt: unknown;
  reachedStage?: number;
  cleared?: boolean;
};

async function main(): Promise<void> {
  const options = adminOptions(process.argv.slice(2), process.env);
  initializeApp({projectId: options.projectId, credential: applicationDefault()});
  const database = getFirestore();
  console.log(`Project: ${options.projectId}`);
  console.log(`Mode: ${options.execute ? 'EXECUTE' : 'DRY RUN'}`);

  for (const category of ['stage', 'sixtySeconds'] as const) {
    const source = await database.collection(legacyCollections[category]).get();
    const before = await database.collection(publicCollections[category]).count().get();
    const sourceValues = source.docs.map((document) => ({
        ...document.data(),
        uid: document.data().uid ?? document.id,
      }));
    const selected = selectBestLegacyRecords(category, sourceValues);
    const validCount = sourceValues
      .filter((value) => legacyRecord(category, value) !== null).length;
    let success = 0;
    let skipped = validCount - selected.length;
    let errors = sourceValues.length - validCount;
    for (const record of selected) {
      try {
        const entryId = publicEntryId(options.secret, category, record.uid);
        const reference = database.collection(publicCollections[category]).doc(entryId);
        if (!options.execute) {
          const currentSnapshot = await reference.get();
          const current = comparableEntry(
            currentSnapshot.exists ? currentSnapshot.data() : undefined,
          );
          if (shouldReplace(current, record, category)) {
            success++;
          } else {
            skipped++;
          }
          continue;
        }
        await database.runTransaction(async (transaction) => {
          const currentSnapshot = await transaction.get(reference);
          const current = comparableEntry(
            currentSnapshot.exists ? currentSnapshot.data() : undefined,
          );
          if (!shouldReplace(current, record, category)) {
            skipped++;
            return;
          }
          transaction.set(reference, publicMigrationRecord(category, record));
          success++;
        });
      } catch {
        errors++;
      }
    }
    const after = options.execute
      ? await database.collection(publicCollections[category]).count().get()
      : before;
    console.log(JSON.stringify({
      category,
      sourceCount: source.size,
      targetBefore: before.data().count,
      targetAfter: after.data().count,
      success,
      skipped,
      errors,
    }));
  }
}

export function selectBestLegacyRecords(
  category: RankingCategory,
  values: unknown[],
): LegacyRecord[] {
  const selected = new Map<string, LegacyRecord>();
  for (const value of values) {
    const record = legacyRecord(category, value);
    if (!record) continue;
    const current = selected.get(record.uid);
    if (shouldReplace(current, record, category)) selected.set(record.uid, record);
  }
  return [...selected.values()];
}

function legacyRecord(category: RankingCategory, value: unknown): LegacyRecord | null {
  if (typeof value !== 'object' || value === null) return null;
  const data = value as Record<string, unknown>;
  if (typeof data.uid !== 'string') return null;
  try {
    const payload = validateSubmitPayload({
      category,
      displayName: data.displayName,
      score: data.score,
      ...(category === 'stage' ? {
        reachedStage: data.reachedStage,
        cleared: data.cleared,
      } : {}),
    });
    return {
      uid: data.uid,
      displayName: payload.displayName,
      score: payload.score,
      submittedAt: data.submittedAt,
      ...(category === 'stage' ? {
        reachedStage: payload.reachedStage,
        cleared: payload.cleared,
      } : {}),
    };
  } catch {
    return null;
  }
}

export function publicMigrationRecord(
  category: RankingCategory,
  record: LegacyRecord,
): Record<string, unknown> {
  return {
    displayName: record.displayName,
    score: record.score,
    submittedAt: record.submittedAt,
    schemaVersion: 2,
    ...(category === 'stage' ? {
      reachedStage: record.reachedStage,
      cleared: record.cleared,
    } : {}),
  };
}

if (require.main === module) {
  main().catch(() => {
    console.error('Migration failed. No user identifiers were logged.');
    process.exitCode = 1;
  });
}
