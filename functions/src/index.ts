import {getApps, initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, getFirestore, Timestamp} from 'firebase-admin/firestore';
import {defineSecret} from 'firebase-functions/params';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {
  comparableEntry,
  isCategory,
  isRecord,
  publicCollections,
  publicEntryId,
  requireAnonymousUid,
  sanitizedEntry,
  shouldReplace,
  validateSubmitPayload,
} from './domain';
import {deleteOwnedOnlineData} from './delete-service';

if (getApps().length === 0) initializeApp();

const region = 'asia-northeast3';
const leaderboardSecret = defineSecret('LEADERBOARD_HMAC_SECRET');

function authenticatedUid(
  uid: string | undefined,
  signInProvider: string | undefined,
): string {
  try {
    return requireAnonymousUid(uid, signInProvider);
  } catch {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
}

function invalidArgument(): never {
  throw new HttpsError('invalid-argument', 'The ranking request is invalid.');
}

export const submitLeaderboard = onCall(
  {region, secrets: [leaderboardSecret]},
  async (request) => {
    const uid = authenticatedUid(
      request.auth?.uid,
      request.auth?.token.firebase?.sign_in_provider,
    );
    let payload;
    try {
      payload = validateSubmitPayload(request.data);
    } catch {
      return invalidArgument();
    }
    const entryId = publicEntryId(leaderboardSecret.value(), payload.category, uid);
    const reference = getFirestore()
      .collection(publicCollections[payload.category])
      .doc(entryId);
    let updated = false;
    await getFirestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const current = comparableEntry(
        snapshot.exists ? snapshot.data() : undefined,
      );
      const candidate = sanitizedEntry(payload, FieldValue.serverTimestamp());
      if (!shouldReplace(current, candidate, payload.category)) return;
      transaction.set(reference, candidate);
      updated = true;
    });
    return {updated, entryId};
  },
);

export const getMyLeaderboardEntry = onCall(
  {region, secrets: [leaderboardSecret]},
  async (request) => {
    const uid = authenticatedUid(
      request.auth?.uid,
      request.auth?.token.firebase?.sign_in_provider,
    );
    if (!isRecord(request.data) ||
        Object.keys(request.data).some((key) => key !== 'category') ||
        !isCategory(request.data.category)) {
      return invalidArgument();
    }
    const category = request.data.category;
    const entryId = publicEntryId(leaderboardSecret.value(), category, uid);
    const snapshot = await getFirestore()
      .collection(publicCollections[category])
      .doc(entryId)
      .get();
    if (!snapshot.exists) return {entryId, entry: null};
    const entry = snapshot.data() ?? {};
    const submittedAt = entry.submittedAt;
    return {
      entryId,
      entry: {
        ...entry,
        submittedAt: submittedAt instanceof Timestamp
          ? submittedAt.toDate().toISOString()
          : null,
      },
    };
  },
);

export const deleteOnlineData = onCall(
  {region, secrets: [leaderboardSecret]},
  async (request) => {
    const uid = authenticatedUid(
      request.auth?.uid,
      request.auth?.token.firebase?.sign_in_provider,
    );
    if (isRecord(request.data) && Object.keys(request.data).length > 0) {
      return invalidArgument();
    }
    let firestoreDeleted = false;
    try {
      const database = getFirestore();
      await deleteOwnedOnlineData(uid, leaderboardSecret.value(), {
        deleteFirestoreDocuments: async (paths) => {
          const batch = database.batch();
          for (const path of paths) batch.delete(database.doc(path));
          await batch.commit();
          firestoreDeleted = true;
        },
        deleteAuthUser: async (userId) => {
          try {
            await getAuth().deleteUser(userId);
          } catch (error) {
            if (isRecord(error) && error.code === 'auth/user-not-found') return;
            throw error;
          }
        },
      });
    } catch {
      throw new HttpsError(
        firestoreDeleted ? 'internal' : 'unavailable',
        'Online data could not be deleted. Please retry.',
      );
    }
    return {deleted: true};
  },
);
