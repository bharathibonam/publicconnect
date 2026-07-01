import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/party_setting.dart';

class AppTheme {
  // Fallback / Static Brand Colors (used for initial static theme)
  static const Color primary = Color(0xFF0F766E); // Deep Teal/Emerald
  static const Color primaryLight = Color(0xFF14B8A6); // Bright Teal
  static const Color secondary = Color(0xFF0F172A); // Slate Dark
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color background = Color(0xFFF8FAFC); // Very light slate gray
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Dynamic Theme Generator
  static ThemeData getThemeFromSetting(PartySetting setting) {
    final cPrimary = setting.getPrimaryColor() ?? primary;
    final cSecondary = setting.getSecondaryColor() ?? secondary;
    final cAccent = setting.getAccentColor() ?? accent;
    final cBackground = setting.getBackgroundColor() ?? background;
    final cCardBg = setting.getSurfaceColor() ?? cardBg;
    final cBorder = setting.getBorderColor() ?? border;
    final cTextDark = setting.getTextColor() ?? textDark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cPrimary,
        primary: cPrimary,
        secondary: cSecondary,
        tertiary: cAccent,
        surface: cCardBg,
      ),
      scaffoldBackgroundColor: cBackground,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(
          color: cTextDark,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.outfit(
          color: cTextDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: cTextDark,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textLight,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: cTextDark),
        titleTextStyle: GoogleFonts.outfit(
          color: cTextDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: cCardBg,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        labelStyle: GoogleFonts.outfit(color: textLight),
        hintStyle: GoogleFonts.outfit(color: textLight.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: cPrimary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cPrimary,
          side: BorderSide(color: cPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Fallback for parts of the app still referencing AppTheme.lightTheme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textDark,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textLight,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.outfit(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        labelStyle: GoogleFonts.outfit(color: textLight),
        hintStyle: GoogleFonts.outfit(color: textLight.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
