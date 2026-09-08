import 'package:flutter/material.dart';

import '../legal_pages.dart';
import '../l10n/l10n.dart';
import 'ranking_safety_store.dart';

Future<bool> ensureRankingSafetyConsent(
  BuildContext context, {
  RankingSafetyStore? store,
}) async {
  final safetyStore = store ?? SharedPreferencesRankingSafetyStore();
  if (!await safetyStore.isOnlineRankingEnabled()) {
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('ranking-disabled-dialog'),
        title: Text(context.l10n.onlineRankingDisabledTitle),
        content: Text(context.l10n.onlineRankingDisabledBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
    return false;
  }
  if (await safetyStore.hasCurrentConsent()) return true;
  if (!context.mounted) return false;

  var safetyConfirmed = false;
  var termsConfirmed = false;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const ValueKey('ranking-safety-consent-dialog'),
        title: Text(context.l10n.rankingSafetyTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.rankingSafetyBody),
              const SizedBox(height: 10),
              Text(
                context.l10n.rankingSafetyPersonalInfo,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey('ranking-safety-confirmation'),
                contentPadding: EdgeInsets.zero,
                value: safetyConfirmed,
                onChanged: (value) =>
                    setState(() => safetyConfirmed = value ?? false),
                title: Text(context.l10n.rankingSafetyCheckbox),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                key: const ValueKey('ranking-terms-confirmation'),
                contentPadding: EdgeInsets.zero,
                value: termsConfirmed,
                onChanged: (value) =>
                    setState(() => termsConfirmed = value ?? false),
                title: Text(context.l10n.rankingTermsCheckbox),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    key: const ValueKey('ranking-open-terms'),
                    onPressed: () => Navigator.of(dialogContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServicePage(),
                      ),
                    ),
                    child: Text(context.l10n.terms),
                  ),
                  TextButton(
                    key: const ValueKey('ranking-open-privacy'),
                    onPressed: () => Navigator.of(dialogContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                    child: Text(context.l10n.privacy),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('ranking-safety-decline'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('ranking-safety-accept'),
            onPressed: safetyConfirmed && termsConfirmed
                ? () => Navigator.pop(dialogContext, true)
                : null,
            child: Text(context.l10n.agreeAndContinue),
          ),
        ],
      ),
    ),
  );
  if (accepted != true) return false;
  await safetyStore.acceptCurrentPolicy();
  return true;
}
