import 'package:url_launcher/url_launcher.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

abstract final class PoppopExternalLinks {
  static const supportEmailAddress = 'oopsidestudio@gmail.com';

  static final privacy = Uri.parse(
    'https://estrella-creator00.github.io/balloon-pop-game/privacy/',
  );
  static final support = Uri.parse(
    'https://estrella-creator00.github.io/balloon-pop-game/support/',
  );

  static Uri supportEmail({required String subject, String? supportId}) => Uri(
        scheme: 'mailto',
        path: supportEmailAddress,
        queryParameters: {
          'subject': subject,
          if (supportId != null) 'body': 'Support ID: $supportId',
        },
      );

  static Future<bool> open(Uri uri) => launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
}
