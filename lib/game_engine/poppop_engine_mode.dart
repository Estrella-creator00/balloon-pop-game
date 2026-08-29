enum PoppopEngineMode {
  production,
  canvasPhase4A,
  flamePreview,
  flameIntegration,
}

const String canvasPhase4AEngineQueryValue = 'canvas-phase4a';
const String flamePreviewEngineQueryValue = 'flame-preview';
const String flameIntegrationEngineQueryValue = 'flame-integration';
const PoppopEngineMode defaultPoppopEngineMode =
    PoppopEngineMode.flameIntegration;

PoppopEngineMode poppopEngineModeFromUri(Uri uri) =>
    switch (uri.queryParameters['engine']) {
      canvasPhase4AEngineQueryValue => PoppopEngineMode.canvasPhase4A,
      flamePreviewEngineQueryValue => PoppopEngineMode.flamePreview,
      flameIntegrationEngineQueryValue => PoppopEngineMode.flameIntegration,
      _ => defaultPoppopEngineMode,
    };

int flamePreviewStageFromUri(Uri uri) {
  final stage = int.tryParse(uri.queryParameters['stage'] ?? '');
  return stage != null && stage >= 1 && stage <= 30 ? stage : 1;
}
