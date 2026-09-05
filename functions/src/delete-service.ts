import {
  legacyCollections,
  publicCollections,
  publicEntryId,
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
  return paths;
}

export async function deleteOwnedOnlineData(
  uid: string,
  secret: string,
  dependencies: OnlineDataDeletionDependencies,
): Promise<void> {
  const paths = ownedOnlineDataPaths(uid, secret);
  await dependencies.deleteFirestoreDocuments(paths);
  await dependencies.deleteAuthUser(uid);
}
