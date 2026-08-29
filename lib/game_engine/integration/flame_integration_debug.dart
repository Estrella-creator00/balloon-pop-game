import '../legendary/flame_preview_skin.dart';
import '../poppop_engine_mode.dart';

class FlameIntegrationDebugConfig {
  const FlameIntegrationDebugConfig({
    this.enabled = false,
    this.stage = 1,
    this.skin = FlamePreviewSkin.basic,
  });

  final bool enabled;
  final int stage;
  final FlamePreviewSkin skin;

  factory FlameIntegrationDebugConfig.fromUri(Uri uri) {
    if (uri.queryParameters['engine'] != flameIntegrationEngineQueryValue ||
        uri.queryParameters['debug'] != '1') {
      return const FlameIntegrationDebugConfig();
    }
    return FlameIntegrationDebugConfig(
      enabled: true,
      stage: flamePreviewStageFromUri(uri),
      skin: flamePreviewSkinFromUri(uri),
    );
  }
}

class FlameIntegrationMetrics {
  int activeGameInstances = 0;
  int activeGameWidgetInstances = 0;
  int hudRebuildCount = 0;
  int sessionNotificationCount = 0;
  int shellRebuildCount = 0;
  int lifecycleObserverCount = 0;
  String lifecycleState = 'resumed';
  int? shutdownUpdateCount;
  bool updateAdvancedAfterShutdown = false;

  void recordShutdown(int updateCount) {
    shutdownUpdateCount ??= updateCount;
  }

  void observePostShutdownUpdateCount(int updateCount) {
    final atShutdown = shutdownUpdateCount;
    if (atShutdown != null && updateCount > atShutdown) {
      updateAdvancedAfterShutdown = true;
    }
  }
}
