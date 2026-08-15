enum PoppopEngineMode { production, flamePreview }

const String flamePreviewEngineQueryValue = 'flame-preview';
const PoppopEngineMode defaultPoppopEngineMode = PoppopEngineMode.production;

PoppopEngineMode poppopEngineModeFromUri(Uri uri) {
  return uri.queryParameters['engine'] == flamePreviewEngineQueryValue
      ? PoppopEngineMode.flamePreview
      : defaultPoppopEngineMode;
}
