enum AccessibilityProfile {
  None('none', 'None'),
  Blind('blind', 'Blind'),
  LowVision('low_vision', 'Low Vision'),
  Wheelchair('wheelchair', 'Wheelchair'),
  WheelchairBiometric('wheelchair_biometric', 'Wheelchair Biometric');

  final String serverValue;
  final String displayName;

  const AccessibilityProfile(this.serverValue, this.displayName);

  static AccessibilityProfile fromServerValue(String? value) {
    switch (value) {
      case 'blind':
        return AccessibilityProfile.Blind;
      case 'low_vision':
        return AccessibilityProfile.LowVision;
      case 'wheelchair':
        return AccessibilityProfile.Wheelchair;
      case 'wheelchair_biometric':
        return AccessibilityProfile.WheelchairBiometric;
      case 'none':
      default:
        return AccessibilityProfile.None;
    }
  }

  static AccessibilityProfile fromToggles({
    required bool wheelchair,
    required bool blind,
  }) {
    if (wheelchair && blind) {
      return AccessibilityProfile.LowVision;
    }
    if (wheelchair) {
      return AccessibilityProfile.Wheelchair;
    }
    if (blind) {
      return AccessibilityProfile.Blind;
    }
    return AccessibilityProfile.None;
  }

  bool get isWheelchair =>
      this == AccessibilityProfile.Wheelchair ||
      this == AccessibilityProfile.WheelchairBiometric ||
      this == AccessibilityProfile.LowVision;

  bool get isBlind =>
      this == AccessibilityProfile.Blind ||
      this == AccessibilityProfile.LowVision;

  AccessibilityProfile get simpleProfile {
    if (this == AccessibilityProfile.LowVision) return AccessibilityProfile.LowVision;
    if (isWheelchair) return AccessibilityProfile.Wheelchair;
    if (isBlind) return AccessibilityProfile.Blind;
    return AccessibilityProfile.None;
  }
}
