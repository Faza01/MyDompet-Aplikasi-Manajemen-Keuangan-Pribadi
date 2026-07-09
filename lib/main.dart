import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
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

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
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
        scaffoldBackgroundColor: AppColors.darkScaffold,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: AppColors.accentOrange,
          surface: AppColors.darkCard,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkScaffold,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.snackBarBackground,
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
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBlack,
          secondary: AppColors.accentOrange,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryBlack,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.snackBarBackground,
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
