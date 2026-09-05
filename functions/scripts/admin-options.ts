export type AdminOptions = {
  projectId: string;
  execute: boolean;
  secret: string;
};

export function adminOptions(
  argv: string[],
  environment: NodeJS.ProcessEnv,
  allowUid = false,
): AdminOptions {
  const projectArgument = argv.find((value) => value.startsWith('--project='));
  const projectId = projectArgument?.slice('--project='.length) ?? '';
  const unknown = argv.filter((value) =>
    value !== '--execute' &&
    !value.startsWith('--project=') &&
    !(allowUid && value.startsWith('--uid=')));
  if (!projectId || unknown.length > 0) {
    throw new Error('Use --project=<firebase-project-id> and optionally --execute.');
  }
  const secret = environment.LEADERBOARD_HMAC_SECRET ?? '';
  if (secret.length < 32) {
    throw new Error('LEADERBOARD_HMAC_SECRET must be supplied securely.');
  }
  return {projectId, execute: argv.includes('--execute'), secret};
}
