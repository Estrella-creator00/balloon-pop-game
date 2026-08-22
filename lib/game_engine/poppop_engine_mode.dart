enum PoppopEngineMode { production, flamePreview }

const String flamePreviewEngineQueryValue = 'flame-preview';
const PoppopEngineMode defaultPoppopEngineMode = PoppopEngineMode.production;

PoppopEngineMode poppopEngineModeFromUri(Uri uri) {
  return uri.queryParameters['engine'] == flamePreviewEngineQueryValue
      ? PoppopEngineMode.flamePreview
      : defaultPoppopEngineMode;
}

int flamePreviewStageFromUri(Uri uri) {
  final stage = int.tryParse(uri.queryParameters['stage'] ?? '');
  return stage != null && stage >= 1 && stage <= 30 ? stage : 1;
}
