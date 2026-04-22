import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';

// Main Pages
import 'pages/map_page.dart';
import 'pages/goto_page.dart';
import 'pages/diary_page.dart';
import 'pages/profile_page.dart';

void main() {
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
    setState(() {});
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const MainNavigationScreen(),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

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
              selectedIcon: const Icon(Icons.book),
              icon: const Icon(Icons.book_outlined),
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
          const MapPage(),
          const GoToPage(),
          const DiaryPage(),
          const ProfilePage(),
        ][currentPageIndex],
      ),
    );
  }
}
