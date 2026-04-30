// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Navigation Diary';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get faq => 'FAQ';

  @override
  String get gdpr => 'GDPR';

  @override
  String get general => 'General';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'Enable alerts for notifications';

  @override
  String get appPermissions => 'App Permissions';

  @override
  String get appPermissionsSubtitle => 'Manage application\'s permissions';

  @override
  String get locationPermissionRequiredTitle => 'Location Permission Required';

  @override
  String get locationPermissionRequiredSubtitle =>
      'Please allow location access to continue.';

  @override
  String get grantLocationPermission => 'Grant Location Permission';

  @override
  String get locationPermissionRequiredMessage =>
      'Location permission is required to use this app.';

  @override
  String get locationPermissionRequiredOpenSettingsMessage =>
      'Location permission is required to use this app. Open settings to enable it.';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionCameraSubtitle =>
      'Required for taking new images or videos';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionMicrophoneSubtitle =>
      'Required for capturing video sound';

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String get permissionNotificationsSubtitle =>
      'Required for receiving push notifications';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionLocationSubtitle =>
      'Required to get your current coordinates';

  @override
  String get permissionGallery => 'Photo Library';

  @override
  String get permissionGallerySubtitle =>
      'Required for selecting existing images or videos';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionDenied => 'Denied';

  @override
  String get permissionPermanentlyDenied => 'Permanently denied';

  @override
  String get requestPermission => 'Request';

  @override
  String get openAppSettings => 'Open App Settings';

  @override
  String get appTheme => 'App Theme';

  @override
  String get appThemeSubtitle => 'Appearance preference';

  @override
  String get mobility => 'Mobility';

  @override
  String get wheelchairRoutes => 'Wheelchair Routes';

  @override
  String get wheelchairRoutesSubtitle =>
      'Prioritize Wheelchair Accessible Routes';

  @override
  String get connectEmotiv => 'Connect to Emotiv EPOC+';

  @override
  String get connectBluetoothSubtitle => 'Connect via Bluetooth';

  @override
  String get navigationAudio => 'Navigation & Audio';

  @override
  String get audioFeedback => 'Audio Feedback';

  @override
  String get audioFeedbackSubtitle => 'Enable sound effects and cues';

  @override
  String get audioNavigation => 'Audio Navigation';

  @override
  String get audioNavigationSubtitle => 'Enable Spoken Feedback';

  @override
  String get speechRate => 'Speech Rate';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get accessibilityProfile => 'Accessibility Profile';

  @override
  String get wheelchairProfile => 'Wheelchair';

  @override
  String get lowVisionProfile => 'Low Vision';

  @override
  String get blindProfile => 'Blind';

  @override
  String get applyProfileSettings => 'Apply Profile Settings';

  @override
  String get accessibilityProfileDescriptionWheelchair =>
      'Routes will use wheelchair-friendly path weights.';

  @override
  String get accessibilityProfileDescriptionBlind =>
      'Routes will use blind-friendly path weights.';

  @override
  String get accessibilityProfileDescriptionBoth =>
      'Low vision mode is enabled: high contrast, large text, audio feedback, navigation, and haptic assistance.';

  @override
  String get accessibilityProfileDescriptionNone =>
      'Standard routing will be used.';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get hapticFeedbackSubtitle => 'Enable Vibration';

  @override
  String get highContrast => 'High Contrast';

  @override
  String get highContrastSubtitle => 'Enable Stronger Colors';

  @override
  String get largeText => 'Large Text';

  @override
  String get largeTextSubtitle => 'Enable Bigger Font Sizes';

  @override
  String get account => 'Account';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get changeEmailNotification => 'Email change request sent.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordNotification => 'Password reset request sent.';

  @override
  String get logOut => 'Log Out';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changeAppLanguage => 'Change App Language';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to access your profile.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Log In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createAccountTitle => 'Create an Account';

  @override
  String get signupSubtitle => 'Join us! Create your profile here.';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get agreeTerms => 'I Agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get gdprCompliant => ' (GDPR Compliant)';

  @override
  String get signUp => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already Have an Account';

  @override
  String get continueWithoutAccount => 'Continue Without Account';

  @override
  String get continueWithoutAccountHint =>
      'You can continue without an account, but the experience will be different.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email to receive recovery instructions.';

  @override
  String get sendRecoveryLink => 'Send Recovery Link';

  @override
  String get backToLogin => 'Back to Log In';

  @override
  String get invalidCredentials => 'Invalid credentials. Please try again.';

  @override
  String get nameRequired => 'Full Name is required.';

  @override
  String get invalidEmail => 'Invalid email address.';

  @override
  String get passwordLength => 'Password must be at least 8 characters.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get previousLanguage => 'Previous';

  @override
  String get cancel => 'Cancel';

  @override
  String recoveryLinkSent(String email) {
    return 'Recovery link sent to $email';
  }

  @override
  String get navMap => 'Map';

  @override
  String get navGoTo => 'Go To';

  @override
  String get navDiary => 'Diary';

  @override
  String get navProfile => 'Profile';

  @override
  String get sessionExpiredLogoutMessage => 'Your session expired.';

  @override
  String get goToProfile => 'Login';

  @override
  String get faqSubtitle => 'Frequently Asked Questions';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get slow => 'Slow';

  @override
  String get fast => 'Fast';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get custom => 'Custom';

  @override
  String get animationsMotion => 'Animations & Motion';

  @override
  String get animationsMotionSubtitle => 'Control UI Animation and Movement';

  @override
  String get enableAnimations => 'Enable Animations';

  @override
  String get enableAnimationsSubtitle => 'Controls transitions and UI effects';

  @override
  String get pulsingBadges => 'Pulsing Badges';

  @override
  String get pulsingBadgesSubtitle => 'Allows notifications to pulse';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String instruction(String command) {
    return 'Instruction: $command';
  }

  @override
  String get attention => 'Attention';

  @override
  String get engagement => 'Engagement';

  @override
  String get excitement => 'Excitement';

  @override
  String get stress => 'Stress';

  @override
  String get relaxation => 'Relaxation';

  @override
  String get interest => 'Interest';
}
