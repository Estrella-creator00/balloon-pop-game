import 'dart:io';

import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:balloon_pop_game/services/external_links.dart';
import 'package:balloon_pop_game/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings opens privacy/support and keeps Support ID private', (
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
          copiedText = (call.arguments as Map<Object?, Object?>)['text'] as String?;
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('settings-contact-row')));
    await tester.pump();
    expect(opened, [PoppopExternalLinks.privacy, PoppopExternalLinks.support]);

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

  test('privacy and support pages contain bilingual, local-only controls', () {
    final privacy = File('web/privacy/index.html').readAsStringSync();
    final support = File('web/support/index.html').readAsStringSync();

    for (final html in [privacy, support]) {
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
    expect(
      support,
      contains('href="/balloon-pop-game/privacy/"'),
    );
    expect(support, contains('id="delete-data"'));
    expect(support, contains('POPPOP%20Data%20Deletion%20Request'));
    expect(support, contains('Support%20ID%3A%20'));
    expect(support, contains('POPPOP%20%EB%8D%B0%EC%9D%B4%ED%84%B0'));
  });
}
