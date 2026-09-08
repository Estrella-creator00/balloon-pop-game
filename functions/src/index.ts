import {getApps, initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, getFirestore, Timestamp} from 'firebase-admin/firestore';
import {defineSecret} from 'firebase-functions/params';
import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {
  comparableEntry,
  actorModerationCollection,
  isCategory,
  isRecord,
  isPublicActorId,
  isSelfActor,
  nextReportRate,
  publicCollections,
  publicEntryId,
  publicActorId,
  rankingSafetyPolicyVersion,
  reportDocumentId,
  reporterPublicId,
  requireAnonymousUid,
  sanitizedEntry,
  shouldReplace,
  validateSubmitPayload,
  validateReportPayload,
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
    const actorId = publicActorId(leaderboardSecret.value(), uid);
    const reference = getFirestore()
      .collection(publicCollections[payload.category])
      .doc(entryId);
    let updated = false;
    await getFirestore().runTransaction(async (transaction) => {
      const [snapshot, moderation] = await Promise.all([
        transaction.get(reference),
        transaction.get(
          getFirestore().collection(actorModerationCollection).doc(actorId),
        ),
      ]);
      if (moderation.exists && moderation.get('status') === 'blocked') {
        throw new HttpsError('permission-denied', 'Ranking access is blocked.');
      }
      const current = comparableEntry(
        snapshot.exists ? snapshot.data() : undefined,
      );
      const candidate = sanitizedEntry(
        payload,
        FieldValue.serverTimestamp(),
        actorId,
      );
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

const reportRetentionDays = 180;

export const reportLeaderboardEntry = onCall(
  {region, secrets: [leaderboardSecret]},
  async (request) => {
    const uid = authenticatedUid(
      request.auth?.uid,
      request.auth?.token.firebase?.sign_in_provider,
    );
    let payload;
    try {
      payload = validateReportPayload(request.data);
    } catch {
      return invalidArgument();
    }
    const secret = leaderboardSecret.value();
    const database = getFirestore();
    const target = database.collection(publicCollections[payload.category])
      .doc(payload.entryId);
    const reporterId = reporterPublicId(secret, uid);
    const report = database.collection('ranking_reports_v1')
      .doc(reportDocumentId(secret, uid, payload));
    const rate = database.collection('ranking_reporters_v1').doc(reporterId);
    let created = false;
    await database.runTransaction(async (transaction) => {
      const [targetSnapshot, reportSnapshot, rateSnapshot] = await Promise.all([
        transaction.get(target),
        transaction.get(report),
        transaction.get(rate),
      ]);
      if (!targetSnapshot.exists) {
        throw new HttpsError('not-found', 'The ranking entry does not exist.');
      }
      const targetData = targetSnapshot.data() ?? {};
      const targetActorId = targetData.publicActorId;
      if (!isPublicActorId(targetActorId)) {
        throw new HttpsError(
          'failed-precondition',
          'This legacy ranking entry cannot be reported yet.',
        );
      }
      if (isSelfActor(secret, uid, targetActorId)) {
        throw new HttpsError('failed-precondition', 'You cannot report yourself.');
      }
      if (reportSnapshot.exists) return;

      const now = Timestamp.now();
      const previousWindow = rateSnapshot.get('windowStartedAt');
      const previousCount = rateSnapshot.get('count');
      const nextRate = nextReportRate(
        now.toMillis(),
        previousWindow instanceof Timestamp
          ? previousWindow.toMillis()
          : undefined,
        Number.isInteger(previousCount) ? previousCount as number : undefined,
      );
      if (!nextRate.allowed) {
        throw new HttpsError(
          'resource-exhausted',
          'The report limit has been reached.',
        );
      }
      transaction.create(report, {
        category: payload.category,
        targetEntryId: payload.entryId,
        targetPublicActorId: targetActorId,
        targetDisplayName: targetData.displayName ?? '',
        reason: payload.reason,
        reporterId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(
          now.toMillis() + reportRetentionDays * 24 * 60 * 60 * 1000,
        ),
        policyVersion: rankingSafetyPolicyVersion,
        status: 'pending',
      });
      transaction.set(rate, {
        windowStartedAt: Timestamp.fromMillis(nextRate.windowStartedAtMillis),
        count: nextRate.count,
        updatedAt: FieldValue.serverTimestamp(),
      });
      created = true;
    });
    return {reported: created};
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
      const reporterId = reporterPublicId(leaderboardSecret.value(), uid);
      const reports = await database.collection('ranking_reports_v1')
        .where('reporterId', '==', reporterId)
        .get();
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
      }, reports.docs.map((document) => document.ref.path));
    } catch {
      throw new HttpsError(
        firestoreDeleted ? 'internal' : 'unavailable',
        'Online data could not be deleted. Please retry.',
      );
    }
    return {deleted: true};
  },
);
