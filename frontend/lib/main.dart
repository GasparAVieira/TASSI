import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'pages/welcome_page.dart';
import 'services/auth_service.dart';
import 'services/diary_service.dart';
import 'services/feedback_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

// Main Pages
import 'pages/loading_screen.dart';

import 'pages/map_page.dart';
import 'pages/goto_page.dart';
import 'pages/diary_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settings = SettingsService();
  await settings.load();
  await FeedbackService().init();
  
  final authService = AuthService.instance;
  await authService.loadSession();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  final SettingsService _settings = SettingsService();
  final AuthService _authService = AuthService.instance;

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _authService.addListener(_onAuthChanged);
    _loadInitialSettings();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadInitialSettings() async {
    if (!mounted) return;

    final authLanguage = _authService.preferredLanguageCode;
    final settingsLanguage = _settings.preferredLanguageCode;
    final initialLocale = _settings.hasPreferredLanguageSetting
        ? Locale(settingsLanguage)
        : Locale(authLanguage.isNotEmpty ? authLanguage : settingsLanguage);

    setState(() {
      _locale = initialLocale;
      _isInitializing = false;
    });
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  void _onAuthChanged() {
    if (_isInitializing) return;
    final auth = _authService;
    if (auth.isLoggedIn &&
        auth.preferredLanguageCode.isNotEmpty &&
        _settings.preferredLanguageCode == 'pt' &&
        auth.preferredLanguageCode != _locale?.languageCode) {
      _settings.setPreferredLanguageCode(auth.preferredLanguageCode);
      setState(() {
        _locale = Locale(auth.preferredLanguageCode);
      });
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: AuthService.instance,
      child: MaterialApp(
        title: 'Navigation Diary',
        debugShowCheckedModeBanner: false,
        themeMode: _settings.themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: _settings.useLargeText ? const TextScaler.linear(1.15) : TextScaler.noScaling,
              highContrast: _settings.isHighContrast,
            ),
            child: child!,
          );
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        home: const LoadingScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const strongRed = Color(0xFFB00020);
    
    ColorScheme colorScheme;
    if (_settings.isHighContrast) {
      colorScheme = isDark
          ? const ColorScheme.dark(
              primary: Colors.yellow,
              onPrimary: Colors.black,
              secondary: Colors.cyanAccent,
              onSecondary: Colors.black,
              error: strongRed, 
              onError: Colors.white, // White text on red background
              surface: Colors.black,
              onSurface: Colors.white,
              surfaceContainerHighest: Color(0xFF333333),
              onSurfaceVariant: Colors.white,
              outline: Colors.white,
              outlineVariant: Colors.white,
            )
          : const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              secondary: Color(0xFF0000AA),
              onSecondary: Colors.white,
              error: strongRed, 
              onError: Colors.white, // White text on red background
              surface: Colors.white,
              onSurface: Colors.black,
              surfaceContainerHighest: Color(0xFFEEEEEE),
              onSurfaceVariant: Colors.black,
              outline: Colors.black,
              outlineVariant: Colors.black,
            );
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
        error: strongRed,
      ).copyWith(
        onError: Colors.white, // Ensure white text on red error backgrounds
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _settings.isHighContrast 
              ? BorderSide(color: colorScheme.onSurface, width: 2.0) 
              : BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimary);
          }
          return IconThemeData(color: colorScheme.onSurface);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold);
          }
          return TextStyle(color: colorScheme.onSurface);
        }),
      ),
    );
  }
}

