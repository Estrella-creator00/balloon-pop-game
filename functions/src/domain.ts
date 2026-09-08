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

export const actorModerationCollection = 'ranking_actor_moderation_v1';

export type PublicEntry = {
  publicActorId: string;
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
  policyVersion: number;
  reachedStage?: number;
  cleared?: boolean;
};

export const rankingSafetyPolicyVersion = 1;
// Control and invisible direction characters are intentionally rejected.
// eslint-disable-next-line no-control-regex
const unsafeCodePoints = /[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF]/u;
const allowedName = /^[가-힣A-Za-z0-9 ]+$/u;
const blockedFragments = [
  'fuck', 'shit', 'bitch', 'cunt', 'nigger', 'nigga', 'whore', 'slut',
  'porn', 'rape', 'killurself', '씨발', '병신', '개새끼', '개색기',
  '좆', '보지', '자지', '섹스', '강간', '창녀', '김치녀', '한남충',
  '한녀충', '죽어버려',
];
const blockedWhole = new Set([
  'admin', 'administrator', 'operator', 'moderator', '운영자', '관리자',
  '시발', 'sex', 'nazi', 'kys', '죽어', '꺼져', '자살',
]);

export function normalizeSafeName(value: unknown): string | undefined {
  if (typeof value !== 'string' || unsafeCodePoints.test(value)) return undefined;
  const normalized = value.normalize('NFKC').trim().replace(/\s+/gu, ' ');
  if (normalized.length < 2 || normalized.length > 16) return undefined;
  const lowered = normalized.toLowerCase();
  const digits = lowered.replace(/[^0-9]/gu, '');
  if (digits.length >= 7 ||
      /(?:[a-z0-9][a-z0-9._%+-]{0,63})\s*(?:@|\bat\b)\s*[a-z0-9-]+(?:\s*\.\s*[a-z]{2,}|\s+dot\s+[a-z]{2,})/iu.test(lowered) ||
      /(?:https?\s*:\s*\/\/|www\s*\.|[a-z0-9-]+\s*\.\s*(?:com|net|org|kr|io|gg)\b)/iu.test(lowered) ||
      /(?:학교|초등|중학교|고등학교|대학교|school|academy)/iu.test(lowered) ||
      /(?:@|instagram|insta|discord|telegram|kakao|카톡|오픈채팅|텔레그램|디엠|dm)/iu.test(lowered)) {
    return undefined;
  }
  if (!allowedName.test(normalized)) return undefined;
  const substitutions: Record<string, string> = {
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't',
    '8': 'b', '9': 'g',
  };
  const key = lowered
    .replace(/[^가-힣a-z0-9]/gu, '')
    .replace(/[01345789]/gu, (value) => substitutions[value])
    .replace(/(.)\1{2,}/gu, '$1');
  if (blockedWhole.has(key) || blockedFragments.some((word) => key.includes(word))) {
    return undefined;
  }
  if (isMeaningless(key)) return undefined;
  return normalized;
}

function isMeaningless(value: string): boolean {
  if (value.length >= 3 && new Set(value).size === 1) return true;
  for (let unit = 1; unit <= 3; unit += 1) {
    if (value.length < unit * 3 || value.length % unit !== 0) continue;
    if (value.slice(0, unit).repeat(value.length / unit) === value) return true;
  }
  return false;
}

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

export function publicActorId(secret: string, uid: string): string {
  if (secret.length < 32) throw new Error('Leaderboard secret is invalid.');
  return createHmac('sha256', secret)
    .update(`actor:${uid}`, 'utf8')
    .digest('hex');
}

export function isPublicActorId(value: unknown): value is string {
  return typeof value === 'string' && /^[a-f0-9]{64}$/u.test(value);
}

export function validateSubmitPayload(value: unknown): SubmitPayload {
  if (!isRecord(value)) throw new Error('invalid-argument');
  const category = value.category;
  if (!isCategory(category)) throw new Error('invalid-argument');
  const allowed = category === 'stage'
    ? ['category', 'displayName', 'score', 'policyVersion', 'reachedStage', 'cleared']
    : ['category', 'displayName', 'score', 'policyVersion'];
  if (Object.keys(value).some((key) => !allowed.includes(key))) {
    throw new Error('invalid-argument');
  }
  const displayName = normalizeSafeName(value.displayName);
  if (!displayName || value.policyVersion !== rankingSafetyPolicyVersion) {
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
  return {...value, displayName} as SubmitPayload;
}

export const reportReasons = [
  'personalInformation',
  'hateOrHarassment',
  'sexualContent',
  'impersonation',
  'otherInappropriate',
] as const;
export type ReportReason = typeof reportReasons[number];
export type ReportPayload = {
  category: RankingCategory;
  entryId: string;
  reason: ReportReason;
  policyVersion: number;
};

export function validateReportPayload(value: unknown): ReportPayload {
  if (!isRecord(value) ||
      Object.keys(value).some((key) =>
        !['category', 'entryId', 'reason', 'policyVersion'].includes(key)) ||
      !isCategory(value.category) ||
      typeof value.entryId !== 'string' ||
      !/^[a-f0-9]{64}$/u.test(value.entryId) ||
      typeof value.reason !== 'string' ||
      !reportReasons.includes(value.reason as ReportReason) ||
      value.policyVersion !== rankingSafetyPolicyVersion) {
    throw new Error('invalid-argument');
  }
  return value as ReportPayload;
}

export function reporterPublicId(secret: string, uid: string): string {
  if (secret.length < 32) throw new Error('Leaderboard secret is invalid.');
  return createHmac('sha256', secret)
    .update(`reporter:${uid}`, 'utf8')
    .digest('hex');
}

export function reportDocumentId(
  secret: string,
  uid: string,
  payload: Pick<ReportPayload, 'category' | 'entryId'>,
): string {
  return createHmac('sha256', secret)
    .update(`report:${uid}:${payload.category}:${payload.entryId}`, 'utf8')
    .digest('hex');
}

export function isSelfReport(
  secret: string,
  uid: string,
  payload: Pick<ReportPayload, 'category' | 'entryId'>,
): boolean {
  return payload.entryId === publicEntryId(secret, payload.category, uid);
}

export function isSelfActor(
  secret: string,
  uid: string,
  actorId: unknown,
): boolean {
  return isPublicActorId(actorId) && actorId === publicActorId(secret, uid);
}

export const reportLimitPerDay = 5;

export function nextReportRate(
  nowMillis: number,
  previousWindowMillis: number | undefined,
  previousCount: number | undefined,
): {allowed: boolean; windowStartedAtMillis: number; count: number} {
  const withinWindow = previousWindowMillis !== undefined &&
    nowMillis - previousWindowMillis < 24 * 60 * 60 * 1000;
  const count = withinWindow && Number.isInteger(previousCount)
    ? previousCount as number
    : 0;
  return {
    allowed: count < reportLimitPerDay,
    windowStartedAtMillis: withinWindow ? previousWindowMillis : nowMillis,
    count: count + 1,
  };
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
  actorId: string,
): PublicEntry {
  if (!isPublicActorId(actorId)) throw new Error('invalid-argument');
  return {
    publicActorId: actorId,
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
