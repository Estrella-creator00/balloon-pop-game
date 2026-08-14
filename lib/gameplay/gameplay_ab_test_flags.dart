/// Temporary device A/B switches for isolating MUGI/BOO latency.
///
/// Keep the sound/idle switches enabled for normal gameplay. The reference
/// color switch is enabled only for the current BOO GPU diagnostic build.
const bool mugiSoundTest = true;
const bool booSoundTest = true;
const bool booIdleTest = true;
const bool booReferenceColorTest = true;
const bool booZeroRotationTest = true;
const bool booZeroMovementTest = true;
const bool booDrawImageRectTest = true;

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

bool usesBooReferenceColorTest(
  String skinId, {
  bool? booReferenceColorTestOverride,
}) =>
    skinId == 'balloon-boo' &&
    (booReferenceColorTestOverride ?? booReferenceColorTest);

bool usesBooZeroRotationTest(
  String skinId, {
  bool? booZeroRotationTestOverride,
}) =>
    skinId == 'balloon-boo' &&
    (booZeroRotationTestOverride ?? booZeroRotationTest);

bool usesBooZeroMovementTest(
  String skinId, {
  bool? booZeroMovementTestOverride,
}) =>
    skinId == 'balloon-boo' &&
    (booZeroMovementTestOverride ?? booZeroMovementTest);

bool usesBooDrawImageRectTest(
  String skinId, {
  bool? booDrawImageRectTestOverride,
}) =>
    skinId == 'balloon-boo' &&
    (booDrawImageRectTestOverride ?? booDrawImageRectTest);
