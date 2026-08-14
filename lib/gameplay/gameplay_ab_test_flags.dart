/// Temporary device A/B switches for isolating MUGI/BOO latency.
///
/// Keep these enabled for normal gameplay. Change only these three values when
/// producing a diagnostic build.
const bool mugiSoundTest = true;
const bool booSoundTest = false;
const bool booIdleTest = true;

bool isGameplaySkinSoundEnabled(
  String skinId, {
  bool? mugiSoundTestOverride,
  bool? booSoundTestOverride,
}) {
  if (skinId == 'balloon-jello') {
    return mugiSoundTestOverride ?? mugiSoundTest;
  }
  if (skinId == 'balloon-boo') {
    return booSoundTestOverride ?? booSoundTest;
  }
  return true;
}

bool isBooIdleTestEnabled(
  String skinId, {
  bool? booIdleTestOverride,
}) =>
    skinId != 'balloon-boo' || (booIdleTestOverride ?? booIdleTest);
