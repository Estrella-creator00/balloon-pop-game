import {createHmac} from 'node:crypto';

export const categories = ['stage', 'sixtySeconds'] as const;
export type RankingCategory = typeof categories[number];

export const publicCollections: Record<RankingCategory, string> = {
  stage: 'leaderboards_stage_v2',
  sixtySeconds: 'leaderboards_60s_v2',
};

export const legacyCollections: Record<RankingCategory, string> = {
  stage: 'leaderboards_stage_v1',
  sixtySeconds: 'leaderboards_60s_v1',
};

export type PublicEntry = {
  displayName: string;
  score: number;
  submittedAt: unknown;
  schemaVersion: 2;
  reachedStage?: number;
  cleared?: boolean;
};

export type SubmitPayload = {
  category: RankingCategory;
  displayName: string;
  score: number;
  reachedStage?: number;
  cleared?: boolean;
};

const safeName = /^[가-힣A-Za-z0-9](?:[가-힣A-Za-z0-9 ]{0,14}[가-힣A-Za-z0-9])$/u;

export function publicEntryId(
  secret: string,
  category: RankingCategory,
  uid: string,
): string {
  if (secret.length < 32) throw new Error('Leaderboard secret is invalid.');
  return createHmac('sha256', secret)
    .update(`${category}:${uid}`, 'utf8')
    .digest('hex');
}

export function validateSubmitPayload(value: unknown): SubmitPayload {
  if (!isRecord(value)) throw new Error('invalid-argument');
  const category = value.category;
  if (!isCategory(category)) throw new Error('invalid-argument');
  const allowed = category === 'stage'
    ? ['category', 'displayName', 'score', 'reachedStage', 'cleared']
    : ['category', 'displayName', 'score'];
  if (Object.keys(value).some((key) => !allowed.includes(key))) {
    throw new Error('invalid-argument');
  }
  if (typeof value.displayName !== 'string' ||
      value.displayName.length < 2 ||
      value.displayName.length > 16 ||
      !safeName.test(value.displayName)) {
    throw new Error('invalid-argument');
  }
  const maximum = category === 'stage' ? 600 : 900;
  if (!Number.isInteger(value.score) ||
      (value.score as number) < 0 ||
      (value.score as number) > maximum) {
    throw new Error('invalid-argument');
  }
  if (category === 'stage') {
    if (!Number.isInteger(value.reachedStage) ||
        (value.reachedStage as number) < 1 ||
        (value.reachedStage as number) > 30 ||
        typeof value.cleared !== 'boolean' ||
        (value.cleared && value.reachedStage !== 30)) {
      throw new Error('invalid-argument');
    }
  }
  return value as SubmitPayload;
}

export function shouldReplace(
  current: Pick<PublicEntry, 'score' | 'reachedStage' | 'cleared'> | undefined,
  candidate: Pick<PublicEntry, 'score' | 'reachedStage' | 'cleared'>,
  category: RankingCategory,
): boolean {
  if (!current) return true;
  if (candidate.score !== current.score) return candidate.score > current.score;
  if (category !== 'stage') return false;
  const currentStage = current.reachedStage ?? 1;
  const candidateStage = candidate.reachedStage ?? 1;
  return candidateStage > currentStage ||
    (candidateStage === currentStage && !current.cleared && candidate.cleared === true);
}

export function comparableEntry(
  value: unknown,
): Pick<PublicEntry, 'score' | 'reachedStage' | 'cleared'> | undefined {
  if (!isRecord(value) || !Number.isInteger(value.score)) return undefined;
  return {
    score: value.score as number,
    ...(Number.isInteger(value.reachedStage)
      ? {reachedStage: value.reachedStage as number}
      : {}),
    ...(typeof value.cleared === 'boolean' ? {cleared: value.cleared} : {}),
  };
}

export function sanitizedEntry(
  payload: SubmitPayload,
  submittedAt: unknown,
): PublicEntry {
  return {
    displayName: payload.displayName,
    score: payload.score,
    submittedAt,
    schemaVersion: 2,
    ...(payload.category === 'stage' ? {
      reachedStage: payload.reachedStage,
      cleared: payload.cleared,
    } : {}),
  };
}

export function isCategory(value: unknown): value is RankingCategory {
  return value === 'stage' || value === 'sixtySeconds';
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function requireAnonymousUid(
  uid: string | undefined,
  signInProvider: string | undefined,
): string {
  if (!uid || signInProvider !== 'anonymous') throw new Error('unauthenticated');
  return uid;
}
