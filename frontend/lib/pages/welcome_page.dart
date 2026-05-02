import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/accessibility_profile_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../widgets/accessibility_profile_picker.dart';
import '../widgets/auth_widgets.dart';

const String _kHasSeenWelcomePageKey = 'has_seen_welcome_page';

enum _AuthView { login, signup, resetPassword }

class WelcomePage extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomePage({super.key, required this.onContinue});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final AccessibilityProfileService _accessibilityService = AccessibilityProfileService();
  _AuthView _currentView = _AuthView.signup;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accessibilityService.resetFromSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessibleNavigation = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;
      if (accessibleNavigation) {
        _accessibilityService.setBlindEnabled(true, persist: true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setSeenWelcomePage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenWelcomePageKey, true);
  }

  Future<bool> _onLogin(String email, String password) async {
    final success = await AuthService.instance.login(email, password);
    if (success) {
      await _setSeenWelcomePage();
      widget.onContinue();
    }
    return success;
  }

  Future<bool> _onSignup(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final success = await AuthService.instance.signup(
      name,
      email,
      password,
      confirmPassword,
      _accessibilityService.selectedProfile,
    );
    if (success) {
      await _setSeenWelcomePage();
      widget.onContinue();
    }
    return success;
  }

  Future<void> _onContinueWithoutAccount() async {
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation) {
      _accessibilityService.setBlindEnabled(true, persist: true);
    }

    await _setSeenWelcomePage();
    if (AuthService.instance.isLoggedIn) {
      await AuthService.instance.logout();
    }
    widget.onContinue();
  }

  void _switchToLogin() {
    setState(() {
      _currentView = _AuthView.login;
    });
  }

  void _switchToSignup() {
    setState(() {
      _currentView = _AuthView.signup;
    });
  }

  void _switchToResetPassword() {
    setState(() {
      _currentView = _AuthView.resetPassword;
    });
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
                            await SettingsService().setPreferredLanguageCode('en');
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
                            await SettingsService().setPreferredLanguageCode('pt');
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
    final authCard = _currentView == _AuthView.login
        ? LoginCard(
            emailController: _emailController,
            passwordController: _passwordController,
            onLogin: _onLogin,
            onSwitchToSignup: _switchToSignup,
            onForgotPassword: _switchToResetPassword,
          )
        : _currentView == _AuthView.signup
            ? SignupCard(
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                onSignup: _onSignup,
                onSwitchToLogin: _switchToLogin,
                accessibilityProfileWidget: ListenableBuilder(
                  listenable: _accessibilityService,
                  builder: (context, _) {
                    return AccessibilityProfilePicker(
                      wheelchairEnabled: _accessibilityService.wheelchairEnabled,
                      lowVisionEnabled: _accessibilityService.lowVisionEnabled,
                      blindEnabled: _accessibilityService.blindEnabled,
                      onWheelchairChanged: (value) =>
                          _accessibilityService.setWheelchairEnabled(value),
                      onLowVisionChanged: (value) =>
                          _accessibilityService.setLowVisionEnabled(value),
                      onBlindChanged: (value) =>
                          _accessibilityService.setBlindEnabled(value),
                      showApplyButton: false,
                      useCard: false,
                    );
                  },
                ),
              )
            : ResetPasswordCard(
                emailController: _emailController,
                onReset: (email) async {
                  return await AuthService.instance.resetPassword(email);
                },
                onBackToLogin: _switchToLogin,
              );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _onContinueWithoutAccount,
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text(
                      l10n.continueWithoutAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showLanguageBottomSheet(context),
                    icon: Icon(
                      Icons.translate,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: l10n.changeLanguage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 520),
                      child: authCard,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