Widget _buildPermissionScreen({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required String buttonText,
  required VoidCallback onPressed,
}) {
  final theme = Theme.of(context);
  return Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.appPermissions),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    ),
  );
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  Future<bool>? _initialization;
  bool _showWelcome = false;
  bool _hasSeenWelcome = false;
  PermissionStatus? _locationPermissionStatus;
  PermissionStatus? _bluetoothPermissionStatus;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    _initialization = _loadInitialState();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<bool> _loadInitialState() async {
    final preferences = await SharedPreferences.getInstance();
    _hasSeenWelcome = preferences.getBool('has_seen_welcome_page') ?? false;
    final isLoggedIn = AuthService.instance.isLoggedIn;
    _showWelcome = !isLoggedIn && !_hasSeenWelcome;
    if (!_showWelcome) {
      await _refreshPermissions();
    }
    return _showWelcome;
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final isLoggedIn = AuthService.instance.isLoggedIn;
    setState(() {
      _showWelcome = !isLoggedIn && !_hasSeenWelcome;
    });
  }

  Future<void> _refreshPermissions() async {
    final locationStatus = await Permission.location.status;
    final bluetoothStatus = await _getBluetoothPermissionStatus();
    if (!mounted) return;
    setState(() {
      _locationPermissionStatus = locationStatus;
      _bluetoothPermissionStatus = bluetoothStatus;
    });
  }

  Future<PermissionStatus> _getBluetoothPermissionStatus() async {
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    if (scanStatus.isGranted && connectStatus.isGranted) {
      return PermissionStatus.granted;
    }
    if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }
    return PermissionStatus.denied;
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return;
    setState(() {
      _locationPermissionStatus = status;
    });
  }

  Future<void> _requestBluetoothPermissions() async {
    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final bluetoothStatus = scanStatus.isGranted && connectStatus.isGranted
        ? PermissionStatus.granted
        : scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied
            ? PermissionStatus.permanentlyDenied
            : PermissionStatus.denied;
    if (!mounted) return;
    setState(() {
      _bluetoothPermissionStatus = bluetoothStatus;
    });
  }

  void _onWelcomeComplete() {
    if (!mounted) return;
    _refreshPermissions().then((_) {
      if (!mounted) return;
      setState(() {
        _hasSeenWelcome = true;
        _showWelcome = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const MainNavigationScreen();
        }

        final l10n = AppLocalizations.of(context)!;

        if (_showWelcome) {
          return WelcomePage(onContinue: _onWelcomeComplete);
        }

        if (_locationPermissionStatus == null || _bluetoothPermissionStatus == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_locationPermissionStatus!.isGranted) {
          final isPermanentlyDenied =
              _locationPermissionStatus == PermissionStatus.permanentlyDenied;
          return _buildPermissionScreen(
            context: context,
            icon: Icons.location_off,
            title: l10n.locationPermissionRequiredTitle,
            subtitle: l10n.locationPermissionRequiredSubtitle,
            buttonText: isPermanentlyDenied
                ? l10n.openAppSettings
                : l10n.grantLocationPermission,
            onPressed:
                isPermanentlyDenied ? openAppSettings : _requestLocationPermission,
          );
        }

        if (!_bluetoothPermissionStatus!.isGranted) {
          final isPermanentlyDenied =
              _bluetoothPermissionStatus == PermissionStatus.permanentlyDenied;
          return _buildPermissionScreen(
            context: context,
            icon: Icons.bluetooth_disabled,
            title: l10n.bluetoothPermissionRequiredTitle,
            subtitle: l10n.bluetoothPermissionRequiredSubtitle,
            buttonText: isPermanentlyDenied
                ? l10n.openAppSettings
                : l10n.grantBluetoothPermission,
            onPressed: isPermanentlyDenied
                ? openAppSettings
                : _requestBluetoothPermissions,
          );
        }

        return const MainNavigationScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int currentPageIndex = 0;
  int profileInitialTabIndex = 0;
  PermissionStatus? _locationPermissionStatus;
  PermissionStatus? _bluetoothPermissionStatus;
  final NotificationService _notificationService = NotificationService();
  final DiaryService _diaryService = DiaryService();
  bool _wasLoggedIn = AuthService.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
    _notificationService.addListener(_onNotificationChanged);
    _diaryService.addListener(_onDiaryChanged);
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.removeListener(_onNotificationChanged);
    _diaryService.removeListener(_onDiaryChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onNotificationChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onDiaryChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onAuthChanged() {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    if (_wasLoggedIn && !isLoggedIn && NotificationService().sessionExpiredLogout) {
      NotificationService().clearSessionExpiredLogout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        if (l10n == null) return;
        
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sessionExpiredLogoutMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      currentPageIndex = 3;
                      profileInitialTabIndex = 0;
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? theme.colorScheme.primary : theme.colorScheme.secondary,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.goToProfile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    _wasLoggedIn = isLoggedIn;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final status = await Permission.location.status;
    final bluetoothStatus = await _getBluetoothPermissionStatus();
    if (!mounted) return;
    setState(() {
      _locationPermissionStatus = status;
      _bluetoothPermissionStatus = bluetoothStatus;
    });
  }

  Future<PermissionStatus> _getBluetoothPermissionStatus() async {
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    if (scanStatus.isGranted && connectStatus.isGranted) {
      return PermissionStatus.granted;
    }
    if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }
    return PermissionStatus.denied;
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return;
    setState(() {
      _locationPermissionStatus = status;
    });
    if (!status.isGranted) {
      final l10n = AppLocalizations.of(context)!;
      final message = status.isPermanentlyDenied
          ? l10n.locationPermissionRequiredOpenSettingsMessage
          : l10n.locationPermissionRequiredMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final bluetoothStatus = scanStatus.isGranted && connectStatus.isGranted
        ? PermissionStatus.granted
        : scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied
            ? PermissionStatus.permanentlyDenied
            : PermissionStatus.denied;
    if (!mounted) return;
    setState(() {
      _bluetoothPermissionStatus = bluetoothStatus;
    });
  }

  void _openSettings() {
    setState(() {
      currentPageIndex = 3; // Profile page index
      profileInitialTabIndex = 1; // Settings tab index
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    if (_locationPermissionStatus == null || _bluetoothPermissionStatus == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_locationPermissionStatus!.isGranted) {
      final isPermanentlyDenied =
          _locationPermissionStatus == PermissionStatus.permanentlyDenied;
      return _buildPermissionScreen(
        context: context,
        icon: Icons.location_off,
        title: l10n.locationPermissionRequiredTitle,
        subtitle: l10n.locationPermissionRequiredSubtitle,
        buttonText: isPermanentlyDenied
            ? l10n.openAppSettings
            : l10n.grantLocationPermission,
        onPressed:
            isPermanentlyDenied ? openAppSettings : _requestLocationPermission,
      );
    }

    if (!_bluetoothPermissionStatus!.isGranted) {
      final isPermanentlyDenied =
          _bluetoothPermissionStatus == PermissionStatus.permanentlyDenied;
      return _buildPermissionScreen(
        context: context,
        icon: Icons.bluetooth_disabled,
        title: l10n.bluetoothPermissionRequiredTitle,
        subtitle: l10n.bluetoothPermissionRequiredSubtitle,
        buttonText: isPermanentlyDenied
            ? l10n.openAppSettings
            : l10n.grantBluetoothPermission,
        onPressed:
            isPermanentlyDenied ? openAppSettings : _requestBluetoothPermissions,
      );
    }

    final hasDiaryUnreadMessages = _diaryService.hasUnreadMessages;
    final hasAnyDiaryPageAlert = _notificationService.unreadCount > 0 || hasDiaryUnreadMessages;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
              if (index != 3) {
                profileInitialTabIndex = 0;
              }
            });
          },
          selectedIndex: currentPageIndex,
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: const Icon(Icons.map),
              icon: const Icon(Icons.map_outlined),
              label: l10n.navMap,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.near_me),
              icon: const Icon(Icons.near_me_outlined),
              label: l10n.navGoTo,
            ),
            NavigationDestination(
              selectedIcon: Badge(
                label: null,
                isLabelVisible: hasAnyDiaryPageAlert,
                child: const Icon(Icons.book),
              ),
              icon: Badge(
                label: null,
                isLabelVisible: hasAnyDiaryPageAlert,
                child: const Icon(Icons.book_outlined),
              ),
              label: l10n.navDiary,
            ),
            NavigationDestination(
              selectedIcon: const Icon(Icons.person),
              icon: const Icon(Icons.person_outlined),
              label: l10n.navProfile,
            ),
          ],
        ),
        body: <Widget>[
          MapPage(onOpenSettings: _openSettings),
          const GoToPage(),
          const DiaryPage(),
          ProfilePage(
            key: ValueKey('profile_tab_$profileInitialTabIndex'),
            initialTabIndex: profileInitialTabIndex,
          ),
        ][currentPageIndex],
      ),
    );
  }
}
