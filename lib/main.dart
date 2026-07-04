import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/main_navigation_hub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system overlays to transparent for a truly edge-to-edge floating UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  // Enable edge-to-edge mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: KeuanganApp(),
    ),
  );
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class KeuanganApp extends ConsumerWidget {
  const KeuanganApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MyDompet',
      debugShowCheckedModeBanner: false,
      
      // Modern Premium Dark Theme (Core Ledger)
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'General Sans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090F0F), // Deep Slate Teal
        colorScheme: const ColorScheme.dark(
          primary: Colors.white, // White primary for dark mode
          secondary: Color(0xFFFC8A40), // Vibrant Orange
          surface: Color(0xFF131D1D), // Dark Card Surface
          error: Color(0xFFBA1A1A), // Red
          background: Color(0xFF090F0F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090F0F),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF131D1D),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF131D1D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13.0,
            fontFamily: 'General Sans',
          ),
        ),
      ),
      
      // Matching Clean Light Theme (Core Ledger)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'General Sans',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFA), // Off-white
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2C2C2C), // Charcoal primary for light mode
          secondary: Color(0xFF9B4500), // Dark Orange
          surface: Color(0xFFECEEEE), // Soft Mint-Gray surface
          error: Color(0xFFBA1A1A),
          background: Color(0xFFF8FAFA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFA),
          foregroundColor: Color(0xFF191C1D),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E3131),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13.0,
            fontFamily: 'General Sans',
          ),
        ),
      ),
      
      themeMode: themeMode, // Controlled dynamically
      home: const MainNavigationHub(),
    );
  }
}
