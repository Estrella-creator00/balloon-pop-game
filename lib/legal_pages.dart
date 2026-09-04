import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'ranking/firebase_ranking_runtime.dart';
import 'services/external_links.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    this.externalLinkOpener = PoppopExternalLinks.open,
  });

  final ExternalLinkOpener externalLinkOpener;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return _LegalDocumentPage(
      pageKey: const ValueKey('privacy-policy-page'),
      title: strings.privacy,
      introduction: strings.privacyIntroduction,
      sections: [
        _LegalSection(
            strings.privacyOperatorTitle, strings.privacyOperatorBody),
        _LegalSection(strings.privacyOnlineTitle, strings.privacyOnlineBody),
        _LegalSection(strings.privacyLocalTitle, strings.privacyLocalBody),
        _LegalSection(
            strings.privacyFirebaseTitle, strings.privacyFirebaseBody),
        _LegalSection(
          strings.privacyNotCollectedTitle,
          strings.privacyNotCollectedBody,
        ),
        _LegalSection(
          strings.privacyRetentionTitle,
          strings.privacyRetentionBody,
        ),
        _LegalSection(
            strings.privacyChildrenTitle, strings.privacyChildrenBody),
        _LegalSection(
            strings.privacySecurityTitle, strings.privacySecurityBody),
        _LegalSection(strings.privacyContactTitle, strings.privacyContactBody),
      ],
      actions: [
        _LegalActionButton(
          key: const ValueKey('privacy-view-on-web'),
          icon: Icons.open_in_new_rounded,
          label: strings.viewOnWeb,
          onPressed: () => _openExternal(
            context,
            externalLinkOpener,
            PoppopExternalLinks.privacy,
          ),
        ),
      ],
    );
  }
}

class SupportPage extends StatefulWidget {
  const SupportPage({
    super.key,
    this.externalLinkOpener = PoppopExternalLinks.open,
    this.supportIdProvider,
  });

  final ExternalLinkOpener externalLinkOpener;
  final Future<String> Function()? supportIdProvider;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late final Future<String> _supportIdFuture;
  String? _supportId;

  @override
  void initState() {
    super.initState();
    _supportIdFuture = _loadSupportId();
  }

  Future<String> _loadSupportId() async {
    final value = await (widget.supportIdProvider?.call() ??
        FirebaseRankingRuntime.instance.ensureUid());
    if (mounted) setState(() => _supportId = value);
    return value;
  }

  Future<void> _copySupportId() async {
    final supportId = _supportId;
    if (supportId == null) return;
    await Clipboard.setData(ClipboardData(text: supportId));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.supportIdCopied)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return _LegalDocumentPage(
      pageKey: const ValueKey('support-page'),
      title: strings.support,
      introduction: strings.supportIntroduction,
      sections: [
        _LegalSection(strings.supportContactTitle, strings.supportContactBody),
        _LegalSection(strings.supportResetTitle, strings.supportResetBody),
        _LegalSection(strings.supportRankingTitle, strings.supportRankingBody),
        _LegalSection(
            strings.supportNicknameTitle, strings.supportNicknameBody),
        _LegalSection(
            strings.supportDeletionTitle, strings.supportDeletionBody),
        _LegalSection(
          strings.supportDataDifferenceTitle,
          strings.supportDataDifferenceBody,
        ),
        _LegalSection(strings.supportTimingTitle, strings.supportTimingBody),
      ],
      additionalContent: [
        _SupportIdCard(
          future: _supportIdFuture,
          onCopy: _copySupportId,
        ),
      ],
      actions: [
        _LegalActionButton(
          key: const ValueKey('support-email-button'),
          icon: Icons.email_rounded,
          label: strings.emailSupport,
          onPressed: () => _openExternal(
            context,
            widget.externalLinkOpener,
            PoppopExternalLinks.supportEmail(
              subject: strings.supportEmailSubject,
              supportId: _supportId,
            ),
          ),
        ),
        _LegalActionButton(
          key: const ValueKey('support-view-on-web'),
          icon: Icons.open_in_new_rounded,
          label: strings.viewOnWeb,
          onPressed: () => _openExternal(
            context,
            widget.externalLinkOpener,
            PoppopExternalLinks.support,
          ),
        ),
      ],
    );
  }
}

Future<void> _openExternal(
  BuildContext context,
  ExternalLinkOpener opener,
  Uri uri,
) async {
  final opened = await opener(uri);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.linkOpenError)));
  }
}

class _LegalDocumentPage extends StatelessWidget {
  const _LegalDocumentPage({
    required this.pageKey,
    required this.title,
    required this.introduction,
    required this.sections,
    required this.actions,
    this.additionalContent = const [],
  });

  final Key pageKey;
  final String title;
  final String introduction;
  final List<_LegalSection> sections;
  final List<Widget> additionalContent;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: pageKey,
        backgroundColor: const Color(0xFFE8F8FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D70A0),
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF4F7B),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            key: const ValueKey('legal-document-scroll'),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              Material(
                color: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x33204A5F),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        introduction,
                        style: const TextStyle(
                          color: Color(0xFF415F70),
                          fontSize: 15,
                          height: 1.55,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      for (final section in sections) ...[
                        const SizedBox(height: 20),
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: Color(0xFF244F68),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          section.body,
                          style: const TextStyle(
                            color: Color(0xFF526E7D),
                            fontSize: 14,
                            height: 1.58,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (additionalContent.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...additionalContent,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: action,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SupportIdCard extends StatelessWidget {
  const _SupportIdCard({required this.future, required this.onCopy});

  final Future<String> future;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF2FAFE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7EDF7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.supportId,
                style: const TextStyle(
                  color: Color(0xFF244F68),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.supportIdDescription,
                style: const TextStyle(
                  color: Color(0xFF526E7D),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Text(context.l10n.supportIdError);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(
                        snapshot.data!,
                        key: const ValueKey('support-page-id-value'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const ValueKey('support-page-id-copy'),
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(context.l10n.copySupportId),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _LegalActionButton extends StatelessWidget {
  const _LegalActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7354E8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
