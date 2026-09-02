import 'pop_sound_native.dart';

Future<void> initializeNativePopSound() => PopSound.initializeNativeAudio();

Future<void> prepareNativeSemanticGameplaySounds({
  required bool hasHitAsset,
  required bool hasPopAsset,
  required String popSoundKind,
}) =>
    PopSound.prepareSemanticGameplaySounds(
      hasHitAsset: hasHitAsset,
      hasPopAsset: hasPopAsset,
      popSoundKind: popSoundKind,
    );

void releaseNativeSemanticGameplaySounds() =>
    PopSound.releaseSemanticGameplaySounds();

void pauseNativePopSound() => PopSound.pauseNativeAudio();

void resumeNativePopSound() => PopSound.resumeNativeAudio();

void stopActiveNativePopSound() => PopSound.stopActiveNativeAudio();

Future<void> shutdownNativePopSound() => PopSound.shutdownNativeAudio();
