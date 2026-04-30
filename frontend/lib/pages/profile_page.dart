import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../models/accessibility_profile.dart';
import '../services/settings_service.dart';
import '../services/accessibility_profile_service.dart';
import '../services/epoc_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/accessibility_profile_picker.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/faq_widgets.dart';
import '../widgets/gdpr_widgets.dart';

class ProfilePage extends StatelessWidget {
  final int initialTabIndex;

  const ProfilePage({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final SettingsService settings = SettingsService();

    return DefaultTabController(
      length: 4,
      initialIndex: initialTabIndex,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              // Horizontal Navigation TabBar Card
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) {
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: SizedBox(
                          height: 48, // Strictly fixed height
                          child: TabBar(
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: settings.isHighContrast
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                            ),
                            splashBorderRadius: BorderRadius.circular(8),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: settings.isHighContrast
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                            unselectedLabelColor:
                                theme.colorScheme.onSurfaceVariant,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            labelStyle: TextStyle(
                              fontSize: settings.useLargeText ? 14 : 12,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            tabs: [
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person, size: 18),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.profile,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.settings, size: 18),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.settings,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.help, size: 18),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.faq,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.security, size: 18),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.gdpr,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Tab Views
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: const TabBarView(
                    physics: ClampingScrollPhysics(),
                    children: [
                      _ProfileTabContent(),
                      _SettingsTabContent(),
                      FAQTabContent(),
                      GDPRTabContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AuthView { login, signup, resetPassword }

class _ProfileTabContent extends StatefulWidget {
  const _ProfileTabContent();

  @override
  State<_ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<_ProfileTabContent>
    with AutomaticKeepAliveClientMixin {
  _AuthView _currentView = _AuthView.login;

  // Shared controllers for data preservation across views and tabs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _profileNameController = TextEditingController();
  final _profilePhoneController = TextEditingController();
  final _profileBioController = TextEditingController();
  PhoneNumber _profilePhoneNumber = PhoneNumber(isoCode: 'PT');
  String _profileRawPhoneNumber = '';
  String _profilePhoneDisplay = 'Not set yet';
  final AuthService _authService = AuthService();
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
    _loadProfileData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadProfileData() async {
    await _authService.loadSession();
    if (!mounted) return;
    await _syncProfileControllers();
    if (!mounted) return;
    setState(() {
      _isProfileLoading = false;
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _profileNameController.dispose();
    _profilePhoneController.dispose();
    _profileBioController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_authService.isLoggedIn) {
      _syncProfileControllers().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isProfileLoading = false;
        });
      });
    } else {
      _profileNameController.clear();
      _profilePhoneController.clear();
      _profileBioController.clear();
      _profilePhoneDisplay = 'Not set yet';
      _profilePhoneNumber = PhoneNumber(isoCode: 'PT');
      _profileRawPhoneNumber = '';
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _syncProfileControllers() async {
    if (!_authService.isLoggedIn) {
      setState(() {});
      return;
    }

    _profileNameController.text = _authService.userName ?? '';
    _profileBioController.text = _authService.bio ?? '';
    _profileRawPhoneNumber = _authService.phone?.trim() ?? '';

    if (_profileRawPhoneNumber.isNotEmpty) {
      try {
        final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
          _profileRawPhoneNumber,
          'PT',
        );
        _profilePhoneNumber = parsed;
        _profilePhoneController.text = parsed.phoneNumber ?? _profileRawPhoneNumber;
        if (parsed.dialCode != null && parsed.dialCode!.trim().isNotEmpty) {
          final originalDialCode = parsed.dialCode!.trim();
          final dialCode = originalDialCode.startsWith('+')
              ? originalDialCode
              : '+$originalDialCode';
          final numberPart = parsed.phoneNumber?.trim() ?? _profileRawPhoneNumber;
          final national = numberPart.startsWith(dialCode)
              ? numberPart.substring(dialCode.length).trimLeft()
              : numberPart.startsWith(originalDialCode)
                  ? numberPart.substring(originalDialCode.length).trimLeft()
                  : numberPart.startsWith('+$originalDialCode')
                      ? numberPart.substring(originalDialCode.length + 1).trimLeft()
                      : numberPart;
          _profilePhoneDisplay = '$dialCode $national';
        } else {
          _profilePhoneDisplay = parsed.phoneNumber ?? _profileRawPhoneNumber;
        }
      } catch (_) {
        _profilePhoneNumber = PhoneNumber(isoCode: 'PT');
        _profilePhoneController.text = '';
        _profilePhoneDisplay = 'Could not retrieve a valid phone number';
      }
    } else {
      _profilePhoneNumber = PhoneNumber(isoCode: 'PT');
      _profilePhoneController.text = '';
      _profilePhoneDisplay = 'Not set yet';
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveProfileEdits() async {
    final rawPhone = _profileRawPhoneNumber.trim();

    await _authService.updateLocalProfile(
      fullName: _profileNameController.text.trim(),
      phone: rawPhone,
      bio: _profileBioController.text.trim(),
      accessibilityProfile: _authService.accessibilityProfile ?? AccessibilityProfile.None,
    );
    await _syncProfileControllers();
  }

  void _cancelProfileEdits() {
    _syncProfileControllers();
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _toggleProfileEditing() async {
    if (_isEditingProfile) {
      setState(() {
        _isSavingProfile = true;
      });
      try {
        await _saveProfileEdits();
        setState(() {
          _isEditingProfile = false;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSavingProfile = false;
          });
        }
      }
      return;
    }

    setState(() {
      _isEditingProfile = true;
    });
  }

  void _setView(_AuthView view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          _authService.isLoggedIn ? _buildLoggedInCard() : _buildActiveCard(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildLoggedInCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeaderCard(
            name: _authService.userName ?? _authService.userEmail ?? '',
            role: _authService.role ?? 'user',
            onLogoutConfirm: () async {
              await _authService.logout();
              _setView(_AuthView.login);
            },
          ),
          const SizedBox(height: 10),
          ProfileStatsCard(
            email: _authService.userEmail ?? 'Not available',
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: AccessibilityProfileService(),
            builder: (context, _) {
              final accessibilityService = AccessibilityProfileService();
              return AccessibilityProfilePicker(
                wheelchairEnabled: accessibilityService.wheelchairEnabled,
                lowVisionEnabled: accessibilityService.lowVisionEnabled,
                blindEnabled: accessibilityService.blindEnabled,
                onWheelchairChanged: (value) =>
                    accessibilityService.setWheelchairEnabled(value),
                onLowVisionChanged: (value) =>
                    accessibilityService.setLowVisionEnabled(value),
                onBlindChanged: (value) =>
                    accessibilityService.setBlindEnabled(value),
                showApplyButton: true,
                onApply: accessibilityService.applyProfile,
              );
            },
          ),
          const SizedBox(height: 10),
          ProfileDetailsCard(
            isLoading: _isProfileLoading,
            isEditing: _isEditingProfile,
            isSaving: _isSavingProfile,
            nameController: _profileNameController,
            phoneController: _profilePhoneController,
            bioController: _profileBioController,
            phoneNumber: _profilePhoneNumber,
            phoneDisplayValue: _profilePhoneDisplay,
            onPhoneNumberChanged: (PhoneNumber phoneNumber) {
                _profilePhoneNumber = phoneNumber;
                _profileRawPhoneNumber = phoneNumber.phoneNumber ?? '';
                final originalDialCode = phoneNumber.dialCode?.trim() ?? '';
                final dialCode = originalDialCode.startsWith('+')
                    ? originalDialCode
                    : (originalDialCode.isNotEmpty ? '+$originalDialCode' : '');
                final numberPart = phoneNumber.phoneNumber?.trim() ?? '';
                final formattedNumber = dialCode.isNotEmpty
                    ? numberPart.startsWith(dialCode)
                        ? numberPart.substring(dialCode.length).trimLeft()
                        : numberPart.startsWith(originalDialCode)
                            ? numberPart.substring(originalDialCode.length).trimLeft()
                            : numberPart.startsWith('+$originalDialCode')
                                ? numberPart.substring(originalDialCode.length + 1).trimLeft()
                                : numberPart
                    : numberPart;
                _profilePhoneDisplay = dialCode.isNotEmpty
                    ? '$dialCode $formattedNumber'
                    : formattedNumber;
              },
              onToggleEditing: _toggleProfileEditing,
              onCancelEditing: _cancelProfileEdits,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveCard() {
    switch (_currentView) {
      case _AuthView.login:
        return Column(
          children: [
            LoginCard(
              emailController: _emailController,
              passwordController: _passwordController,
              onLogin: (email, password) async {
                final success = await _authService.login(email, password);
                if (success) {
                  _emailController.clear();
                  _passwordController.clear();
                }
                return success;
              },
              onSwitchToSignup: () => _setView(_AuthView.signup),
              onForgotPassword: () => _setView(_AuthView.resetPassword),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListenableBuilder(
                listenable: AccessibilityProfileService(),
                builder: (context, _) {
                  final accessibilityService = AccessibilityProfileService();
                  return AccessibilityProfilePicker(
                    wheelchairEnabled: accessibilityService.wheelchairEnabled,
                    lowVisionEnabled: accessibilityService.lowVisionEnabled,
                    blindEnabled: accessibilityService.blindEnabled,
                    onWheelchairChanged: (value) =>
                        accessibilityService.setWheelchairEnabled(value),
                    onLowVisionChanged: (value) =>
                        accessibilityService.setLowVisionEnabled(value),
                    onBlindChanged: (value) =>
                        accessibilityService.setBlindEnabled(value),
                    showApplyButton: true,
                    onApply: accessibilityService.applyProfile,
                  );
                },
              ),
            ),
          ],
        );
      case _AuthView.signup:
        return Column(
          children: [
            SignupCard(
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              onSignup: (name, email, password, confirmPassword) async {
                final accessibilityService = AccessibilityProfileService();
                final success = await _authService.signup(
                  name,
                  email,
                  password,
                  confirmPassword,
                  accessibilityService.selectedProfile,
                );
                if (success) {
                  _nameController.clear();
                  _emailController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                }
                return success;
              },
              onSwitchToLogin: () => _setView(_AuthView.login),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListenableBuilder(
                listenable: AccessibilityProfileService(),
                builder: (context, _) {
                  final accessibilityService = AccessibilityProfileService();
                  return AccessibilityProfilePicker(
                    wheelchairEnabled: accessibilityService.wheelchairEnabled,
                    lowVisionEnabled: accessibilityService.lowVisionEnabled,
                    blindEnabled: accessibilityService.blindEnabled,
                    onWheelchairChanged: (value) =>
                        accessibilityService.setWheelchairEnabled(value),
                    onLowVisionChanged: (value) =>
                        accessibilityService.setLowVisionEnabled(value),
                    onBlindChanged: (value) =>
                        accessibilityService.setBlindEnabled(value),
                    showApplyButton: true,
                    onApply: accessibilityService.applyProfile,
                  );
                },
              ),
            ),
          ],
        );
      case _AuthView.resetPassword:
        return Column(
          children: [
            ResetPasswordCard(
              emailController: _emailController,
              onReset: (email) async => await _authService.resetPassword(email),
              onBackToLogin: () => _setView(_AuthView.login),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListenableBuilder(
                listenable: AccessibilityProfileService(),
                builder: (context, _) {
                  final accessibilityService = AccessibilityProfileService();
                  return AccessibilityProfilePicker(
                    wheelchairEnabled: accessibilityService.wheelchairEnabled,
                    lowVisionEnabled: accessibilityService.lowVisionEnabled,
                    blindEnabled: accessibilityService.blindEnabled,
                    onWheelchairChanged: (value) =>
                        accessibilityService.setWheelchairEnabled(value),
                    onLowVisionChanged: (value) =>
                        accessibilityService.setLowVisionEnabled(value),
                    onBlindChanged: (value) =>
                        accessibilityService.setBlindEnabled(value),
                    showApplyButton: true,
                    onApply: accessibilityService.applyProfile,
                  );
                },
              ),
            ),
          ],
        );
    }
  }
}

class _SettingsTabContent extends StatefulWidget {
  const _SettingsTabContent();

  @override
  State<_SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<_SettingsTabContent> {
  final AuthService _authService = AuthService();
  final SettingsService _settings = SettingsService();
  bool _showEpocPanel = false;
  bool _showPercentages = false;

  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  PermissionStatus _microphonePermissionStatus = PermissionStatus.denied;
  PermissionStatus _notificationPermissionStatus = PermissionStatus.denied;
  PermissionStatus _galleryPermissionStatus = PermissionStatus.denied;
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handlePushNotificationsChanged(bool value) async {
    if (!value) {
      await _settings.setPushNotificationsEnabled(false);
      return;
    }

    final granted = await _requestPermission(
      Permission.notification,
      'notifications',
    );

    await _settings.setPushNotificationsEnabled(granted);
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final initialLocale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentLocale = Localizations.localeOf(context);
            final theme = Theme.of(context);
            final size = MediaQuery.of(context).size;

            return Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCustomDragHandle(theme),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      l10n.selectLanguage,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildSelectionTile(
                          context,
                          title: 'English',
                          subtitle: 'EN',
                          previousLanguageLabel: 'Previous',
                          isSelected: currentLocale.languageCode == 'en',
                          isInitial: initialLocale.languageCode == 'en',
                          onTap: () async {
                            final currentContext = context;
                            await _settings.setPreferredLanguageCode('en');
                            if (_authService.isLoggedIn) {
                              await _authService.setPreferredLanguageCode('en');
                            }
                            if (!currentContext.mounted) return;
                            MyApp.setLocale(currentContext, const Locale('en'));
                            setModalState(() {});
                          },
                        ),
                        _buildSelectionTile(
                          context,
                          title: 'Português',
                          subtitle: 'PT',
                          previousLanguageLabel: 'Anterior',
                          isSelected: currentLocale.languageCode == 'pt',
                          isInitial: initialLocale.languageCode == 'pt',
                          onTap: () async {
                            final currentContext = context;
                            await _settings.setPreferredLanguageCode('pt');
                            if (_authService.isLoggedIn) {
                              await _authService.setPreferredLanguageCode('pt');
                            }
                            if (!currentContext.mounted) return;
                            MyApp.setLocale(currentContext, const Locale('pt'));
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    final initialThemeMode = _settings.themeMode;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final size = MediaQuery.of(context).size;

            return Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCustomDragHandle(theme),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      l10n.appTheme,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildSelectionTile(
                          context,
                          title: l10n.themeSystem,
                          icon: Icons.brightness_auto,
                          isSelected: _settings.themeMode == ThemeMode.system,
                          isInitial: initialThemeMode == ThemeMode.system,
                          onTap: () {
                            _settings.setThemeMode('System');
                            setModalState(() {});
                          },
                        ),
                        _buildSelectionTile(
                          context,
                          title: l10n.themeLight,
                          icon: Icons.light_mode,
                          isSelected: _settings.themeMode == ThemeMode.light,
                          isInitial: initialThemeMode == ThemeMode.light,
                          onTap: () {
                            _settings.setThemeMode('Light');
                            setModalState(() {});
                          },
                        ),
                        _buildSelectionTile(
                          context,
                          title: l10n.themeDark,
                          icon: Icons.dark_mode,
                          isSelected: _settings.themeMode == ThemeMode.dark,
                          isInitial: initialThemeMode == ThemeMode.dark,
                          onTap: () {
                            _settings.setThemeMode('Dark');
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAnimationsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            final theme = Theme.of(context);
            final size = MediaQuery.of(context).size;

            return Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCustomDragHandle(theme),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      l10n.animationsMotion,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildSwitchTile(
                          context,
                          title: l10n.enableAnimations,
                          subtitle: l10n.enableAnimationsSubtitle,
                          icon: Icons.movie_filter_outlined,
                          value: _settings.isAnimationsEnabled,
                          onChanged: (val) =>
                              _settings.setAnimationsEnabled(val),
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          context,
                          title: l10n.pulsingBadges,
                          subtitle: l10n.pulsingBadgesSubtitle,
                          icon: Icons.blur_on,
                          value: _settings.isPulsingEnabled,
                          onChanged: (val) => _settings.setPulsingEnabled(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomDragHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 4,
      width: double.infinity,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? previousLanguageLabel,
    IconData? icon,
    required bool isSelected,
    required bool isInitial,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return ListTile(
      leading: icon != null
          ? Icon(icon, color: color)
          : subtitle != null
          ? CircleAvatar(
              backgroundColor: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              radius: 16,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isInitial && !isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                previousLanguageLabel ?? l10n.previousLanguage,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      tileColor: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final languageName = currentLocale.languageCode == 'en'
        ? 'English'
        : 'Português';

    // Map theme mode to localized label
    String currentThemeLabel = l10n.themeSystem;
    if (_settings.themeMode == ThemeMode.light) {
      currentThemeLabel = l10n.themeLight;
    }
    if (_settings.themeMode == ThemeMode.dark) {
      currentThemeLabel = l10n.themeDark;
    }

    // Calculate enabled animations count
    int enabledCount = 0;
    if (_settings.isAnimationsEnabled) enabledCount++;
    if (_settings.isPulsingEnabled) enabledCount++;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General section
            _buildSectionHeader(theme, l10n.general),
            _buildSettingsCard(
              theme,
              children: [
                _buildSwitchTile(
                  context,
                  title: l10n.pushNotifications,
                  subtitle: l10n.pushNotificationsSubtitle,
                  icon: Icons.notifications_active_outlined,
                  value: _settings.pushNotificationsEnabled,
                  onChanged: (val) {
                    _handlePushNotificationsChanged(val);
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: l10n.appPermissions,
                  subtitle: l10n.appPermissionsSubtitle,
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _showPermissionsBottomSheet(context),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: l10n.appTheme,
                  subtitle: l10n.appThemeSubtitle,
                  icon: Icons.palette_outlined,
                  showChevron: false,
                  trailing: Text(
                    currentThemeLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showThemeBottomSheet(context),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: l10n.changeLanguage,
                  subtitle: l10n.changeAppLanguage,
                  icon: Icons.language,
                  showChevron: false,
                  trailing: Text(
                    languageName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showLanguageBottomSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Mobility section
            _buildSectionHeader(theme, l10n.mobility),
            _buildSettingsCard(
              theme,
              children: [
                _buildSwitchTile(
                  context,
                  title: l10n.wheelchairRoutes,
                  subtitle: l10n.wheelchairRoutesSubtitle,
                  icon: Icons.accessible_forward_outlined,
                  value: _settings.wheelchairRoutesEnabled,
                  onChanged: (val) =>
                      _settings.setWheelchairRoutesEnabled(val),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: l10n.connectEmotiv,
                  subtitle: l10n.connectBluetoothSubtitle,
                  icon: Icons.bluetooth,
                  onTap: () {
                    setState(() {
                      _showEpocPanel = !_showEpocPanel;
                    });
                  },
                ),
                if (_showEpocPanel) ...[
                  const Divider(height: 1),
                  _buildEpocPanel(context),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Navigation audio section
            _buildSectionHeader(theme, l10n.navigationAudio),
            _buildSettingsCard(
              theme,
              children: [
                _buildSwitchTile(
                  context,
                  title: l10n.audioFeedback,
                  subtitle: l10n.audioFeedbackSubtitle,
                  icon: Icons.volume_up_outlined,
                  value: _settings.audioFeedbackEnabled,
                  onChanged: (val) =>
                      _settings.setAudioFeedbackEnabled(val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  context,
                  title: l10n.audioNavigation,
                  subtitle: l10n.audioNavigationSubtitle,
                  icon: Icons.record_voice_over_outlined,
                  value: _settings.audioNavigationEnabled,
                  onChanged: (val) =>
                      _settings.setAudioNavigationEnabled(val),
                ),
                if (_settings.audioNavigationEnabled) ...[
                  const Divider(height: 1),
                  _buildSliderTile(
                    context,
                    title: l10n.speechRate,
                    value: _settings.audioSpeechRate,
                    onChanged: (val) => _settings.setAudioSpeechRate(val),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Accessibility section
            _buildSectionHeader(theme, l10n.accessibility),
            _buildSettingsCard(
              theme,
              children: [
                _buildSwitchTile(
                  context,
                  title: l10n.hapticFeedback,
                  subtitle: l10n.hapticFeedbackSubtitle,
                  icon: Icons.vibration,
                  value: _settings.hapticFeedbackEnabled,
                  onChanged: (val) => _settings.setHapticFeedbackEnabled(val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  context,
                  title: l10n.highContrast,
                  subtitle: l10n.highContrastSubtitle,
                  icon: Icons.contrast,
                  value: _settings.isHighContrast,
                  onChanged: (val) => _settings.setHighContrast(val),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  context,
                  title: l10n.largeText,
                  subtitle: l10n.largeTextSubtitle,
                  icon: Icons.text_fields,
                  value: _settings.useLargeText,
                  onChanged: (val) => _settings.setLargeText(val),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: l10n.animationsMotion,
                  subtitle: l10n.animationsMotionSubtitle,
                  icon: Icons.auto_awesome_motion_outlined,
                  showChevron: false,
                  trailing: Text(
                    '$enabledCount/2',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showAnimationsBottomSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_authService.isLoggedIn) ...[
              // Account section
              _buildSectionHeader(theme, l10n.account),
              _buildSettingsCard(
                theme,
                children: [
                  _buildActionTile(
                    context,
                    title: l10n.changeEmail,
                    icon: Icons.email_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.changeEmailNotification),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    context,
                    title: l10n.resetPassword,
                    icon: Icons.lock_reset_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.resetPasswordNotification),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    context,
                    title: l10n.logOut,
                    icon: Icons.logout,
                    textColor: theme.colorScheme.error,
                    iconColor: theme.colorScheme.error,
                    onTap: () async {
                      await _authService.logout();
                      if (mounted) setState(() {});
                    }
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: (val) => onChanged(val)),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
              Text(
                '${value.toStringAsFixed(1)}x',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(l10n.slow, style: theme.textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${value.toStringAsFixed(1)}x',
                  onChanged: onChanged,
                ),
              ),
              Text(l10n.fast, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEpocPanel(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final epocService = EpocService();

    return ListenableBuilder(
      listenable: epocService,
      builder: (context, _) {
        final isRunning = epocService.isRunning;
        final metrics = epocService.lastMetrics;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (isRunning) {
                          epocService.stop();
                        } else {
                          epocService.startDummy();
                        }
                      },
                      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(isRunning ? l10n.disconnect : l10n.connect),
                      style: FilledButton.styleFrom(
                        backgroundColor: isRunning ? theme.colorScheme.error : null,
                        foregroundColor: isRunning ? theme.colorScheme.onError : null,
                      ),
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _showPercentages = !_showPercentages;
                        });
                      },
                      icon: Icon(_showPercentages ? Icons.abc : Icons.percent),
                      tooltip: _showPercentages ? "Show Codes" : "Show Percentages",
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 8,
                childAspectRatio: 1.25,
                children: [
                  _EpocMetricCircle(
                    label: l10n.attention,
                    code: 'AT',
                    value: metrics['attention'],
                    color: Colors.blue,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                  _EpocMetricCircle(
                    label: l10n.engagement,
                    code: 'EN',
                    value: metrics['engagement'],
                    color: Colors.green,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                  _EpocMetricCircle(
                    label: l10n.excitement,
                    code: 'EX',
                    value: metrics['excitement'],
                    color: Colors.orange,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                  _EpocMetricCircle(
                    label: l10n.stress,
                    code: 'ST',
                    value: metrics['stress'],
                    color: Colors.red,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                  _EpocMetricCircle(
                    label: l10n.relaxation,
                    code: 'RE',
                    value: metrics['relaxation'],
                    color: Colors.teal,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                  _EpocMetricCircle(
                    label: l10n.interest,
                    code: 'IN',
                    value: metrics['interest'],
                    color: Colors.purple,
                    enabled: isRunning,
                    showPercentage: _showPercentages,
                  ),
                ],
              ),
              Center(
                child: Text(
                  l10n.instruction(epocService.lastCommand ?? '---'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isRunning ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // No dummy indicator shown in the UI; the service currently uses
              // either the real EPOC flow or the fallback simulation internally.
              if (isRunning) ...[
                 const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAppSettings() async {
    final opened = await openAppSettings();
    if (!opened) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open app settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPermissionsBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    await _refreshPermissionStatuses();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCustomDragHandle(theme),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      l10n.appPermissions,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildPermissionTile(
                          context,
                          title: l10n.permissionCamera,
                          subtitle: l10n.permissionCameraSubtitle,
                          status: _cameraPermissionStatus,
                          onPressed: () async {
                            await _requestPermission(
                              Permission.camera,
                              'camera',
                            );
                            await _refreshPermissionStatuses();
                            setModalState(() {});
                          },
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          context,
                          title: l10n.permissionMicrophone,
                          subtitle: l10n.permissionMicrophoneSubtitle,
                          status: _microphonePermissionStatus,
                          onPressed: () async {
                            await _requestPermission(
                              Permission.microphone,
                              'microphone',
                            );
                            await _refreshPermissionStatuses();
                            setModalState(() {});
                          },
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          context,
                          title: l10n.permissionNotifications,
                          subtitle: l10n.permissionNotificationsSubtitle,
                          status: _notificationPermissionStatus,
                          onPressed: () async {
                            await _requestPermission(
                              Permission.notification,
                              'notifications',
                            );
                            await _refreshPermissionStatuses();
                            setModalState(() {});
                          },
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          context,
                          title: l10n.permissionLocation,
                          subtitle: l10n.permissionLocationSubtitle,
                          status: _locationPermissionStatus,
                          onPressed: () async {
                            await _requestPermission(
                              Permission.location,
                              'location',
                            );
                            await _refreshPermissionStatuses();
                            setModalState(() {});
                          },
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          context,
                          title: l10n.permissionGallery,
                          subtitle: l10n.permissionGallerySubtitle,
                          status: _galleryPermissionStatus,
                          onPressed: () async {
                            await _requestGalleryPermission();
                            await _refreshPermissionStatuses();
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _openAppSettings,
                        child: Text(l10n.openAppSettings),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isRequestingPermission = false;

  Future<void> _refreshPermissionStatuses() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.location.status;
    final galleryStatus = await _getGalleryPermissionStatus();

    if (!mounted) return;
    setState(() {
      _cameraPermissionStatus = cameraStatus;
      _microphonePermissionStatus = microphoneStatus;
      _notificationPermissionStatus = notificationStatus;
      _locationPermissionStatus = locationStatus;
      _galleryPermissionStatus = galleryStatus;
    });
  }

  Future<PermissionStatus> _getGalleryPermissionStatus() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      final videosStatus = await Permission.videos.status;
      if (photosStatus.isGranted || videosStatus.isGranted) {
        return PermissionStatus.granted;
      }
      if (photosStatus.isPermanentlyDenied ||
          videosStatus.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }
      if (photosStatus.isDenied ||
          videosStatus.isDenied ||
          photosStatus.isRestricted ||
          videosStatus.isRestricted) {
        return PermissionStatus.denied;
      }
      return PermissionStatus.denied;
    }

    return Permission.photos.status;
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final photosGranted = await _requestPermission(
        Permission.photos,
        'photos',
      );
      if (!photosGranted) return false;
      return _requestPermission(Permission.videos, 'videos');
    }

    return _requestPermission(Permission.photos, 'photo library');
  }

  Future<bool> _requestPermission(Permission permission, String name) async {
    if (_isRequestingPermission) {
      return false;
    }

    _isRequestingPermission = true;
    try {
      final currentStatus = await permission.status;
      if (currentStatus.isGranted) return true;

      final status = await permission.request();
      if (status.isGranted) return true;
      if (!mounted) return false;

      final deniedMessage = permission == Permission.location
          ? 'Location permission is required to use this app.'
          : 'Allow $name permission to continue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deniedMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  String _permissionStatusLabel(
    AppLocalizations l10n,
    PermissionStatus status,
  ) {
    if (status.isGranted) return l10n.permissionGranted;
    return l10n.permissionDenied;
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = _permissionStatusLabel(l10n, status);
    final isGranted = status.isGranted;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isGranted
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          statusLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isGranted
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onPressed,
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing,
            if (showChevron) const SizedBox(width: 8),
          ],
          if (showChevron) const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _EpocMetricCircle extends StatelessWidget {
  final String label;
  final String code;
  final double? value;
  final Color color;
  final bool enabled;
  final bool showPercentage;

  const _EpocMetricCircle({
    required this.label,
    required this.code,
    required this.value,
    required this.color,
    required this.enabled,
    required this.showPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value ?? 0.0;
    final opacity = enabled ? 1.0 : 0.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          tween: Tween<double>(begin: 0, end: displayValue),
          builder: (context, val, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: val,
                    strokeWidth: 4,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5 * opacity),
                    valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: opacity)),
                  ),
                ),
                Text(
                  showPercentage ? "${(val * 100).toInt()}%" : code,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: showPercentage ? 11 : null,
                    color: theme.colorScheme.onSurface.withValues(alpha: opacity),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: opacity),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
