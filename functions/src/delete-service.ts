import {
  legacyCollections,
  publicCollections,
  publicActorId,
  publicEntryId,
  reporterPublicId,
} from './domain';

export type OnlineDataDeletionDependencies = {
  deleteFirestoreDocuments: (paths: readonly string[]) => Promise<void>;
  deleteAuthUser: (uid: string) => Promise<void>;
};

export function ownedOnlineDataPaths(uid: string, secret: string): string[] {
  const paths: string[] = [];
  for (const category of ['stage', 'sixtySeconds'] as const) {
    paths.push(
      `${publicCollections[category]}/${publicEntryId(secret, category, uid)}`,
      `${legacyCollections[category]}/${uid}`,
    );
  }
  paths.push(`ranking_private/${uid}`);
  paths.push(`ranking_reporters_v1/${reporterPublicId(secret, uid)}`);
  paths.push(`ranking_actor_moderation_v1/${publicActorId(secret, uid)}`);
  return paths;
}

export async function deleteOwnedOnlineData(
  uid: string,
  secret: string,
  dependencies: OnlineDataDeletionDependencies,
  additionalPaths: readonly string[] = [],
): Promise<void> {
  const paths = [...ownedOnlineDataPaths(uid, secret), ...additionalPaths];
  await dependencies.deleteFirestoreDocuments(paths);
  await dependencies.deleteAuthUser(uid);
}
