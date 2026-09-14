// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - FLUTTER MAIN ENTRYPOINT
// ==============================================================================
// Section Purpose: Root entrypoint initializing Flutter application, MultiProvider state
// scopes, Material 3 ThemeData, typography system, and initial login screen route.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/production_provider.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CocotuftApp());
}

class CocotuftApp extends StatelessWidget {
  const CocotuftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider<ProductionProvider>(create: (_) => ProductionProvider(apiService)),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryNavy,
            primary: AppColors.primaryNavy,
            secondary: AppColors.secondaryTeal,
            surface: AppColors.surfaceWhite,
            error: AppColors.dangerRed,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
            displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textDark),
            titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textDark),
            titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textDark),
            bodyMedium: GoogleFonts.inter(color: AppColors.textBody),
          ),
          cardTheme: CardThemeData(
            color: AppColors.surfaceWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
            ),
            labelStyle: GoogleFonts.inter(color: AppColors.textMedium, fontSize: 13),
            hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: AppColors.borderLight),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
