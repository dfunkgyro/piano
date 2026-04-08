import 'dart:math' as math;

enum VelocityCurvePreset {
  linear,
  soft,
  medium,
  hard,
  custom,
}

double velocityCurveExponent(
    VelocityCurvePreset preset, double customExponent) {
  switch (preset) {
    case VelocityCurvePreset.linear:
      return 1.0;
    case VelocityCurvePreset.soft:
      return 0.7;
    case VelocityCurvePreset.medium:
      return 1.0;
    case VelocityCurvePreset.hard:
      return 1.4;
    case VelocityCurvePreset.custom:
      return customExponent;
  }
}

VelocityCurvePreset velocityCurvePresetFromString(String? value) {
  switch (value) {
    case 'soft':
      return VelocityCurvePreset.soft;
    case 'medium':
      return VelocityCurvePreset.medium;
    case 'hard':
      return VelocityCurvePreset.hard;
    case 'custom':
      return VelocityCurvePreset.custom;
    case 'linear':
    default:
      return VelocityCurvePreset.linear;
  }
}

String velocityCurvePresetToString(VelocityCurvePreset preset) {
  switch (preset) {
    case VelocityCurvePreset.soft:
      return 'soft';
    case VelocityCurvePreset.medium:
      return 'medium';
    case VelocityCurvePreset.hard:
      return 'hard';
    case VelocityCurvePreset.custom:
      return 'custom';
    case VelocityCurvePreset.linear:
    default:
      return 'linear';
  }
}

double computeExponentFromCalibration(double softVelocity, double hardVelocity) {
  const targetSoft = 0.25;
  const targetHard = 0.85;

  final safeSoft = softVelocity.clamp(0.01, 0.99);
  final safeHard = hardVelocity.clamp(0.01, 0.99);

  final expSoft = math.log(targetSoft) / math.log(safeSoft);
  final expHard = math.log(targetHard) / math.log(safeHard);

  final exponent = ((expSoft + expHard) / 2).clamp(0.5, 2.0);
  return exponent.toDouble();
}
