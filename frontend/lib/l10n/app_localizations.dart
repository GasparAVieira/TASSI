import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation Diary'**
  String get appTitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @gdpr.
  ///
  /// In en, this message translates to:
  /// **'GDPR'**
  String get gdpr;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable alerts for notifications'**
  String get pushNotificationsSubtitle;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get appPermissions;

  /// No description provided for @appPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage application\'s permissions'**
  String get appPermissionsSubtitle;

  /// No description provided for @locationPermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequiredTitle;

  /// No description provided for @locationPermissionRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please allow location access to continue.'**
  String get locationPermissionRequiredSubtitle;

  /// No description provided for @grantLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Location Permission'**
  String get grantLocationPermission;

  /// No description provided for @locationPermissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to use this app.'**
  String get locationPermissionRequiredMessage;

  /// No description provided for @locationPermissionRequiredOpenSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to use this app. Open settings to enable it.'**
  String get locationPermissionRequiredOpenSettingsMessage;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for taking new images or videos'**
  String get permissionCameraSubtitle;

  /// No description provided for @permissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionMicrophone;

  /// No description provided for @permissionMicrophoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for capturing video sound'**
  String get permissionMicrophoneSubtitle;

  /// No description provided for @permissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotifications;

  /// No description provided for @permissionNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for receiving push notifications'**
  String get permissionNotificationsSubtitle;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionLocation;

  /// No description provided for @permissionLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required to get your current coordinates'**
  String get permissionLocationSubtitle;

  /// No description provided for @permissionGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get permissionGallery;

  /// No description provided for @permissionGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for selecting existing images or videos'**
  String get permissionGallerySubtitle;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permanently denied'**
  String get permissionPermanentlyDenied;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestPermission;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @appThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance preference'**
  String get appThemeSubtitle;

  /// No description provided for @mobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get mobility;

  /// No description provided for @wheelchairRoutes.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Routes'**
  String get wheelchairRoutes;

  /// No description provided for @wheelchairRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prioritize Wheelchair Accessible Routes'**
  String get wheelchairRoutesSubtitle;

  /// No description provided for @connectEmotiv.
  ///
  /// In en, this message translates to:
  /// **'Connect to Emotiv EPOC+'**
  String get connectEmotiv;

  /// No description provided for @connectBluetoothSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect via Bluetooth'**
  String get connectBluetoothSubtitle;

  /// No description provided for @navigationAudio.
  ///
  /// In en, this message translates to:
  /// **'Navigation & Audio'**
  String get navigationAudio;

  /// No description provided for @audioFeedback.
  ///
  /// In en, this message translates to:
  /// **'Audio Feedback'**
  String get audioFeedback;

  /// No description provided for @audioFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable sound effects and cues'**
  String get audioFeedbackSubtitle;

  /// No description provided for @audioNavigation.
  ///
  /// In en, this message translates to:
  /// **'Audio Navigation'**
  String get audioNavigation;

  /// No description provided for @audioNavigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Spoken Feedback'**
  String get audioNavigationSubtitle;

  /// No description provided for @speechRate.
  ///
  /// In en, this message translates to:
  /// **'Speech Rate'**
  String get speechRate;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @accessibilityProfile.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Profile'**
  String get accessibilityProfile;

  /// No description provided for @wheelchairProfile.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get wheelchairProfile;

  /// No description provided for @lowVisionProfile.
  ///
  /// In en, this message translates to:
  /// **'Low Vision'**
  String get lowVisionProfile;

  /// No description provided for @blindProfile.
  ///
  /// In en, this message translates to:
  /// **'Blind'**
  String get blindProfile;

  /// No description provided for @applyProfileSettings.
  ///
  /// In en, this message translates to:
  /// **'Apply Profile Settings'**
  String get applyProfileSettings;

  /// No description provided for @accessibilityProfileDescriptionWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Routes will use wheelchair-friendly path weights.'**
  String get accessibilityProfileDescriptionWheelchair;

  /// No description provided for @accessibilityProfileDescriptionBlind.
  ///
  /// In en, this message translates to:
  /// **'Routes will use blind-friendly path weights.'**
  String get accessibilityProfileDescriptionBlind;

  /// No description provided for @accessibilityProfileDescriptionBoth.
  ///
  /// In en, this message translates to:
  /// **'Low vision mode is enabled: high contrast, large text, audio feedback, navigation, and haptic assistance.'**
  String get accessibilityProfileDescriptionBoth;

  /// No description provided for @accessibilityProfileDescriptionNone.
  ///
  /// In en, this message translates to:
  /// **'Standard routing will be used.'**
  String get accessibilityProfileDescriptionNone;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Vibration'**
  String get hapticFeedbackSubtitle;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get highContrast;

  /// No description provided for @highContrastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Stronger Colors'**
  String get highContrastSubtitle;

  /// No description provided for @largeText.
  ///
  /// In en, this message translates to:
  /// **'Large Text'**
  String get largeText;

  /// No description provided for @largeTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Bigger Font Sizes'**
  String get largeTextSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @changeEmailNotification.
  ///
  /// In en, this message translates to:
  /// **'Email change request sent.'**
  String get changeEmailNotification;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordNotification.
  ///
  /// In en, this message translates to:
  /// **'Password reset request sent.'**
  String get resetPasswordNotification;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change App Language'**
  String get changeAppLanguage;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your profile.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get createAccountTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us! Create your profile here.'**
  String get signupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I Agree to the '**
  String get agreeTerms;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @gdprCompliant.
  ///
  /// In en, this message translates to:
  /// **' (GDPR Compliant)'**
  String get gdprCompliant;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already Have an Account'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue Without Account'**
  String get continueWithoutAccount;

  /// No description provided for @continueWithoutAccountHint.
  ///
  /// In en, this message translates to:
  /// **'You can continue without an account, but the experience will be different.'**
  String get continueWithoutAccountHint;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive recovery instructions.'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Link'**
  String get sendRecoveryLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Log In'**
  String get backToLogin;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please try again.'**
  String get invalidCredentials;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required.'**
  String get nameRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @previousLanguage.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @recoveryLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Recovery link sent to {email}'**
  String recoveryLinkSent(String email);

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go To'**
  String get navGoTo;

  /// No description provided for @navDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get navDiary;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @sessionExpiredLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired.'**
  String get sessionExpiredLogoutMessage;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get goToProfile;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @animationsMotion.
  ///
  /// In en, this message translates to:
  /// **'Animations & Motion'**
  String get animationsMotion;

  /// No description provided for @animationsMotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control UI Animation and Movement'**
  String get animationsMotionSubtitle;

  /// No description provided for @enableAnimations.
  ///
  /// In en, this message translates to:
  /// **'Enable Animations'**
  String get enableAnimations;

  /// No description provided for @enableAnimationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Controls transitions and UI effects'**
  String get enableAnimationsSubtitle;

  /// No description provided for @pulsingBadges.
  ///
  /// In en, this message translates to:
  /// **'Pulsing Badges'**
  String get pulsingBadges;

  /// No description provided for @pulsingBadgesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allows notifications to pulse'**
  String get pulsingBadgesSubtitle;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction: {command}'**
  String instruction(String command);

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @engagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get engagement;

  /// No description provided for @excitement.
  ///
  /// In en, this message translates to:
  /// **'Excitement'**
  String get excitement;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @relaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get relaxation;

  /// No description provided for @interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interest;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
