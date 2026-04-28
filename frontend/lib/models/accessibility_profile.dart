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
}
