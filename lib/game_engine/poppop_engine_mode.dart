enum PoppopEngineMode { production, flamePreview, flameIntegration }

const String flamePreviewEngineQueryValue = 'flame-preview';
const String flameIntegrationEngineQueryValue = 'flame-integration';
const PoppopEngineMode defaultPoppopEngineMode = PoppopEngineMode.production;

PoppopEngineMode poppopEngineModeFromUri(Uri uri) =>
    switch (uri.queryParameters['engine']) {
      flamePreviewEngineQueryValue => PoppopEngineMode.flamePreview,
      flameIntegrationEngineQueryValue => PoppopEngineMode.flameIntegration,
      _ => defaultPoppopEngineMode,
    };

int flamePreviewStageFromUri(Uri uri) {
  final stage = int.tryParse(uri.queryParameters['stage'] ?? '');
  return stage != null && stage >= 1 && stage <= 30 ? stage : 1;
}
