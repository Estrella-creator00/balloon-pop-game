import 'package:url_launcher/url_launcher.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

abstract final class PoppopExternalLinks {
  static final privacy = Uri.parse(
    'https://estrella-creator00.github.io/balloon-pop-game/privacy/',
  );
  static final support = Uri.parse(
    'https://estrella-creator00.github.io/balloon-pop-game/support/',
  );

  static Future<bool> open(Uri uri) => launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
}
