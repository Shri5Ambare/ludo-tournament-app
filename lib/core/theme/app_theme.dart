// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(AppConstants.themeModeKey) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeModeKey, state == ThemeMode.dark);
  }
}

class AppColors {
  // Primary palette (Playful)
  static const Color primary = Color(0xFF8E97FD);
  static const Color primaryLight = Color(0xFFADB5FF);
  static const Color primaryDark = Color(0xFF6C76E1);

  static const Color accent = Color(0xFFFFD93D);
  static const Color accentLight = Color(0xFFFFE57F);

  // Player colors (Pastel)
  static const Color redPlayer = Color(0xFFFF6B6B);
  static const Color greenPlayer = Color(0xFF6BCB77);
  static const Color yellowPlayer = Color(0xFFFDCB6E);
  static const Color bluePlayer = Color(0xFF4D96FF);

  // Soft Dark theme
  static const Color darkBg = Color(0xFF1E1E2E);
  static const Color darkSurface = Color(0xFF2E2E3E);
  static const Color darkCard = Color(0xFF3E3E4E);
  static const Color darkBorder = Color(0xFF4E4E6E);

  // Playful Light theme
  static const Color lightBg = Color(0xFFF9F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F1FF);
  static const Color lightBorder = Color(0xFFE0E2FF);

  // Text
  static const Color textLight = Color(0xFFF0F1FF);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF7675);
  static const Color info = Color(0xFF0984E3);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(AppColors.textLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(AppColors.textDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.fredoka(
        fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.fredoka(
        fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.fredoka(
        fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: GoogleFonts.fredoka(
        fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.fredoka(
        fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      titleMedium: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, color: textColor),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, color: textColor),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12, color: textColor.withValues(alpha: 0.7)),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
    );
  }
}
