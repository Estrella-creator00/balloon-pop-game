import 'dart:io';

import 'package:balloon_pop_game/legal_pages.dart';
import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:balloon_pop_game/l10n/l10n.dart';
import 'package:balloon_pop_game/services/external_links.dart';
import 'package:balloon_pop_game/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings opens native privacy/support with explicit actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          onDataReset: () {},
          externalLinkOpener: (uri) async {
            opened.add(uri);
            return true;
          },
          supportIdProvider: () async => 'anonymous-support-id',
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-privacy-row')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-privacy-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('privacy-policy-page')), findsOneWidget);
    expect(find.textContaining('Effective date: September 4, 2026'),
        findsOneWidget);
    expect(opened, isEmpty);
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('privacy-view-on-web')),
    );
    await tester.tap(find.byKey(const ValueKey('privacy-view-on-web')));
    await tester.pump();
    expect(opened, [PoppopExternalLinks.privacy]);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-contact-row')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-contact-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('support-page')), findsOneWidget);
    expect(find.text('anonymous-support-id'), findsOneWidget);
    expect(opened, [PoppopExternalLinks.privacy]);

    await _scrollTo(
      tester,
      find.byKey(const ValueKey('support-page-id-copy')),
    );
    await tester.tap(find.byKey(const ValueKey('support-page-id-copy')));
    await tester.pump();
    expect(copiedText, 'anonymous-support-id');

    await tester.tap(find.byKey(const ValueKey('support-email-button')));
    await tester.tap(find.byKey(const ValueKey('support-view-on-web')));
    await tester.pump();
    expect(opened[1].scheme, 'mailto');
    expect(opened[1].path, PoppopExternalLinks.supportEmailAddress);
    expect(opened[1].queryParameters['body'], contains('anonymous-support-id'));
    expect(opened[2], PoppopExternalLinks.support);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-support-id-row')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-support-id-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('support-id-dialog')), findsOneWidget);
    expect(find.text('anonymous-support-id'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('support-id-copy')));
    await tester.pumpAndSettle();
    expect(copiedText, 'anonymous-support-id');
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings opens native terms and keeps legal links in-app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          onDataReset: () {},
          externalLinkOpener: (uri) async {
            opened.add(uri);
            return true;
          },
          supportIdProvider: () async => 'terms-support-id',
        ),
      ),
    );

    await tester
        .ensureVisible(find.byKey(const ValueKey('settings-terms-row')));
    await tester.tap(find.byKey(const ValueKey('settings-terms-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('terms-of-service-page')), findsOneWidget);
    expect(find.textContaining('Effective date: September 4, 2026'),
        findsOneWidget);
    expect(find.textContaining('does not currently offer purchases'),
        findsOneWidget);
    expect(opened, isEmpty);

    await _scrollTo(tester, find.byKey(const ValueKey('terms-privacy-button')));
    await tester.tap(find.byKey(const ValueKey('terms-privacy-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('privacy-policy-page')), findsOneWidget);
    expect(opened, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('terms-support-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('support-page')), findsOneWidget);
    expect(opened, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('terms-view-on-web')));
    await tester.pump();
    expect(opened, [PoppopExternalLinks.terms]);
    expect(tester.takeException(), isNull);
  });

  for (final testCase in <({
    Locale locale,
    String privacyExpected,
    String supportExpected,
    String termsExpected,
  })>[
    (
      locale: const Locale('ko'),
      privacyExpected: '시행일: 2026년 9월 4일',
      supportExpected: 'POPPOP 이용 중 문제가 있거나',
      termsExpected: '이 약관은 이용자와 보호자가',
    ),
    (
      locale: const Locale('en'),
      privacyExpected: 'Effective date: September 4, 2026',
      supportExpected: 'Contact OOPSIDE STUDIO',
      termsExpected: 'These Terms explain the rules',
    ),
    (
      locale: const Locale('fr'),
      privacyExpected: 'Effective date: September 4, 2026',
      supportExpected: 'Contact OOPSIDE STUDIO',
      termsExpected: 'These Terms explain the rules',
    ),
  ]) {
    testWidgets(
      'privacy locale ${testCase.locale.languageCode} is readable at 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: testCase.locale,
            localeListResolutionCallback: poppopLocaleResolution,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PrivacyPolicyPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(testCase.privacyExpected), findsOneWidget);
        expect(find.byKey(const ValueKey('legal-document-scroll')),
            findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            locale: testCase.locale,
            localeListResolutionCallback: poppopLocaleResolution,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SupportPage(
              supportIdProvider: () async => 'locale-support-id',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(testCase.supportExpected), findsOneWidget);
        expect(find.byKey(const ValueKey('support-page')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            locale: testCase.locale,
            localeListResolutionCallback: poppopLocaleResolution,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TermsOfServicePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(testCase.termsExpected), findsOneWidget);
        expect(find.byKey(const ValueKey('terms-of-service-page')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('legal pages contain bilingual, local-only controls and links', () {
    final privacy = File('web/privacy/index.html').readAsStringSync();
    final support = File('web/support/index.html').readAsStringSync();
    final terms = File('web/terms/index.html').readAsStringSync();

    for (final html in [privacy, support, terms]) {
      expect(html, contains('data-language-button="ko"'));
      expect(html, contains('data-language-button="en"'));
      expect(html, contains("startsWith('ko') ? 'ko' : 'en'"));
      expect(html, contains('@media (max-width: 380px)'));
      expect(html, isNot(contains('http://')));
      expect(html, isNot(contains('<img')));
      expect(html, isNot(contains('analytics')));
    }

    expect(
      privacy,
      contains('href="/balloon-pop-game/support/#delete-data"'),
    );
    expect(privacy, contains('href="/balloon-pop-game/terms/"'));
    expect(
      support,
      contains('href="/balloon-pop-game/privacy/"'),
    );
    expect(support, contains('href="/balloon-pop-game/terms/"'));
    expect(terms, contains('href="/balloon-pop-game/privacy/"'));
    expect(terms, contains('href="/balloon-pop-game/support/"'));
    expect(terms, contains('POPPOP does not currently offer purchases'));
    expect(terms, contains('관계 법령상 배제할 수 없는 소비자의 권리'));
    expect(support, contains('id="delete-data"'));
    expect(support, contains('POPPOP%20Data%20Deletion%20Request'));
    expect(support, contains('Support%20ID%3A%20'));
    expect(support, contains('POPPOP%20%EB%8D%B0%EC%9D%B4%ED%84%B0'));
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(
      find.byKey(const ValueKey('legal-document-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
